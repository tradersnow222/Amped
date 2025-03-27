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
}

/// Manages all interactions with HealthKit, providing a clean interface to access health data
@MainActor final class HealthKitManager: ObservableObject, @preconcurrency HealthKitManaging {
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitManager")
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
    
    // The complete list of metrics we want from HealthKit - limited to just the critical ones for MVP
    nonisolated static let allMetricTypes: [HealthMetricType] = criticalMetricTypes
    
    // Shared HealthKit store for non-isolated methods - marked nonisolated to be accessible from nonisolated contexts
    @preconcurrency nonisolated private static let sharedHealthStore = HKHealthStore()
    
    // MARK: - Initialization
    
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        
        // Check HealthKit availability immediately
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            return
        }
        
        // Check permission status on init
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
            
            // Important: Immediately check permission status without delay
            // The system has already updated the permissions at this point
            logger.info("Checking permission status immediately after request")
            await checkPermissionsStatus()
            
            // Log the status after authorization to see what changed
            logger.info("Authorization status after request:")
            for metricType in types {
                if let healthKitType = metricType.healthKitType {
                    let status = healthStore.authorizationStatus(for: healthKitType)
                    logger.debug("- \(metricType.displayName): \(self.authorizationStatusToString(status))")
                }
            }
            
            // Check again in case the status hasn't propagated immediately
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
                            break
                        }
                    }
                }
                
                // If newly detected as granted, update our state
                if allCriticalGranted {
                    logger.info("Fresh store detected permissions, updating state")
                    await checkPermissionsStatus()
                }
                
                // One more important check: Actually attempt to retrieve data
                // This is the most reliable way to check if permissions are truly granted
                logger.info("Validating permissions by attempting to access health data")
                let permissionValidated = await validatePermissionsByAccessingData()
                if permissionValidated {
                    logger.info("Successfully accessed health data, permissions confirmed")
                    criticalPermissionsGranted = true
                    return true
                }
            }
            
            // Return true if we have at least critical permissions
            return criticalPermissionsGranted
        } catch {
            logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
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
            return false
        }
        
        // Try to access steps data as a test
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            // No need to store HKUnit.count() as it's not used
            
            let now = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
            
            do {
                // Try to execute a sample query - this will fail if permissions aren't granted
                logger.debug("Attempting to query steps data to validate permissions")
                let _ = try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(
                        sampleType: stepsType,
                        predicate: predicate,
                        limit: 1,
                        sortDescriptors: nil
                    ) { [self] _, results, error in
                        if let error = error {
                            self.logger.debug("Error accessing steps data: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        self.logger.debug("Successfully accessed steps data: \(results?.count ?? 0) samples")
                        continuation.resume(returning: results ?? [])
                    }
                    
                    healthStore.execute(query)
                }
                
                logger.info("Successfully executed health data query, permissions confirmed")
                return true
            } catch {
                logger.debug("Failed to access health data: \(error.localizedDescription)")
                return false
            }
        }
        
        // Try sleep data as an alternative
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let now = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
            
            do {
                // Try to execute a sample query - this will fail if permissions aren't granted
                logger.debug("Attempting to query sleep data to validate permissions")
                let _ = try await withCheckedThrowingContinuation { [self] (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(
                        sampleType: sleepType,
                        predicate: predicate,
                        limit: 1,
                        sortDescriptors: nil
                    ) { [self] _, results, error in
                        if let error = error {
                            self.logger.debug("Error accessing sleep data: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        self.logger.debug("Successfully accessed sleep data: \(results?.count ?? 0) samples")
                        continuation.resume(returning: results ?? [])
                    }
                    
                    healthStore.execute(query)
                }
                
                logger.info("Successfully executed sleep data query, permissions confirmed")
                return true
            } catch {
                logger.debug("Failed to access sleep data: \(error.localizedDescription)")
                return false
            }
        }
        
        return false
    }
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric? {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return nil
        }
        
        if !hasCriticalPermissions && !hasAllPermissions {
            logger.warning("No HealthKit permissions granted")
            return nil
        }
        
        // Handle different metric types appropriately
        if metricType == .sleepHours {
            return await fetchSleepData()
        } else if let quantityType = metricType.healthKitType,
                  let unit = metricType.unit {
            // Remove unnecessary cast
            return await fetchQuantityData(for: quantityType as HKQuantityType, unit: unit, metricType: metricType)
        }
        
        return nil
    }
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return []
        }
        
        if !hasCriticalPermissions && !hasAllPermissions {
            logger.warning("No HealthKit permissions granted")
            return []
        }
        
        // Simple implementation for now - we'll expand this in the future
        if let metric = await fetchLatestData(for: metricType) {
            return [metric]
        }
        
        return []
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
            // Handle quantity types - avoid redundant cast
            else if let quantityType = metricType.healthKitType, quantityType is HKQuantityType {
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
        
        // Double-check with a fresh instance to validate the status hasn't changed
        // This can help catch issues with stale caches or system updates
        let freshStore = HKHealthStore()
        for metricType in HealthKitManager.criticalMetricTypes {
            // Get the appropriate health type (regular or sleep)
            let healthType: HKObjectType?
            if metricType == .sleepHours {
                healthType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            } else {
                healthType = metricType.healthKitType
            }
            
            // If we have a valid type, verify its permission status
            if let healthType = healthType {
                let status = freshStore.authorizationStatus(for: healthType)
                
                // If we detect a discrepancy, use the more recent status
                if let existingStatus = statusMap[metricType], existingStatus != status {
                    // Fix ambiguous type error with proper string interpolation
                    let message = "Permission status discrepancy for \(metricType.displayName): \(existingStatus) vs \(status)"
                    logger.warning("\(message)")
                    statusMap[metricType] = status
                    
                    // Update the granted flags if this is now authorized
                    if status == .sharingAuthorized && existingStatus != .sharingAuthorized {
                        if HealthKitManager.criticalMetricTypes.contains(metricType) {
                            // Recalculate critical permissions
                            criticalGranted = true
                            for criticalType in HealthKitManager.criticalMetricTypes {
                                if statusMap[criticalType] != .sharingAuthorized {
                                    criticalGranted = false
                                    break
                                }
                            }
                        }
                        
                        // Recalculate all permissions
                        allGranted = true
                        for type in HealthKitManager.allMetricTypes {
                            if statusMap[type] != .sharingAuthorized {
                                allGranted = false
                                break
                            }
                        }
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
        
        // Update state
        _permissionStatus = statusMap
        permissionsGranted = allGranted
        criticalPermissionsGranted = criticalGranted
        
        logger.info("Permission check: all=\(allGranted), critical=\(criticalGranted)")
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
        // Define the predicate for the query
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        // Sort by date (most recent first)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            // Query for the most recent sample
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: results ?? [])
                }
                
                healthStore.execute(query)
            }
            
            // Process the result
            guard let sample = samples.first as? HKQuantitySample else {
                logger.debug("No recent data found for \(metricType.displayName)")
                return nil
            }
            
            // Extract the quantity value
            let value = sample.quantity.doubleValue(for: unit)
            
            // Create and return the health metric
            return HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: sample.endDate,
                source: .healthKit
            )
        } catch {
            logger.error("Error fetching \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch sleep data from HealthKit (special case)
    private func fetchSleepData() async -> HealthMetric? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.error("Sleep analysis type is not available")
            return nil
        }
        
        // Define the predicate for the query (last 7 days)
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
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
            
            // Create and return the health metric with the average daily sleep
            // We'll use the end date of the latest sleep sample as our reference point
            return HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: totalSleepHours / 7.0, // Average per day over the week
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
        do {
            // Create the query
            let query = HKObserverQuery(sampleType: objectType, predicate: nil) { [weak self, subject] query, completionHandler, error in
                // Error handling
                if let error = error {
                    self?.logger.error("Observer query error for \(metricType.displayName): \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                    completionHandler()
                    return
                }
                
                // Fetch the updated data
                Task { [weak self] in
                    guard let self = self else {
                        completionHandler()
                        return
                    }
                    
                    let metric = await self.fetchLatestData(for: metricType)
                    subject.send(metric)
                    completionHandler()
                }
            }
            
            // Execute the query
            healthStore.execute(query)
            
            // Set up background delivery if possible
            try await healthStore.enableBackgroundDelivery(for: objectType, frequency: .immediate)
            
            logger.info("Started observing changes for \(metricType.displayName)")
        } catch {
            logger.error("Failed to set up observer for \(metricType.displayName): \(error.localizedDescription)")
            subject.send(completion: .failure(error))
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