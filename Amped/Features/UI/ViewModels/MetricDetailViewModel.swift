import SwiftUI
import Combine
import HealthKit
import OSLog

/// View model for the metric detail view
/// CRITICAL FIX: Prevents value corruption when switching between time periods.
/// The original daily metric is preserved immutably, while period-specific display values
/// are stored separately to maintain data integrity during period switching.
@MainActor
final class MetricDetailViewModel: ObservableObject {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "Amped", category: "MetricDetailViewModel")
    
    @Published var historyData: [HistoryDataPoint] = []
    @Published var recommendations: [MetricRecommendation] = []
    @Published var metric: HealthMetric  // Always stores the original daily metric
    @Published var selectedPeriod: ImpactDataPoint.PeriodType = .day {
        didSet {
            // Cancel previous task to prevent race conditions
            currentDataTask?.cancel()
            
            // Reload real data when period changes
            currentDataTask = Task {
                await loadRealHistoryData(for: originalMetric)
                await updatePeriodSpecificValue()
            }
        }
    }
    
    // CRITICAL FIX: Store original daily metric to prevent value corruption
    private let originalMetric: HealthMetric
    
    // Store period-specific calculated values separately
    @Published private var periodSpecificValue: Double?
    
    private let healthKitManager: HealthKitManager
    private let healthDataService: HealthDataService
    private var currentDataTask: Task<Void, Never>?
    
    // MARK: - Real-time Updates Support
    
    /// Combine cancellables for real-time subscriptions - following Apple's Combine best practices
    private var cancellables = Set<AnyCancellable>()
    
    /// Track if we're currently refreshing to prevent overlapping operations
    @Published private var isRefreshing: Bool = false
    
    // MARK: - Impact Chart Data
    
    /// Chart data points showing cumulative life impact over time
    var impactChartDataPoints: [ChartImpactDataPoint] {
        // Rule: Simplicity is KING - Clear, focused calculation
        let userProfile = UserProfile()
        let lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        var impactPoints: [ChartImpactDataPoint] = []
        var cumulativeImpact: Double = 0.0
        
        // Sort history data by date for proper cumulative calculation
        let sortedHistory = historyData.sorted { $0.date < $1.date }
        
        // Track current day for resetting cumulative impact (Rule: Follow Apple's Human Interface Guidelines)
        let calendar = Calendar.current
        var currentDay = calendar.startOfDay(for: sortedHistory.first?.date ?? Date())
        
        for (_, dataPoint) in sortedHistory.enumerated() {
            // Check if we've moved to a new day (for daily period view)
            if selectedPeriod == .day {
                let dataPointDay = calendar.startOfDay(for: dataPoint.date)
                if dataPointDay != currentDay {
                    // Reset cumulative impact for new day
                    cumulativeImpact = 0.0
                    currentDay = dataPointDay
                }
            }
            
            // Create a temporary metric for this data point using original metric properties
            let tempMetric = HealthMetric(
                id: UUID().uuidString,
                type: originalMetric.type,
                value: dataPoint.value,
                date: dataPoint.date,
                source: originalMetric.source
            )
            
            // CRITICAL FIX: Always recalculate impact for accurate real-time charts
            let impactDetail = lifeImpactService.calculateImpact(for: tempMetric)
            let impactMinutes = impactDetail.lifespanImpactMinutes
            
            // For cumulative metrics in daily view, calculate incremental impact
            if originalMetric.type.isCumulative && selectedPeriod == .day {
                // For cumulative metrics, show incremental daily impact
                cumulativeImpact += impactMinutes
                impactPoints.append(ChartImpactDataPoint(
                    date: dataPoint.date,
                    impact: cumulativeImpact,
                    value: dataPoint.value
                ))
            } else {
                // For discrete metrics or non-daily periods, show direct impact
                impactPoints.append(ChartImpactDataPoint(
                    date: dataPoint.date,
                    impact: impactMinutes,
                    value: dataPoint.value
                ))
            }
        }
        
        return impactPoints
    }
    
    /// Display the current metric value, handling period-specific calculations
    var displayMetricValue: Double {
        // CRITICAL FIX: Always use original daily value for day period
        if selectedPeriod == .day {
            return originalMetric.value
        }
        
        // For month/year periods, use the calculated period-specific value if available
        if let periodValue = periodSpecificValue {
            return periodValue
        }
        
        // Fallback to calculating from history data if available
        if !historyData.isEmpty {
            let totalValue = historyData.reduce(0.0) { $0 + $1.value }
            let averageValue = totalValue / Double(historyData.count)
            return averageValue
        }
        
        // Final fallback to original metric value
        return originalMetric.value
    }
    
    /// CRITICAL FIX: Calculate current impact dynamically based on displayed value
    var currentImpactMinutes: Double {
        let userProfile = UserProfile()
        let lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        // Create a metric with the current displayed value for real-time impact calculation
        let currentMetric = HealthMetric(
            id: originalMetric.id,
            type: originalMetric.type,
            value: displayMetricValue,
            date: Date(), // Use current date for real-time calculation
            source: originalMetric.source
        )
        
        // Calculate fresh impact details
        let impactDetail = lifeImpactService.calculateImpact(for: currentMetric)
        return impactDetail.lifespanImpactMinutes
    }
    
    /// Get contextual information about the displayed value
    var displayValueContext: String {
        switch selectedPeriod {
        case .day:
            return "current"
        case .month:
            if !historyData.isEmpty {
                return "avg over \(historyData.count) days"
            } else {
                return "avg (limited data)"
            }
        case .year:
            if !historyData.isEmpty {
                return "avg over \(historyData.count) data points"
            } else {
                return "avg (limited data)"
            }
        }
    }
    
    // Convert history data to chart data points with processing
    var chartDataPoints: [MetricDataPoint] {
        let rawPoints = historyData.map { 
            MetricDataPoint(date: $0.date, value: $0.value)
        }
        
        // Apply data processing with smoothing and outlier detection
        return ChartDataProcessor.processDataPoints(
            rawPoints,
            metricType: originalMetric.type,
            smoothingLevel: .light
        )
    }
    
    // Calculate total impact for the selected period using current displayed value
    var totalPeriodImpact: Double {
        // CRITICAL FIX: Use current metric's impact, not original metric's stale impact
        let dailyImpact = self.metric.impactDetails?.lifespanImpactMinutes ?? currentImpactMinutes
        
        switch selectedPeriod {
        case .day:
            return dailyImpact
        case .month:
            return dailyImpact * 30.0
        case .year:
            return dailyImpact * 365.0
        }
    }
    
    // Computed properties for the power level indicator
    var powerLevel: Int {
        // CRITICAL FIX: Use original metric's impact for consistent power level
        if let impact = originalMetric.impactDetails?.lifespanImpactMinutes {
            if impact > 120 { return 5 }
            else if impact > 60 { return 4 }
            else if impact > 0 { return 3 }
            else if impact > -60 { return 2 }
            else { return 1 }
        }
        return 3 // Default middle level
    }
    
    var powerColor: Color {
        if let impact = originalMetric.impactDetails?.lifespanImpactMinutes, impact >= 0 {
            return .ampedGreen
        }
        return .ampedRed
    }
    
    // MARK: - Initialization
    
    init(metric: HealthMetric) {
        // CRITICAL FIX: Store original daily metric to prevent corruption during period switching
        let userProfile = UserProfile() // Using default initialization
        
        // Initialize health services
        self.healthKitManager = HealthKitManager()
        self.healthDataService = HealthDataService(
            healthKitManager: healthKitManager,
            userProfile: userProfile
        )
        
        // Always recalculate daily impact to ensure consistency
        let tempLifeImpactService = LifeImpactService(userProfile: userProfile)
        let dailyImpact = tempLifeImpactService.calculateImpact(for: metric)
        
        // Store the original daily metric permanently
        self.originalMetric = HealthMetric(
            id: metric.id,
            type: metric.type,
            value: metric.value,
            date: metric.date,
            source: metric.source,
            impactDetails: dailyImpact
        )
        
        // Initialize the displayed metric with the original
        self.metric = self.originalMetric
        
        // ENHANCED: Setup real-time subscriptions for automatic chart updates
        setupSubscriptions()
    }
    
    /// Setup real-time subscriptions for automatic updates when health data changes
    /// Follows Apple's Combine best practices with proper error handling and logging
    private func setupSubscriptions() {
        logger.info("🔔 Setting up real-time subscriptions for \(self.originalMetric.type.displayName)")
        
        // CRITICAL: Listen for HealthKit data updates to refresh charts in real-time
        NotificationCenter.default.publisher(for: NSNotification.Name("HealthKitDataUpdated"))
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Prevent excessive refreshes
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("📱 HealthKit data updated - refreshing chart for \(self.originalMetric.type.displayName)")
                
                Task { @MainActor in
                    await self.handleRealTimeDataUpdate()
                }
            }
            .store(in: &cancellables)
        
        // Listen for questionnaire updates that might affect manual metrics
        NotificationCenter.default.publisher(for: NSNotification.Name("QuestionnaireDataUpdated"))
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Only refresh if this is a manual metric that could be affected
                if self.originalMetric.source == .userInput {
                    self.logger.info("📝 Questionnaire updated - refreshing manual metric \(self.originalMetric.type.displayName)")
                    
                    Task { @MainActor in
                        await self.handleRealTimeDataUpdate()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for app foreground events to refresh stale data
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.logger.debug("📱 App became active - checking for stale chart data")
                
                Task { @MainActor in
                    await self.handleAppForeground()
                }
            }
            .store(in: &cancellables)
        
        logger.info("✅ Real-time subscriptions configured for \(self.originalMetric.type.displayName)")
    }
    
    /// Handle real-time data updates with intelligent refresh logic
    @MainActor
    private func handleRealTimeDataUpdate() async {
        // Prevent overlapping refresh operations
        guard !isRefreshing else {
            logger.debug("⏸️ Skipping real-time update - already refreshing")
            return
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        logger.info("🔄 Processing real-time data update for \(self.originalMetric.type.displayName)")
        
        // Check if we have new data for this specific metric
            let latestMetric = await healthDataService.fetchLatestMetric(for: self.originalMetric.type)
            
            // Only refresh if the value has actually changed
            if let newMetric = latestMetric,
               abs(newMetric.value - self.metric.value) > 0.001 { // Use small epsilon for floating point comparison
                
                logger.info("📊 Value changed from \(self.metric.formattedValue) to \(newMetric.formattedValue) - refreshing chart")
                
                // Update the displayed metric with fresh impact calculation
                let tempLifeImpactService = LifeImpactService(userProfile: UserProfile())
                let freshImpact = tempLifeImpactService.calculateImpact(for: newMetric)
                
                self.metric = HealthMetric(
                    id: newMetric.id,
                    type: newMetric.type,
                    value: newMetric.value,
                    date: newMetric.date,
                    source: newMetric.source,
                    impactDetails: freshImpact
                )
                
                // Refresh historical data and period-specific values
                await refreshChartData()
                
                logger.info("✅ Real-time update completed for \(self.originalMetric.type.displayName)")
            } else {
                logger.debug("📊 No significant change in \(self.originalMetric.type.displayName) - skipping refresh")
            }
    }
    
    /// Handle app foreground with smart refresh logic
    @MainActor
    private func handleAppForeground() async {
        // Only refresh if the data might be stale (older than 30 seconds)
        let dataAge = Date().timeIntervalSince(self.metric.date)
        if dataAge > 30 {
            logger.info("🔄 Data is stale (\(Int(dataAge))s old) - refreshing on app foreground")
            await handleRealTimeDataUpdate()
        }
    }
    
    /// Refresh chart data while preserving current period selection
    @MainActor
    private func refreshChartData() async {
        // Cancel any existing data loading task
        currentDataTask?.cancel()
        
        // Reload chart data for current period
        currentDataTask = Task {
            await loadRealHistoryData(for: originalMetric)
            await updatePeriodSpecificValue()
        }
    }
    
    deinit {
        // Cancel any running tasks to prevent memory leaks
        currentDataTask?.cancel()
        
        // Cancel all Combine subscriptions - following Apple's memory management best practices
        cancellables.removeAll()
        
        logger.debug("🗑️ MetricDetailViewModel deinitialized for \(self.originalMetric.type.displayName)")
    }
    
    // MARK: - Methods
    
    func loadData(for metric: HealthMetric) {
        // Cancel previous task to prevent race conditions
        currentDataTask?.cancel()
        
        // Load real historical data from HealthKit using original metric
        currentDataTask = Task {
            await loadRealHistoryData(for: originalMetric)
            await updatePeriodSpecificValue()
        }
        generateRecommendations(for: originalMetric)
    }
    
    /// Update the period-specific display value without modifying the original metric
    @MainActor
    private func updatePeriodSpecificValue() async {
        // For day period, clear the period-specific value to use original
        guard selectedPeriod != .day else { 
            periodSpecificValue = nil
            return 
        }
        
        // For month/year periods, fetch the period-appropriate value
        do {
            let timePeriod: TimePeriod = selectedPeriod == .month ? .month : .year
            let periodMetrics = try await healthDataService.fetchHealthMetricsForPeriod(timePeriod: timePeriod)
            
            // Find the matching metric type in the period results
            if let updatedMetric = periodMetrics.first(where: { $0.type == originalMetric.type }) {
                // Store the period-specific value separately - NEVER modify original metric
                self.periodSpecificValue = updatedMetric.value
                
                logger.info("✅ Updated period-specific value for \(self.selectedPeriod.rawValue): \(self.originalMetric.type.displayName) = \(updatedMetric.formattedValue)")
            }
        } catch {
            logger.error("❌ Failed to update period-specific value: \(error.localizedDescription)")
            // On error, clear period-specific value to fall back to original
            periodSpecificValue = nil
        }
    }
    
    func getChartYRange(for metric: HealthMetric) -> ClosedRange<Double> {
        guard !historyData.isEmpty else { return 0...100 }
        
        let values = historyData.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.2
        
        return (minValue - padding)...(maxValue + padding)
    }
    
    func logRecommendationAction(_ recommendation: MetricRecommendation) {
        // In a real app, this would track the user's interaction
        AnalyticsService.shared.trackEvent(.featureUsed, parameters: [
            "feature": "recommendation_action",
            "recommendation_id": recommendation.id
        ])
    }
    
    /// CRITICAL FIX: Update metric data when dashboard provides fresh data
    /// This ensures the detail view always shows current values instead of stale snapshots
    func updateMetric(with freshMetric: HealthMetric) {
        logger.info("🔄 Updating metric data from dashboard: \(freshMetric.type.displayName) = \(freshMetric.formattedValue)")
        
        // Update the displayed metric with fresh data
        self.metric = HealthMetric(
            id: freshMetric.id,
            type: freshMetric.type,
            value: freshMetric.value,
            date: freshMetric.date,
            source: freshMetric.source,
            impactDetails: freshMetric.impactDetails
        )
        
        // Force refresh of chart data with new values
        currentDataTask?.cancel()
        currentDataTask = Task {
            await loadRealHistoryData(for: self.metric)
            await updatePeriodSpecificValue()
        }
        
        logger.info("✅ Metric updated successfully - new impact: \(freshMetric.impactDetails?.lifespanImpactMinutes ?? 0) minutes")
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadRealHistoryData(for metric: HealthMetric) async {
        // Check if task was cancelled before proceeding
        guard !Task.isCancelled else { return }
        
        // Clear existing data
        historyData.removeAll()
        
        let now = Date()
        
        // Determine the date range based on the selected period
        let (startDate, endDate, interval) = getDateRangeAndInterval(for: selectedPeriod, now: now)
        
        // For manual metrics, just show the current value across the time period
        if metric.type.isHealthKitMetric == false {
            // Generate a flat line showing the current manual value
            generateManualMetricData(metric: metric, startDate: startDate, endDate: endDate, interval: interval)
            return
        }
        
        // Fetch real data from HealthKit based on metric type
        switch metric.type {
        case .sleepHours:
            await fetchSleepData(from: startDate, to: endDate)
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            await fetchCumulativeData(for: metric.type, from: startDate, to: endDate, interval: interval)
        case .restingHeartRate, .heartRateVariability, .bodyMass, .vo2Max, .oxygenSaturation:
            await fetchDiscreteData(for: metric.type, from: startDate, to: endDate)
        default:
            // For other metrics, try to fetch discrete data
            await fetchDiscreteData(for: metric.type, from: startDate, to: endDate)
        }
    }
    
    private func getDateRangeAndInterval(for period: ImpactDataPoint.PeriodType, now: Date) -> (startDate: Date, endDate: Date, interval: DateComponents) {
        let calendar = Calendar.current
        var interval = DateComponents()
        
        switch period {
        case .day:
            // Align with HealthKit's day boundaries (Rule: Follow Apple's Human Interface Guidelines)
            // Start from beginning of current day
            let startOfToday = calendar.startOfDay(for: now)
            // For daily view, we want to show from start of day to current time
            interval.hour = 1
            return (startOfToday, now, interval)
            
        case .month:
            // Show last 30 days aligned to day boundaries
            let startOfToday = calendar.startOfDay(for: now)
            let startDate = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
            interval.day = 1
            return (startDate, now, interval)
            
        case .year:
            // Show last 12 months aligned to month boundaries
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startDate = calendar.date(byAdding: .month, value: -11, to: startOfMonth) ?? startOfMonth
            interval.month = 1
            return (startDate, now, interval)
        }
    }
    
    @MainActor
    private func fetchSleepData(from startDate: Date, to endDate: Date) async {
        // Sleep data needs special handling - fetch actual sleep sessions from HealthKit
        let sleepManager = HealthKitSleepManager(healthStore: HKHealthStore())
        let calendar = Calendar.current
        
        if selectedPeriod == .day {
            // For daily view, show single value for sleep (not hourly)
            if let todaysSleep = await sleepManager.processSleepData(from: startDate, to: endDate) {
                // Show sleep as a single data point for the day
                historyData.append(HistoryDataPoint(date: endDate, value: todaysSleep.value))
            } else {
                // Show current metric value if no data
                historyData.append(HistoryDataPoint(date: endDate, value: originalMetric.value))
            }
        } else if selectedPeriod == .month {
            // For monthly view, show daily sleep totals
            var currentDate = startDate
            
            while currentDate <= endDate {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                
                if let sleepData = await sleepManager.processSleepData(from: currentDate, to: nextDate) {
                    historyData.append(HistoryDataPoint(date: currentDate, value: sleepData.value))
                } else {
                    // No sleep data for this day
                    historyData.append(HistoryDataPoint(date: currentDate, value: 0.0))
                }
                
                currentDate = nextDate
            }
        } else {
            // For yearly view, show monthly averages
            var currentMonth = calendar.dateInterval(of: .month, for: startDate)?.start ?? startDate
            
            while currentMonth <= endDate {
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                var totalSleep = 0.0
                var daysWithSleep = 0
                
                // Calculate average sleep for the month
                var day = currentMonth
                while day < monthEnd && day <= endDate {
                    if let sleepData = await sleepManager.processSleepData(from: day, to: calendar.date(byAdding: .day, value: 1, to: day) ?? day) {
                        totalSleep += sleepData.value
                        daysWithSleep += 1
                    }
                    day = calendar.date(byAdding: .day, value: 1, to: day) ?? monthEnd
                }
                
                let averageSleep = daysWithSleep > 0 ? totalSleep / Double(daysWithSleep) : 0.0
                historyData.append(HistoryDataPoint(date: currentMonth, value: averageSleep))
                
                currentMonth = monthEnd
            }
        }
    }
    
    @MainActor
    private func fetchCumulativeData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date, interval: DateComponents) async {
        // For cumulative metrics like steps, we need to fetch aggregated data
        guard let quantityType = metricType.healthKitType,
              let unit = metricType.unit else { return }
        
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        
        // Create a statistics collection query
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        do {
            let statisticsCollection = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatisticsCollection?, Error>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: calendar.startOfDay(for: startDate),
                    intervalComponents: interval
                )
                
                query.initialResultsHandler = { _, statisticsCollection, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: statisticsCollection)
                }
                
                healthStore.execute(query)
            }
            
            guard let collection = statisticsCollection else { return }
            
            // Extract data points from the collection
            collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sumQuantity = statistics.sumQuantity() {
                    let value = sumQuantity.doubleValue(for: unit)
                    
                    // CRITICAL FIX: Show appropriate values based on period
                    let adjustedValue: Double
                    if self.selectedPeriod == .day {
                        // Day view with hourly intervals: Show hourly totals
                        adjustedValue = value
                    } else if self.selectedPeriod == .month {
                        // Month view with daily intervals: Show daily totals
                        adjustedValue = value
                    } else if self.selectedPeriod == .year {
                        // Year view with monthly intervals: Show AVERAGE daily value for each month
                        // This matches how the dashboard displays yearly data
                        let daysInMonth = self.getDaysInMonth(for: statistics.startDate)
                        adjustedValue = value / Double(daysInMonth)
                    } else {
                        adjustedValue = value
                    }
                    
                    self.historyData.append(HistoryDataPoint(date: statistics.startDate, value: adjustedValue))
                } else {
                    // No data for this period
                    self.historyData.append(HistoryDataPoint(date: statistics.startDate, value: 0))
                }
            }
            
            // Sort by date
            historyData.sort { $0.date < $1.date }
            
            // If no data at all, show zeros across the period
            if historyData.isEmpty {
                var currentDate = startDate
                while currentDate <= endDate {
                    historyData.append(HistoryDataPoint(date: currentDate, value: 0))
                    currentDate = calendar.date(byAdding: interval, to: currentDate) ?? endDate
                }
            }
        } catch {
            print("Error fetching cumulative data: \(error)")
            
            // On error, show zeros
            var currentDate = startDate
            while currentDate <= endDate {
                historyData.append(HistoryDataPoint(date: currentDate, value: 0))
                currentDate = calendar.date(byAdding: interval, to: currentDate) ?? endDate
            }
        }
    }
    
    // Helper function to get the number of days in a month
    private func getDaysInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }
    
    @MainActor
    private func fetchDiscreteData(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async {
        // For discrete metrics like heart rate, we need different handling based on period
        if selectedPeriod == .year {
            // For year view, fetch monthly averages
            await fetchMonthlyAveragesForDiscrete(metricType: metricType, from: startDate, to: endDate)
        } else {
            // For day/month views, fetch individual samples
            await fetchIndividualSamples(metricType: metricType, from: startDate, to: endDate)
        }
    }
    
    private func fetchIndividualSamples(metricType: HealthMetricType, from startDate: Date, to endDate: Date) async {
        // Fetch the actual samples
        let samples = await healthKitManager.fetchData(for: metricType, from: startDate, to: endDate)
        
        if samples.isEmpty {
                    // If no data, show current value as a flat line
        generateManualMetricData(metric: originalMetric, startDate: startDate, endDate: endDate, interval: DateComponents(hour: 1))
            return
        }
        
        // Convert samples to history data points
        for sample in samples {
            // Convert body mass from kg to lbs for display if needed
            let displayValue: Double
            if metricType == .bodyMass {
                // Value is stored in kg internally, convert to lbs for US users
                let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
                displayValue = useMetric ? sample.value : sample.value * 2.20462
            } else {
                displayValue = sample.value
            }
            historyData.append(HistoryDataPoint(date: sample.date, value: displayValue))
        }
        
        // Sort by date
        historyData.sort { $0.date < $1.date }
        
        // If we still have no data after fetching, show current value as fallback
        if historyData.isEmpty {
            generateManualMetricData(metric: originalMetric, startDate: startDate, endDate: endDate, interval: DateComponents(hour: 1))
        }
        
        // For body mass, if showing daily view, we should show the actual weight changes throughout the day
        // not just a flat line. Only use flat line if there's truly only one measurement.
        if metricType == .bodyMass && selectedPeriod == .day && historyData.count == 1 {
            // Only one measurement for the whole day, so extend it as a flat line
            let singleValue = historyData.first?.value ?? originalMetric.value
            historyData.removeAll()
            
            let calendar = Calendar.current
            for hour in 0..<24 {
                let date = calendar.date(byAdding: .hour, value: hour - 24, to: endDate) ?? endDate
                historyData.append(HistoryDataPoint(date: date, value: singleValue))
            }
        }
    }
    
    private func fetchMonthlyAveragesForDiscrete(metricType: HealthMetricType, from startDate: Date, to endDate: Date) async {
        let calendar = Calendar.current
        var currentMonth = startDate
        
        // Process each month
        while currentMonth <= endDate {
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            
            // Fetch all samples for this month
            let monthSamples = await healthKitManager.fetchData(for: metricType, from: currentMonth, to: monthEnd)
            
            if !monthSamples.isEmpty {
                // Calculate average for the month
                let sum = monthSamples.reduce(0.0) { total, sample in
                    // Handle unit conversion for body mass
                    if metricType == .bodyMass {
                        let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
                        return total + (useMetric ? sample.value : sample.value * 2.20462)
                    } else {
                        return total + sample.value
                    }
                }
                let average = sum / Double(monthSamples.count)
                
                // Add the monthly average as a data point
                historyData.append(HistoryDataPoint(date: currentMonth, value: average))
            } else {
                // No data for this month, add zero or current value
                if historyData.isEmpty && currentMonth == startDate {
                    // First month with no data - use current metric value
                    let displayValue: Double
                    if metricType == .bodyMass {
                        let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
                        displayValue = useMetric ? originalMetric.value : originalMetric.value * 2.20462
                    } else {
                        displayValue = originalMetric.value
                    }
                    historyData.append(HistoryDataPoint(date: currentMonth, value: displayValue))
                } else {
                    // Subsequent months with no data - use last known value or zero
                    let lastValue = historyData.last?.value ?? 0
                    historyData.append(HistoryDataPoint(date: currentMonth, value: lastValue))
                }
            }
            
            currentMonth = monthEnd
        }
    }
    
    private func generateManualMetricData(metric: HealthMetric, startDate: Date, endDate: Date, interval: DateComponents) {
        let calendar = Calendar.current
        var currentDate = startDate
        
        // For body mass, ensure we're using the display value not the stored kg value
        let displayValue: Double
        if metric.type == .bodyMass {
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            displayValue = useMetric ? metric.value : metric.value * 2.20462
        } else {
            displayValue = metric.value
        }
        
        // Generate data points showing the same value across the time period
        while currentDate <= endDate {
            historyData.append(HistoryDataPoint(date: currentDate, value: displayValue))
            currentDate = calendar.date(byAdding: interval, to: currentDate) ?? endDate
        }
    }
    
    private func generateRecommendations(for metric: HealthMetric) {
        // Clear existing recommendations
        recommendations.removeAll()
        
        // Generate recommendations based on metric type
        switch metric.type {
        case .steps:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Daily Walking",
                description: "Try to walk for at least \(Double(30).formattedAsTime()) each day, ideally reaching 10,000 steps for optimal cardiovascular benefits.",
                iconName: "figure.walk",
                actionText: "Set Walking Reminder"
            ))
            
            if metric.value < 7500 {
                recommendations.append(MetricRecommendation(
                    id: UUID(),
                    title: "Increase Movement",
                    description: "Finding it hard to get enough steps? Try parking farther away, taking the stairs, or walking during phone calls.",
                    iconName: "arrow.up.forward",
                    actionText: "See Movement Tips"
                ))
            }
            
        case .exerciseMinutes:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Activity Variety",
                description: "Mix cardio, strength training, and flexibility exercises for best results. Aim for at least \(Double(150).formattedAsTime()) per week.",
                iconName: "person.fill.turn.right",
                actionText: "Explore Exercise Types"
            ))
            
        case .sleepHours:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Sleep Consistency",
                description: "Maintain a consistent sleep schedule, even on weekends, to optimize your sleep quality and overall health.",
                iconName: "moon.fill",
                actionText: "Set Sleep Schedule"
            ))
            
            if metric.value < 7 {
                recommendations.append(MetricRecommendation(
                    id: UUID(),
                    title: "Sleep Environment",
                    description: "Create a dark, quiet, and cool sleep environment. Avoid screens at least one hour before bedtime.",
                    iconName: "bed.double.fill",
                    actionText: "Sleep Tips"
                ))
            }
            
        case .heartRateVariability:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Stress Management",
                description: "Regular meditation, deep breathing exercises, and adequate recovery time can improve your HRV.",
                iconName: "heart.fill",
                actionText: "Try Breathing Exercise"
            ))
            
        case .restingHeartRate:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Cardiovascular Health",
                description: "Regular aerobic exercise, adequate hydration, and good sleep hygiene can help optimize your resting heart rate.",
                iconName: "heart.circle.fill",
                actionText: "Learn More"
            ))
            
        case .bodyMass:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Balanced Nutrition",
                description: "Focus on whole foods, fruits, vegetables, lean proteins, and proper hydration for maintaining healthy weight.",
                iconName: "fork.knife",
                actionText: "Nutrition Guide"
            ))
            
        case .nutritionQuality:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Dietary Diversity",
                description: "Include a variety of colors in your diet to ensure you're getting a wide range of nutrients.",
                iconName: "leaf.fill",
                actionText: "Recipe Ideas"
            ))
            
        case .smokingStatus:
            if metric.value < 9 { // Not 'never' smoker
                recommendations.append(MetricRecommendation(
                    id: UUID(),
                    title: "Smoking Cessation",
                    description: "Quitting smoking has immediate and long-term health benefits. Support programs significantly increase success rates.",
                    iconName: "lungs.fill",
                    actionText: "Find Support Resources"
                ))
            }
            
        case .alcoholConsumption:
            if metric.value < 9 { // Not 'never' drinker
                recommendations.append(MetricRecommendation(
                    id: UUID(),
                    title: "Moderate Consumption",
                    description: "If you drink alcohol, do so in moderation. Guidelines suggest no more than 1 drink per day for women and 2 for men.",
                    iconName: "drop.fill",
                    actionText: "Moderation Tips"
                ))
            }
            
        case .socialConnectionsQuality:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Social Engagement",
                description: "Regular meaningful social interactions boost mental health and can add years to your life. Schedule regular connection time.",
                iconName: "person.2.fill",
                actionText: "Social Activities Ideas"
            ))
            
        case .activeEnergyBurned:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Active Energy",
                description: "Increasing your daily active energy expenditure through regular exercise and movement contributes to overall cardiovascular health.",
                iconName: "flame.fill",
                actionText: "Activity Tips"
            ))
            
        case .vo2Max:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Cardiorespiratory Fitness",
                description: "Improve your VO2 Max through consistent cardio exercise like running, cycling, or swimming to enhance oxygen utilization.",
                iconName: "lungs.fill",
                actionText: "Fitness Program"
            ))
            
        case .oxygenSaturation:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Oxygen Levels",
                description: "Maintain healthy oxygen saturation through good respiratory practices and consider consulting a doctor for persistently low levels.",
                iconName: "drop.fill",
                actionText: "Learn More"
            ))
            
        case .stressLevel:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Stress Management",
                description: "Incorporate relaxation techniques, mindfulness practices, and regular breaks to manage stress levels effectively.",
                iconName: "brain.head.profile",
                actionText: "Stress Relief Techniques"
            ))
        }
        
        // Add a general recommendation for all metrics
        recommendations.append(MetricRecommendation(
            id: UUID(),
            title: "Consistency is Key",
            description: "Small, consistent improvements have a greater impact on longevity than occasional major changes.",
            iconName: "calendar.badge.clock",
            actionText: ""
        ))
    }
}

// MARK: - Models

struct HistoryDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricRecommendation: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let actionText: String
}

// MARK: - Supporting Types

/// Data point for impact charts showing cumulative life impact over time
struct ChartImpactDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let impact: Double // Cumulative impact up to this point
    let value: Double  // Original metric value (e.g., steps taken)
} 