import Foundation
import HealthKit
import OSLog
import Combine

/// Protocol defining the health data processing functionality
@MainActor protocol HealthDataServicing {
    /// Fetch the latest data for all supported HealthKit metrics
    func fetchLatestMetrics() async -> [HealthMetric]
    
    /// Fetch data for all supported HealthKit metrics within a time range
    func fetchMetrics(from startDate: Date, to endDate: Date) async -> [HealthMetric]
    
    /// Fetch the latest data for a specific HealthKit metric
    func fetchLatestMetric(for type: HealthMetricType) async -> HealthMetric?
    
    /// Process sleep data which requires special handling
    func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric?
    
    /// Combine HealthKit data with manual inputs
    func combineHealthKitAndManualMetrics(healthKitMetrics: [HealthMetric], manualMetrics: [ManualMetricInput]) -> [HealthMetric]
    
    /// Start observing changes to health metrics
    func startObservingMetrics(types: [HealthMetricType]) -> AnyPublisher<[HealthMetric], Never>
    
    /// Calculate statistical summaries of health data
    func calculateMetricStatistics(for type: HealthMetricType, from startDate: Date, to endDate: Date) async -> MetricStatistics?
}

/// Structure to hold statistics about a health metric
struct MetricStatistics {
    let metricType: HealthMetricType
    let average: Double
    let minimum: Double
    let maximum: Double
    let sum: Double
    let count: Int
    let startDate: Date
    let endDate: Date
}

/// Service for processing HealthKit data into usable metrics for the app
@MainActor final class HealthDataService: HealthDataServicing, ObservableObject {
    // MARK: - Properties
    
    private let healthKitManager: HealthKitManaging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthDataService")
    private var metricObservers: [AnyCancellable] = []
    
    /// Published properties for UI binding
    @Published private(set) var latestMetrics: [HealthMetric] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    /// Metrics subject for combining multiple metric updates
    private let metricsSubject = PassthroughSubject<[HealthMetric], Never>()
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
        
        // Initial fetch of metrics if permissions granted
        Task {
            if healthKitManager.hasAllPermissions {
                // Use underscore to explicitly discard result
                _ = await fetchLatestMetrics()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetch the latest data for all supported HealthKit metrics
    func fetchLatestMetrics() async -> [HealthMetric] {
        await withTaskGroup(of: HealthMetric?.self) { group in
            self.isLoading = true
            self.errorMessage = nil
            
            // Add tasks for each metric type
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    await self.fetchLatestMetric(for: metricType)
                }
            }
            
            // Collect results
            var metrics: [HealthMetric] = []
            for await metric in group {
                if let metric = metric {
                    metrics.append(metric)
                }
            }
            
            self.latestMetrics = metrics
            self.isLoading = false
            
            // Notify observers
            self.metricsSubject.send(metrics)
            
            return metrics
        }
    }
    
    /// Fetch data for all supported HealthKit metrics within a time range
    func fetchMetrics(from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        await withTaskGroup(of: [HealthMetric].self) { group in
            self.isLoading = true
            
            // Add tasks for each metric type
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    if metricType == .sleepHours {
                        // Sleep requires special processing
                        if let sleepMetric = await self.healthKitManager.fetchData(for: metricType, from: startDate, to: endDate).first {
                            return [sleepMetric]
                        }
                        return []
                    } else {
                        return await self.healthKitManager.fetchData(for: metricType, from: startDate, to: endDate)
                    }
                }
            }
            
            // Collect results
            var allMetrics: [HealthMetric] = []
            for await metrics in group {
                allMetrics.append(contentsOf: metrics)
            }
            
            self.isLoading = false
            
