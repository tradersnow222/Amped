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
}

/// Service for processing HealthKit data into usable metrics
@MainActor final class HealthDataService: HealthDataServicing, ObservableObject {
    // MARK: - Properties
    
    private let healthKitManager: HealthKitManaging
    private let logger = Logger(subsystem: "com.amped.Amped", category: "HealthDataService")
    
    @Published var latestMetrics: [HealthMetric] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - Public methods
    
    func fetchLatestMetrics() async -> [HealthMetric] {
        await withCheckedContinuation { continuation in
            Task {
                self.isLoading = true
                
                var metrics: [HealthMetric] = []
                
                // Process each HealthKit metric type
                for metricType in HealthMetricType.healthKitTypes {
                    if metricType == .sleepHours {
                        // Sleep requires special processing
                        if let sleepMetric = await processSleepData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, to: Date()) {
                            metrics.append(sleepMetric)
                        }
                    } else {
                        // Standard HealthKit metric
                        if let metric = await healthKitManager.fetchLatestData(for: metricType) {
                            metrics.append(metric)
                        }
                    }
                }
                
                self.latestMetrics = metrics
                self.isLoading = false
                
                continuation.resume(returning: metrics)
            }
        }
    }
    
    func fetchMetrics(from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        var allMetrics: [HealthMetric] = []
        
        // Process each HealthKit metric type
        for metricType in HealthMetricType.healthKitTypes {
            if metricType == .sleepHours {
                // Sleep requires special processing
                if let sleepMetric = await processSleepData(from: startDate, to: endDate) {
                    allMetrics.append(sleepMetric)
                }
            } else {
                // Standard HealthKit metrics
                let metrics = await healthKitManager.fetchData(for: metricType, from: startDate, to: endDate)
                allMetrics.append(contentsOf: metrics)
            }
        }
        
        return allMetrics
    }
    
    func fetchLatestMetric(for type: HealthMetricType) async -> HealthMetric? {
        if type == .sleepHours {
            // Sleep requires special processing
            return await processSleepData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, to: Date())
        } else {
            // Standard HealthKit metric
            return await healthKitManager.fetchLatestData(for: type)
        }
    }
    
    func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric? {
        guard healthKitManager.isHealthKitAvailable else {
            logger.warning("HealthKit is not available for sleep processing")
            return nil
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        do {
            let samples = try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<[HKSample], Error>) in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                    return
                }
                
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
                
                if let healthKitManager = self.healthKitManager as? HealthKitManager {
                    healthKitManager.getHealthStore().execute(query)
                } else {
                    continuation.resume(returning: [])
                }
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
    
    nonisolated func combineHealthKitAndManualMetrics(healthKitMetrics: [HealthMetric], manualMetrics: [ManualMetricInput]) -> [HealthMetric] {
        var combinedMetrics = healthKitMetrics
        
        // Convert manual inputs to HealthMetric and add them
        let manualHealthMetrics = manualMetrics.map { $0.toHealthMetric() }
        
        // Add manual metrics that don't already exist in HealthKit metrics
        for manualMetric in manualHealthMetrics {
            // Skip if we already have this metric type from HealthKit
            if !combinedMetrics.contains(where: { $0.type == manualMetric.type }) {
                combinedMetrics.append(manualMetric)
            }
        }
        
        return combinedMetrics
    }
} 