import SwiftUI
import Charts

struct MetricDetailContentView: View {
    let metricTitle: String
    let period: String
    let periodType: ImpactDataPoint.PeriodType
    @Binding var navigationPath: NavigationPath
    
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @StateObject private var viewModel = DashboardViewModel()
    var selectedHealthMetric: HealthMetric?

    // Cache the data to prevent infinite loops
    private let metrics: [DashboardMetric]
    private let chartData: [ChartDataPoint]

    init(metricTitle: String,
         period: String,
         periodType: ImpactDataPoint.PeriodType,
         navigationPath: Binding<NavigationPath>,
         selectedHealthMetric: HealthMetric?
    ) {
        self.metricTitle = metricTitle
        self.period = period
        self.periodType = periodType
        self._navigationPath = navigationPath

        let periodString: String
        switch periodType {
        case .day: periodString = "day"
        case .month: periodString = "month"
        case .year: periodString = "year"
        }

        // Cache all data during initialization to prevent recalculation loops
        self.metrics = Self.getMetricsForPeriod(periodType)
        self.chartData = []
        
        selectedPeriod = periodType
        self.selectedHealthMetric = selectedHealthMetric
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            LinearGradient.customBlueToDarkGray.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button(action: {
                        DispatchQueue.main.async { navigationPath.removeLast() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().fill(Color.white.opacity(0.08))
                            )
                    }

                    personalizedHeader
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)

                // Date navigation bar
                dateNavigationBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Status sentence
                        // Status text
                        let impactMinutes = selectedHealthMetric?.impactDetails?.lifespanImpactMinutes ?? 0
                        let isPositive = impactMinutes >= 0
                        let minutes = Int(abs(impactMinutes))
                        let lostOrGained = isPositive ? "gained" : "lost"
                        let mainColor: Color = isPositive ? .ampedGreen : .ampedRed
                        let metric = metricTitle.lowercased()
                        let periodLabel: String = {
                            switch selectedPeriod {
                            case .day: return "Today"
                            case .month: return "This month"
                            case .year: return "This year"
                            }
                        }()

                        // Descriptive sentence (period-aware)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            
                            // Example: "This month you've"
                            Text("\(periodLabel) you've")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(lostOrGained) \(minutes) mins")
                                .foregroundColor(mainColor)
                                .fontWeight(.semibold)
                            
                            // Correct grammar for lost/gained
                            if isPositive {
                                Text("thanks to your \(metric).")
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text("due to poor \(metric).")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        // Big metric value
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                if let metric = selectedHealthMetric {
                                    Text(metric.formattedValue)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(metricUnit(for: metric.type))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    Text("--")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }

                            Text(Date.now, style: .date)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)

                        // Chart container with native Swift Charts
                        chartView
                            .frame(height: 280)
                            .padding(.horizontal, 16)

                        // Recommendations header
                        if let healthMetric = selectedHealthMetric {
                            Text("\(title(for: healthMetric.type)) Recommendations")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                            
                            // Recommendation card
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.yellow.opacity(0.15))
                                    Image(systemName: Self.getIconForMetric(metricTitle))
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(width: 36, height: 36)
                                
                                Text(healthMetric.impactDetails?.recommendation ?? "")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            
                            // Secondary tip row
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Tap to see what XX research studies tell us about \(metricTitle.lowercased())")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 6)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                yAxisLabelsView
                mainChartView
            }
            .padding(16)
            .background(chartBackground)
            .overlay(chartBorder)
        }
    }
    
    private var yAxisLabelsView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yAxisValues.reversed(), id: \.self) { value in
                Text(formatYAxisValue(value))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 35)
    }
    
    private var mainChartView: some View {
        Chart(Array(chartData.enumerated()), id: \.offset) { index, point in
            lineMarkForPoint(point, at: index)
            if index == 0 {
                targetRuleMark
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisMarkValues) { value in
                if let index = value.as(Int.self), index < chartData.count {
                    AxisValueLabel {
                        Text(chartData[index].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: minYValue...maxYValue)
        .chartPlotStyle { plotArea in
            plotArea.background(plotBackgroundGradient)
        }
        .frame(height: 200)
    }
    
    private var xAxisMarkValues: [Int] {
        let rawStep = max(getXAxisStride(), 1)
        guard chartData.count > 0 else { return [] }
        let indices = Array(stride(from: 0, to: chartData.count, by: rawStep))
        return indices
    }
    
    private func lineMarkForPoint(_ point: ChartDataPoint, at index: Int) -> some ChartContent {
        LineMark(
            x: .value("Time", index),
            y: .value("Value", point.value)
        )
        .foregroundStyle(getColorForPoint(point))
        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }
    
    private var targetRuleMark: some ChartContent {
        RuleMark(y: .value("Target", targetValue))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(Color.white.opacity(0.25))
    }
    
    private var plotBackgroundGradient: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.03), Color.white.opacity(0.01)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
    }
    
    private var chartBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
    }
    
    private func getXAxisStride() -> Int {
        let totalPoints = chartData.count
        if totalPoints > 12 {
            return totalPoints / 5
        } else if totalPoints > 7 {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK: - Chart Helpers
    private var targetValue: Double {
        switch metricTitle.lowercased() {
        case "sleep":
            return 7.5 // 7.5 hours target
        case "heart rate":
            return 65
        case "steps":
            return 10000
        default:
            let values = chartData.map { $0.value }
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }
    }
    
    private var yAxisValues: [Double] {
        let values = chartData.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max(), minVal.isFinite, maxVal.isFinite else {
            return [0, 1, 2, 3, 4]
        }
        let padding = max(abs(minVal), abs(maxVal)) * 0.1
        let min = minVal - padding
        let max = maxVal + padding
        let range = max - min
        let step = range == 0 ? 1 : range / 4
        return stride(from: min, through: max, by: step).map { $0 }
    }
    
    private var minYValue: Double {
        let values = chartData.map { $0.value }
        guard let minVal = values.min() else { return 0 }
        let padding = abs(minVal) * 0.1
        return minVal - padding
    }
    
    private var maxYValue: Double {
        let values = chartData.map { $0.value }
        guard let maxVal = values.max() else { return 1 }
        let padding = abs(maxVal) * 0.1
        return maxVal + padding
    }
    
    private func formatYAxisValue(_ value: Double) -> String {
        switch metricTitle.lowercased() {
        case "sleep":
            return String(format: "%.0fh", value)
        case "steps":
            if value >= 1000 {
                return String(format: "%.0fk", value / 1000)
            }
            return String(format: "%.0f", value)
        case "heart rate":
            return String(format: "%.0f", value)
        default:
            return String(format: "%.0f", value)
        }
    }
    
    private func getColorForPoint(_ point: ChartDataPoint) -> Color {
        // Color logic: red if below target, green if above
        switch metricTitle.lowercased() {
        case "sleep":
            return point.value < targetValue ? .red : .green
        case "heart rate":
            // Lower is better for heart rate
            return point.value > targetValue ? .red : .green
        case "steps":
            return point.value < targetValue ? .red : .green
        default:
            return point.value < targetValue ? .red : .green
        }
    }

    // MARK: - Static Helper Functions

    static func getMetricsForPeriod(_ period: ImpactDataPoint.PeriodType) -> [DashboardMetric] {
        switch period {
        case .day:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "75",
                    unit: "BPM",
                    status: "↑ 4 mins added",
                    statusColor: .green,
                    timestamp: "21:43"
                ),
                DashboardMetric(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Steps",
                    value: "3,421",
                    unit: "steps",
                    status: "↓ 2 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Active Energy",
                    value: "670",
                    unit: "kcal",
                    status: "↓ 2 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "moon.fill",
                    iconColor: .yellow,
                    title: "Sleep",
                    value: "5h 12m",
                    unit: "",
                    status: "↓ 5 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "heart.circle.fill",
                    iconColor: .blue,
                    title: "Cardio (VO2)",
                    value: "56ml/65",
                    unit: "per min",
                    status: "↑ 3 mins added",
                    statusColor: .green,
                    timestamp: "21:35"
                )
            ]
        case .month:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "78",
                    unit: "BPM",
                    status: "↑ 12 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                ),
                DashboardMetric(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Steps",
                    value: "89,234",
                    unit: "steps",
                    status: "↑ 8 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                )
            ]
        case .year:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "76",
                    unit: "BPM",
                    status: "↑ 45 mins added",
                    statusColor: .green,
                    timestamp: "2024"
                )
            ]
        }
    }

