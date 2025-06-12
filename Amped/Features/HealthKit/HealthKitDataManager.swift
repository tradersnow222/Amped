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
        
        // CRITICAL FIX: Use the same methodology as HealthKitManager for consistency
        switch metricType {
        case .sleepHours:
            // CRITICAL FIX: Sleep manager should only calculate for TODAY, not a 7-day range
            logger.info("🛏️ Using special sleep handling for \(metricType.displayName)")
            let today = Date()
            let result = await sleepManager.processSleepData(from: today, to: today)
            if let result = result {
                logger.info("✅ Sleep data fetched successfully: \(result.formattedValue)")
            } else {
                logger.warning("⚠️ No sleep data found")
            }
            return result
            
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            // CUMULATIVE METRICS: Use today's total with HKStatisticsQuery
            return await fetchCumulativeMetricForToday(metricType: metricType)
            
        case .restingHeartRate, .heartRateVariability:
            // DAILY HEALTH STATUS METRICS: Get most recent daily value
            return await fetchDailyHealthStatusMetric(metricType: metricType)
            
        case .bodyMass, .vo2Max, .oxygenSaturation:
            // POINT-IN-TIME METRICS: Get most recent sample
            return await fetchMostRecentSample(metricType: metricType)
            
        default:
            logger.warning("⚠️ Unknown metric type \(metricType.displayName), using sample fallback")
            return await fetchMostRecentSample(metricType: metricType)
        }
    }
    
    /// Fetch today's cumulative total for a metric (steps, exercise minutes, active energy)
    private func fetchCumulativeMetricForToday(metricType: HealthMetricType) async -> HealthMetric? {
        guard let quantityType = metricType.healthKitType,
              let unit = metricType.unit else {
            logger.warning("⚠️ Cannot fetch data for \(metricType.rawValue): Type or unit not available")
            return nil
        }
        
        // CRITICAL FIX: Use today only for daily totals
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        logger.info("🔢 Fetching cumulative \(metricType.displayName) for today: \(startOfToday) to \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictEndDate)
        
        do {
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum  // This handles de-duplication automatically
                ) { _, statistics, error in
                    if let error = error {
                        self.logger.error("❌ HKStatisticsQuery error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statistics)
                }
                self.healthStore.execute(query)
            }
            
            guard let sumQuantity = statistics?.sumQuantity() else {
                logger.info("⚠️ No cumulative data found for \(metricType.displayName) today")
                return nil
            }
            
            let value = sumQuantity.doubleValue(for: unit)
            logger.info("✅ Today's \(metricType.displayName): \(value) \(unit.unitString)")
            
            return HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: now,
                source: .healthKit
            )
        } catch {
            logger.error("❌ Error fetching cumulative \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch daily health status metrics (resting heart rate, HRV) - get most recent daily value
    private func fetchDailyHealthStatusMetric(metricType: HealthMetricType) async -> HealthMetric? {
        guard let quantityType = metricType.healthKitType,
              let unit = metricType.unit else {
            logger.warning("⚠️ Cannot fetch data for \(metricType.rawValue): Type or unit not available")
            return nil
        }
        
        // CRITICAL FIX: For daily health metrics, get the most recent daily value (last 7 days max)
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        logger.info("🫀 Fetching daily \(metricType.displayName) from last 7 days: \(startDate) to \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: 1,  // Just get the most recent daily value
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error = error {
                        self.logger.error("❌ Sample query error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: results ?? [])
                }
                self.healthStore.execute(query)
            }
            
            guard let sample = samples.first as? HKQuantitySample else {
                logger.info("⚠️ No recent daily \(metricType.displayName) data found")
                return nil
            }
            
            let value = sample.quantity.doubleValue(for: unit)
            logger.info("✅ Latest daily \(metricType.displayName): \(value) \(unit.unitString) from \(sample.endDate)")
            
            return HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: sample.endDate,
                source: .healthKit
            )
        } catch {
            logger.error("❌ Error fetching daily \(metricType.displayName): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetch most recent sample for point-in-time metrics (body mass, VO2 max, oxygen saturation)
    private func fetchMostRecentSample(metricType: HealthMetricType) async -> HealthMetric? {
        guard let quantityType = metricType.healthKitType,
              let unit = metricType.unit else {
            logger.warning("⚠️ Cannot fetch data for \(metricType.rawValue): Type or unit not available")
            return nil
        }
        
        // CRITICAL FIX: For point-in-time metrics, search wider range but get most recent
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now  // Last 3 months
        
        logger.info("📊 Fetching most recent \(metricType.displayName) from last 3 months: \(startDate) to \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: 1,  // Just get the most recent sample
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error = error {
                        self.logger.error("❌ Sample query error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: results ?? [])
                }
                self.healthStore.execute(query)
            }
            
            guard let sample = samples.first as? HKQuantitySample else {
                logger.info("⚠️ No recent \(metricType.displayName) data found")
                return nil
            }
            
            let value = sample.quantity.doubleValue(for: unit)
            logger.info("✅ Most recent \(metricType.displayName): \(value) \(unit.unitString) from \(sample.endDate)")
            
            return HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: sample.endDate,
                source: .healthKit
            )
        } catch {
            logger.error("❌ Error fetching \(metricType.displayName): \(error.localizedDescription)")
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