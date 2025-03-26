import Foundation
import HealthKit
import OSLog
import Combine

/// Protocol defining the core HealthKit management functionality
@MainActor protocol HealthKitManaging {
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool { get }
    
    /// Check if all permissions have been granted
    var hasAllPermissions: Bool { get }
    
    /// Request authorization for all supported HealthKit data types
    func requestAuthorization() async -> Bool
    
    /// Request authorization for specific HealthKit data types
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric?
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric]
    
    /// Set up background delivery for updates to specific metric types
    func startBackgroundDelivery(for metricTypes: [HealthMetricType]) async -> Bool
    
    /// Start observing changes to a specific metric type
    func startObserving(metricType: HealthMetricType) async -> AnyPublisher<HealthMetric?, Error>
    
    /// Get the underlying HealthKit store for direct access
    func getHealthStore() -> HKHealthStore
}

/// Manages all interactions with HealthKit, providing a clean interface to access health data
@MainActor final class HealthKitManager: HealthKitManaging, ObservableObject {
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitManager")
    private var observers: [String: AnyCancellable] = [:]
    
    /// Observable property to track permission status changes
    @Published private(set) var permissionsGranted: Bool = false
    
    /// Observable property for metric updates
    @Published var latestMetrics: [HealthMetricType: HealthMetric] = [:]
    
