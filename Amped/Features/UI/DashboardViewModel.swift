import SwiftUI
@preconcurrency import Combine
import OSLog

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var healthMetrics: [HealthMetric] = []
    @Published var lifeImpactData: LifeImpactData?
    @Published var lifeProjection: LifeProjection?
    @Published var selectedTimePeriod: TimePeriod = .day
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Computed property to expose user's current age
    var currentUserAge: Double {
        return userProfile.age.map(Double.init) ?? 30.0 // Default to 30 if no age available
    }
    
    private let healthKitManager: HealthKitManaging
    private let healthDataService: HealthDataService
    private let lifeImpactService: LifeImpactService
    private let lifeProjectionService: LifeProjectionService
    private let questionnaireManager: QuestionnaireManager
    private let userProfile: UserProfile
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Debug Logging
    private let logger = Logger(subsystem: "com.amped.app", category: "DashboardViewModel")
    
    init(
        healthKitManager: HealthKitManaging? = nil,
        healthDataService: HealthDataService? = nil,
        lifeImpactService: LifeImpactService? = nil,
        lifeProjectionService: LifeProjectionService? = nil,
        questionnaireManager: QuestionnaireManager? = nil,
        userProfile: UserProfile? = nil
    ) {
        // Initialize QuestionnaireManager first
        self.questionnaireManager = questionnaireManager ?? QuestionnaireManager()
        
        // Use profile from questionnaire if available, otherwise create default
        if let profile = userProfile {
            self.userProfile = profile
        } else if let savedProfile = self.questionnaireManager.getCurrentUserProfile() {
            self.userProfile = savedProfile
            logger.info("✅ Using saved user profile from questionnaire")
        } else {
            // CRITICAL FIX: Create a temporary profile with sensible defaults for impact calculations
            // This ensures health metrics can still show impact data even before onboarding completion
            let currentYear = Calendar.current.component(.year, from: Date())
            self.userProfile = UserProfile(
                id: UUID().uuidString,
                birthYear: currentYear - 30, // Default to 30 years old for reasonable baseline calculations
                gender: nil, // Use nil as default neutral gender
                height: nil,
                weight: nil,
                isSubscribed: false,
                hasCompletedOnboarding: false,
                hasCompletedQuestionnaire: false,
                hasGrantedHealthKitPermissions: false,
                createdAt: Date(),
                lastActive: Date()
            )
            logger.info("⚠️ Using default user profile")
        }
        
        // Create default health kit manager and services if none provided
        let healthKitManager = healthKitManager ?? HealthKitManager()
        self.healthKitManager = healthKitManager
        self.healthDataService = healthDataService ?? HealthDataService(
            healthKitManager: healthKitManager,
            userProfile: self.userProfile,
            questionnaireManager: self.questionnaireManager
        )
        self.lifeImpactService = lifeImpactService ?? LifeImpactService(userProfile: self.userProfile)
        self.lifeProjectionService = lifeProjectionService ?? LifeProjectionService()
        
        setupSubscriptions()
        loadData()
    }
    
    private func setupSubscriptions() {
        $selectedTimePeriod
            .sink { [weak self] (timePeriod: TimePeriod) in
                // CRITICAL FIX: Update both health metrics AND life impact when time period changes
                self?.loadDataForPeriod(timePeriod)
            }
            .store(in: &cancellables)
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
                        from: periodMetrics,
                        for: timePeriod,
                        userProfile: userProfile
                    )
                    
                    if let impactData = lifeImpactData {
                        logger.info("⚡ Life impact calculated for \(timePeriod.displayName): \(impactData.totalImpact.displayString)")
                        logger.info("🔋 Battery level: \(String(format: "%.1f", impactData.batteryLevel))%")
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
    
    private func calculateLifeProjection() {
        logger.info("🔮 Calculating life projection...")
        
        lifeProjection = lifeProjectionService.calculateLifeProjection(
            from: self.healthMetrics,
            userProfile: userProfile
        )
        
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
                
                // Calculate life impact
                lifeImpactData = lifeImpactService.calculateLifeImpact(
                    from: periodMetrics,
                    for: self.selectedTimePeriod,
                    userProfile: self.userProfile
                )
                
                // Calculate life projection
                lifeProjection = lifeProjectionService.calculateLifeProjection(
                    from: periodMetrics,
                    userProfile: self.userProfile
                )
                
                self.isLoading = false
                
                if let impactData = lifeImpactData {
                    logger.info("⚡ Refresh complete - Life impact: \(impactData.totalImpact.displayString)")
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
} 