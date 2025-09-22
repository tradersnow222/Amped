import Foundation
import HealthKit
import OSLog
@preconcurrency import Combine

/// ViewModel for the health permissions view
@MainActor final class HealthKitPermissionsViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Data for each health metric in the permissions UI
    struct HealthMetricUIItem: Identifiable {
        let id = UUID()
        let type: HealthMetricType
        let icon: String
        let title: String
        let description: String
        let isGranted: Bool
        let isCritical: Bool
    }
    
    private let healthKitManager: HealthKitManaging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitPermissionsViewModel")
    private var healthMetricItems: [HealthMetricUIItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    /// Published properties for UI binding
    @Published var healthMetrics: [HealthMetricUIItem] = []
    @Published var allPermissionsGranted: Bool = false
    @Published var criticalPermissionsGranted: Bool = false
    @Published var isRequestingPermissions: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
        
        // Configure the health metrics UI data
        setupHealthMetricsData()
        
        // Setup bindings from the HealthKitManager
        setupBindings()
    }
    
    convenience init() {
        self.init(healthKitManager: HealthKitManager())
    }
    
    // MARK: - Public Methods
    
    /// Request HealthKit permissions
    func requestHealthKitPermissions() async -> Bool {
        guard checkHealthKitAvailability() else {
            showError(with: "HealthKit is not available on this device.")
            return false
        }
        
        logger.info("Requesting HealthKit permissions")
        
        // Clear any existing error state before proceeding
        clearErrorState()
        
        isRequestingPermissions = true
        
        // Force a manual permission check first to avoid unnecessary requests
        // This helps when permissions are already granted but not properly detected
        await checkPermissionsStatus(forceRefresh: true)
        
        // If permissions are already granted, return success
        if allPermissionsGranted {
            logger.info("Permissions already granted, no need to request again")
            isRequestingPermissions = false
            return true
        }
        
        // If at least critical permissions are granted, we can also return success
        if criticalPermissionsGranted {
            logger.info("Critical permissions already granted, no need to request again")
            isRequestingPermissions = false
            return true
        }
        
        // If not, request permissions for all health metric types
        let granted = await healthKitManager.requestAuthorization()
        
        isRequestingPermissions = false
        
        if granted {
            logger.info("HealthKit permissions granted successfully")
            
            // Refresh the UI with the updated permissions
            await checkPermissionsStatus(forceRefresh: true)
            
            return true
        } else {
            logger.warning("Failed to get all HealthKit permissions")
            
            // Check permissions status to update UI with forced refresh
            await checkPermissionsStatus(forceRefresh: true)
            
            // Only show error if critical permissions are missing
            if !criticalPermissionsGranted {
                showError(with: "Some required health permissions were not granted. These are needed for Amped to calculate your life battery.")
            }
            
            return criticalPermissionsGranted
        }
    }
    
    /// Check the current status of permissions
    func checkPermissionsStatus(forceRefresh: Bool = false) async {
        guard checkHealthKitAvailability() else {
            return
        }
        
        // Multiple attempts to ensure we get accurate permission status
        // This helps address race conditions or caching issues with HealthKit
        for attempt in 1...3 {
            // Reflect the current permission status in the UI
            allPermissionsGranted = healthKitManager.hasAllPermissions
            criticalPermissionsGranted = healthKitManager.hasCriticalPermissions
            
            // Clear error state if we have at least critical permissions
            if allPermissionsGranted || criticalPermissionsGranted {
                clearErrorState()
            }
            
            // Break if we have all permissions or this isn't a forced refresh
            if allPermissionsGranted || (!forceRefresh && attempt > 1) {
                break
            }
            
            // Small delay between attempts
            if attempt < 3 && forceRefresh {
                do {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                } catch {
                    // Ignore sleep errors
                }
            }
        }
        
        // Update the UI data for each metric
        updateHealthMetricsWithPermissionStatus()
        
        logger.info("Updated permissions status: all=\(self.allPermissionsGranted), critical=\(self.criticalPermissionsGranted)")
    }
    
    /// Show an error message
    func showError(with message: String) {
        logger.error("\(message)")
        errorMessage = message
        showError = true
    }
    
    /// Clear the error state
    func clearErrorState() {
        logger.debug("Clearing error state")
        showError = false
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    /// Set up bindings to the HealthKitManager
    private func setupBindings() {
        // No need to manually bind to manager's published properties
        // as we update manually through checkPermissionsStatus
    }
    
    /// Configure the health metrics data for the UI
    private func setupHealthMetricsData() {
        // Build health metrics data with descriptions - limiting to 5 critical metrics for MVP
        healthMetricItems = [
            HealthMetricUIItem(
                type: .steps,
                icon: "figure.walk",
                title: "Steps",
                description: "Your daily steps count helps calculate activity impact on your life battery.",
                isGranted: false,
                isCritical: true
            ),
            HealthMetricUIItem(
                type: .exerciseMinutes,
                icon: "figure.run",
                title: "Exercise Minutes",
                description: "Time spent exercising significantly impacts your life expectancy.",
                isGranted: false,
                isCritical: true
            ),
            HealthMetricUIItem(
                type: .sleepHours,
                icon: "bed.double.fill",
                title: "Sleep",
                description: "Sleep quality and duration are critical factors for your health.",
                isGranted: false,
                isCritical: true
            ),
            HealthMetricUIItem(
                type: .restingHeartRate,
                icon: "heart",
                title: "Resting Heart Rate",
                description: "Your resting heart rate is a key indicator of cardiovascular health.",
                isGranted: false,
                isCritical: true
            ),
            HealthMetricUIItem(
                type: .heartRateVariability,
                icon: "waveform.path.ecg",
                title: "Heart Rate Variability",
                description: "HRV reflects your autonomic nervous system health and stress levels.",
                isGranted: false,
                isCritical: true
            )
        ]
        
        // Set initial data
        healthMetrics = healthMetricItems
    }
    
    /// Update the health metrics data with current permission status
    private func updateHealthMetricsWithPermissionStatus() {
        let statusMap = healthKitManager.permissionStatus
        
        // Update permission status for each metric
        healthMetrics = healthMetricItems.map { item in
            let status = statusMap[item.type] ?? .notDetermined
            let isGranted = status == .sharingAuthorized
            
            return HealthMetricUIItem(
                type: item.type,
                icon: item.icon,
                title: item.title,
                description: item.description,
                isGranted: isGranted,
                isCritical: item.isCritical
            )
        }
    }
    
    /// Check if HealthKit is available on this device
    private func checkHealthKitAvailability() -> Bool {
        if !healthKitManager.isHealthKitAvailable {
            showError(with: "HealthKit is not available on this device.")
            return false
        }
        return true
    }
} 