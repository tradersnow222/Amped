import Foundation
import HealthKit
@preconcurrency import Combine
import OSLog

/// Protocol defining the health data processing functionality
protocol HealthDataServicing {
    /// Fetch the latest data for all supported HealthKit metrics
    func fetchLatestMetrics() async -> [HealthMetric]
    
    /// Fetch data for all supported HealthKit metrics within a time range
    func fetchMetrics(from startDate: Date, to endDate: Date) async -> [HealthMetric]
    
    /// Fetch the latest data for a specific HealthKit metric
    func fetchLatestMetric(for type: HealthMetricType) async -> HealthMetric?
    
    /// Combine HealthKit data with manual inputs
    func combineHealthKitAndManualMetrics(healthKitMetrics: [HealthMetric], manualMetrics: [ManualMetricInput]) -> [HealthMetric]
    
    /// Start observing changes to health metrics
    func startObservingMetrics(types: [HealthMetricType]) -> AnyPublisher<[HealthMetric], Never>
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
    private let statisticsCalculator: HealthMetricsStatisticsCalculator
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthDataService")
    private var metricObservers = Set<AnyCancellable>()
    
    /// Published properties for UI binding
    @Published private(set) var latestMetrics: [HealthMetric] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    /// Metrics subject for combining multiple metric updates
    private let metricsSubject = PassthroughSubject<[HealthMetric], Never>()
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManaging) {
        self.healthKitManager = healthKitManager
        self.statisticsCalculator = HealthMetricsStatisticsCalculator(healthKitManager: healthKitManager)
        
        // Initial fetch of metrics if permissions granted
        Task {
            if healthKitManager.hasAllPermissions || healthKitManager.hasCriticalPermissions {
                _ = await fetchLatestMetrics()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetch the latest data for all supported HealthKit metrics
    func fetchLatestMetrics() async -> [HealthMetric] {
        isLoading = true
        errorMessage = nil
        
        var metrics: [HealthMetric] = []
        
        // Fetch data for each health metric type concurrently
        await withTaskGroup(of: HealthMetric?.self) { group in
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    await self.fetchLatestMetric(for: metricType)
                }
            }
            
            // Collect results, filtering out nil values
            for await metric in group {
                if let metric = metric {
                    metrics.append(metric)
                }
            }
        }
        
        await MainActor.run {
            self.latestMetrics = metrics
            self.isLoading = false
            self.metricsSubject.send(metrics)
        }
        
        return metrics
    }
    
    /// Fetch data for all supported HealthKit metrics within a time range
    func fetchMetrics(from startDate: Date, to endDate: Date) async -> [HealthMetric] {
        isLoading = true
        
        var allMetrics: [HealthMetric] = []
        
        // Fetch data for each health metric type concurrently
        await withTaskGroup(of: [HealthMetric].self) { group in
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    await self.healthKitManager.fetchData(for: metricType, from: startDate, to: endDate)
                }
            }
            
            // Collect results
            for await metrics in group {
                allMetrics.append(contentsOf: metrics)
            }
        }
        
        isLoading = false
        return allMetrics
    }
    
    /// Fetch the latest data for a specific HealthKit metric
    func fetchLatestMetric(for type: HealthMetricType) async -> HealthMetric? {
        let metric = await healthKitManager.fetchLatestData(for: type)
        
        if metric == nil {
            logger.warning("Failed to fetch \(type.displayName) data")
            errorMessage = "Failed to fetch \(type.displayName) data"
        }
        
        return metric
    }
    
    /// Combine HealthKit data with manual inputs
    nonisolated func combineHealthKitAndManualMetrics(healthKitMetrics: [HealthMetric], manualMetrics: [ManualMetricInput]) -> [HealthMetric] {
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
    nonisolated func startObservingMetrics(types: [HealthMetricType]) -> AnyPublisher<[HealthMetric], Never> {
        // This implementation will need to be updated to work properly with nonisolated
        // For now, returning an empty publisher
        return Empty().eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Update the metrics list with a new metric
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
} 