    // MARK: - Initialization
    
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        
        // Initialize permission status
        Task {
            self.permissionsGranted = await checkPermissionsStatus()
        }
    }
    
    // MARK: - Public API
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    var hasAllPermissions: Bool {
        permissionsGranted
    }
    
    /// Get the underlying HealthStore (for testing and special cases)
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }
    
    /// Request authorization for all supported HealthKit data types
    func requestAuthorization() async -> Bool {
        await requestAuthorization(for: HealthMetricType.healthKitTypes)
    }
    
    /// Request authorization for specific HealthKit data types
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        // Check if permissions are already granted
        let existingPermissionsGranted = await checkPermissionsStatus()
        if existingPermissionsGranted {
            logger.info("HealthKit permissions already granted")
            self.permissionsGranted = true
            return true
        }
        
        // Prepare read types set
        var typesToRead = Set<HKObjectType>()
        
        // Add each requested HealthKit type
        for metricType in types {
            if let healthKitType = metricType.healthKitType {
                typesToRead.insert(healthKitType)
                logger.debug("Requesting permission for: \(metricType.displayName)")
            }
            
            // Special handling for sleep which uses category type
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    typesToRead.insert(sleepType)
                    logger.debug("Requesting permission for sleep analysis")
                }
            }
        }
        
        // Add demographic data types
        addDemographicTypesToRequest(typesToRead: &typesToRead)
        
        // Request permissions - this will trigger the system dialog
        do {
            logger.info("Directly requesting HealthKit authorization for \(typesToRead.count) types via HKHealthStore")
            
            // This is the key line that triggers the iOS permission dialog
            // Call it directly without additional await wrapping
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            
            // After the user responds to the dialog, check if permissions were granted
            try? await Task.sleep(nanoseconds: 500_000_000) // Small delay to let system update
            
            // Verify permissions status
            let granted = await checkPermissionsStatus()
            self.permissionsGranted = granted
            
            logger.info("HealthKit authorization completed, result: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric? {
        guard isHealthKitAvailable, let healthKitType = metricType.healthKitType else {
            if metricType == .sleepHours {
                // Special handling for sleep
                return await processSleepData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, to: Date())
            }
            
            logger.warning("Cannot fetch data for \(metricType.rawValue): Type not available or manual metric")
            return nil
        }
        
        // Query the most recent sample in the last 7 days
        let recentPredicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            end: Date(),
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: healthKitType,
                    predicate: recentPredicate,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
            }
            
            guard let sample = samples.first as? HKQuantitySample else {
                logger.info("No recent data found for \(metricType.rawValue)")
                return nil
            }
            
            // Convert to HealthMetric
            let metric = HealthMetric(from: sample, for: metricType)
            
            // Store the latest metric for observability
            if let metric = metric {
                latestMetrics[metricType] = metric
            }
            
            return metric
        } catch {
            logger.error("Error fetching data for \(metricType.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        guard isHealthKitAvailable else {
            logger.warning("HealthKit is not available on this device")
            return []
        }
        
        // Special handling for sleep
        if metricType == .sleepHours {
            if let sleepMetric = await processSleepData(from: startDate, to: endDate) {
                return [sleepMetric]
            }
            return []
        }
        
        guard let healthKitType = metricType.healthKitType else {
            logger.warning("Cannot fetch data for \(metricType.rawValue): No corresponding HealthKit type")
            return []
        }
        
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        do {
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: healthKitType,
                    predicate: datePredicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
            }
            
            // Convert all samples to HealthMetric objects
            return samples.compactMap { sample in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return HealthMetric(from: quantitySample, for: metricType)
            }
        } catch {
            logger.error("Error fetching data for \(metricType.rawValue): \(error.localizedDescription)")
            return []
        }
    }
    
    /// Set up background delivery for updates to specific metric types
    func startBackgroundDelivery(for metricTypes: [HealthMetricType]) async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        var allSucceeded = true
        
        for metricType in metricTypes {
            guard let healthKitType = metricType.healthKitType else {
                // Skip types without corresponding HealthKit types
                continue
            }
            
            do {
                // Enable background delivery with hourly frequency
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    self.healthStore.enableBackgroundDelivery(
                        for: healthKitType,
                        frequency: .hourly
                    ) { success, error in
                        if let error = error {
                            self.logger.error("Failed to enable background delivery for \(metricType.rawValue): \(error.localizedDescription)")
                            allSucceeded = false
                            continuation.resume(throwing: error)
                        } else if success {
                            self.logger.info("Background delivery enabled for \(metricType.rawValue)")
                            continuation.resume()
                        } else {
                            self.logger.warning("Background delivery not enabled for \(metricType.rawValue)")
                            allSucceeded = false
                            continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to enable background delivery"]))
                        }
                    }
                }
            } catch {
                logger.error("Error enabling background delivery for \(metricType.rawValue): \(error.localizedDescription)")
                allSucceeded = false
            }
        }
        
        return allSucceeded
    }
    
    /// Start observing changes to a specific metric type
    func startObserving(metricType: HealthMetricType) async -> AnyPublisher<HealthMetric?, Error> {
        guard isHealthKitAvailable else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available"]))
                .eraseToAnyPublisher()
        }
        
        // Special handling for sleep which requires category type
        if metricType == .sleepHours {
            return observeSleepChanges()
        }
        
        guard let healthKitType = metricType.healthKitType else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 2, userInfo: [NSLocalizedDescriptionKey: "No HealthKit type for \(metricType.rawValue)"]))
                .eraseToAnyPublisher()
        }
        
        // Create a subject that will emit metric updates
        let subject = PassthroughSubject<HealthMetric?, Error>()
        
        // Set up the query to observe changes
        let query = HKObserverQuery(sampleType: healthKitType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }
            
            if let error = error {
                self.logger.error("Observer query error for \(metricType.rawValue): \(error.localizedDescription)")
                subject.send(completion: .failure(error))
                completionHandler()
                return
            }
            
            // When change is detected, fetch the latest data
            Task { @MainActor [weak self] in
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
        
        // Store the observer for later cancellation
        let cancellable = AnyCancellable {
            self.healthStore.stop(query)
        }
        
        observers[metricType.rawValue] = cancellable
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Add demographic data types to the request set
    private func addDemographicTypesToRequest(typesToRead: inout Set<HKObjectType>) {
        // Add date of birth
        if let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            typesToRead.insert(dobType)
        }
        
        // Add biological sex
        if let sexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            typesToRead.insert(sexType)
        }
        
        // Add height and weight
        typesToRead.insert(HKQuantityType(.height))
        typesToRead.insert(HKQuantityType(.bodyMass))
    }
    
    /// Process sleep data which requires special handling
    private func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric? {
        guard isHealthKitAvailable else {
            logger.warning("HealthKit is not available for sleep processing")
            return nil
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.warning("Sleep analysis type is not available")
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        do {
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
            }
            
            // Calculate total sleep time
            var totalSleepTime: TimeInterval = 0
            
            for sample in samples {
                guard let categorySample = sample as? HKCategorySample else { continue }
                
                // Count only asleep states
                if categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                    
                    let sleepTime = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                    totalSleepTime += sleepTime
                }
            }
            
            // Convert to hours
            let sleepHours = totalSleepTime / 3600.0
            
            // Only create metric if we have valid sleep data
            if sleepHours > 0 {
                return HealthMetric(
                    type: .sleepHours,
                    value: sleepHours,
                    date: endDate
                )
            } else {
                logger.info("No valid sleep data found in the specified period")
                return nil
            }
            
        } catch {
            logger.error("Error processing sleep data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Set up an observer for sleep changes
    private func observeSleepChanges() -> AnyPublisher<HealthMetric?, Error> {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 3, userInfo: [NSLocalizedDescriptionKey: "Sleep analysis type is not available"]))
                .eraseToAnyPublisher()
        }
        
        // Create a subject for sleep updates
        let subject = PassthroughSubject<HealthMetric?, Error>()
        
        // Set up the query to observe sleep changes
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }
            
            if let error = error {
                self.logger.error("Sleep observer query error: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
                completionHandler()
                return
            }
            
            // When sleep data changes, process the updated data
            Task { @MainActor [weak self] in
                guard let self = self else {
                    completionHandler()
                    return
                }
                
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                if let sleepMetric = await self.processSleepData(from: yesterday, to: Date()) {
                    subject.send(sleepMetric)
                    self.latestMetrics[.sleepHours] = sleepMetric
                } else {
                    subject.send(nil)
                }
                completionHandler()
            }
        }
        
        // Execute the query
        healthStore.execute(query)
        
        // Store the observer for later cancellation
        let cancellable = AnyCancellable {
            self.healthStore.stop(query)
        }
        
        observers["sleepHours"] = cancellable
        
        return subject.eraseToAnyPublisher()
    }
    
    /// Check if all required permissions have been granted
    private func checkPermissionsStatus() async -> Bool {
        guard isHealthKitAvailable else { 
            logger.warning("HealthKit is not available on this device")
            return false 
        }
        
        logger.debug("Checking permissions status for all health metrics...")
        var permissionsCount = 0
        var grantedCount = 0
        var deniedPermissions: [String] = []
        
        // Check status for each HealthKit type
        for metricType in HealthMetricType.healthKitTypes {
            if let healthKitType = metricType.healthKitType {
                permissionsCount += 1
                let status = healthStore.authorizationStatus(for: healthKitType)
                
                if status == .sharingAuthorized {
                    grantedCount += 1
                    logger.debug("✅ Permission granted for \(metricType.displayName)")
                } else {
                    deniedPermissions.append(metricType.displayName)
                    logger.debug("❌ Permission not granted for \(metricType.displayName): \(status.rawValue)")
                }
            }
            
            // Special handling for sleep
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    permissionsCount += 1
                    let status = healthStore.authorizationStatus(for: sleepType)
                    
                    if status == .sharingAuthorized {
                        grantedCount += 1
                        logger.debug("✅ Permission granted for sleep analysis")
                    } else {
                        deniedPermissions.append("Sleep Analysis")
                        logger.debug("❌ Permission not granted for sleep analysis: \(status.rawValue)")
                    }
                }
            }
        }
        
        // Report overall status
        let allGranted = grantedCount == permissionsCount && permissionsCount > 0
        
        if allGranted {
            logger.info("✅ HealthKit permissions check: All \(grantedCount) permissions granted")
        } else {
            logger.info("❌ HealthKit permissions check: \(grantedCount)/\(permissionsCount) granted, missing: \(deniedPermissions.joined(separator: ", "))")
        }
        
        return allGranted
    }
} 