//    static func getChartDataForMetric(_ metricTitle: String, period: String) -> [ChartDataPoint] {
//        switch metricTitle.lowercased() {
//        case "sleep":
//            return getSleepChartData(for: period)
//        case "steps":
//            return getStepsChartData(for: period)
//        case "heart rate":
//            return getHeartRateChartData(for: period)
//        case "exercise", "active energy":
//            return getExerciseChartData(for: period)
//        case "weight":
//            return getWeightChartData(for: period)
//        default:
//            return getDefaultChartData(for: period)
//        }
//    }

    static func getIconForMetric(_ metricTitle: String) -> String {
        switch metricTitle.lowercased() {
        case "sleep":
            return "moon.fill"
        case "steps":
            return "figure.walk"
        case "heart rate":
            return "heart.fill"
        case "exercise", "active energy":
            return "flame.fill"
        case "weight":
            return "scalemass.fill"
        default:
            return "chart.bar.fill"
        }
    }

    static func getRecommendationForMetric(_ metricTitle: String) -> String {
        switch metricTitle.lowercased() {
        case "sleep":
            return "Get 8 hours of sleep tonight to add 10 minutes to your lifespan."
        case "steps":
            return "Aim for 10,000 steps daily. Take short walks throughout the day to increase activity."
        case "heart rate":
            return "Regular cardio exercise can help improve your resting heart rate over time."
        case "exercise", "active energy":
            return "Include both cardio and strength training in your weekly routine for optimal health."
        case "weight":
            return "Maintain a balanced diet and regular exercise routine for healthy weight management."
        default:
            return "Focus on consistent healthy habits for the best long-term results."
        }
    }

