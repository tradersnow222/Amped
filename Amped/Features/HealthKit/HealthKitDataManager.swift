import Foundation
import HealthKit
import OSLog
@preconcurrency import Combine

/// Manages HealthKit data operations, providing a clean interface for data access
@MainActor final class HealthKitDataManager {
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitDataManager")
    private let sleepManager: HealthKitSleepManager
    
    // MARK: - Initialization
    
    init(healthStore: HKHealthStore, sleepManager: HealthKitSleepManager) {
        self.healthStore = healthStore
        self.sleepManager = sleepManager
    }
    
    // MARK: - Public API
    
    /// Fetch the latest value for a specific metric type
    func fetchLatestData(for metricType: HealthMetricType) async -> HealthMetric? {
        logger.info("🔍 HealthKitDataManager: Starting fetchLatestData for \(metricType.displayName)")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("❌ HealthKit is not available on this device")
            return nil
        }
        
        logger.info("✅ HealthKit is available, proceeding with data fetch for \(metricType.displayName)")
        
        // Special handling for sleep
        if metricType == .sleepHours {
            logger.info("🛏️ Using special sleep handling for \(metricType.displayName)")
            let result = await sleepManager.processSleepData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, to: Date())
            if let result = result {
                logger.info("✅ Sleep data fetched successfully: \(result.formattedValue)")
            } else {
                logger.warning("⚠️ No sleep data found")
            }
            return result
        }
        
        guard let healthKitType = metricType.healthKitType else {
            logger.warning("⚠️ Cannot fetch data for \(metricType.rawValue): Type not available or manual metric")
            return nil
        }
        
        guard let unit = metricType.unit else {
            logger.warning("⚠️ Cannot fetch data for \(metricType.rawValue): No unit defined")
            return nil
        }
        
        logger.info("📊 Fetching HealthKit data for \(metricType.displayName) with type: \(healthKitType) and unit: \(unit)")
        
        // Query the most recent sample in the last 7 days
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        let recentPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        logger.info("🗓️ Querying samples from \(startDate) to \(endDate)")
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            logger.info("⚡ Executing HealthKit query for \(metricType.displayName)")
            
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: healthKitType,
                    predicate: recentPredicate,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        self.logger.error("❌ Query error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    self.logger.info("📋 Query completed for \(metricType.displayName), found \(samples?.count ?? 0) samples")
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
                self.logger.info("🚀 Query submitted to HealthStore for \(metricType.displayName)")
            }
            
            guard let sample = samples.first as? HKQuantitySample else {
                logger.warning("⚠️ No recent data found for \(metricType.displayName) (no samples or wrong type)")
                return nil
            }
            
            // Convert to HealthMetric
            let value = sample.quantity.doubleValue(for: unit)
            logger.info("✅ Successfully extracted value for \(metricType.displayName): \(value) \(unit.unitString)")
            
            let healthMetric = HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: sample.endDate,
                source: .healthKit
            )
            
            logger.info("🎯 Created HealthMetric for \(metricType.displayName): \(healthMetric.formattedValue)")
            return healthMetric
        } catch {
            logger.error("❌ Error fetching data for \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch data for a specific metric type within a time range
    func fetchData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit is not available on this device")
            return []
        }
        
        // Special handling for sleep
        if metricType == .sleepHours {
            if let sleepMetric = await sleepManager.processSleepData(from: startDate, to: endDate) {
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
                let value = quantitySample.quantity.doubleValue(for: metricType.unit ?? HKUnit.count())
                return HealthMetric(
                    id: UUID().uuidString,
                    type: metricType,
                    value: value,
                    date: quantitySample.endDate,
                    source: .healthKit
                )
            }
        } catch {
            logger.error("Error fetching data for \(metricType.rawValue): \(error.localizedDescription)")
            return []
        }
    }
    
    /// Set up background delivery for updates to specific metric types
    func startBackgroundDelivery(for metricTypes: [HealthMetricType]) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
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
    func startObserving(
        metricType: HealthMetricType, 
        onCancellable: @escaping (AnyCancellable) -> Void,
        onUpdate: @escaping (HealthMetric?) -> Void
    ) async -> AnyPublisher<HealthMetric?, Error> {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available"]))
                .eraseToAnyPublisher()
        }
        
        // Special handling for sleep which requires category type
        if metricType == .sleepHours {
            return sleepManager.observeSleepChanges(onCancellable: onCancellable)
        }
        
        guard let healthKitType = metricType.healthKitType else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 2, userInfo: [NSLocalizedDescriptionKey: "No HealthKit type for \(metricType.rawValue)"]))
                .eraseToAnyPublisher()
        }
        
        // Create a subject that will emit metric updates
        let subject = PassthroughSubject<HealthMetric?, Error>()
        
        // Create a weak reference to self to avoid strong capture
        weak var weakSelf = self
        
        // Set up the query to observe changes
        let query = HKObserverQuery(sampleType: healthKitType, predicate: nil) { _, completionHandler, error in
            // This closure executes on a background thread
            if let error = error {
                Task { @MainActor in
                    weakSelf?.logger.error("Observer query error for \(metricType.rawValue): \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                }
                completionHandler()
                return
            }
            
            // When change is detected, fetch the latest data
            Task { 
                do {
                    // Explicitly hop to main actor to access the fetchLatestData method
                    let metric = await MainActor.run { 
                        return Task { 
                            await weakSelf?.fetchLatestData(for: metricType)
                        }
                    }.value
                    
                    // Send the result back on the main thread
                    await MainActor.run {
                        subject.send(metric)
                        onUpdate(metric)
                    }
                }
                
                completionHandler()
            }
        }
        
        // Execute the query
        healthStore.execute(query)
        
        // Create the cancellable
        let cancellable = AnyCancellable {
            self.healthStore.stop(query)
        }
        
        // Use the callback to store the cancellable
        onCancellable(cancellable)
        
        return subject.eraseToAnyPublisher()
    }
} 