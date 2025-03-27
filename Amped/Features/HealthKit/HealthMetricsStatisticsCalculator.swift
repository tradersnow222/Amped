import Foundation
import HealthKit
import OSLog

/// Protocol defining health metrics statistics calculation functionality
@MainActor protocol HealthMetricsStatisticsCalculating {
    /// Calculate statistical summaries of health data
    func calculateMetricStatistics(for type: HealthMetricType, from startDate: Date, to endDate: Date) async -> MetricStatistics?
}

/// Service for calculating health metrics statistics
@MainActor final class HealthMetricsStatisticsCalculator: HealthMetricsStatisticsCalculating {
    // MARK: - Properties
    
    private let healthKitManager: HealthKitManaging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthMetricsStatisticsCalculator")
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - Public Methods
    
    /// Calculate statistical summaries of health data
    func calculateMetricStatistics(for type: HealthMetricType, from startDate: Date, to endDate: Date) async -> MetricStatistics? {
        guard HKHealthStore.isHealthDataAvailable() else {
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
                
                // Use the proper method to execute the query
                if let manager = healthKitManager as? HealthKitManager {
                    manager.executeQuery(query)
                } else {
                    continuation.resume(throwing: NSError(domain: "com.amped.Amped", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid HealthKit manager"]))
                }
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