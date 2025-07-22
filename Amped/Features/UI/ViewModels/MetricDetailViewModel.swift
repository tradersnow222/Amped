import SwiftUI
import Combine
import HealthKit

/// View model for the metric detail view
@MainActor
final class MetricDetailViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var historyData: [HistoryDataPoint] = []
    @Published var recommendations: [MetricRecommendation] = []
    @Published var metric: HealthMetric
    @Published var selectedPeriod: ImpactDataPoint.PeriodType = .day {
        didSet {
            // Cancel previous task to prevent race conditions
            currentDataTask?.cancel()
            
            // Reload real data when period changes
            currentDataTask = Task {
                await loadRealHistoryData(for: metric)
            }
        }
    }
    
    private let healthKitManager: HealthKitManager
    private let healthDataService: HealthDataService
    private var currentDataTask: Task<Void, Never>?
    
    // Convert history data to chart data points with processing
    var chartDataPoints: [MetricDataPoint] {
        let rawPoints = historyData.map { 
            MetricDataPoint(date: $0.date, value: $0.value)
        }
        
        // Apply data processing with smoothing and outlier detection
        return ChartDataProcessor.processDataPoints(
            rawPoints,
            metricType: metric.type,
            smoothingLevel: .light
        )
    }
    
    // Calculate total impact for the selected period
    var totalImpactForPeriod: Double {
        // If we have impact details, scale them based on the period
        guard let baseImpact = metric.impactDetails?.lifespanImpactMinutes else {
            return 0
        }
        
        // Scale the impact based on the selected period
        // This assumes the base impact is per day
        switch selectedPeriod {
        case .day:
            return baseImpact
        case .month:
            return baseImpact * 30  // Approximate month
        case .year:
            return baseImpact * 365 // Approximate year
        }
    }
    
    // Computed properties for the power level indicator
    var powerLevel: Int {
        // Simulate power level based on metric's impact
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            if impact > 120 { return 5 }
            else if impact > 60 { return 4 }
            else if impact > 0 { return 3 }
            else if impact > -60 { return 2 }
            else { return 1 }
        }
        return 3 // Default middle level
    }
    
    var powerColor: Color {
        if let impact = metric.impactDetails?.lifespanImpactMinutes, impact >= 0 {
            return .ampedGreen
        }
        return .ampedRed
    }
    
    // MARK: - Initialization
    
    init(metric: HealthMetric) {
        // CRITICAL FIX: Ensure we always work with daily impacts in the detail view
        // The metric might have scaled impacts from period views, so recalculate daily impact
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
        
        // Create metric with daily impact details
        self.metric = HealthMetric(
            id: metric.id,
            type: metric.type,
            value: metric.value,
            date: metric.date,
            source: metric.source,
            impactDetails: dailyImpact
        )
    }
    
    deinit {
        // Cancel any running tasks to prevent memory leaks
        currentDataTask?.cancel()
    }
    
    // MARK: - Methods
    
    func loadData(for metric: HealthMetric) {
        // Cancel previous task to prevent race conditions
        currentDataTask?.cancel()
        
        // Load real historical data from HealthKit
        currentDataTask = Task {
            await loadRealHistoryData(for: metric)
        }
        generateRecommendations(for: metric)
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
            // Show last 24 hours
            let startDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
            interval.hour = 1
            return (startDate, now, interval)
            
        case .month:
            // Show last 30 days
            let startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            interval.day = 1
            return (startDate, now, interval)
            
        case .year:
            // Show last 12 months
            let startDate = calendar.date(byAdding: .month, value: -12, to: now) ?? now
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
                historyData.append(HistoryDataPoint(date: endDate, value: metric.value))
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
            generateManualMetricData(metric: metric, startDate: startDate, endDate: endDate, interval: DateComponents(hour: 1))
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
            generateManualMetricData(metric: metric, startDate: startDate, endDate: endDate, interval: DateComponents(hour: 1))
        }
        
        // For body mass, if showing daily view, we should show the actual weight changes throughout the day
        // not just a flat line. Only use flat line if there's truly only one measurement.
        if metricType == .bodyMass && selectedPeriod == .day && historyData.count == 1 {
            // Only one measurement for the whole day, so extend it as a flat line
            let singleValue = historyData.first?.value ?? metric.value
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
                        displayValue = useMetric ? metric.value : metric.value * 2.20462
                    } else {
                        displayValue = metric.value
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