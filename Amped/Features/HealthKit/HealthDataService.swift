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
    
    /// User profile for impact calculations
    private let userProfile: UserProfile
    
    /// Published properties for UI binding
    @Published private(set) var latestMetrics: [HealthMetric] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    /// Metrics subject for combining multiple metric updates
    private let metricsSubject = PassthroughSubject<[HealthMetric], Never>()
    
    /// Questionnaire manager for fetching manual metrics
    private let questionnaireManager: QuestionnaireManager
    
    // MARK: - Initialization
    
    init(
        healthKitManager: HealthKitManaging,
        userProfile: UserProfile,
        questionnaireManager: QuestionnaireManager? = nil
    ) {
        self.healthKitManager = healthKitManager
        self.userProfile = userProfile
        self.questionnaireManager = questionnaireManager ?? QuestionnaireManager()
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
        logger.info("🏥 Starting to fetch latest health metrics...")
        
        // CRITICAL DEBUG: Show exactly which metric types we're trying to fetch
        let metricTypesToFetch = HealthMetricType.healthKitTypes
        logger.info("🎯 Will attempt to fetch \(metricTypesToFetch.count) HealthKit metric types:")
        for metricType in metricTypesToFetch {
            logger.info("  - \(metricType.displayName) (\(metricType.rawValue))")
        }
        
        // CRITICAL DEBUG: Also check what the HealthKitManager thinks we should fetch
        if self.healthKitManager is HealthKitManager {
            let managerTypes = HealthKitManager.allMetricTypes
            logger.info("🔍 HealthKitManager.allMetricTypes contains \(managerTypes.count) types:")
            for metricType in managerTypes {
                logger.info("  - Manager: \(metricType.displayName) (\(metricType.rawValue))")
            }
            
            // Check if there's a mismatch
            let mismatchedTypes = metricTypesToFetch.filter { !managerTypes.contains($0) }
            if !mismatchedTypes.isEmpty {
                logger.warning("⚠️ MISMATCH DETECTED! These types are in healthKitTypes but not in manager's allMetricTypes:")
                for mismatchedType in mismatchedTypes {
                    logger.warning("  - MISMATCH: \(mismatchedType.displayName)")
                }
            }
        }
        
        // CRITICAL DEBUG: Let's also check HealthKit availability at the HealthStore level
        if HKHealthStore.isHealthDataAvailable() {
            logger.info("✅ HKHealthStore.isHealthDataAvailable() returns true")
        } else {
            logger.error("❌ HKHealthStore.isHealthDataAvailable() returns false")
        }
        
        // Fetch data for each health metric type concurrently
        let results = await withTaskGroup(of: (HealthMetricType, HealthMetric?).self) { group in
            for metricType in metricTypesToFetch {
                group.addTask { [self] in
                    logger.info("🔄 Fetching data for: \(metricType.displayName)")
                    let metric = await self.healthKitManager.fetchLatestData(for: metricType)
                    
                    if var metric = metric {
                        // CRITICAL FIX: Always calculate impact details, even for zero values
                        self.logger.info("🧮 Calculating impact details for \(metricType.displayName) with value: \(metric.value)")
                        
                        let tempLifeImpactService = LifeImpactService(userProfile: self.userProfile)
                        let impactDetails = tempLifeImpactService.calculateImpact(for: metric)
                        
                        // Create new metric with impact details
                        metric = HealthMetric(
                            id: metric.id,
                            type: metric.type,
                            value: metric.value,
                            date: metric.date,
                            source: metric.source,
                            impactDetails: impactDetails
                        )
                        
                        self.logger.info("✅ Added impact details to \(metricType.rawValue): \(impactDetails.lifespanImpactMinutes) minutes")
                    }
                    
                    return (metricType, metric)
                }
            }
            
            // Collect results, filtering out nil values
            var healthKitMetrics: [HealthMetric] = []
            for await (metricType, metric) in group {
                if let metric = metric {
                    logger.info("✅ Successfully fetched: \(metricType.displayName) = \(metric.formattedValue)")
                    healthKitMetrics.append(metric)
                } else {
                    logger.warning("⚠️ No data available for: \(metricType.displayName)")
                }
            }
            return healthKitMetrics
        }
        
        // CRITICAL FIX: Fetch manual metrics from questionnaire and combine with HealthKit metrics
        logger.info("📝 Fetching manual metrics from questionnaire...")
        let manualMetricInputs = questionnaireManager.getCurrentManualMetrics()
        logger.info("📊 Found \(manualMetricInputs.count) manual metrics from questionnaire")
        
        // Convert manual inputs to health metrics with impact calculations
        var manualHealthMetrics: [HealthMetric] = []
        for manualInput in manualMetricInputs {
            var healthMetric = manualInput.toHealthMetric()
            
            // Calculate impact details for manual metric
            let tempLifeImpactService = LifeImpactService(userProfile: userProfile)
            let impactDetails = tempLifeImpactService.calculateImpact(for: healthMetric)
            
            // Add impact details to the metric
            healthMetric = HealthMetric(
                id: healthMetric.id,
                type: healthMetric.type,
                value: healthMetric.value,
                date: healthMetric.date,
                source: healthMetric.source,
                impactDetails: impactDetails
            )
            
            manualHealthMetrics.append(healthMetric)
            logger.info("📋 Added manual metric: \(healthMetric.type.displayName) = \(healthMetric.formattedValue) (Impact: \(impactDetails.lifespanImpactMinutes) minutes)")
        }
        
        // Combine HealthKit and manual metrics
        let combinedMetrics = results + manualHealthMetrics
        
        logger.info("🎉 Fetch complete! Retrieved \(results.count) HealthKit metrics + \(manualHealthMetrics.count) manual metrics = \(combinedMetrics.count) total")
        logger.info("📊 Combined metrics breakdown:")
        for metric in combinedMetrics {
            logger.info("  - \(metric.type.displayName): \(metric.formattedValue) (Source: \(metric.source.rawValue))")
        }
        
        return combinedMetrics
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
        logger.info("🔍 Checking permissions for \(type.displayName)")
        
        // Check authorization status using the permission status property
        let authStatus = healthKitManager.permissionStatus[type] ?? .notDetermined
        logger.info("🔐 Authorization status for \(type.displayName): \(String(describing: authStatus))")
        
        // CRITICAL FIX: Don't strictly block on permission status since it can be unreliable
        // Log the status but always attempt to fetch data - the HealthKitManager will handle
        // the actual permission validation during data access
        if authStatus != .sharingAuthorized {
            logger.info("⚠️ Permission status reports \(String(describing: authStatus)) for \(type.displayName), but will attempt data access anyway since permission status can be unreliable")
        } else {
            logger.info("✅ Permission granted for \(type.displayName)")
        }
        
        // ALWAYS attempt to fetch the actual data - let HealthKitManager handle permission validation
        logger.info("📊 Fetching latest data for \(type.displayName)")
        let metric = await healthKitManager.fetchLatestData(for: type)
        
        if let metric = metric {
            logger.info("✅ Found data for \(type.displayName): \(metric.formattedValue)")
            return metric
        } else {
            logger.warning("⚠️ No data found for \(type.displayName)")
            return nil
        }
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
    
    /// Fetch health metrics for dashboard (alias for fetchLatestMetrics)
    func fetchHealthMetrics() async throws -> [HealthMetric] {
        return await fetchLatestMetrics()
    }
    
    /// Fetch health metrics aggregated appropriately for the specified time period
    func fetchHealthMetricsForPeriod(timePeriod: TimePeriod) async throws -> [HealthMetric] {
        logger.info("🏥 Fetching health metrics for time period: \(timePeriod.displayName)")
        
        // Calculate the date range for the period
        let endDate = Date()
        let startDate: Date
        
        switch timePeriod {
        case .day:
            // Last 24 hours
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        case .month:
            // Last 30 days
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .year:
            // Last 365 days
            startDate = Calendar.current.date(byAdding: .day, value: -365, to: endDate) ?? endDate
        }
        
        logger.info("📅 Date range: \(startDate) to \(endDate)")
        
        var metrics: [HealthMetric] = []
        
        // Fetch data for each health metric type with period-appropriate aggregation
        await withTaskGroup(of: (HealthMetricType, HealthMetric?).self) { group in
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    await self.fetchMetricForPeriod(metricType: metricType, from: startDate, to: endDate, timePeriod: timePeriod)
                }
            }
            
            // Collect results
            for await (metricType, metric) in group {
                if let metric = metric {
                    // Calculate impact details
                    let tempLifeImpactService = LifeImpactService(userProfile: self.userProfile)
                    let impactDetails = tempLifeImpactService.calculateImpact(for: metric)
                    
                    // Create metric with impact details
                    let metricWithImpact = HealthMetric(
                        id: metric.id,
                        type: metric.type,
                        value: metric.value,
                        date: metric.date,
                        source: metric.source,
                        impactDetails: impactDetails
                    )
                    
                    metrics.append(metricWithImpact)
                    logger.info("✅ Added \(metricType.displayName) for \(timePeriod.displayName): \(metric.formattedValue)")
                }
            }
        }
        
        // CRITICAL FIX: Add manual metrics from questionnaire
        logger.info("📝 Adding manual metrics from questionnaire...")
        let manualMetricInputs = questionnaireManager.getCurrentManualMetrics()
        logger.info("📊 Found \(manualMetricInputs.count) manual metrics from questionnaire")
        
        // Convert manual inputs to health metrics with impact calculations
        for manualInput in manualMetricInputs {
            var healthMetric = manualInput.toHealthMetric()
            
            // Calculate impact details for manual metric
            let tempLifeImpactService = LifeImpactService(userProfile: userProfile)
            let impactDetails = tempLifeImpactService.calculateImpact(for: healthMetric)
            
            // Add impact details to the metric
            healthMetric = HealthMetric(
                id: healthMetric.id,
                type: healthMetric.type,
                value: healthMetric.value,
                date: healthMetric.date,
                source: healthMetric.source,
                impactDetails: impactDetails
            )
            
            metrics.append(healthMetric)
            logger.info("📋 Added manual metric: \(healthMetric.type.displayName) = \(healthMetric.formattedValue) (Impact: \(impactDetails.lifespanImpactMinutes) minutes)")
        }
        
        logger.info("🎉 Total metrics for \(timePeriod.displayName): \(metrics.count)")
        
        return metrics
    }
    
    /// Fetch a single metric appropriately aggregated for the time period
    private func fetchMetricForPeriod(metricType: HealthMetricType, from startDate: Date, to endDate: Date, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        
        logger.info("🔍 fetchMetricForPeriod: \(metricType.displayName) for \(timePeriod.displayName) from \(startDate) to \(endDate)")
        
        switch metricType {
        case .sleepHours:
            // Sleep: Always get most recent night regardless of period
            let sleepMetric = await healthKitManager.fetchLatestData(for: metricType)
            logger.info("😴 Sleep metric for \(timePeriod.displayName): \(sleepMetric?.formattedValue ?? "nil")")
            return (metricType, sleepMetric)
            
        case .steps, .activeEnergyBurned, .exerciseMinutes:
            // Activity metrics: Get TOTAL activity over the period (not average)
            logger.info("🏃 Fetching historical data for \(metricType.displayName) over \(timePeriod.displayName)")
            let metrics = await healthKitManager.fetchData(for: metricType, from: startDate, to: endDate)
            logger.info("📊 Found \(metrics.count) historical samples for \(metricType.displayName)")
            
            if !metrics.isEmpty {
                // CRITICAL FIX: For activity metrics, sum the values over the period
                let totalValue = metrics.reduce(0) { $0 + $1.value }
                
                // Create a metric with the total value
                let totalMetric = HealthMetric(
                    id: UUID().uuidString,
                    type: metricType,
                    value: totalValue,
                    date: endDate,
                    source: .healthKit
                )
                
                logger.info("📈 Total \(metricType.displayName) for \(timePeriod.displayName): \(totalMetric.formattedValue)")
                return (metricType, totalMetric)
            }
            
            // No data available
            logger.warning("❌ No real data available for \(metricType.displayName) - will not show this metric")
            return (metricType, nil)
            
        case .restingHeartRate, .heartRateVariability, .vo2Max, .oxygenSaturation:
            // Physiological metrics: Get most recent measurement (represents current state)
            let latest = await healthKitManager.fetchLatestData(for: metricType)
            logger.info("❤️ Latest \(metricType.displayName): \(latest?.formattedValue ?? "nil")")
            return (metricType, latest)
            
        case .bodyMass:
            // Body composition: Get most recent measurement
            let latest = await healthKitManager.fetchLatestData(for: metricType)
            logger.info("⚖️ Latest \(metricType.displayName): \(latest?.formattedValue ?? "nil")")
            return (metricType, latest)
            
        case .nutritionQuality, .stressLevel, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality:
            // Lifestyle metrics: These are manual inputs, get latest
            let latest = await healthKitManager.fetchLatestData(for: metricType)
            logger.info("📝 Manual metric \(metricType.displayName): \(latest?.formattedValue ?? "nil")")
            return (metricType, latest)
            
        @unknown default:
            // Default: get latest
            let latest = await healthKitManager.fetchLatestData(for: metricType)
            logger.info("❓ Unknown metric \(metricType.displayName): \(latest?.formattedValue ?? "nil")")
            return (metricType, latest)
        }
    }
    
    /// Calculate average metric from a collection of metrics
    private func calculateAverageMetric(from metrics: [HealthMetric], metricType: HealthMetricType, endDate: Date) -> HealthMetric? {
        guard !metrics.isEmpty else { return nil }
        
        let totalValue = metrics.reduce(0) { $0 + $1.value }
        let averageValue = totalValue / Double(metrics.count)
        
        return HealthMetric(
            id: UUID().uuidString,
            type: metricType,
            value: averageValue,
            date: endDate,
            source: .healthKit
        )
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