//    // Chart data helper functions
//    static func getSleepChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 0, label: "16:15"),
//                ChartDataPoint(value: 0, label: "16:30"),
//                ChartDataPoint(value: 0, label: "16:45"),
//                ChartDataPoint(value: 0, label: "17:00"),
//                ChartDataPoint(value: 0, label: "17:15"),
//                ChartDataPoint(value: 0, label: "17:30"),
//                ChartDataPoint(value: 0, label: "17:45"),
//                ChartDataPoint(value: 0, label: "18:00"),
//                ChartDataPoint(value: -2.5, label: "18:15"),
//                ChartDataPoint(value: -2, label: "18:30"),
//                ChartDataPoint(value: -1.5, label: "18:45"),
//                ChartDataPoint(value: -1.7, label: "19:00"),
//                ChartDataPoint(value: -2, label: "19:15"),
//                ChartDataPoint(value: -1.3, label: "19:30"),
//                ChartDataPoint(value: 1.5, label: "19:45"),
//                ChartDataPoint(value: 2.5, label: "20:00"),
//                ChartDataPoint(value: 1.8, label: "20:15")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 7.5, label: "Week 1"),
//                ChartDataPoint(value: 8.0, label: "Week 2"),
//                ChartDataPoint(value: 7.2, label: "Week 3"),
//                ChartDataPoint(value: 7.8, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 7.3, label: "Q1"),
//                ChartDataPoint(value: 7.8, label: "Q2"),
//                ChartDataPoint(value: 8.1, label: "Q3"),
//                ChartDataPoint(value: 7.6, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
//
//    static func getStepsChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 8500, label: "Mon"),
//                ChartDataPoint(value: 12000, label: "Tue"),
//                ChartDataPoint(value: 9800, label: "Wed"),
//                ChartDataPoint(value: 11500, label: "Thu"),
//                ChartDataPoint(value: 13200, label: "Fri"),
//                ChartDataPoint(value: 15800, label: "Sat"),
//                ChartDataPoint(value: 9200, label: "Sun")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 10500, label: "Week 1"),
//                ChartDataPoint(value: 12000, label: "Week 2"),
//                ChartDataPoint(value: 9800, label: "Week 3"),
//                ChartDataPoint(value: 11200, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 9500, label: "Q1"),
//                ChartDataPoint(value: 11200, label: "Q2"),
//                ChartDataPoint(value: 12800, label: "Q3"),
//                ChartDataPoint(value: 10500, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
//
//    static func getHeartRateChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 65, label: "Mon"),
//                ChartDataPoint(value: 62, label: "Tue"),
//                ChartDataPoint(value: 68, label: "Wed"),
//                ChartDataPoint(value: 64, label: "Thu"),
//                ChartDataPoint(value: 61, label: "Fri"),
//                ChartDataPoint(value: 59, label: "Sat"),
//                ChartDataPoint(value: 66, label: "Sun")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 66, label: "Week 1"),
//                ChartDataPoint(value: 64, label: "Week 2"),
//                ChartDataPoint(value: 63, label: "Week 3"),
//                ChartDataPoint(value: 62, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 68, label: "Q1"),
//                ChartDataPoint(value: 65, label: "Q2"),
//                ChartDataPoint(value: 63, label: "Q3"),
//                ChartDataPoint(value: 61, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
//
//    static func getExerciseChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 25, label: "Mon"),
//                ChartDataPoint(value: 45, label: "Tue"),
//                ChartDataPoint(value: 30, label: "Wed"),
//                ChartDataPoint(value: 50, label: "Thu"),
//                ChartDataPoint(value: 35, label: "Fri"),
//                ChartDataPoint(value: 60, label: "Sat"),
//                ChartDataPoint(value: 20, label: "Sun")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 35, label: "Week 1"),
//                ChartDataPoint(value: 42, label: "Week 2"),
//                ChartDataPoint(value: 38, label: "Week 3"),
//                ChartDataPoint(value: 45, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 30, label: "Q1"),
//                ChartDataPoint(value: 38, label: "Q2"),
//                ChartDataPoint(value: 45, label: "Q3"),
//                ChartDataPoint(value: 42, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
//
//    static func getWeightChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 70.2, label: "Mon"),
//                ChartDataPoint(value: 70.1, label: "Tue"),
//                ChartDataPoint(value: 69.8, label: "Wed"),
//                ChartDataPoint(value: 70.0, label: "Thu"),
//                ChartDataPoint(value: 69.9, label: "Fri"),
//                ChartDataPoint(value: 70.3, label: "Sat"),
//                ChartDataPoint(value: 70.1, label: "Sun")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 71.0, label: "Week 1"),
//                ChartDataPoint(value: 70.5, label: "Week 2"),
//                ChartDataPoint(value: 70.2, label: "Week 3"),
//                ChartDataPoint(value: 70.0, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 72.5, label: "Q1"),
//                ChartDataPoint(value: 71.8, label: "Q2"),
//                ChartDataPoint(value: 70.5, label: "Q3"),
//                ChartDataPoint(value: 70.0, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
//
//    static func getDefaultChartData(for period: String) -> [ChartDataPoint] {
//        switch period {
//        case "day":
//            return [
//                ChartDataPoint(value: 85, label: "Mon"),
//                ChartDataPoint(value: 92, label: "Tue"),
//                ChartDataPoint(value: 78, label: "Wed"),
//                ChartDataPoint(value: 88, label: "Thu"),
//                ChartDataPoint(value: 95, label: "Fri"),
//                ChartDataPoint(value: 90, label: "Sat"),
//                ChartDataPoint(value: 82, label: "Sun")
//            ]
//        case "month":
//            return [
//                ChartDataPoint(value: 82, label: "Week 1"),
//                ChartDataPoint(value: 88, label: "Week 2"),
//                ChartDataPoint(value: 85, label: "Week 3"),
//                ChartDataPoint(value: 90, label: "Week 4")
//            ]
//        case "year":
//            return [
//                ChartDataPoint(value: 80, label: "Q1"),
//                ChartDataPoint(value: 85, label: "Q2"),
//                ChartDataPoint(value: 88, label: "Q3"),
//                ChartDataPoint(value: 90, label: "Q4")
//            ]
//        default:
//            return []
//        }
//    }
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
            .padding(.top, 10)
    }
    
    private var dateNavigationBar: some View {
        HStack(spacing: 4) {
            ForEach([ImpactDataPoint.PeriodType.day, .month, .year], id: \.self) { period in
                Button(action: {
                    changePeriod(to: period)
                }) {
                    Text(period.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#318AFC"),
                                            Color(hex: "#18EF47").opacity(0.58)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(selectedPeriod == period ? 1 : 0)
                        )
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(hex: "#828282").opacity(0.45))
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = abs(value.translation.height)
                    
                    if abs(horizontalAmount) > verticalAmount {
                        if horizontalAmount > 0 {
                            swipeToPreviousPeriod()
                        } else {
                            swipeToNextPeriod()
                        }
                    }
                }
        )
    }
    
    private func changePeriod(to period: ImpactDataPoint.PeriodType) {
        guard selectedPeriod != period else { return }
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.selectedPeriod = period
                let timePeriod = TimePeriod(from: period)
                if self.viewModel.selectedTimePeriod != timePeriod {
                    self.viewModel.selectedTimePeriod = timePeriod
                }
            }
            
