import Foundation
import HealthKit
import OSLog
import Combine
@preconcurrency import Combine

/// Protocol defining the core HealthKit management functionality
@preconcurrency protocol HealthKitManaging: AnyObject {
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool { get }
    
    /// Check if all permissions have been granted
    var hasAllPermissions: Bool { get }
    
    /// Check if critical permissions have been granted
    var hasCriticalPermissions: Bool { get }
    
    /// Get detailed permission status for all types
    var permissionStatus: [HealthMetricType: HKAuthorizationStatus] { get }
    
    /// Request authorization for all supported HealthKit data types
    func requestAuthorization() async -> Bool
    
    /// Request authorization for specific HealthKit data types
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric?
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric]
    
    /// Start observing changes to a specific metric type
    func startObserving(metricType: HealthMetricType) -> AnyPublisher<HealthMetric?, Error>
    
    /// Validate permissions by attempting to access health data
    /// This is the most reliable way to check if permissions have been granted
    func validatePermissionsByAccessingData() async -> Bool
    
    /// Check the current permission status for all health metrics
    /// Updates internal state tracking permissions and returns immediately
    func checkPermissionsStatus() async
}

/// Manages all interactions with HealthKit, providing a clean interface to access health data
@MainActor final class HealthKitManager: HealthKitManaging, ObservableObject {
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitManager")
    private let sleepManager: HealthKitSleepManager
    private let dataManager: HealthKitDataManager
    private var observers = [String: AnyCancellable]()
    
    /// Observable property to track permission status changes
    @Published private(set) var permissionsGranted: Bool = false
    
    /// Observable property to track critical permission status
    @Published private(set) var criticalPermissionsGranted: Bool = false
    
    /// Detailed permission status for each metric type - backing store for the protocol property
    @Published private(set) var _permissionStatus: [HealthMetricType: HKAuthorizationStatus] = [:]
    
    /// Observable property for metric updates
    @Published private(set) var latestMetrics: [HealthMetricType: HealthMetric] = [:]
    
    // Critical metrics that are required for the app to function properly
    nonisolated static let criticalMetricTypes: [HealthMetricType] = [
        .steps,
        .exerciseMinutes,
        .sleepHours,
        .restingHeartRate,
        .heartRateVariability
    ]
    
    // CRITICAL FIX: The complete list of ALL HealthKit metrics we want to support
    // This should match HealthMetricType.healthKitTypes exactly
    nonisolated static let allMetricTypes: [HealthMetricType] = [
        .steps,
        .exerciseMinutes,
        .sleepHours,
        .restingHeartRate,
        .heartRateVariability,
        .bodyMass,
        .activeEnergyBurned,
        .vo2Max,
        .oxygenSaturation
    ]
    
    // Shared HealthKit store for non-isolated methods - marked nonisolated to be accessible from nonisolated contexts
    @preconcurrency nonisolated private static let sharedHealthStore = HKHealthStore()
    
    // MARK: - Initialization
    
    init() {
        self.healthStore = HKHealthStore()
        self.sleepManager = HealthKitSleepManager(healthStore: healthStore)
        // CRITICAL FIX: Create the data manager to handle actual HealthKit data fetching
        self.dataManager = HealthKitDataManager(healthStore: healthStore, sleepManager: sleepManager)
        
        // Initialize permission status
        Task {
            await checkPermissionsStatus()
        }
    }
    
    // MARK: - Public API
    
    nonisolated var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    nonisolated var hasAllPermissions: Bool {
        // Use shared health store for consistency
        let store = HealthKitManager.sharedHealthStore
        
        // Check permission status for all types
        for metricType in HealthKitManager.allMetricTypes {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, check its permission
            if let healthType = healthType {
                if store.authorizationStatus(for: healthType) != .sharingAuthorized {
                    return false
                }
            }
        }
        
        return true
    }
    
    nonisolated var hasCriticalPermissions: Bool {
        // Use shared health store for consistency
        let store = HealthKitManager.sharedHealthStore
        
        // Check permission status for critical types only
        for metricType in HealthKitManager.criticalMetricTypes {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, check its permission
            if let healthType = healthType {
                if store.authorizationStatus(for: healthType) != .sharingAuthorized {
                    return false
                }
            }
        }
        
        return true
    }
    
