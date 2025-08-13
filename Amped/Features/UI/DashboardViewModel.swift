import SwiftUI
@preconcurrency import Combine
import OSLog
import UIKit
import HealthKit

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        var components = dateComponents([.year, .month, .day], from: date)
        components.day! += 1
        components.second = -1
        return self.date(from: components) ?? date
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let healthKitManager: HealthKitManaging
    private var healthDataService: HealthDataServicing
    private var lifeImpactService: LifeImpactService
    private let lifeProjectionService: LifeProjectionService
    private let questionnaireManager: QuestionnaireManager
    private let streakManager: StreakManager
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "DashboardViewModel")
    
    // MARK: - State Management
    
    @Published var healthMetrics: [HealthMetric] = []
    @Published var lifeImpactData: LifeImpactData?
    @Published var lifeProjection: LifeProjection?
    @Published var optimalHabitsProjection: LifeProjection?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTimePeriod: TimePeriod = .day
    @Published var historicalChartData: [ChartImpactDataPoint] = []
    
    // MARK: - Streak Management
    
    /// Current user engagement streak
    @Published var currentStreak: BatteryStreak = BatteryStreak()
    
    /// New milestone reached today (for celebration UI)
    @Published var newMilestone: StreakMilestone?
    
    /// Whether to show streak celebration
    @Published var showStreakCelebration: Bool = false
    
    // MARK: - Real-time Update Notification
    
    /// Published property to notify when metrics have been refreshed
    @Published var lastMetricUpdateTime: Date = Date()
    
    /// Get the latest value for a specific metric type
    func getLatestMetricValue(for type: HealthMetricType) -> HealthMetric? {
        return healthMetrics.first { $0.type == type }
    }

    /// Expose questionnaire data in a safe, read-only way for UI decisions
    func getQuestionnaireData() -> QuestionnaireData? {
        return questionnaireManager.questionnaireData
    }
    
    // User profile for calculations
    @Published private(set) var userProfile: UserProfile
    
    /// Computed property to expose user's current age
    var currentUserAge: Double {
        return userProfile.age.map(Double.init) ?? 30.0 // Default to 30 if no age available
    }
    
    // Internal properties for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Foreground Auto-Refresh Timer
    
    /// Timer for foreground auto-refresh - follows Apple's 10-second pattern used in Fitness and Health apps
    private var foregroundRefreshTimer: Timer?
    
    /// Track if app is in foreground to control timer
    @Published private(set) var isAppInForeground: Bool = true
    
    /// Interval for foreground refresh (10 seconds - matches Apple Fitness app)
    private let foregroundRefreshInterval: TimeInterval = 10.0
    
    init(
        healthKitManager: HealthKitManaging? = nil,
        healthDataService: HealthDataService? = nil,
        lifeImpactService: LifeImpactService? = nil,
        lifeProjectionService: LifeProjectionService? = nil,
        questionnaireManager: QuestionnaireManager? = nil,
        userProfile: UserProfile? = nil,
        streakManager: StreakManager? = nil
    ) {
        // Local logger to allow logging before all stored properties are initialized
        let initLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "DashboardViewModel.init")

        // Initialize QuestionnaireManager first
        let questionnaireManager = questionnaireManager ?? QuestionnaireManager()
        
        // CRITICAL FIX: Load questionnaire data synchronously to get the correct user profile
        // This prevents falling back to default profile with wrong birth year
        let savedProfile = Self.loadUserProfileSynchronously()
        
        // Choose profile without touching self, then assign
        let chosenProfile: UserProfile
        if let profile = userProfile {
            chosenProfile = profile
            initLogger.info("✅ Using provided user profile: Age \(profile.age ?? 0), Gender: \(profile.gender?.rawValue ?? "none"), Birth Year: \(profile.birthYear ?? 0)")
        } else if let saved = savedProfile {
            chosenProfile = saved
            initLogger.info("✅ Using saved user profile from questionnaire: Age \(saved.age ?? 0), Gender: \(saved.gender?.rawValue ?? "none"), Birth Year: \(saved.birthYear ?? 0)")
        } else {
            let currentYear = Calendar.current.component(.year, from: Date())
            let defaultProfile = UserProfile(
                id: UUID().uuidString,
                birthYear: currentYear - 30,
                gender: nil,
                height: nil,
                weight: nil,
                isSubscribed: false,
                hasCompletedOnboarding: false,
                hasCompletedQuestionnaire: false,
                hasGrantedHealthKitPermissions: false,
                createdAt: Date(),
                lastActive: Date()
            )
            chosenProfile = defaultProfile
            initLogger.info("⚠️ Using default user profile: Age \(defaultProfile.age ?? 0), Birth Year: \(defaultProfile.birthYear ?? 0)")
        }
        self.userProfile = chosenProfile
        
        // Create questionnaire manager first to ensure same instance is used everywhere
        self.questionnaireManager = questionnaireManager
        
        // Create default health kit manager and services if none provided
        let healthKitManager = healthKitManager ?? HealthKitManager()
        self.healthKitManager = healthKitManager
        self.healthDataService = healthDataService ?? HealthDataService(
            healthKitManager: healthKitManager,
            userProfile: chosenProfile,
            questionnaireManager: self.questionnaireManager  // Use the same instance
        )
        self.lifeImpactService = lifeImpactService ?? LifeImpactService(userProfile: chosenProfile)
        self.lifeProjectionService = lifeProjectionService ?? LifeProjectionService()
        self.streakManager = streakManager ?? StreakManager.shared
        
        // Ensure questionnaire data is loaded
        Task {
            await self.questionnaireManager.loadDataIfNeeded()
        }
        
        setupSubscriptions()
        setupStreakObservers()
        loadData()
        
        // Start foreground timer if app is currently active
        // Check app state and start timer if needed
        Task { @MainActor in
            if UIApplication.shared.applicationState == .active {
                self.startForegroundRefreshTimer()
            }
        }
    }
    
    private func setupSubscriptions() {
        $selectedTimePeriod
            .sink { [weak self] (timePeriod: TimePeriod) in
                // CRITICAL FIX: Update both health metrics AND life impact when time period changes
                self?.loadDataForPeriod(timePeriod)
            }
            .store(in: &cancellables)
        
        // Rules: Listen for questionnaire updates to refresh data
        NotificationCenter.default.publisher(for: NSNotification.Name("QuestionnaireDataUpdated"))
            .sink { [weak self] _ in
                self?.logger.info("📝 Questionnaire data updated, refreshing dashboard")
                // Reload user profile to get updated name/data
                if let updatedProfile = self?.reloadUserProfileFromDefaults() {
                    self?.userProfile = updatedProfile
                }
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        // CRITICAL FIX: Listen for HealthKit data updates to refresh calculations in real-time
        NotificationCenter.default.publisher(for: NSNotification.Name("HealthKitDataUpdated"))
            .sink { [weak self] _ in
                self?.logger.info("📱 HealthKit data updated, refreshing dashboard calculations")
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        // Rules: Listen for app data reset
        NotificationCenter.default.publisher(for: NSNotification.Name("AppDataReset"))
            .sink { [weak self] _ in
                self?.logger.info("🗑️ App data reset, clearing and reloading")
                Task {
                    await self?.handleDataReset()
                }
            }
            .store(in: &cancellables)
        
        // NEW: Listen for app foreground/background state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.logger.info("📱 App became active - starting foreground refresh timer")
                self?.startForegroundRefreshTimer()
                self?.isAppInForeground = true
                
                // Immediate refresh when app becomes active
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.logger.info("📱 App entered background - stopping foreground refresh timer")
                self?.stopForegroundRefreshTimer()
                self?.isAppInForeground = false
            }
            .store(in: &cancellables)

        // Listen for profile updates coming from Settings to refresh calculations
        NotificationCenter.default.publisher(for: NSNotification.Name("ProfileDataUpdated"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("👤 Profile updated. Reloading profile and recalculating data")
                self.handleProfileOrManualMetricsUpdate()
            }
            .store(in: &cancellables)

        // Listen for manual metrics updates from Settings
        NotificationCenter.default.publisher(for: NSNotification.Name("ManualMetricsUpdated"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("📝 Manual metrics updated. Recalculating data")
                self.handleProfileOrManualMetricsUpdate(updateProfile: false)
            }
            .store(in: &cancellables)
    }
    
    /// Setup observers for streak management
    private func setupStreakObservers() {
        // Bind streak manager's published properties to our local properties
        streakManager.$currentStreak
            .assign(to: &$currentStreak)
        
        streakManager.$newMilestoneToday
            .sink { [weak self] milestone in
                self?.newMilestone = milestone
                if milestone != nil {
                    self?.showStreakCelebration = true
                }
            }
            .store(in: &cancellables)
    }

    /// Reload profile from UserDefaults (synchronous) and rebuild dependent services
    private func reloadUserProfileFromDefaults() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else { return nil }
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            return profile
        } catch {
            logger.error("❌ Failed to decode updated user profile: \(error.localizedDescription)")
            return nil
        }
    }

    /// Handle profile or manual metric updates by refreshing services and recalculations
    private func handleProfileOrManualMetricsUpdate(updateProfile: Bool = true) {
        // Always invalidate questionnaire cache so manual metrics reload from disk
        QuestionnaireManager.invalidateCache() // Rule: ensure ALL calculations use latest manual data

        if updateProfile, let updated = reloadUserProfileFromDefaults() {
            // Update stored profile and rebuild services that depend on it
            self.userProfile = updated
            self.lifeImpactService = LifeImpactService(userProfile: updated)

            // Rebuild health data service so impact details use updated age/gender
            let newHealthDataService = HealthDataService(
                healthKitManager: self.healthKitManager,
                userProfile: updated,
                questionnaireManager: self.questionnaireManager
            )
            self.healthDataService = newHealthDataService
        }

        // Force questionnaire manager to reload fresh values before recalculation
        Task {
            await self.questionnaireManager.loadDataIfNeeded()
        }

        // Recalculate for currently selected period and projections
        loadDataForPeriod(selectedTimePeriod)
        calculateLifeProjection()
    }
    
    /// Load data for a specific time period (both metrics and impact calculations)
    private func loadDataForPeriod(_ timePeriod: TimePeriod) {
        logger.info("🔄 Loading data for time period: \(timePeriod.displayName)")
        
        Task {
            do {
                logger.info("📊 Fetching period-specific health metrics for \(timePeriod.displayName)")
                let periodMetrics = try await healthDataService.fetchHealthMetricsForPeriod(timePeriod: timePeriod)
                
                await MainActor.run {
                    logger.info("✅ Retrieved \(periodMetrics.count) metrics for \(timePeriod.displayName)")
                    
                    // CRITICAL FIX: Update the displayed health metrics with period-appropriate data
                    self.healthMetrics = periodMetrics
                    
                    // CRITICAL: Notify that metrics have been updated
                    self.lastMetricUpdateTime = Date()
                    
                    // Log each metric in detail
                    for (index, metric) in periodMetrics.enumerated() {
                        if let impact = metric.impactDetails {
                            logger.info("📈 Period Metric \(index + 1): \(metric.type.rawValue) = \(metric.formattedValue) (Impact: \(impact.lifespanImpactMinutes) minutes)")
                        } else {
                            logger.info("📊 Period Metric \(index + 1): \(metric.type.rawValue) = \(metric.formattedValue) (No impact data)")
                        }
                    }
                    
                    // Now calculate life impact with the period-appropriate metrics
                    let metricsWithImpact = periodMetrics.filter { $0.impactDetails != nil }
                    logger.info("📊 Found \(metricsWithImpact.count) metrics with impact data out of \(periodMetrics.count) total")
                    
                    lifeImpactData = lifeImpactService.calculateLifeImpact(
                        from: healthMetrics,
                        for: timePeriod.impactDataPointPeriodType,
                        userProfile: userProfile
                    )
                    
                    if let impactData = lifeImpactData {
                        logger.info("⚡ Life impact calculated for \(timePeriod.displayName): \(impactData.totalImpact.displayString)")
                        logger.info("🔋 Battery level: \(String(format: "%.1f", impactData.batteryLevel))%")
                        
                        // Load historical chart data when impact data is available
                        loadHistoricalChartData()
                    } else {
                        logger.warning("⚠️ No life impact data calculated for \(timePeriod.displayName)")
                    }
                }
            } catch {
                await MainActor.run {
                    logger.error("❌ Failed to fetch period metrics for \(timePeriod.displayName): \(error.localizedDescription)")
                    self.errorMessage = "Failed to load data for \(timePeriod.displayName): \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadData() {
        logger.info("🔄 Starting data load process")
        isLoading = true
        errorMessage = nil
        
        Task {
            // First, check if we have HealthKit permissions
            logger.info("🔐 Checking HealthKit permissions status...")
            logger.info("  - Has all permissions: \(self.healthKitManager.hasAllPermissions)")
            logger.info("  - Has critical permissions: \(self.healthKitManager.hasCriticalPermissions)")
            
            // If we don't have permissions, request them
            if !self.healthKitManager.hasAllPermissions && !self.healthKitManager.hasCriticalPermissions {
                logger.info("📝 No HealthKit permissions found, requesting authorization...")
                
                let permissionsGranted = await self.healthKitManager.requestAuthorization()
                logger.info("✅ Permission request completed. Granted: \(permissionsGranted)")
                
                if !permissionsGranted {
                    await MainActor.run {
                        self.errorMessage = "HealthKit permissions are required for health data analysis"
                        self.isLoading = false
                        logger.warning("⚠️ HealthKit permissions were denied")
                    }
                    return
                }
            } else {
                logger.info("✅ HealthKit permissions already granted")
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
            // CRITICAL FIX: Load data for the currently selected time period
            // This ensures we show period-appropriate data from the start
            loadDataForPeriod(selectedTimePeriod)
            
            // Also calculate life projection (this doesn't depend on time period)
            calculateLifeProjection()
        }
    }
    
    // MARK: - Life Projection Calculations
    
    private func calculateLifeProjection() {
        logger.info("🔮 Calculating life projection for user age: \(self.userProfile.age ?? 0)")
        
        lifeProjection = lifeProjectionService.calculateLifeProjection(
            from: self.healthMetrics,
            userProfile: userProfile
        )
        
        // Also calculate optimal habits projection using scientific pipeline
        optimalHabitsProjection = calculateOptimalHabitsProjection()
        
        if let projection = lifeProjection {
            logger.info("📊 Life projection calculated:")
            logger.info("  - Baseline expectancy: \(String(format: "%.1f", projection.baselineLifeExpectancy)) years")
            logger.info("  - Current age: \(String(format: "%.1f", projection.currentAge)) years")
            logger.info("  - Health adjustment: \(String(format: "%.2f", projection.healthAdjustment)) years")
            logger.info("  - Projected expectancy: \(String(format: "%.1f", projection.projectedLifeExpectancy)) years")
            logger.info("  - Years remaining: \(String(format: "%.1f", projection.yearsRemaining)) years")
            logger.info("  - Percentage remaining: \(String(format: "%.1f", projection.percentageRemaining))%")
        } else {
            logger.warning("⚠️ No life projection calculated")
        }
    }
    
    /// Calculate optimal habits lifespan projection using scientifically-backed optimal values
    /// This represents what the user could achieve with perfect health habits based on research
    func calculateOptimalHabitsProjection() -> LifeProjection? {
        logger.info("🎯 Calculating OPTIMAL habits projection using scientifically-backed perfect values")
        
        // Create truly optimal metrics based on scientific research (not just improved current metrics)
        let optimalMetrics = createScientificallyOptimalMetrics()
        
        // Use the same scientific pipeline as current habits calculation
        let optimalProjection = lifeProjectionService.calculateLifeProjection(
            from: optimalMetrics,
            userProfile: userProfile
        )
        
        if let projection = optimalProjection {
            let currentProjectedYears = self.lifeProjection?.adjustedLifeExpectancyYears ?? projection.baselineLifeExpectancyYears
            let potentialGain = projection.adjustedLifeExpectancyYears - currentProjectedYears
            
            logger.info("✅ OPTIMAL habits projection calculated:")
            logger.info("  - Baseline expectancy: \(String(format: "%.1f", projection.baselineLifeExpectancyYears)) years")
            logger.info("  - OPTIMAL projected expectancy: \(String(format: "%.1f", projection.adjustedLifeExpectancyYears)) years")
            logger.info("  - MAXIMUM improvement potential: \(String(format: "%.1f", potentialGain)) years")
            
            return projection
        } else {
            logger.warning("⚠️ Failed to calculate optimal habits projection")
            return nil
        }
    }
    
    /// Create scientifically optimal health metrics based on peer-reviewed research
    /// This represents the absolute best possible values a person could achieve
    private func createScientificallyOptimalMetrics() -> [HealthMetric] {
        logger.info("🔄 Creating SCIENTIFICALLY OPTIMAL metrics based on research")
        
        var optimalMetrics: [HealthMetric] = []
        let now = Date()
        
        // PHYSICAL ACTIVITY METRICS - Research-backed optimal values
        
        // Steps: Saint-Maurice et al. (2020) JAMA - 10,000 steps optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_steps",
            type: .steps,
            value: 12000, // Slightly above optimal to maximize benefit
            date: now,
            source: .calculated
        ))
        
        // Exercise: WHO/AHA guidelines + research - 150-300 min/week optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_exercise",
            type: .exerciseMinutes,
            value: 45, // 45 min/day = 315 min/week (above WHO optimal)
            date: now,
            source: .calculated
        ))
        
        // CARDIOVASCULAR METRICS - Research-backed optimal values
        
        // Sleep: Jike et al. (2018) meta-analysis - 7-8 hours optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_sleep",
            type: .sleepHours,
            value: 7.5, // Perfect middle of optimal range
            date: now,
            source: .calculated
        ))
        
        // Resting Heart Rate: Aune et al. (2013) CMAJ - 60 bpm optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_rhr",
            type: .restingHeartRate,
            value: 55, // Excellent athlete-level RHR
            date: now,
            source: .calculated
        ))
        
        // HRV: Higher is better, age-adjusted excellent value
        let age = Double(userProfile.age ?? 30)
        let optimalHRV = max(50.0, 60.0 - (age - 30) * 0.5) // Age-adjusted excellent HRV
        optimalMetrics.append(HealthMetric(
            id: "optimal_hrv",
            type: .heartRateVariability,
            value: optimalHRV,
            date: now,
            source: .calculated
        ))
        
        // LIFESTYLE METRICS - Perfect questionnaire values (scale 1-10)
        
        // Smoking: Perfect score (never smoked)
        optimalMetrics.append(HealthMetric(
            id: "optimal_smoking",
            type: .smokingStatus,
            value: 10, // Never smoked (best possible)
            date: now,
            source: .calculated
        ))
        
        // Alcohol: Wood et al. (2018) Lancet - minimal consumption optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_alcohol",
            type: .alcoholConsumption,
            value: 9, // Very minimal alcohol consumption
            date: now,
            source: .calculated
        ))
        
        // Stress: Chronic stress research - very low stress optimal
        optimalMetrics.append(HealthMetric(
            id: "optimal_stress",
            type: .stressLevel,
            value: 2, // Very low stress level
            date: now,
            source: .calculated
        ))
        
        // Nutrition: Mediterranean diet research - excellent quality
        optimalMetrics.append(HealthMetric(
            id: "optimal_nutrition",
            type: .nutritionQuality,
            value: 9, // Excellent Mediterranean-style nutrition
            date: now,
            source: .calculated
        ))
        
        // Social Connections: Loneliness mortality research - strong connections
        optimalMetrics.append(HealthMetric(
            id: "optimal_social",
            type: .socialConnectionsQuality,
            value: 8, // Strong social connections
            date: now,
            source: .calculated
        ))
        
        // BODY COMPOSITION METRICS
        
        // Body Mass: BMI research - optimal BMI ~22-23
        let gender = userProfile.gender ?? .male
        let optimalWeight = gender == .male ? 155.0 : 135.0 // Healthy BMI for average height
        optimalMetrics.append(HealthMetric(
            id: "optimal_weight",
            type: .bodyMass,
            value: optimalWeight,
            date: now,
            source: .calculated
        ))
        
        // VO2 Max: Cardiovascular fitness research - excellent for age/gender
        let genderMultiplier = gender == .male ? 1.0 : 0.88
        let baseVO2Max = 50.0 * genderMultiplier // Excellent fitness level
        let ageAdjustedVO2Max = max(baseVO2Max - max(0, age - 30) * 0.3, 35.0 * genderMultiplier)
        optimalMetrics.append(HealthMetric(
            id: "optimal_vo2max",
            type: .vo2Max,
            value: ageAdjustedVO2Max,
            date: now,
            source: .calculated
        ))
        
        // Active Energy: Calorie expenditure research - excellent daily burn
        optimalMetrics.append(HealthMetric(
            id: "optimal_energy",
            type: .activeEnergyBurned,
            value: 600, // Excellent active calories per day
            date: now,
            source: .calculated
        ))
        
        // Oxygen Saturation: Optimal healthy level
        optimalMetrics.append(HealthMetric(
            id: "optimal_oxygen",
            type: .oxygenSaturation,
            value: 98, // Perfect oxygen saturation
            date: now,
            source: .calculated
        ))
        
        logger.info("🎯 Created \(optimalMetrics.count) scientifically optimal metrics")
        
        // Log each optimal metric for debugging
        for metric in optimalMetrics {
            logger.info("  🔬 Optimal \(metric.type.displayName): \(String(format: "%.1f", metric.value))")
        }
        
        return optimalMetrics
    }
    
    /// Improve a metric only if it's currently suboptimal, otherwise keep it unchanged
    private func improveMetricIfSuboptimal(_ metric: HealthMetric) -> HealthMetric {
        let improvedValue: Double
        
        switch metric.type {
        // Physical Activity Metrics
        case .steps:
            // Optimal: 10,000 steps (Saint-Maurice et al. 2020 JAMA)
            improvedValue = metric.value < 10000 ? min(10000, metric.value * 1.5) : metric.value
            
        case .exerciseMinutes:
            // Optimal: 30 minutes daily (WHO/AHA guidelines)
            improvedValue = metric.value < 30 ? min(30, metric.value * 2.0) : metric.value
            
        // Cardiovascular Metrics
        case .sleepHours:
            // Optimal: 7-8 hours (Jike et al. 2018 meta-analysis)
            if metric.value < 7.0 {
                improvedValue = min(7.5, metric.value + 1.5)
            } else if metric.value > 8.5 {
                improvedValue = max(7.5, metric.value - 1.0)
            } else {
                improvedValue = metric.value // Already optimal
            }
            
        case .restingHeartRate:
            // Optimal: 50-70 bpm for adults
            if metric.value > 70 {
                improvedValue = max(65, metric.value - 10)
            } else if metric.value < 50 {
                improvedValue = min(60, metric.value + 5)
            } else {
                improvedValue = metric.value // Already optimal
            }
            
        case .heartRateVariability:
            // Optimal: Higher is better, age-adjusted
            improvedValue = metric.value < 40 ? min(50, metric.value * 1.3) : metric.value
            
        // Lifestyle Metrics (questionnaire data)
        case .smokingStatus:
            // Scale 1-10 where 10 = never smoked, improve if below 8
            improvedValue = metric.value < 8 ? min(10, metric.value + 3) : metric.value
            
        case .alcoholConsumption:
            // Scale 1-10 where 10 = no alcohol, improve if below 7
            improvedValue = metric.value < 7 ? min(9, metric.value + 2) : metric.value
            
        case .stressLevel:
            // Scale 1-10 where lower is better, improve if above 4
            improvedValue = metric.value > 4 ? max(2, metric.value - 2) : metric.value
            
        case .nutritionQuality:
            // Scale 1-10 where higher is better, improve if below 7
            improvedValue = metric.value < 7 ? min(9, metric.value + 2) : metric.value
            
        case .socialConnectionsQuality:
            // Scale 1-10 where higher is better, improve if below 6
            improvedValue = metric.value < 6 ? min(8, metric.value + 2) : metric.value
            
        default:
            // For other metrics, keep unchanged
            improvedValue = metric.value
        }
        
        // Create new metric with improved value but same other properties
        return HealthMetric(
            id: "improved_\(metric.id)",
            type: metric.type,
            value: improvedValue,
            date: metric.date,
            source: metric.source,
            impactDetails: metric.impactDetails // Keep original impact details for now
        )
    }
    
    func refreshData() async {
        logger.info("🔄 Manual data refresh requested")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Check and request HealthKit permissions if needed
        if !healthKitManager.hasAllPermissions && !healthKitManager.hasCriticalPermissions {
            logger.info("📝 No HealthKit permissions found, requesting authorization...")
            
            let permissionsGranted = await healthKitManager.requestAuthorization()
            logger.info("✅ Permission request completed. Granted: \(permissionsGranted)")
            
            if !permissionsGranted {
                await MainActor.run {
                    self.errorMessage = "HealthKit permissions are required for health data analysis"
                    self.isLoading = false
                    logger.warning("⚠️ HealthKit permissions were denied")
                }
                return
            }
        }
        
        // Fetch fresh data
        do {
            logger.info("📊 Fetching period-specific health metrics for \(self.selectedTimePeriod.displayName)")
            let periodMetrics = try await healthDataService.fetchHealthMetricsForPeriod(timePeriod: self.selectedTimePeriod)
            
            await MainActor.run {
                logger.info("✅ Retrieved \(periodMetrics.count) metrics for \(self.selectedTimePeriod.displayName)")
                
                // Update the displayed health metrics
                self.healthMetrics = periodMetrics
                
                // CRITICAL: Notify that metrics have been updated
                self.lastMetricUpdateTime = Date()
                
                // Calculate life impact
                lifeImpactData = lifeImpactService.calculateLifeImpact(
                    from: periodMetrics,
                    for: self.selectedTimePeriod.impactDataPointPeriodType,
                    userProfile: self.userProfile
                )
                
                // Calculate life projection
                lifeProjection = lifeProjectionService.calculateLifeProjection(
                    from: periodMetrics,
                    userProfile: self.userProfile
                )
                
                // Also recalculate optimal habits projection
                optimalHabitsProjection = calculateOptimalHabitsProjection()
                
                self.isLoading = false
                
                if let impactData = lifeImpactData {
                    logger.info("⚡ Refresh complete - Life impact: \(impactData.totalImpact.displayString)")
                }
                
                // Load historical chart data after refresh
                loadHistoricalChartData()
                
                // Record engagement for streak tracking
                // Only record if we have meaningful health data
                if !periodMetrics.isEmpty {
                    self.recordUserEngagement()
                }
            }
        } catch {
            await MainActor.run {
                logger.error("❌ Failed to refresh data: \(error.localizedDescription)")
                self.errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Handle app data reset
    private func handleDataReset() async {
        await MainActor.run {
            // Clear all data
            healthMetrics = []
            lifeImpactData = nil
            lifeProjection = nil
            errorMessage = nil
        }
        
        // Reload fresh data
        loadData()
    }
    
    // MARK: - Foreground Auto-Refresh System
    
    /// Start the foreground refresh timer - follows Apple's pattern of regular updates when app is active
    private func startForegroundRefreshTimer() {
        // Stop any existing timer first
        stopForegroundRefreshTimer()
        
        logger.info("⏰ Starting foreground refresh timer (every \(Int(self.foregroundRefreshInterval)) seconds)")
        
        foregroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: self.foregroundRefreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Use Task to handle main actor isolation properly
            Task { @MainActor in
                // Only refresh if app is still in foreground and not currently loading
                guard self.isAppInForeground && !self.isLoading else {
                    return
                }
                
                self.logger.debug("⏰ Foreground timer triggered - refreshing HealthKit data")
                await self.performLightweightRefresh()
            }
        }
        
        // Ensure timer runs in common run loop modes for responsiveness
        if let timer = foregroundRefreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// Stop the foreground refresh timer
    private func stopForegroundRefreshTimer() {
        foregroundRefreshTimer?.invalidate()
        foregroundRefreshTimer = nil
        logger.debug("⏸️ Stopped foreground refresh timer")
    }
    
    /// Perform lightweight refresh - optimized for frequent execution
    private func performLightweightRefresh() async {
        // Skip if already loading to prevent overlapping refreshes
        guard !isLoading else {
            logger.debug("⏸️ Skipping foreground refresh - already loading")
            return
        }
        
        logger.debug("🔄 Performing lightweight foreground refresh")
        
        do {
            // Quick fetch of current period metrics without showing loading state
            let freshMetrics = try await healthDataService.fetchHealthMetricsForPeriod(timePeriod: selectedTimePeriod)
            
            // Only update if data has actually changed to avoid unnecessary UI updates
            let countChanged = healthMetrics.count != freshMetrics.count
            let valuesChanged = !zip(healthMetrics, freshMetrics).allSatisfy { existing, fresh in
                existing.value == fresh.value && existing.date == fresh.date
            }
            let hasChanges = countChanged || valuesChanged
            
            if hasChanges {
                logger.debug("✅ Found updated health data - refreshing calculations")
                
                await MainActor.run {
                    self.healthMetrics = freshMetrics
                    
                    // CRITICAL: Notify that metrics have been updated
                    self.lastMetricUpdateTime = Date()
                    
                    // Recalculate life impact with fresh data
                    self.lifeImpactData = self.lifeImpactService.calculateLifeImpact(
                        from: freshMetrics,
                        for: self.selectedTimePeriod.impactDataPointPeriodType,
                        userProfile: self.userProfile
                    )
                    
                    // Recalculate life projection
                    self.lifeProjection = self.lifeProjectionService.calculateLifeProjection(
                        from: freshMetrics,
                        userProfile: self.userProfile
                    )
                }
            } else {
                logger.debug("📊 No changes in health data - skipping calculations")
            }
            
        } catch {
            // Log error but don't show to user since this is background refresh
            logger.warning("⚠️ Lightweight refresh failed: \(error.localizedDescription)")
        }
    }
    
    /// Get status of auto-refresh system for debugging
    var autoRefreshStatus: String {
        var status = "Auto-Refresh Status:\n"
        status += "• Foreground Timer: \(foregroundRefreshTimer != nil ? "Active" : "Inactive")\n"
        status += "• App State: \(isAppInForeground ? "Foreground" : "Background")\n"
        status += "• Refresh Interval: \(Int(foregroundRefreshInterval))s\n"
        status += "• Background Health Manager: Available"
        return status
    }

    // MARK: - Chart Data Generation
    
    /// Calculate neutral baseline impact for comparison
    @Published private var neutralBaseline: Double = 0.0
    
    /// Generate collective impact chart data points showing real historical data
    func generateCollectiveImpactChartData() -> [ChartImpactDataPoint] {
        // Return current historicalChartData if available, otherwise empty
        // The real data will be loaded asynchronously
        return historicalChartData
    }
    
    /// Load real historical chart data with TradingView-style progression
    func loadHistoricalChartData() {
        guard lifeImpactData != nil else { 
            logger.warning("⚠️ No lifeImpactData available for chart generation")
            historicalChartData = []
            return 
        }
        
        let now = Date()
        logger.info("📊 Loading TradingView-style historical data for \(self.selectedTimePeriod.displayName)")
        
        // Clear existing data to show loading state
        historicalChartData = []
        
        // Generate realistic historical data based on selected period
        Task {
            let chartData: [ChartImpactDataPoint]
            
            switch selectedTimePeriod {
            case .day:
                chartData = await generateTradingViewStyleHourlyData(currentDate: now)
            case .month:
                chartData = await generateTradingViewStyleDailyData(currentDate: now, days: 30)
            case .year:
                chartData = await generateTradingViewStyleMonthlyData(currentDate: now, months: 12)
            }
            
            await MainActor.run {
                self.historicalChartData = chartData
                logger.info("✅ Loaded \(chartData.count) TradingView-style chart points for \(self.selectedTimePeriod.displayName)")
                if let lastPoint = chartData.last {
                    logger.info("  📍 Final chart impact: \(String(format: "%.2f", lastPoint.impact)) minutes")
                }
            }
        }
    }

    // MARK: - TradingView-Style Chart Generation
    
    /// Generate TradingView-style hourly data showing actual hourly impacts (scaled for day period)
    private func generateTradingViewStyleHourlyData(currentDate: Date) async -> [ChartImpactDataPoint] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let currentHour = calendar.component(.hour, from: currentDate)
        var chartPoints: [ChartImpactDataPoint] = []
        
        logger.info("📊 Generating TradingView-style hourly data (Day period scaling) - REAL DATA ONLY")
        
        // TradingView approach: Only create chart points where we have actual data
        for hour in 0...currentHour {
            guard let hourTime = calendar.date(byAdding: .hour, value: hour, to: startOfDay) else { continue }
            
            // Calculate impact using ONLY real data available at this time
            let hourImpact = await calculatePeriodScaledImpactAtTime(hourTime, periodType: .day)
            
            // TradingView approach: Only add points where we have real data
            // If calculation returned 0, it means no real data was available
            if hourImpact != 0 {
                logger.info("  Hour \(hour): REAL impact = \(String(format: "%.2f", hourImpact)) minutes")
                
                chartPoints.append(ChartImpactDataPoint(
                    date: hourTime,
                    impact: hourImpact,
                    value: 0 // Not used for collective impact display
                ))
            } else {
                logger.info("  Hour \(hour): No real data available - creating gap like TradingView")
            }
        }
        
        // CRITICAL: Ensure the final point matches the headline exactly (if we have data)
        if !chartPoints.isEmpty, let lifeImpactData = self.lifeImpactData {
            let headlineImpact = lifeImpactData.totalImpact.value * (lifeImpactData.totalImpact.direction == .positive ? 1.0 : -1.0)
            let lastPoint = chartPoints[chartPoints.count - 1]
            chartPoints[chartPoints.count - 1] = ChartImpactDataPoint(
                date: lastPoint.date,
                impact: headlineImpact,
                value: lastPoint.value
            )
            logger.info("  📍 Final point synchronized with headline: \(String(format: "%.2f", headlineImpact)) minutes")
        }
        
        return chartPoints
    }

    /// Generate TradingView-style daily data showing actual daily impacts (scaled for month period)
    private func generateTradingViewStyleDailyData(currentDate: Date, days: Int) async -> [ChartImpactDataPoint] {
        let calendar = Calendar.current
        var chartPoints: [ChartImpactDataPoint] = []
        
        logger.info("📊 Generating TradingView-style daily data (Month period scaling) - REAL DATA ONLY")
        
        // TradingView approach: Only process days where we might have actual data
        for dayOffset in -days+1...0 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) else { continue }
            
            // Use end of day for complete data availability
            let dayEnd = calendar.date(byAdding: .hour, value: 23, to: calendar.startOfDay(for: dayDate)) ?? dayDate
            
            // Skip future dates (TradingView doesn't show future data)
            if dayEnd > Date() { continue }
            
            // Calculate impact using ONLY real data available for this day
            let dayImpact = await calculatePeriodScaledImpactAtTime(dayEnd, periodType: .month)
            
            // TradingView approach: Only add points where we have real data
            if dayImpact != 0 {
                logger.info("  Day \(dayOffset): REAL impact = \(String(format: "%.2f", dayImpact)) minutes")
                
                chartPoints.append(ChartImpactDataPoint(
                    date: dayDate,
                    impact: dayImpact,
                    value: 0 // Not used for collective impact display
                ))
            } else {
                logger.info("  Day \(dayOffset): No real data available - creating gap like TradingView")
            }
        }
        
        // CRITICAL: Ensure the final point matches the headline exactly (if we have data)
        if !chartPoints.isEmpty, let lifeImpactData = self.lifeImpactData {
            let headlineImpact = lifeImpactData.totalImpact.value * (lifeImpactData.totalImpact.direction == .positive ? 1.0 : -1.0)
            let lastPoint = chartPoints[chartPoints.count - 1]
            chartPoints[chartPoints.count - 1] = ChartImpactDataPoint(
                date: lastPoint.date,
                impact: headlineImpact,
                value: lastPoint.value
            )
            logger.info("  📍 Final point synchronized with headline: \(String(format: "%.2f", headlineImpact)) minutes")
        }
        
        return chartPoints
    }

    /// Generate TradingView-style monthly data showing actual monthly impacts (scaled for year period)
    private func generateTradingViewStyleMonthlyData(currentDate: Date, months: Int) async -> [ChartImpactDataPoint] {
        let calendar = Calendar.current
        var chartPoints: [ChartImpactDataPoint] = []
        
        logger.info("📊 Generating TradingView-style monthly data (Year period scaling) - REAL DATA ONLY")
        
        // TradingView approach: Only process months where we might have actual data
        for monthOffset in -months+1...0 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: currentDate) else { continue }
            
            // Use end of month for complete data availability
            guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
                  let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) else { continue }
            
            // Skip future dates (TradingView doesn't show future data)
            if endOfMonth > Date() { continue }
            
            // Calculate impact using ONLY real data available for this month
            let monthImpact = await calculatePeriodScaledImpactAtTime(endOfMonth, periodType: .year)
            
            // TradingView approach: Only add points where we have real data
            if monthImpact != 0 {
                logger.info("  Month \(monthOffset): REAL impact = \(String(format: "%.2f", monthImpact)) minutes")
                
                chartPoints.append(ChartImpactDataPoint(
                    date: monthDate,
                    impact: monthImpact,
                    value: 0 // Not used for collective impact display
                ))
            } else {
                logger.info("  Month \(monthOffset): No real data available - creating gap like TradingView")
            }
        }
        
        // CRITICAL: Ensure the final point matches the headline exactly (if we have data)
        if !chartPoints.isEmpty, let lifeImpactData = self.lifeImpactData {
            let headlineImpact = lifeImpactData.totalImpact.value * (lifeImpactData.totalImpact.direction == .positive ? 1.0 : -1.0)
            let lastPoint = chartPoints[chartPoints.count - 1]
            chartPoints[chartPoints.count - 1] = ChartImpactDataPoint(
                date: lastPoint.date,
                impact: headlineImpact,
                value: lastPoint.value
            )
            logger.info("  📍 Final point synchronized with headline: \(String(format: "%.2f", headlineImpact)) minutes")
        }
        
        return chartPoints
    }
    
    /// Calculate period-scaled impact at a specific time using ONLY real data (like TradingView)
    private func calculatePeriodScaledImpactAtTime(_ targetTime: Date, periodType: ImpactDataPoint.PeriodType) async -> Double {
        let lifeImpactService = LifeImpactService(userProfile: self.userProfile)
        var hasAnyRealData = false
        
        // Collect all available metrics at the target time - TradingView approach: REAL DATA ONLY
        var metricsAtTime: [HealthMetric] = []
        
        for metricType in HealthMetricType.allCases {
            if let metricValue = await getMetricValueAtTime(metricType, targetTime: targetTime) {
                let metric = HealthMetric(
                    id: UUID().uuidString,
                    type: metricType,
                    value: metricValue.value,
                    date: targetTime,
                    source: HealthMetricSource(rawValue: metricValue.source) ?? .healthKit
                )
                metricsAtTime.append(metric)
                hasAnyRealData = true
                
                logger.debug("  ✅ Real data found for \(metricType.displayName): \(String(format: "%.2f", metricValue.value))")
            } else {
                logger.debug("  ❌ No real data for \(metricType.displayName) at \(targetTime)")
            }
        }
        
        // TradingView approach: If no real data exists, return 0 (creates gap in chart)
        if !hasAnyRealData {
            logger.info("  🚫 No real data available for any metrics at \(targetTime) - TradingView gap")
            return 0.0
        }
        
        // Calculate impact using the same sophisticated logic as headline, but only with real data
        let impactDataPoint = lifeImpactService.calculateTotalImpact(from: metricsAtTime, for: periodType)
        
        let scaledImpact = impactDataPoint.totalImpactMinutes
        logger.info("  📊 Real impact calculated: \(String(format: "%.2f", scaledImpact)) minutes from \(metricsAtTime.count) real metrics")
        
        return scaledImpact
    }
    
    /// Get the actual metric value at a specific time using 100% real data (like TradingView)
    private func getMetricValueAtTime(_ metricType: HealthMetricType, targetTime: Date) async -> (value: Double, source: String)? {
        // Handle manual metrics (from questionnaire) - TradingView approach
        if !metricType.isHealthKitMetric {
            // Manual metrics represent lifestyle patterns that don't change minute-by-minute
            // Like TradingView showing last known price, we use current questionnaire value
            if self.questionnaireManager.manualMetrics.isEmpty && self.questionnaireManager.hasCompletedQuestionnaire {
                await self.questionnaireManager.loadDataIfNeeded()
            }
            
            let manualMetricInputs = self.questionnaireManager.getCurrentManualMetrics()
            
            if let manualInput = manualMetricInputs.first(where: { $0.type == metricType }) {
                // TradingView approach: Use actual value (no artificial variations)
                // Manual metrics represent consistent lifestyle patterns
                return (value: manualInput.value, source: "Manual")
            }
            // TradingView approach: If no data exists, return nil (gap in chart)
            return nil
        }
        
        // Handle HealthKit metrics using REAL historical data only
        let calendar = Calendar.current
        
        // For cumulative metrics, get the actual total for that specific day
        if metricType == .steps || metricType == .exerciseMinutes || metricType == .activeEnergyBurned {
            // Get real cumulative total for the specific day (like TradingView getting actual volume)
            if let cumulativeValue = await fetchCumulativeValueForDay(metricType: metricType, targetTime: targetTime) {
                return (value: cumulativeValue, source: "healthKit")
            }
            // TradingView approach: If no real data exists, return nil (gap)
            return nil
        }
        
        // For status metrics, get the actual HealthKit reading for that day
        let startOfDay = calendar.startOfDay(for: targetTime)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? targetTime
        
        // Fetch actual historical HealthKit data (no artificial generation)
        let healthKitData = await healthKitManager.fetchData(for: metricType, from: startOfDay, to: endOfDay)
        
        // Use actual data that was recorded before or at the target time
        let validData = healthKitData.filter { $0.date <= targetTime }
        
        if let latestMetric = validData.last {
            // TradingView approach: Use actual recorded data
            return (value: latestMetric.value, source: latestMetric.source.rawValue)
        }
        
        // TradingView approach: If no real data exists for this time, return nil (creates gap)
        return nil
    }
    
    /// Fetch cumulative value for a specific day up to the target time
    private func fetchCumulativeValueForDay(metricType: HealthMetricType, targetTime: Date) async -> Double? {
        guard let quantityType = metricType.healthKitType,
              let unit = metricType.unit else { return nil }
        
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        
        // For cumulative metrics, we want data from start of day to the target time
        let startOfDay = calendar.startOfDay(for: targetTime)
        
        // Create predicate for the time range
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: targetTime, options: .strictEndDate)
        
        do {
            // Use HKStatisticsQuery to get the cumulative sum
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statistics)
                }
                
                healthStore.execute(query)
            }
            
            // Extract the cumulative sum
            if let sumQuantity = statistics?.sumQuantity() {
                let value = sumQuantity.doubleValue(for: unit)
                return value
            }
            
            return nil
        } catch {
            logger.error("Failed to fetch cumulative value for \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// FIXED: Get appropriate time windows for different metric types
    /// Based on how long the data is typically valid, not artificial availability logic
    private func getAppropriateTimeWindow(for metricType: HealthMetricType, targetTime: Date, calendar: Calendar) -> (Date, Date) {
        switch metricType {
        case .sleepHours:
            // Sleep: Look for sleep data from the night before (past 24 hours)
            let past24Hours = calendar.date(byAdding: .hour, value: -24, to: targetTime) ?? targetTime
            return (past24Hours, targetTime)
            
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            // Cumulative metrics: From start of current day to target time
            let startOfDay = calendar.startOfDay(for: targetTime)
            return (startOfDay, targetTime)
            
        case .restingHeartRate:
            // Resting HR: Past 24 hours (typically measured during sleep/rest)
            let past24Hours = calendar.date(byAdding: .hour, value: -24, to: targetTime) ?? targetTime
            return (past24Hours, targetTime)
            
        case .heartRateVariability:
            // HRV: Past 24 hours (typically from sleep)
            let past24Hours = calendar.date(byAdding: .hour, value: -24, to: targetTime) ?? targetTime
            return (past24Hours, targetTime)
            
        case .bodyMass:
            // Weight: Past week (doesn't change rapidly)
            let pastWeek = calendar.date(byAdding: .day, value: -7, to: targetTime) ?? targetTime
            return (pastWeek, targetTime)
            
        case .vo2Max:
            // VO2 Max: Past month (measured infrequently)
            let pastMonth = calendar.date(byAdding: .month, value: -1, to: targetTime) ?? targetTime
            return (pastMonth, targetTime)
            
        case .oxygenSaturation:
            // Oxygen sat: Past 24 hours
            let past24Hours = calendar.date(byAdding: .hour, value: -24, to: targetTime) ?? targetTime
            return (past24Hours, targetTime)
            
        default:
            // Default: Past 24 hours
            let past24Hours = calendar.date(byAdding: .hour, value: -24, to: targetTime) ?? targetTime
            return (past24Hours, targetTime)
        }
    }
    
    /// Load user profile synchronously from UserDefaults to prevent fallback to default profile
    /// This ensures we get the correct birth year immediately without async delays
    private static func loadUserProfileSynchronously() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else {
            return nil
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            return profile
        } catch {
            print("Failed to decode user profile synchronously: \(error)")
            return nil
        }
    }
    
    // MARK: - Streak Management Methods
    
    /// Record user engagement for streak tracking
    private func recordUserEngagement() {
        streakManager.recordEngagement()
        logger.info("📈 User engagement recorded for streak tracking")
    }
    
    /// Get encouragement message based on current streak
    func getStreakMessage() -> String {
        return streakManager.getStreakStatusMessage()
    }
    
    /// Get detailed encouragement message
    func getEncouragementMessage() -> String {
        return streakManager.getEncouragementMessage()
    }
    
    /// Dismiss milestone celebration
    func dismissMilestoneCelebration() {
        showStreakCelebration = false
        newMilestone = nil
    }
    
    /// Check if streak needs protection (for UI warnings)
    func streakNeedsProtection() -> Bool {
        return streakManager.needsStreakProtection()
    }
    
    /// Cleanup when view model is deallocated
    deinit {
        // Direct timer cleanup is synchronous and safe in deinit
        foregroundRefreshTimer?.invalidate()
        foregroundRefreshTimer = nil
        logger.info("🗑️ DashboardViewModel deallocated - stopped foreground refresh timer")
    }
}
