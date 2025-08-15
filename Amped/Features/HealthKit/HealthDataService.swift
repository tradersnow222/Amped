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
    
    /// Fetch health metrics aggregated appropriately for the specified time period
    func fetchHealthMetricsForPeriod(timePeriod: TimePeriod) async throws -> [HealthMetric]
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
        
        // Fetch supported HealthKit metric types
        let metricTypesToFetch = HealthMetricType.healthKitTypes
        for metricType in metricTypesToFetch {
            logger.info("  - \(metricType.displayName) (\(metricType.rawValue))")
        }
        
        // Validate metric types with HealthKitManager
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
        
        // Check HealthKit availability
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
    
    /// Fetch health metrics aggregated appropriately for the specified time period using Apple's HealthKit methodology
    func fetchHealthMetricsForPeriod(timePeriod: TimePeriod) async throws -> [HealthMetric] {
        logger.info("🏥 Fetching health metrics for time period: \(timePeriod.displayName) using Apple HealthKit methodology")
        
        var metrics: [HealthMetric] = []
        var successfulMetrics = 0
        var failedMetrics = 0
        
        // Process HealthKit metrics using HKStatisticsCollectionQuery (Apple's method)
        await withTaskGroup(of: (HealthMetricType, HealthMetric?).self) { group in
            for metricType in HealthMetricType.healthKitTypes {
                group.addTask {
                    await self.fetchMetricUsingAppleHealthKitMethodology(metricType: metricType, timePeriod: timePeriod)
                }
            }
            
            // Process manual metrics
            for metricType in HealthMetricType.manualTypes {
                group.addTask {
                    await self.fetchManualMetricForPeriod(metricType: metricType, timePeriod: timePeriod)
                }
            }
            
            // Collect results
            for await (metricType, metric) in group {
                if let metric = metric {
                    // Calculate impact details
                    let tempLifeImpactService = LifeImpactService(userProfile: self.userProfile)
                    let impactDetails = tempLifeImpactService.calculateImpact(for: metric)
                    
                    // CRITICAL FIX: Individual metrics should ALWAYS show DAILY impact, never scaled!
                    // Only the total aggregate impact should be scaled for the dashboard
                    // This fixes the -360.4h issue where individual metrics were incorrectly scaled
                    
                    // Always use daily impact for individual metrics regardless of time period
                    logger.info("📊 \(metric.source.rawValue) metric \(metricType.displayName): \(metric.formattedValue) (Daily Impact: \(impactDetails.lifespanImpactMinutes) min)")
                    
                    // Create metric with DAILY impact details (no scaling for individual metrics)
                    let metricWithImpact = HealthMetric(
                        id: metric.id,
                        type: metric.type,
                        value: metric.value,
                        date: metric.date,
                        source: metric.source,
                        impactDetails: impactDetails
                    )
                    
                    metrics.append(metricWithImpact)
                    successfulMetrics += 1
                } else {
                    failedMetrics += 1
                    logger.warning("⚠️ No data for \(metricType.displayName) in \(timePeriod.displayName)")
                }
            }
        }
        
        let totalHealthKitTypes = HealthMetricType.healthKitTypes.count
        let totalManualTypes = HealthMetricType.manualTypes.count
        
        logger.info("🎉 Total metrics for \(timePeriod.displayName): \(metrics.count) (checked \(totalHealthKitTypes) HealthKit + \(totalManualTypes) manual types, \(failedMetrics) failed)")
        
        return metrics
    }
    
    /// Fetch metric using Apple's exact HealthKit methodology (HKStatisticsCollectionQuery)
    private func fetchMetricUsingAppleHealthKitMethodology(metricType: HealthMetricType, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        
        logger.info("🍎 Fetching \(metricType.displayName) using Apple HealthKit methodology for \(timePeriod.displayName)")
        
        switch metricType {
        case .sleepHours:
            return await fetchSleepForPeriod(timePeriod: timePeriod, endDate: Date())
            
        case .steps, .activeEnergyBurned, .exerciseMinutes:
            return await fetchCumulativeMetricUsingHKStatisticsCollection(metricType: metricType, timePeriod: timePeriod)
            
        case .restingHeartRate, .heartRateVariability, .bodyMass, .vo2Max, .oxygenSaturation:
            return await fetchStatusMetricUsingHKStatisticsCollection(metricType: metricType, timePeriod: timePeriod)
            
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return await fetchManualMetricForPeriod(metricType: metricType, timePeriod: timePeriod)
            
        @unknown default:
            logger.info("❓ Unknown metric type \(metricType.displayName), using latest data")
            let metric = await healthKitManager.fetchLatestData(for: metricType)
            return (metricType, metric)
        }
    }
    
    /// Fetch cumulative metrics using HKStatisticsCollectionQuery (Apple's exact method)
    private func fetchCumulativeMetricUsingHKStatisticsCollection(metricType: HealthMetricType, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        
        guard let quantityType = metricType.healthKitType, let unit = metricType.unit else {
            logger.error("❌ Invalid type or unit for \(metricType.displayName)")
            return (metricType, nil)
        }
        
        logger.info("📊 Using HKStatisticsCollectionQuery for \(metricType.displayName) (\(timePeriod.displayName))")
        
        let calendar = Calendar.current
        let now = Date()
        
        // CRITICAL FIX: Set up dates using Apple Health's exact methodology
        var interval = DateComponents()
        let startDate: Date
        let endDate: Date
        let anchor: Date
        
        switch timePeriod {
        case .day:
            // Day: Just use today's total with HKStatisticsQuery (simpler for single day)
            return await fetchDailyTotalUsingHKStatisticsQuery(metricType: metricType, quantityType: quantityType, unit: unit)
            
        case .month:
            // CRITICAL FIX: Monthly = last 31 calendar days ending today (matches Apple Health "May 12—Jun 11")
            interval.day = 1
            let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
            endDate = endOfToday
            
            // Calculate start date: 31 days back from end of today (to include both endpoints)
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else {
                logger.error("❌ Could not calculate start date for monthly period")
                return (metricType, nil)
            }
            startDate = calculatedStartDate
            anchor = calendar.startOfDay(for: calculatedStartDate)
            
        case .year:
            // CRITICAL FIX: Yearly = last 365 calendar days ending today  
            interval.day = 1
            let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
            endDate = endOfToday
            
            // Calculate start date: 365 days back from end of today
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: now)) else {
                logger.error("❌ Could not calculate start date for yearly period")
                return (metricType, nil)
            }
            startDate = calculatedStartDate  
            anchor = calendar.startOfDay(for: calculatedStartDate)
        }
        
        logger.info("📅 FIXED HKStatisticsCollectionQuery range: \(startDate) to \(endDate)")
        logger.info("🎯 Expected to match Apple Health: \(DateFormatter.localizedString(from: startDate, dateStyle: .medium, timeStyle: .none))—\(DateFormatter.localizedString(from: now, dateStyle: .medium, timeStyle: .none))")
        
        do {
            let statisticsCollection = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatisticsCollection?, Error>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: nil,
                    options: .cumulativeSum, // Apple uses cumulativeSum for these metrics
                    anchorDate: anchor,
                    intervalComponents: interval
                )
                
                query.initialResultsHandler = { _, statisticsCollection, error in
                    if let error = error {
                        self.logger.error("❌ HKStatisticsCollectionQuery error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statisticsCollection)
                }
                
                healthKitManager.executeQuery(query)
            }
            
            guard let collection = statisticsCollection else {
                logger.warning("⚠️ No statistics collection for \(metricType.displayName)")
                return (metricType, nil)
            }
            
            // CRITICAL FIX: Extract daily values and calculate average (Apple's exact methodology)
            var dailyValues: [Double] = []
            var totalDays = 0
            var activeDays = 0
            var totalSum = 0.0
            
            collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                totalDays += 1
                
                if let sumQuantity = statistics.sumQuantity() {
                    let dailyValue = sumQuantity.doubleValue(for: unit)
                    dailyValues.append(dailyValue)
                    totalSum += dailyValue
                    
                    if dailyValue > 0 {
                        activeDays += 1
                    }
                    
                    self.logger.debug("📊 \(statistics.startDate): \(String(format: "%.0f", dailyValue)) \(metricType.displayName)")
                } else {
                    // Include zero days (critical for accurate averages matching Apple Health)
                    dailyValues.append(0.0)
                    self.logger.debug("📊 \(statistics.startDate): 0 \(metricType.displayName)")
                }
            }
            
            guard !dailyValues.isEmpty else {
                logger.warning("⚠️ No daily values found for \(metricType.displayName)")
                return (metricType, nil)
            }
            
            // CRITICAL FIX: Calculate average daily value exactly like Apple Health
            let averageDailyValue = totalSum / Double(totalDays)
            
            logger.info("✅ FIXED Apple HealthKit result for \(metricType.displayName) (\(timePeriod.displayName)):")
            logger.info("   📊 \(String(format: "%.0f", averageDailyValue)) cal/day average")
            logger.info("   📈 \(String(format: "%.0f", totalSum)) cal total over \(totalDays) days (\(activeDays) active)")
            logger.info("   🎯 This should now match Apple Health's \(metricType.displayName) calculation")
            
            let metric = HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: averageDailyValue,
                date: now, // Use current time for metric timestamp
                source: .healthKit
            )
            
            return (metricType, metric)
            
        } catch {
            logger.error("❌ Error with HKStatisticsCollectionQuery for \(metricType.displayName): \(error.localizedDescription)")
            return (metricType, nil)
        }
    }
    
    /// Fetch daily total using HKStatisticsQuery for single-day calculations
    private func fetchDailyTotalUsingHKStatisticsQuery(metricType: HealthMetricType, quantityType: HKQuantityType, unit: HKUnit) async -> (HealthMetricType, HealthMetric?) {
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        logger.info("📊 Using HKStatisticsQuery for today's \(metricType.displayName): \(startOfToday) to \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictEndDate)
        
        do {
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        self.logger.error("❌ HKStatisticsQuery error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statistics)
                }
                
                healthKitManager.executeQuery(query)
            }
            
            guard let statistics = statistics, let sumQuantity = statistics.sumQuantity() else {
                logger.info("⚠️ No daily data for \(metricType.displayName)")
                return (metricType, nil)
            }
            
            let value = sumQuantity.doubleValue(for: unit)
            logger.info("✅ Today's \(metricType.displayName): \(String(format: "%.0f", value))")
            
            let metric = HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: value,
                date: now,
                source: .healthKit
            )
            
            return (metricType, metric)
            
        } catch {
            logger.error("❌ Error with daily HKStatisticsQuery for \(metricType.displayName): \(error.localizedDescription)")
            return (metricType, nil)
        }
    }
    
    /// Fetch status metrics using HKStatisticsCollectionQuery for time periods
    private func fetchStatusMetricUsingHKStatisticsCollection(metricType: HealthMetricType, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        
        guard let quantityType = metricType.healthKitType, let unit = metricType.unit else {
            logger.error("❌ Invalid type or unit for \(metricType.displayName)")
            return (metricType, nil)
        }
        
        switch timePeriod {
        case .day:
            // Day: Get latest value
            logger.info("🫀 Fetching latest \(metricType.displayName)")
            let metric = await healthKitManager.fetchLatestData(for: metricType)
            return (metricType, metric)
            
        case .month, .year:
            // Use HKStatisticsCollectionQuery with daily intervals, then average
            return await fetchStatusMetricAverageUsingHKStatisticsCollection(metricType: metricType, quantityType: quantityType, unit: unit, timePeriod: timePeriod)
        }
    }
    
    /// Fetch average status metric using HKStatisticsCollectionQuery
    private func fetchStatusMetricAverageUsingHKStatisticsCollection(metricType: HealthMetricType, quantityType: HKQuantityType, unit: HKUnit, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        
        logger.info("📊 Using HKStatisticsCollectionQuery for \(metricType.displayName) average (\(timePeriod.displayName))")
        
        let calendar = Calendar.current
        let now = Date()
        
        // CRITICAL FIX: Use same date calculation logic as cumulative metrics
        var interval = DateComponents()
        interval.day = 1  // Daily intervals
        
        let startDate: Date
        let endDate: Date
        let anchor: Date
        
        switch timePeriod {
        case .day:
            logger.error("❌ Day period should not reach this method")
            return (metricType, nil)
            
        case .month:
            // CRITICAL FIX: Monthly = last 31 calendar days ending today
            let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
            endDate = endOfToday
            
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else {
                logger.error("❌ Could not calculate start date for monthly period")
                return (metricType, nil)
            }
            startDate = calculatedStartDate
            anchor = calendar.startOfDay(for: calculatedStartDate)
            
        case .year:
            // CRITICAL FIX: Yearly = last 365 calendar days ending today
            let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now
            endDate = endOfToday
            
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: now)) else {
                logger.error("❌ Could not calculate start date for yearly period")
                return (metricType, nil)
            }
            startDate = calculatedStartDate
            anchor = calendar.startOfDay(for: calculatedStartDate)
        }
        
        logger.info("📅 FIXED Status metric HKStatisticsCollectionQuery range: \(startDate) to \(endDate)")
        
        do {
            let statisticsCollection = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatisticsCollection?, Error>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: nil,
                    options: .discreteAverage, // Use discreteAverage for status metrics
                    anchorDate: anchor,
                    intervalComponents: interval
                )
                
                query.initialResultsHandler = { _, statisticsCollection, error in
                    if let error = error {
                        self.logger.error("❌ HKStatisticsCollectionQuery error for \(metricType.displayName): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statisticsCollection)
                }
                
                healthKitManager.executeQuery(query)
            }
            
            guard let collection = statisticsCollection else {
                logger.warning("⚠️ No statistics collection for \(metricType.displayName)")
                return (metricType, nil)
            }
            
            // Extract daily averages and calculate overall average
            var dailyAverages: [Double] = []
            var totalDays = 0
            var daysWithData = 0
            
            collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                totalDays += 1
                
                if let averageQuantity = statistics.averageQuantity() {
                    let dailyAverage = averageQuantity.doubleValue(for: unit)
                    dailyAverages.append(dailyAverage)
                    daysWithData += 1
                    
                    self.logger.debug("📊 \(statistics.startDate): \(String(format: "%.1f", dailyAverage)) avg \(metricType.displayName)")
                }
            }
            
            guard !dailyAverages.isEmpty else {
                logger.warning("⚠️ No daily averages found for \(metricType.displayName)")
                return (metricType, nil)
            }
            
            // Calculate overall average
            let overallAverage = dailyAverages.reduce(0, +) / Double(dailyAverages.count)
            
            logger.info("✅ FIXED Apple HealthKit average for \(metricType.displayName) (\(timePeriod.displayName)): \(String(format: "%.1f", overallAverage)) over \(daysWithData) days with data out of \(totalDays) total days")
            
            let metric = HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: overallAverage,
                date: now, // Use current time for metric timestamp
                source: .healthKit
            )
            
            return (metricType, metric)
            
        } catch {
            logger.error("❌ Error with status metric HKStatisticsCollectionQuery for \(metricType.displayName): \(error.localizedDescription)")
            return (metricType, nil)
        }
    }
    
    /// Fetch sleep with appropriate aggregation for time period
    private func fetchSleepForPeriod(timePeriod: TimePeriod, endDate: Date) async -> (HealthMetricType, HealthMetric?) {
        guard let concreteManager = healthKitManager as? HealthKitManager else {
            logger.error("❌ Cannot access sleepManager - healthKitManager is not HealthKitManager")
            return (.sleepHours, nil)
        }
        
        switch timePeriod {
        case .day:
            // DAY: Last night's sleep (attributed to today)
            let today = Date()
            let sleepMetric = await concreteManager.sleepManager.processSleepData(from: today, to: today)
            logger.info("😴 Today's sleep: \(sleepMetric?.formattedValue ?? "nil")")
            return (.sleepHours, sleepMetric)
            
        case .month, .year:
            // MONTH/YEAR: Average nightly sleep over the period
            return await fetchAverageSleepForPeriod(timePeriod: timePeriod, endDate: endDate, sleepManager: concreteManager.sleepManager)
        }
    }
    
    /// Fetch average sleep for month/year periods  
    private func fetchAverageSleepForPeriod(timePeriod: TimePeriod, endDate: Date, sleepManager: HealthKitSleepManager) async -> (HealthMetricType, HealthMetric?) {
        let calendar = Calendar.current
        
        // CRITICAL FIX: Use same date calculation logic as other metrics
        let daysToFetch: Int
        let startDate: Date
        
        switch timePeriod {
        case .day:
            logger.error("❌ Day period should not reach this method")
            return (.sleepHours, nil)
            
        case .month:
            // CRITICAL FIX: Monthly = last 31 calendar days ending today (matches other metrics)
            daysToFetch = 31
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: endDate)) else {
                logger.error("❌ Could not calculate start date for monthly sleep period")
                return (.sleepHours, nil)
            }
            startDate = calculatedStartDate
            
        case .year:
            // CRITICAL FIX: Yearly = last 365 calendar days ending today (matches other metrics)  
            daysToFetch = 365
            guard let calculatedStartDate = calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: endDate)) else {
                logger.error("❌ Could not calculate start date for yearly sleep period")
                return (.sleepHours, nil)
            }
            startDate = calculatedStartDate
        }
        
        logger.info("😴 FIXED sleep calculation over \(daysToFetch) days for \(timePeriod.displayName)")
        logger.info("📅 Sleep period range: \(startDate) to \(endDate)")
        
        var sleepValues: [Double] = []
        var validNights = 0
        var totalDaysChecked = 0
        
        // CRITICAL FIX: Process each night in the rolling period exactly like other metrics
        for dayOffset in 0..<daysToFetch {
            guard let targetDay = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { 
                logger.warning("⚠️ Could not calculate date for day offset \(dayOffset)")
                continue 
            }
            
            totalDaysChecked += 1
            
            if let sleepMetric = await sleepManager.processSleepData(from: targetDay, to: targetDay) {
                sleepValues.append(sleepMetric.value)
                validNights += 1
                logger.debug("✅ Sleep for \(calendar.startOfDay(for: targetDay)): \(String(format: "%.2f", sleepMetric.value))h")
            } else {
                logger.debug("⚠️ No sleep data for \(calendar.startOfDay(for: targetDay))")
            }
        }
        
        logger.info("📊 FIXED sleep data summary for \(timePeriod.displayName): \(validNights) nights with data out of \(totalDaysChecked) days checked")
        
        guard !sleepValues.isEmpty else {
            logger.warning("⚠️ No sleep data found for \(timePeriod.displayName) period (\(totalDaysChecked) days checked)")
            return (.sleepHours, nil)
        }
        
        // Calculate average sleep
        let averageSleep = sleepValues.reduce(0, +) / Double(sleepValues.count)
        let totalSleep = sleepValues.reduce(0, +)
        let minSleep = sleepValues.min() ?? 0
        let maxSleep = sleepValues.max() ?? 0
        
        logger.info("✅ FIXED average sleep for \(timePeriod.displayName): \(String(format: "%.2f", averageSleep))h over \(validNights) nights out of \(totalDaysChecked) total days")
        logger.info("📈 Sleep totals: \(String(format: "%.1f", totalSleep))h total, \(String(format: "%.2f", averageSleep))h avg, min: \(String(format: "%.2f", minSleep))h, max: \(String(format: "%.2f", maxSleep))h")
        logger.info("🎯 This should now match Apple Health's Sleep calculation")
        
        // CRITICAL FIX: Ensure the average is reasonable before creating metric
        if averageSleep >= 0.5 && averageSleep <= 16.0 {
            let averageMetric = HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: averageSleep,
                date: endDate,
                source: .healthKit
            )
            
            return (.sleepHours, averageMetric)
        } else {
            logger.warning("⚠️ Calculated average sleep \(String(format: "%.2f", averageSleep))h is outside reasonable range")
            return (.sleepHours, nil)
        }
    }
    
    /// Fetch manual metrics for time period display
    private func fetchManualMetricForPeriod(metricType: HealthMetricType, timePeriod: TimePeriod) async -> (HealthMetricType, HealthMetric?) {
        // Get the manual metric from questionnaire
        let manualMetricInputs = questionnaireManager.getCurrentManualMetrics()
        
        if let manualInput = manualMetricInputs.first(where: { $0.type == metricType }) {
            var healthMetric = manualInput.toHealthMetric()
            
            // Calculate impact details for manual metric with time period context
            let tempLifeImpactService = LifeImpactService(userProfile: userProfile)
            let impactDetails = tempLifeImpactService.calculateImpact(for: healthMetric)
            
            // Note: Manual metrics are NOT scaled by time period since they represent lifestyle factors
            // that have the same daily impact regardless of the viewing period
            // The impact already represents the ongoing effect of this lifestyle choice
            
            // Add impact details to the metric
            healthMetric = HealthMetric(
                id: healthMetric.id,
                type: healthMetric.type,
                value: healthMetric.value,
                date: healthMetric.date,
                source: healthMetric.source,
                impactDetails: impactDetails
            )
            
            logger.info("📋 Manual metric \(metricType.displayName): \(healthMetric.formattedValue) (Impact: \(impactDetails.lifespanImpactMinutes) minutes)")
            return (metricType, healthMetric)
        }
        
        logger.info("⚠️ No manual metric data found for \(metricType.displayName)")
        return (metricType, nil)
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