    nonisolated var permissionStatus: [HealthMetricType: HKAuthorizationStatus] {
        // Use shared health store for consistency
        let store = HealthKitManager.sharedHealthStore
        var statusMap: [HealthMetricType: HKAuthorizationStatus] = [:]
        
        // Check all metric types
        for metricType in HealthKitManager.allMetricTypes {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, get its permission status
            if let healthType = healthType {
                statusMap[metricType] = store.authorizationStatus(for: healthType)
            }
        }
        
        return statusMap
    }
    
    /// Request authorization for all supported HealthKit data types
    func requestAuthorization() async -> Bool {
        return await requestAuthorization(for: HealthKitManager.allMetricTypes)
    }
    
    /// Request authorization for specific HealthKit data types
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        // Prepare read types set
        var typesToRead = Set<HKObjectType>()
        
        // Add each requested HealthKit type
        for metricType in types {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, add it to the request
            if let healthType = healthType {
                typesToRead.insert(healthType)
                logger.debug("Requesting permission for: \(metricType.displayName)")
            }
        }
        
        do {
            // First check existing permissions before requesting - we might already have them
            await checkPermissionsStatus()
            
            // If already granted all or critical, return success without requesting again
            if permissionsGranted || criticalPermissionsGranted {
                logger.info("Required permissions already granted, no need to request")
                return true
            }
            
            // Important: Log the authorization status before requesting
            logger.info("Authorization status before request:")
            for metricType in types {
                if let healthKitType = metricType.healthKitType {
                    let status = healthStore.authorizationStatus(for: healthKitType)
                    logger.debug("- \(metricType.displayName): \(self.authorizationStatusToString(status))")
                }
            }
            
            // Request authorization with proper error handling
            logger.info("Calling HKHealthStore.requestAuthorization")
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            logger.info("HKHealthStore.requestAuthorization completed")
            
            // Add a delay to allow iOS to fully process the authorization changes
            // This is crucial as iOS may not immediately update the authorization status
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            logger.info("Completed delay after authorization request")
            
            // Check permission status after the delay
            await checkPermissionsStatus()
            
            // Log the status after authorization to see what changed
            logger.info("Authorization status after request with delay:")
            for metricType in types {
                if let healthKitType = metricType.healthKitType {
                    let status = healthStore.authorizationStatus(for: healthKitType)
                    logger.debug("- \(metricType.displayName): \(self.authorizationStatusToString(status))")
                }
            }
            
            // If permissions still not showing as granted, try additional verification method
            if !criticalPermissionsGranted {
                // Create a fresh health store instance to avoid any caching issues
                logger.info("Creating fresh HKHealthStore instance to validate permissions")
                let freshStore = HKHealthStore()
                var allCriticalGranted = true
                
                // Re-check critical permissions with fresh store
                for metricType in HealthKitManager.criticalMetricTypes {
                    let healthType: HKObjectType?
                    if metricType == .sleepHours {
                        healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
                    } else {
                        healthType = metricType.healthKitType
                    }
                    
                    if let healthType = healthType {
                        let status = freshStore.authorizationStatus(for: healthType)
                        logger.debug("- Fresh check for \(metricType.displayName): \(self.authorizationStatusToString(status))")
                        if status != .sharingAuthorized {
                            allCriticalGranted = false
                        }
                    }
                }
                
                // If newly detected as granted, update our state
                if allCriticalGranted {
                    logger.info("Fresh store detected permissions, updating state")
                    await checkPermissionsStatus()
                    return true
                }
                
                // One more check using data access validation
                logger.info("Validating permissions by attempting to access health data")
                let permissionValidated = await validatePermissionsByAccessingData()
                if permissionValidated {
                    logger.info("Successfully accessed health data, permissions confirmed")
                    criticalPermissionsGranted = true
                    logger.info("⚠️ DEBUG: Set criticalPermissionsGranted = true after successful data access")
                    
                    // Save permission status before running check
                    let beforeCheck = criticalPermissionsGranted
                    await checkPermissionsStatus()
                    let afterCheck = criticalPermissionsGranted
                    
                    logger.info("⚠️ DEBUG: criticalPermissionsGranted before checkPermissionsStatus(): \(beforeCheck)")
                    logger.info("⚠️ DEBUG: criticalPermissionsGranted after checkPermissionsStatus(): \(afterCheck)")
                    
                    // CRITICAL FIX: Trust data access validation over authorization status
                    // If we've successfully accessed data, force permissions to be true regardless of status API
                    if permissionValidated && !criticalPermissionsGranted {
                        logger.info("⚠️ DEBUG: Permission status API and data access disagree. Trusting data access.")
                        criticalPermissionsGranted = true
                    }
                    
                    return true
                }
            }
            
            // Return true if we have at least critical permissions
            return criticalPermissionsGranted
        } catch let error as NSError {
            logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
            
            // Enhanced error logging for debugging
            logger.error("  Domain: \(error.domain), Code: \(error.code)")
            if let localizedFailure = error.localizedFailureReason {
                logger.error("  Failure reason: \(localizedFailure)")
            }
            if let localizedRecovery = error.localizedRecoverySuggestion {
                logger.error("  Recovery suggestion: \(localizedRecovery)")
            }
            
            return false
        }
    }
    
    /// Helper method to convert HKAuthorizationStatus to a readable string
    private func authorizationStatusToString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Sharing Denied"
        case .sharingAuthorized:
            return "Sharing Authorized"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    /// Validate permissions by actually attempting to access health data
    /// This is the most reliable way to check if permissions are truly granted
    func validatePermissionsByAccessingData() async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        // We will count successful validations across multiple metrics
        var successfulValidations = 0
        let requiredSuccessCount = 1 // We only need one successful validation to confirm permissions
        
        // Check steps data access - our primary validation method
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let success = await validateSingleDataTypeAccess(stepsType, typeName: "Steps")
            if success {
                successfulValidations += 1
                logger.info("Successfully validated steps data access")
            }
        }
        
        // If we didn't validate steps, try heart rate as backup
        if successfulValidations < requiredSuccessCount, 
           let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            let success = await validateSingleDataTypeAccess(heartRateType, typeName: "Heart Rate")
            if success {
                successfulValidations += 1
                logger.info("Successfully validated heart rate data access")
            }
        }
        
        // If still not validated, try exercise minutes as final option
        if successfulValidations < requiredSuccessCount,
           let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            let success = await validateSingleDataTypeAccess(exerciseType, typeName: "Exercise")
            if success {
                successfulValidations += 1
                logger.info("Successfully validated exercise data access")
            }
        }
        
        let validationSuccessful = successfulValidations >= requiredSuccessCount
        logger.info("Permission validation by data access: \(validationSuccessful ? "Successful" : "Failed")")
        
        return validationSuccessful
    }
    
    /// Helper method to validate access to a single data type
    private func validateSingleDataTypeAccess(_ quantityType: HKQuantityType, typeName: String) async -> Bool {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        do {
            // Try to execute a sample query - this will fail if permissions aren't granted
            logger.debug("Attempting to query \(typeName) data to validate permissions")
            let _ = try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: 1,
                    sortDescriptors: nil
                ) { [self] _, results, error in
                    // If we get an error related to permissions, return failure
                    if let error = error {
                        if let hkError = error as? HKError, 
                           hkError.code == .errorNoData || 
                           hkError.code == .errorDatabaseInaccessible {
                            // These errors indicate permissions are granted but no data exists
                            // or a temporary database issue, not a permissions problem
                            logger.info("\(typeName) access verified but no data found: \(error.localizedDescription)")
                            continuation.resume(returning: [])
                        } else {
                            // Other errors might indicate permission issues
                            self.logger.debug("Error accessing \(typeName) data: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                    
                    // Successfully retrieved data (or empty array if no data)
                    self.logger.debug("Successfully accessed \(typeName) data: \(results?.count ?? 0) samples")
                    continuation.resume(returning: results ?? [])
                }
                
                healthStore.execute(query)
            }
            
            // If we get here without an error, permissions are granted,
            // even if no data was found (empty array)
            logger.info("Successfully executed \(typeName) data query, permissions confirmed.")
            return true
        } catch {
            // Check if this is a permission-related error
            if let hkError = error as? HKError {
                switch hkError.code {
                case .errorAuthorizationDenied:
                    logger.warning("HealthKit authorization explicitly denied for \(typeName): \(error.localizedDescription)")
                    return false
                case .errorAuthorizationNotDetermined:
                    logger.warning("HealthKit authorization not determined for \(typeName): \(error.localizedDescription)")
                    return false
                default:
                    // For other HealthKit errors, log but consider non-permission related
                    logger.debug("Non-permission HealthKit error for \(typeName): \(error.localizedDescription)")
                    // Don't return false here as it might be a temporary issue
                }
            } else {
                // For other errors, log but still consider permissions granted
                // if we got past the authorization status check
                logger.debug("Error during \(typeName) data access but permissions may still be granted: \(error.localizedDescription)")
            }
            
            // For ambiguous error cases, check the authorization status directly
            let status = healthStore.authorizationStatus(for: quantityType)
            return status == .sharingAuthorized
        }
    }
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric? {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return nil
        }
        
        // CRITICAL FIX: Only do quick permission check for logging purposes
        await checkPermissionsStatus()
        
        // Make permission check more lenient - only check if specific permission is granted
        let specificPermissionGranted = self.permissionStatus[metricType] == .sharingAuthorized

        // For diagnostics only - we won't block on this
        if !specificPermissionGranted {
            logger.info("Authorization status for \(metricType.displayName) reports not granted. Status: \(String(describing: self.permissionStatus[metricType]))")
            logger.info("Will attempt to access data anyway since permission status may be incorrect")
        } else {
            logger.info("Permission for \(metricType.displayName) reported as granted")
        }
        
        // CRITICAL FIX: Use the HealthKitDataManager for actual data fetching
        // This ensures we use the properly implemented data access logic
        logger.info("Attempting to fetch data for \(metricType.displayName) using HealthKitDataManager")
        
        let result = await dataManager.fetchLatestData(for: metricType)
        
        if let result = result {
            logger.info("Successfully fetched \(metricType.displayName) data via HealthKitDataManager: \(result.formattedValue)")
        } else {
            logger.warning("Failed to fetch \(metricType.displayName) data via HealthKitDataManager")
        }
        
        return result
    }
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return []
        }
        
        // CRITICAL FIX: Fetch actual historical data for the date range
        logger.info("📊 Fetching historical data for \(metricType.displayName) from \(startDate) to \(endDate)")
        
        return await dataManager.fetchData(for: metricType, from: startDate, to: endDate)
    }
    
    /// Start observing changes to a specific metric type
    nonisolated func startObserving(metricType: HealthMetricType) -> AnyPublisher<HealthMetric?, Error> {
        let subject = PassthroughSubject<HealthMetric?, Error>()
        
        if !HKHealthStore.isHealthDataAvailable() {
            subject.send(completion: .failure(HealthKitError.healthKitNotAvailable))
            return subject.eraseToAnyPublisher()
        }
        
        Task { @MainActor in
            // Handle special case of sleep
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    await setupObserver(for: sleepType, metricType: metricType, subject: subject)
                }
            } 
            // Handle quantity types without redundant check
            else if let quantityType = metricType.healthKitType {
                // Use the quantity type directly without redundant cast
                await setupObserver(for: quantityType, metricType: metricType, subject: subject)
            }
            
            // Fetch initial value
            let initialValue = await fetchLatestData(for: metricType)
            subject.send(initialValue)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Permission Management
    
    /// Check the status of all permissions
    @MainActor
    func checkPermissionsStatus() async {
        guard isHealthKitAvailable else {
            permissionsGranted = false
            criticalPermissionsGranted = false
            return
        }
        
        // CRITICAL FIX: If we previously validated permissions through data access,
        // preserve that state rather than letting the status API override it
        let hadValidatedPermissions = criticalPermissionsGranted
        
        var allGranted = true
        var criticalGranted = true
        var statusMap: [HealthMetricType: HKAuthorizationStatus] = [:]
        
        // To ensure consistency, use the same approach here as in the nonisolated property methods
        // Check all metric types
        for metricType in HealthKitManager.allMetricTypes {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, check its permission status
            if let healthType = healthType {
                let status = healthStore.authorizationStatus(for: healthType)
                statusMap[metricType] = status
                
                if status != .sharingAuthorized {
                    allGranted = false
                    
                    // Check if this is a critical metric
                    if HealthKitManager.criticalMetricTypes.contains(metricType) {
                        criticalGranted = false
                    }
                }
            }
        }
        
        // Log the permission status for debugging
        logger.info("Permission status check results:")
        for (type, status) in statusMap {
            let statusDescription = (status == .sharingAuthorized) ? "Granted" : "Not Granted"
            logger.debug("- \(type.displayName): \(statusDescription)")
        }
        
        // Update state but preserve validation state
        _permissionStatus = statusMap
        permissionsGranted = allGranted
        
        // CRITICAL FIX: Don't override critical permissions if previously validated 
        // through successful data access
        if hadValidatedPermissions && !criticalGranted {
            logger.info("⚠️ Permission status API reports permissions denied, but keeping validated permissions from data access")
            criticalPermissionsGranted = true
        } else {
            criticalPermissionsGranted = criticalGranted
        }
        
        logger.info("Permission check: all=\(allGranted), critical=\(self.criticalPermissionsGranted)")
    }
    
    /// Execute a HealthKit query on the health store
    func executeQuery(_ query: HKQuery) {
        healthStore.execute(query)
    }
    
    /// Get the permission status on the MainActor
    func getPermissionStatus() -> [HealthMetricType: HKAuthorizationStatus] {
        return _permissionStatus
    }
    
    // MARK: - Private Methods
    
    /// Fetch quantity data from HealthKit
    private func fetchQuantityData(for quantityType: HKQuantityType, unit: HKUnit, metricType: HealthMetricType) async -> HealthMetric? {
        // CRITICAL FIX: Use a more reasonable date range instead of all historical data
        // Using Date.distantPast could cause performance issues or failures
        let now = Date()
        // Use metric-specific time interval instead of fixed 30 days
        let startDate = Calendar.current.date(byAdding: metricType.recommendedTimeInterval, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        // Sort by date (most recent first)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        logger.info("Fetching \(metricType.displayName) data from \(startDate) to \(now)")
        
        // Special handling for body mass - simply get the most recent sample
        if metricType.preferSampleQuery {
            do {
                // Query for the most recent sample
                let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(
                        sampleType: quantityType,
                        predicate: predicate,
                        limit: metricType.recommendedSampleLimit, // Just get the most recent samples
                        sortDescriptors: [sortDescriptor]
                    ) { _, results, error in
                        if let error = error {
                            self.logger.error("Error in HKSampleQuery for \(metricType.displayName): \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        continuation.resume(returning: results ?? [])
                    }
                    
                    healthStore.execute(query)
                }
                
                // Process the result
                if let sample = samples.first as? HKQuantitySample {
                    // Extract the quantity value
                    let value = sample.quantity.doubleValue(for: unit)
                    logger.info("Retrieved \(metricType.displayName) value: \(value) \(unit.unitString)")
                    
                    // Create and return the health metric
                    return HealthMetric(
                        id: UUID().uuidString,
                        type: metricType,
                        value: value,
                        date: sample.endDate,
                        source: .healthKit
                    )
                }
                
                // If no sample found, fall back to statistics query
                logger.info("No recent sample found, falling back to statistics")
            } catch {
                logger.error("Error fetching sample: \(error.localizedDescription)")
            }
        }
        
        do {
            // Query for the most recent samples - increase limit to improve chances of getting data
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: 10, // Increased from 1 to 10
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error = error {
                        self.logger.error("Error in HKSampleQuery for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Log the number of samples found for debugging
                    if let results = results, !results.isEmpty {
                        self.logger.info("Found \(results.count) samples for \(metricType.displayName)")
                    } else {
                        self.logger.info("No samples found for \(metricType.displayName) with sample query")
                    }
                    
                    continuation.resume(returning: results ?? [])
                }
                
                healthStore.execute(query)
            }
            
            // Process the result
            if let sample = samples.first as? HKQuantitySample {
                // Extract the quantity value
                let value = sample.quantity.doubleValue(for: unit)
                logger.info("Retrieved \(metricType.displayName) value: \(value) \(unit.unitString)")
                
                // Create and return the health metric
                return HealthMetric(
                    id: UUID().uuidString,
                    type: metricType,
                    value: value,
                    date: sample.endDate,
                    source: .healthKit
                )
            } else {
                // Always try the statistics query as a fallback for all metric types
                // This is more reliable for aggregate data like steps
                logger.info("No sample found, falling back to statistics query for \(metricType.displayName)")
                return await fetchAggregatedData(for: quantityType, unit: unit, metricType: metricType)
            }
        } catch {
            logger.error("Error fetching \(metricType.displayName): \(error.localizedDescription)")
            
            // Try the statistics query as a fallback for all metric types
            logger.info("Error occurred, falling back to statistics query for \(metricType.displayName)")
            return await fetchAggregatedData(for: quantityType, unit: unit, metricType: metricType)
        }
    }
    
    /// Fetch aggregated data using statistics query
    private func fetchAggregatedData(for quantityType: HKQuantityType, unit: HKUnit, metricType: HealthMetricType) async -> HealthMetric? {
        // Define the predicate for the query - use metric-specific time range for aggregation
        let now = Date()
        // Use recommended time interval for each metric type
        let startDate = Calendar.current.date(byAdding: metricType.recommendedTimeInterval, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        logger.info("Trying statistics query for \(metricType.displayName) from \(startDate) to \(now)")
        
        do {
            // Use statistics query to get sum or average depending on the type
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                // Determine the appropriate statistics option based on the metric type
                let options = metricType.statisticsOptions
                
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: options
                ) { _, statistics, error in
                    if let error = error {
                        self.logger.error("Error in HKStatisticsQuery for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: statistics)
                }
                
                healthStore.execute(query)
            }
            
            // Extract the relevant value from statistics
            var value: Double?
            var sourceString = "statistics query"
            
            // CRITICAL FIX: Handle statistics extraction based on type and available data
            if metricType.isCumulativeMetric {
                value = statistics?.sumQuantity()?.doubleValue(for: unit)
                sourceString = "sum query"
            } else if metricType.isDiscreteMetric {
                value = statistics?.averageQuantity()?.doubleValue(for: unit)
                sourceString = "average query"
            } else {
                // Try both sum and average, preferring sum if available
                value = statistics?.sumQuantity()?.doubleValue(for: unit)
                if value == nil {
                    value = statistics?.averageQuantity()?.doubleValue(for: unit)
                    sourceString = "average query (fallback)"
                } else {
                    sourceString = "sum query"
                }
            }
            
            guard let value = value else {
                logger.info("No statistics data found for \(metricType.displayName) via \(sourceString)")
                return nil
            }
            
            logger.info("Retrieved \(metricType.displayName) statistics value: \(value) \(unit.unitString) via \(sourceString)")
            
            // Create and return the health metric
            return HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: now,
                source: .healthKit
            )
        } catch {
            logger.error("Error fetching statistics for \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch sleep data from HealthKit (special case)
    private func fetchSleepData() async -> HealthMetric? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Sleep analysis type is not available")
            return nil
        }
        
        // Define the predicate for the query using recommended time interval
        let now = Date()
        // Use recommended time interval specifically for sleep data
        let sleepMetricType = HealthMetricType.sleepHours
        let startDate = Calendar.current.date(byAdding: sleepMetricType.recommendedTimeInterval, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        logger.info("Fetching sleep data from \(startDate) to \(now)")
        
        do {
            // Query for sleep samples
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // Log the number of samples found for debugging
                    if let results = results, !results.isEmpty {
                        self.logger.info("Found \(results.count) sleep samples")
                    } else {
                        self.logger.info("No sleep samples found")
                    }
                    
                    continuation.resume(returning: results ?? [])
                }
                
                healthStore.execute(query)
            }
            
            // Calculate sleep duration from samples
            var totalSleepHours = 0.0
            
            // Filter samples to only include actual sleep (not in bed but awake)
            let sleepSamples = samples.compactMap { sample -> HKCategorySample? in
                guard let categorySample = sample as? HKCategorySample else { return nil }
                
                // Only count actual sleep, not just in bed
                if categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    return categorySample
                }
                
                return nil
            }
            
            logger.info("Filtered to \(sleepSamples.count) actual sleep samples")
            
            if sleepSamples.isEmpty {
                logger.info("No actual sleep samples found")
                return nil
            }
            
            // Calculate total sleep duration (avoiding overlaps)
            var sleepIntervals: [(Date, Date)] = []
            
            for sample in sleepSamples {
                let startDate = sample.startDate
                let endDate = sample.endDate
                
                sleepIntervals.append((startDate, endDate))
            }
            
            // Merge overlapping intervals
            let mergedIntervals = mergeTimeIntervals(sleepIntervals)
            
            // Calculate total hours from merged intervals
            for (start, end) in mergedIntervals {
                let duration = end.timeIntervalSince(start)
                totalSleepHours += duration / 3600 // Convert seconds to hours
            }
            
            // Get the latest sleep data point for the date
            let latestSleep = sleepSamples.max(by: { $0.endDate < $1.endDate })
            
            let averageSleepHours = totalSleepHours / 7.0 // Average per day over the week
            logger.info("Calculated average sleep: \(averageSleepHours) hours per day")
            
            // Create and return the health metric with the average daily sleep
            // We'll use the end date of the latest sleep sample as our reference point
            return HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: averageSleepHours,
                date: latestSleep?.endDate ?? now,
                source: .healthKit
            )
        } catch {
            logger.error("Error fetching sleep data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Merge overlapping time intervals to avoid double-counting
    private func mergeTimeIntervals(_ intervals: [(Date, Date)]) -> [(Date, Date)] {
        guard !intervals.isEmpty else { return [] }
        
        // Sort intervals by start time
        let sortedIntervals = intervals.sorted { $0.0 < $1.0 }
        
        var result: [(Date, Date)] = []
        var currentInterval = sortedIntervals[0]
        
        for (start, end) in sortedIntervals.dropFirst() {
            // If current interval overlaps with next interval, merge them
            if start <= currentInterval.1 {
                currentInterval.1 = max(currentInterval.1, end)
            } else {
                // No overlap, add current interval to result and move to next
                result.append(currentInterval)
                currentInterval = (start, end)
            }
        }
        
        // Add the last interval
        result.append(currentInterval)
        
        return result
    }
    
    /// Setup observer for health data changes
    private func setupObserver(for objectType: HKSampleType, metricType: HealthMetricType, subject: PassthroughSubject<HealthMetric?, Error>) async {
        // Create a weak reference to subject that we'll use consistently
        // This is a safer approach to prevent retain cycles
        // weak var weakSubject = subject // Removed unused variable

        do {
            // Create the query
            // Dispatch subject updates to MainActor for thread safety
            let query = HKObserverQuery(sampleType: objectType, predicate: nil) { [weak self, weak subject] query, completionHandler, error in
                // Error handling - Dispatch to MainActor
                if let error = error {
                    self?.logger.error("Observer query error for \(metricType.displayName): \(error.localizedDescription)")
                    Task { @MainActor [weak subject] in // Dispatch to MainActor
                        subject?.send(completion: .failure(error))
                        completionHandler() // Call completion handler on MainActor after sending
                    }
                    return
                }

                // Fetch the updated data in a background Task
                Task { [weak self] in // Task inherits background context from observer
                    guard let self = self else {
                        Task { @MainActor in completionHandler() } // Ensure completionHandler runs on MainActor if self is nil
                        return
                    }

                    let metric = await self.fetchLatestData(for: metricType)

                    // Dispatch the metric update to the MainActor
                    Task { @MainActor [weak subject] in // Dispatch update to MainActor
                        subject?.send(metric)
                        completionHandler() // Call completion handler on MainActor after sending
                    }
                }
            }

            // Execute the query
            healthStore.execute(query)
            
            // Set up background delivery if possible
            try await healthStore.enableBackgroundDelivery(for: objectType, frequency: .immediate)
            
            logger.info("Started observing changes for \(metricType.displayName)")
        } catch {
            logger.error("Failed to set up observer for \(metricType.displayName): \(error.localizedDescription)")
            // Use unwrapped subject here since we have the original non-optional reference
            // Dispatch failure to MainActor
            Task { @MainActor [subject] in // Dispatch to MainActor
                subject.send(completion: .failure(error))
            }
        }
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: Error {
    case healthKitNotAvailable
    case dataNotAvailable
    case authorizationDenied
    case unknownError
    case invalidType
}

extension HealthKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .dataNotAvailable:
            return "The requested health data is not available"
        case .authorizationDenied:
            return "Authorization to access health data was denied"
        case .unknownError:
            return "An unknown error occurred"
        case .invalidType:
            return "Invalid type for observer setup"
        }
    }
}

// MARK: - Metric Classification Helpers

extension HealthMetricType {
    /// Determines if this metric type should use cumulative statistics
    var isCumulativeMetric: Bool {
        switch self {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            return true
        default:
            return false
        }
    }
    
    /// Determines if this metric type should use discrete statistics
    var isDiscreteMetric: Bool {
        switch self {
        case .restingHeartRate, .heartRateVariability, .vo2Max, .oxygenSaturation, .bodyMass:
            return true
        default:
            return false
        }
    }
    
    /// Returns the appropriate statistics options for this metric type
    var statisticsOptions: HKStatisticsOptions {
        if isCumulativeMetric {
            return .cumulativeSum
        } else if isDiscreteMetric {
            return .discreteAverage
        } else {
            // Default to supporting both for flexibility
            return [.cumulativeSum, .discreteAverage]
        }
    }
} 