            return allMetrics
        }
    }
    
    /// Fetch the latest data for a specific HealthKit metric
    func fetchLatestMetric(for type: HealthMetricType) async -> HealthMetric? {
        // Remove the unnecessary try/catch
        let metric = await healthKitManager.fetchLatestData(for: type)
        
        if metric == nil {
            logger.warning("Failed to fetch \(type.displayName) data")
            self.errorMessage = "Failed to fetch \(type.displayName) data"
        }
        
        return metric
    }
    
    /// Process sleep data which requires special handling
    func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric? {
        guard healthKitManager.isHealthKitAvailable else {
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
                
                // Use the getHealthStore method from the protocol
                healthKitManager.getHealthStore().execute(query)
            }
            
            // Process sleep samples to calculate total sleep hours
            var totalSleepTime: TimeInterval = 0
            
            for sample in samples {
                guard let categorySample = sample as? HKCategorySample else { continue }
                
                // Only count asleep states: .asleepUnspecified, .deep, .rem, .core
                if categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                    
                    let sleepTime = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                    totalSleepTime += sleepTime
                }
            }
            
            // Convert to hours and create a metric
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
    
    /// Combine HealthKit data with manual inputs
    func combineHealthKitAndManualMetrics(healthKitMetrics: [HealthMetric], manualMetrics: [ManualMetricInput]) -> [HealthMetric] {
        var combinedMetrics = healthKitMetrics
        let manualHealthMetrics = manualMetrics.map { $0.toHealthMetric() }
        
        // For each manual metric, either add it or replace existing of same type
        for manualMetric in manualHealthMetrics {
            if let index = combinedMetrics.firstIndex(where: { $0.type == manualMetric.type }) {
                // Replace existing metric with manual one if it's more recent
                let existingMetric = combinedMetrics[index]
                if manualMetric.date > existingMetric.date {
                    combinedMetrics[index] = manualMetric
                }
            } else {
                // Add new manual metric
                combinedMetrics.append(manualMetric)
            }
        }
        
        return combinedMetrics
    }
    
    /// Start observing changes to health metrics
    func startObservingMetrics(types: [HealthMetricType]) -> AnyPublisher<[HealthMetric], Never> {
        // Cancel any existing observers
        metricObservers.forEach { $0.cancel() }
        metricObservers.removeAll()
        
        // Start observing each metric type
        for metricType in types {
            Task {
                let publisher = await healthKitManager.startObserving(metricType: metricType)
                
                // Handle errors and filter out nil values
                let processedPublisher = publisher
                    .catch { [weak self] error -> AnyPublisher<HealthMetric?, Error> in
                        self?.logger.error("Error observing \(metricType.rawValue): \(error.localizedDescription)")
                        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
                
                // Set up subscription to update metrics when changes occur
                let cancellable = processedPublisher
                    .compactMap { $0 } // Filter out nil values
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            if case .failure(let error) = completion {
                                self?.logger.error("Metric observation error: \(error.localizedDescription)")
                            }
                        },
                        receiveValue: { [weak self] metric in
                            guard let self = self else { return }
                            
                            // Update the metrics list with the new value
                            Task { @MainActor in
                                await self.updateMetricsList(with: metric)
                            }
                        }
                    )
                
                metricObservers.append(cancellable)
            }
        }
        
        // Start background delivery for these types
        Task {
            let success = await healthKitManager.startBackgroundDelivery(for: types)
            if !success {
                logger.warning("Failed to enable background delivery for some metric types")
            }
        }
        
        // Return the metrics subject as the publisher
        return metricsSubject.eraseToAnyPublisher()
    }
    
    /// Calculate statistical summaries of health data
    func calculateMetricStatistics(for type: HealthMetricType, from startDate: Date, to endDate: Date) async -> MetricStatistics? {
        guard healthKitManager.isHealthKitAvailable else {
            logger.warning("HealthKit is not available for statistics calculation")
            return nil
        }
        
        // For sleep data we need special handling
        if type == .sleepHours {
            return await calculateSleepStatistics(from: startDate, to: endDate)
        }
        
        guard let healthKitType = type.healthKitType, let unit = type.unit else {
            logger.warning("Cannot calculate statistics for \(type.rawValue): No corresponding HealthKit type or unit")
            return nil
        }
        
        let datePredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        do {
            // Execute the statistics query with async/await pattern
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: healthKitType,
                    quantitySamplePredicate: datePredicate,
                    options: [.discreteAverage, .discreteMin, .discreteMax, .cumulativeSum]
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let statistics = statistics else {
                        continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 4, userInfo: [NSLocalizedDescriptionKey: "No statistics available"]))
                        return
                    }
                    
                    continuation.resume(returning: statistics)
                }
                
                // Use the getHealthStore method from the protocol
                healthKitManager.getHealthStore().execute(query)
            }
            
            // Extract the statistical values
            var average = 0.0
            var minimum = 0.0
            var maximum = 0.0
            var sum = 0.0
            var count = 0
            
            if let averageQuantity = statistics.averageQuantity() {
                average = averageQuantity.doubleValue(for: unit)
            }
            
            if let minQuantity = statistics.minimumQuantity() {
                minimum = minQuantity.doubleValue(for: unit)
            }
            
            if let maxQuantity = statistics.maximumQuantity() {
                maximum = maxQuantity.doubleValue(for: unit)
            }
            
            if let sumQuantity = statistics.sumQuantity() {
                sum = sumQuantity.doubleValue(for: unit)
                
                // For count-based metrics like steps, we can derive the count
                if type == .steps {
                    count = Int(sum)
                }
            }
            
            return MetricStatistics(
                metricType: type,
                average: average,
                minimum: minimum,
                maximum: maximum,
                sum: sum,
                count: count,
                startDate: startDate,
                endDate: endDate
            )
            
        } catch {
            logger.error("Error calculating statistics for \(type.rawValue): \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Update the metrics list with a new metric
    @MainActor
    private func updateMetricsList(with newMetric: HealthMetric) async {
        // Find and replace the metric of the same type if it exists
        if let index = self.latestMetrics.firstIndex(where: { $0.type == newMetric.type }) {
            self.latestMetrics[index] = newMetric
        } else {
            // Otherwise add the new metric
            self.latestMetrics.append(newMetric)
        }
        
        // Notify observers of the update
        self.metricsSubject.send(self.latestMetrics)
    }
    
    /// Calculate sleep statistics which require special handling
    private func calculateSleepStatistics(from startDate: Date, to endDate: Date) async -> MetricStatistics? {
        // Get all the sleep metrics in the date range
        let sleepMetrics = await healthKitManager.fetchData(for: .sleepHours, from: startDate, to: endDate)
        
        guard !sleepMetrics.isEmpty else {
            logger.info("No sleep data found for statistics calculation")
            return nil
        }
        
        // Calculate statistics manually
        let sleepValues = sleepMetrics.map { $0.value }
        let average = sleepValues.reduce(0, +) / Double(sleepValues.count)
        let minimum = sleepValues.min() ?? 0
        let maximum = sleepValues.max() ?? 0
        let sum = sleepValues.reduce(0, +)
        
        return MetricStatistics(
            metricType: .sleepHours,
            average: average,
            minimum: minimum,
            maximum: maximum,
            sum: sum,
            count: sleepValues.count,
            startDate: startDate,
            endDate: endDate
        )
    }
} 