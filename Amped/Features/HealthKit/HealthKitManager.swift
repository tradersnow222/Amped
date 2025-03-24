import Foundation
import HealthKit
import OSLog

/// Protocol defining the HealthKit management functionality
@MainActor protocol HealthKitManaging {
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool { get }
    
    /// Check if all permissions have been granted
    var hasAllPermissions: Bool { get }
    
    /// Request authorization for HealthKit data access
    func requestAuthorization() async -> Bool
    
    /// Request specific data types authorization
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric?
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric]
    
    /// Start background delivery for specific metric types
    func startBackgroundDelivery(for metricTypes: [HealthMetricType]) async -> Bool
}

/// Class for managing HealthKit interactions
@MainActor final class HealthKitManager: HealthKitManaging, ObservableObject {
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: "com.amped.Amped", category: "HealthKitManager")
    
    /// Published property to notify when permissions change
    @Published var permissionsGranted: Bool = false
    
    // Method to access the health store internally
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }
    
    // MARK: - Initialization
    
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
        self.permissionsGranted = false
        
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
    
    func requestAuthorization() async -> Bool {
        await requestAuthorization(for: HealthMetricType.healthKitTypes)
    }
    
    func requestAuthorization(for types: [HealthMetricType]) async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        // Prepare read types
        var typesToRead = Set<HKObjectType>()
        
        // Add all the requested types that have a corresponding HealthKit type
        for metricType in types {
            if let healthKitType = metricType.healthKitType {
                typesToRead.insert(healthKitType)
            }
            
            // Special handling for sleep
            if metricType == .sleepHours {
                typesToRead.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
            }
        }
        
        // Add additional types for demographic data
        typesToRead.insert(HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!)
        typesToRead.insert(HKObjectType.characteristicType(forIdentifier: .biologicalSex)!)
        typesToRead.insert(HKObjectType.quantityType(forIdentifier: .height)!)
        typesToRead.insert(HKObjectType.quantityType(forIdentifier: .bodyMass)!)
        
        // We only need to read from HealthKit, not write to it
        do {
            logger.info("Requesting HealthKit authorization for \(typesToRead.count) types")
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            
            // Check if permissions were granted
            let granted = await checkPermissionsStatus()
            permissionsGranted = granted
            
            logger.info("HealthKit authorization \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric? {
        guard isHealthKitAvailable, let healthKitType = metricType.healthKitType else {
            logger.warning("Cannot fetch data for \(metricType.rawValue): Type not available or manual metric")
            return nil
        }
        
        let mostRecentPredicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            end: Date(),
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            let samples = try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<[HKSample], Error>) in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
                let query = HKSampleQuery(
                    sampleType: healthKitType,
                    predicate: mostRecentPredicate,
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
            
            let metric = HealthMetric(from: sample, for: metricType)
            return metric
        } catch {
            logger.error("Error fetching data for \(metricType.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        guard isHealthKitAvailable, let healthKitType = metricType.healthKitType else {
            logger.warning("Cannot fetch data for \(metricType.rawValue): Type not available or manual metric")
            return []
        }
        
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        do {
            let samples = try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<[HKSample], Error>) in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
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
            
            return samples.compactMap { sample in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return HealthMetric(from: quantitySample, for: metricType)
            }
        } catch {
            logger.error("Error fetching data for \(metricType.rawValue): \(error.localizedDescription)")
            return []
        }
    }
    
    func startBackgroundDelivery(for metricTypes: [HealthMetricType]) async -> Bool {
        guard isHealthKitAvailable else {
            logger.error("HealthKit is not available on this device")
            return false
        }
        
        var allSucceeded = true
        
        for metricType in metricTypes {
            guard let healthKitType = metricType.healthKitType else {
                logger.warning("Cannot setup background delivery for \(metricType.rawValue): No corresponding HealthKit type")
                continue
            }
            
            do {
                // Enable background delivery with a frequency of 1 hour
                try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
                    guard let self = self else {
                        continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                        return
                    }
                    
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
    
    // MARK: - Private methods
    
    /// Check if all required permissions have been granted
    private func checkPermissionsStatus() async -> Bool {
        guard isHealthKitAvailable else { return false }
        
        // Check status for each HealthKit type
        for metricType in HealthMetricType.healthKitTypes {
            if let healthKitType = metricType.healthKitType {
                let status = healthStore.authorizationStatus(for: healthKitType)
                if status != .sharingAuthorized {
                    return false
                }
            }
            
            // Special handling for sleep
            if metricType == .sleepHours {
                let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                let status = healthStore.authorizationStatus(for: sleepType)
                if status != .sharingAuthorized {
                    return false
                }
            }
        }
        
        return true
    }
} 