//            if let metric = selectedHealthMetric {
//                selectedHealthMetric = viewModel.healthMetrics.first(where: { $0.type == metric.type })
//            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    private func swipeToNextPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let nextIndex = (currentIndex + 1) % periods.count
        let nextPeriod = periods[nextIndex]
        
        changePeriod(to: nextPeriod)
    }
    
    private func swipeToPreviousPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let previousIndex = currentIndex == 0 ? periods.count - 1 : currentIndex - 1
        let previousPeriod = periods[previousIndex]
        
        changePeriod(to: previousPeriod)
    }
    
    func title(for type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "Heart Rate"
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Activity"
        case .sleepHours: return "Sleep"
        case .vo2Max: return "Cardio (VO2)"
        case .bodyMass: return "Weight"
        default: return type.displayName
        }
    }

    func iconName(for type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "heartRateIcon"
        case .steps: return "stepsIcon"
        case .activeEnergyBurned: return "activityIcon"
        case .sleepHours: return "sleepIcon"
        case .vo2Max: return "cardioIcon"
        case .bodyMass: return "weightIcon"
        default: return "heartRateIcon"
        }
    }
    
    /// Get color for metric type
    private func metricColor(for type: HealthMetricType) -> Color {
        switch type {
        case .restingHeartRate: return .ampedRed
        case .steps: return .blue
        case .activeEnergyBurned: return .orange
        case .sleepHours: return .ampedYellow
        case .vo2Max: return .blue
        default: return .ampedRed
        }
    }
    
    func metricUnit(for type: HealthMetricType) -> String {
        // These map to your existing asset names used by MetricCard (e.g., "heartRateIcon", "stepsIcon", etc.)
        switch type {
        case .restingHeartRate: return "BPM"
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Kcal"
        case .sleepHours: return ""
        case .vo2Max: return ""
        case .bodyMass: return "KG"
        default: return ""
        }
    }
}
