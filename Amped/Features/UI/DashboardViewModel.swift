import SwiftUI
@preconcurrency import Combine
import OSLog
import UIKit

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let healthKitManager: HealthKitManaging
    private let healthDataService: HealthDataServicing
    private let lifeImpactService: LifeImpactService
    private let lifeProjectionService: LifeProjectionService
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "DashboardViewModel")
    
    // MARK: - State Management
    
    @Published var healthMetrics: [HealthMetric] = []
    @Published var lifeImpactData: LifeImpactData?
    @Published var lifeProjection: LifeProjection?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTimePeriod: TimePeriod = .day
    
    // MARK: - Real-time Update Notification
    
    /// Published property to notify when metrics have been refreshed
    @Published var lastMetricUpdateTime: Date = Date()
    
    /// Get the latest value for a specific metric type
    func getLatestMetricValue(for type: HealthMetricType) -> HealthMetric? {
        return healthMetrics.first { $0.type == type }
    }
    
    // User profile for calculations
    internal let userProfile: UserProfile
    
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
        userProfile: UserProfile? = nil
    ) {
        // Initialize QuestionnaireManager first
        let questionnaireManager = questionnaireManager ?? QuestionnaireManager()
        
        // Use profile from questionnaire if available, otherwise create default
        if let profile = userProfile {
            self.userProfile = profile
        } else if let savedProfile = questionnaireManager.getCurrentUserProfile() {
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
            questionnaireManager: questionnaireManager
        )
        self.lifeImpactService = lifeImpactService ?? LifeImpactService(userProfile: self.userProfile)
        self.lifeProjectionService = lifeProjectionService ?? LifeProjectionService()
        
        setupSubscriptions()
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

    /// Cleanup when view model is deallocated
    deinit {
        // Direct timer cleanup is synchronous and safe in deinit
        foregroundRefreshTimer?.invalidate()
        foregroundRefreshTimer = nil
        logger.info("🗑️ DashboardViewModel deallocated - stopped foreground refresh timer")
    }
} 