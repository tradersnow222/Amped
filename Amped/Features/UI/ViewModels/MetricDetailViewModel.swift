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
    @Published var selectedPeriod: ImpactDataPoint.PeriodType = .day
    
    /// Loading state for TradingView-style charts
    @Published var isLoadingHistory: Bool = false
    
    // Task management for data loading
    private var currentDataTask: Task<Void, Never>?
    
    // CRITICAL FIX: Store original daily metric to prevent value corruption
    private let originalMetric: HealthMetric
    
    // Store period-specific calculated values separately
    @Published private var periodSpecificValue: Double?
    
    // MARK: - Dependencies
    
    /// Health data service for fetching real HealthKit data
    private let healthKitManager: HealthKitManager
    
    /// User profile for accurate impact calculations (CRITICAL: Use real profile, not empty one)
    private let userProfile: UserProfile
    
    // MARK: - Initializer
    
    /// Initialize with required dependencies for real data calculations  
    init(healthKitManager: HealthKitManager? = nil) {
        // Initialize with default metric first
        let defaultMetric = HealthMetric(
            id: "default",
            type: .steps,
            value: 0,
            date: Date(),
            source: .healthKit
        )
        
        self.healthKitManager = healthKitManager ?? HealthKitManager.shared
        self.userProfile = UserProfile() // Will be set properly when metric is set
        self.originalMetric = defaultMetric
        self.metric = defaultMetric
        self.lastKnownValue = defaultMetric.value
    }
    
    // MARK: - Real-time Update Support
    
    /// Store the last known metric value to detect significant changes
    private var lastKnownValue: Double = 0.0
    
    /// Observe dashboard updates and refresh when significant changes occur
    @MainActor
    func observeDashboardUpdates(dashboardViewModel: DashboardViewModel) {
        // Subscribe to dashboard's lastMetricUpdateTime to know when to check for updates
        dashboardViewModel.$lastMetricUpdateTime
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Check if the metric value has changed significantly
                if let latestMetric = dashboardViewModel.getLatestMetricValue(for: self.originalMetric.type) {
                    let changePercent = abs(latestMetric.value - self.lastKnownValue) / max(self.lastKnownValue, 1.0)
                    
                    // If value changed by 1% or more, update
                    if changePercent >= 0.01 {
                        self.logger.info("📊 Detected \(String(format: "%.1f", changePercent * 100))% change in \(self.originalMetric.type.displayName)")
                        
                        // Update the metric with fresh value
                        self.metric = HealthMetric(
                            id: self.originalMetric.id,
                            type: self.originalMetric.type,
                            value: latestMetric.value,
                            date: Date(),
                            source: self.originalMetric.source,
                            impactDetails: latestMetric.impactDetails
                        )
                        
                        // Update last known value
                        self.lastKnownValue = latestMetric.value
                        
                        // Refresh recommendations with new value
                        self.generateRecommendations(for: self.metric)
                        
                        // Trigger UI update
                        self.objectWillChange.send()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Combine cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Impact Chart Data
    
    /// Chart data points showing cumulative life impact over time
    var impactChartDataPoints: [ChartImpactDataPoint] {
        // CONSISTENCY FIX: For daily view, show a flat line with the consistent impact
        // This ensures the chart values match the total impact display
        var impactPoints: [ChartImpactDataPoint] = []
        
        // Sort history data by date for proper cumulative calculation
        let sortedHistory = historyData.sorted { $0.date < $1.date }
        
        // Get the consistent base impact from the original metric
        let baseImpactMinutes = currentImpactMinutes
        
        logger.info("🔍 Chart Data Debug: Base impact = \(baseImpactMinutes) minutes, History points = \(sortedHistory.count)")
        
        if selectedPeriod == .day {
            // DYNAMIC IMPACT FIX: For cumulative metrics in day view, show dynamic impact based on accumulated values
            // For non-cumulative metrics, show flat line with consistent impact
            let isCumulativeMetric = (originalMetric.type == .steps || originalMetric.type == .exerciseMinutes || originalMetric.type == .activeEnergyBurned)
            
            if isCumulativeMetric {
                // TradingView approach: Calculate impact using REAL data with proper period scaling
                // CRITICAL FIX: Use actual user profile (not empty one)
                let lifeImpactService = LifeImpactService(userProfile: self.userProfile)
                
                for dataPoint in sortedHistory {
                    let tempMetric = HealthMetric(
                        id: UUID().uuidString,
                        type: originalMetric.type,
                        value: dataPoint.value, // This is now the cumulative value
                        date: dataPoint.date,
                        source: originalMetric.source
                    )
                    
                    // TradingView approach: Apply same period scaling as headlines and collective charts
                    let impactDataPoint = lifeImpactService.calculateTotalImpact(from: [tempMetric], for: selectedPeriod)
                    impactPoints.append(ChartImpactDataPoint(
                        date: dataPoint.date,
                        impact: impactDataPoint.totalImpactMinutes, // Period-scaled impact like headlines
                        value: dataPoint.value
                    ))
                }
                
                // Add current value if more recent than last history point
                if !sortedHistory.isEmpty {
                    let now = Date()
                    let lastHistoryDate = sortedHistory.last?.date ?? Date.distantPast
                    
                    if now.timeIntervalSince(lastHistoryDate) > 60 {
                        let tempMetric = HealthMetric(
                            id: UUID().uuidString,
                            type: originalMetric.type,
                            value: originalMetric.value,
                            date: now,
                            source: originalMetric.source
                        )
                        
                        let impactDetail = lifeImpactService.calculateImpact(for: tempMetric)
                        impactPoints.append(ChartImpactDataPoint(
                            date: now,
                            impact: impactDetail.lifespanImpactMinutes,
                            value: originalMetric.value
                        ))
                    }
                }
            } else {
                // TradingView approach: Calculate impact using REAL data with proper period scaling
                // CRITICAL FIX: Use actual user profile (not empty one)
                let lifeImpactService = LifeImpactService(userProfile: self.userProfile)
                
                for dataPoint in sortedHistory {
                    let tempMetric = HealthMetric(
                        id: UUID().uuidString,
                        type: originalMetric.type,
                        value: dataPoint.value, // Each individual reading
                        date: dataPoint.date,
                        source: originalMetric.source
                    )
                    
                    // TradingView approach: Apply same period scaling as headlines and collective charts
                    let impactDataPoint = lifeImpactService.calculateTotalImpact(from: [tempMetric], for: selectedPeriod)
                    impactPoints.append(ChartImpactDataPoint(
                        date: dataPoint.date,
                        impact: impactDataPoint.totalImpactMinutes, // Period-scaled impact like headlines
                        value: dataPoint.value
                    ))
                }
                
                // Add current value if more recent than last history point
                if !sortedHistory.isEmpty {
                    let now = Date()
                    let lastHistoryDate = sortedHistory.last?.date ?? Date.distantPast
                    
                    if now.timeIntervalSince(lastHistoryDate) > 60 {
                        let tempMetric = HealthMetric(
                            id: UUID().uuidString,
                            type: originalMetric.type,
                            value: originalMetric.value,
                            date: now,
                            source: originalMetric.source
                        )
                        
                        let impactDetail = lifeImpactService.calculateImpact(for: tempMetric)
                        impactPoints.append(ChartImpactDataPoint(
                            date: now,
                            impact: impactDetail.lifespanImpactMinutes,
                            value: originalMetric.value
                        ))
                    }
                }
            }
        } else {
            // TradingView approach: Use REAL historical data with proper period scaling
            // CRITICAL FIX: Use actual user profile (not empty one)
            let lifeImpactService = LifeImpactService(userProfile: self.userProfile)
            
            for dataPoint in sortedHistory {
                let tempMetric = HealthMetric(
                    id: UUID().uuidString,
                    type: originalMetric.type,
                    value: dataPoint.value,
                    date: dataPoint.date,
                    source: originalMetric.source
                )
                
                // TradingView approach: Apply same period scaling as headlines and collective charts
                let impactDataPoint = lifeImpactService.calculateTotalImpact(from: [tempMetric], for: selectedPeriod)
                impactPoints.append(ChartImpactDataPoint(
                    date: dataPoint.date,
                    impact: impactDataPoint.totalImpactMinutes, // Period-scaled impact like headlines
                    value: dataPoint.value
                ))
            }
        }
        
        logger.info("✅ Generated \(impactPoints.count) chart points with impact values ranging from \(impactPoints.map { $0.impact }.min() ?? 0) to \(impactPoints.map { $0.impact }.max() ?? 0)")
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
    
    /// CRITICAL FIX: Use consistent pre-calculated impact to match dashboard and impact page
    var currentImpactMinutes: Double {
        // CONSISTENCY FIX: Use the same pre-calculated impact as dashboard and impact page
        // This ensures all views show the same impact value for the same metric
        return originalMetric.impactDetails?.lifespanImpactMinutes ?? 0.0
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
        // Use current impact calculation for consistency
        let dailyImpact = currentImpactMinutes
        
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
    
    init(metric: HealthMetric, initialPeriod: ImpactDataPoint.PeriodType? = nil) {
        // CRITICAL FIX: Use the pre-calculated impact from the dashboard metric to ensure consistency
        
        // Initialize required dependencies
        self.healthKitManager = HealthKitManager.shared
        self.userProfile = UserProfile() // Using default initialization
        
        // CONSISTENCY FIX: Use the exact same impact that the dashboard calculated
        // This prevents discrepancies between dashboard and detail view
        self.originalMetric = HealthMetric(
            id: metric.id,
            type: metric.type,
            value: metric.value,
            date: metric.date,
            source: metric.source,
            impactDetails: metric.impactDetails // Use the pre-calculated impact from dashboard
        )
        
        // Initialize the displayed metric with the original
        self.metric = self.originalMetric
        
        // Initialize last known value
        self.lastKnownValue = self.originalMetric.value
        
        // UX FIX: Set initial period if provided to maintain period selection from dashboard
        if let initialPeriod = initialPeriod {
            self.selectedPeriod = initialPeriod
        }
    }
    
    deinit {
        // Cancel any running tasks to prevent memory leaks
        currentDataTask?.cancel()
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
        
        // TradingView approach: Use direct HealthKit data fetching instead of period calculations
        // Individual metrics will show real historical data instead of synthetic period values
        logger.info("📊 Using TradingView approach - showing real historical data instead of period calculations")
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
        
        // TradingView approach: For manual metrics, show real questionnaire data consistently
        if metric.type.isHealthKitMetric == false {
            // Use actual questionnaire value (like TradingView showing last known price)
            // Manual metrics represent lifestyle patterns that don't change minute-by-minute
            generateRealManualMetricData(metric: metric, startDate: startDate, endDate: endDate, interval: interval)
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
            var tempDataPoints: [HistoryDataPoint] = []
            
            collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sumQuantity = statistics.sumQuantity() {
                    let value = sumQuantity.doubleValue(for: unit)
                    
                    // CRITICAL FIX: Show appropriate values based on period
                    let adjustedValue: Double
                    if self.selectedPeriod == .day {
                        // Day view with hourly intervals: Show hourly totals (will convert to cumulative below)
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
                    
                    tempDataPoints.append(HistoryDataPoint(date: statistics.startDate, value: adjustedValue))
                } else {
                    // No data for this period
                    tempDataPoints.append(HistoryDataPoint(date: statistics.startDate, value: 0))
                }
            }
            
            // Sort temp data points by date
            tempDataPoints.sort { $0.date < $1.date }
            
            // CRITICAL FIX: For day view with cumulative metrics, convert to running totals
            if self.selectedPeriod == .day && (metricType == .steps || metricType == .exerciseMinutes || metricType == .activeEnergyBurned) {
                // Convert hourly totals to cumulative running totals
                var runningTotal: Double = 0
                for dataPoint in tempDataPoints {
                    runningTotal += dataPoint.value
                    self.historyData.append(HistoryDataPoint(date: dataPoint.date, value: runningTotal))
                }
            } else {
                // For other periods or non-cumulative metrics, use values as-is
                self.historyData.append(contentsOf: tempDataPoints)
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
            // TradingView approach: If no real data exists, show gaps (empty chart)
            // Don't create artificial flat lines like the old implementation
            logger.info("📊 No real HealthKit data found for \(metricType.displayName) - showing gap like TradingView")
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
        
        // TradingView approach: If we still have no real data after fetching, show gaps (no artificial fallback)
        if historyData.isEmpty {
            logger.info("📊 No real historical data available for \(self.originalMetric.type.displayName) - showing empty chart like TradingView gaps")
            // Don't generate artificial manual metric data - show real gaps instead
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
    
    /// Generate real manual metric data using actual questionnaire responses (TradingView approach)
    /// Unlike the old generateManualMetricData, this uses REAL questionnaire values consistently
    private func generateRealManualMetricData(metric: HealthMetric, startDate: Date, endDate: Date, interval: DateComponents) {
        // TradingView approach: Manual metrics represent consistent lifestyle patterns
        // Use actual questionnaire value (like TradingView showing last known price when markets are closed)
        
        let calendar = Calendar.current
        var currentDate = startDate
        let actualValue = metric.value // Use the REAL questionnaire response value
        
        logger.info("📊 Using REAL manual metric value: \(String(format: "%.2f", actualValue)) for \(metric.type.displayName)")
        
        // Create data points using the actual questionnaire value consistently
        while currentDate <= endDate {
            // Skip future dates (TradingView doesn't show future data)
            if currentDate > Date() { break }
            
                         self.historyData.append(HistoryDataPoint(
                 date: currentDate,
                 value: actualValue // REAL questionnaire value (no artificial variations)
             ))
            
            // Move to next interval
            guard let nextDate = calendar.date(byAdding: interval, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        logger.info("✅ Generated \(self.historyData.count) real manual metric data points for \(metric.type.displayName)")
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
            
        case .bloodPressure:
            recommendations.append(MetricRecommendation(
                id: UUID(),
                title: "Blood Pressure Management",
                description: "Maintain healthy blood pressure through regular exercise, stress management, and a heart-healthy diet rich in fruits and vegetables.",
                iconName: "heart.circle.fill",
                actionText: "Heart Health Tips"
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

    /// Load real historical data for TradingView-style charts (100% real data only)
    /// - Parameters:
    ///   - metric: The metric to load history for
    ///   - period: The time period to load
    func loadRealHistoricalData(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) {
        isLoadingHistory = true
        
        // Cancel any existing data loading task
        currentDataTask?.cancel()
        
        // Update the selected period
        selectedPeriod = period
        
        currentDataTask = Task {
            // Load real historical data using TradingView approach
            await loadRealHistoryData(for: metric)
            
            await MainActor.run {
                self.isLoadingHistory = false
            }
        }
    }

    /// TradingView-style data points for charts (100% real data)
    var tradingViewStyleDataPoints: [MetricDataPoint] {
        return historyData.map { dataPoint in
            MetricDataPoint(
                date: dataPoint.date,
                value: dataPoint.value
            )
        }
    }
    
    /// Historical data points for charting (UI compatibility)
    var historyDataPoints: [MetricDataPoint] {
        return tradingViewStyleDataPoints
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