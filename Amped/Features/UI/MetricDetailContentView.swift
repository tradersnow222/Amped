import SwiftUI

struct MetricDetailContentView: View {
    let metricTitle: String
    let period: String
    let periodType: ImpactDataPoint.PeriodType
    @Binding var navigationPath: NavigationPath

    // Cache the data to prevent infinite loops
    private let metrics: [DashboardMetric]
    private let chartData: [ChartDataPoint]
    private let yAxisLabels: [String]
    private let xAxisLabels: [String]

    init(metricTitle: String, period: String, periodType: ImpactDataPoint.PeriodType, navigationPath: Binding<NavigationPath>) {
        self.metricTitle = metricTitle
        self.period = period
        self.periodType = periodType
        self._navigationPath = navigationPath

        // Cache all data during initialization to prevent recalculation loops
        self.metrics = Self.getMetricsForPeriod(periodType)
        self.chartData = Self.getChartDataForMetric(metricTitle, period: period)
        self.yAxisLabels = Self.getYAxisLabels(for: metricTitle)
        self.xAxisLabels = Self.getXAxisLabels(for: period)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Button(action: {
                    // Use DispatchQueue to prevent multiple navigation updates per frame
                    DispatchQueue.main.async {
                        navigationPath.removeLast()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
                        )
                }

                Spacer()

                Text(metricTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Empty space to balance the back button
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(Color.black)

            // Day/Month/Year selector - matching home screen design
            HStack(spacing: 4) {
                ForEach(["Day", "Month", "Year"], id: \.self) { periodOption in
                    Button(action: {
                        // Simple tab action - no complex state management
                    }) {
                        Text(periodOption)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(periodOption.lowercased() == period ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(periodOption.lowercased() == period ? Color.black : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Main metric display
                    VStack(spacing: 8) {
                        if let metric = metrics.first(where: { $0.title == metricTitle }) {
                            // Large value display
                            HStack(alignment: .bottom, spacing: 12) {
                                Text(metric.value)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)

                                if !metric.unit.isEmpty {
                                    Text(metric.unit)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Text(metric.status)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(metric.statusColor)

                                Spacer()
                            }
                        }

                        // Date info
                        Text(Date().formatted(.dateTime.day().month().year()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red:213/255,green:213/255,blue:213/255).opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)

                    // Real Chart section
                    VStack(spacing: 16) {
                        // Chart area with real data
                        VStack(spacing: 12) {
                            Spacer()
                                .frame(height:12)

                            // Bar chart implementation with cached data
                            GeometryReader { geometry in
                                VStack(spacing: 0) {
                                    // Chart area with Y-axis labels
                                    HStack(alignment: .bottom, spacing: 0) {
                                        // Y-axis labels
                                        VStack(alignment: .trailing, spacing: 0) {
                                            ForEach(yAxisLabels, id: \.self) { label in
                                                Text(label)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .frame(height: (geometry.size.height - 30) / CGFloat(yAxisLabels.count))
                                            }
                                        }
                                        .frame(width: 30)
                                        .frame(height: geometry.size.height - 30)

                                        // Chart area - full width
                                        ZStack(alignment: .bottomLeading) {
                                            // Background grid lines
                                            HStack(spacing: 0) {
                                                ForEach(0..<4, id: \.self) { _ in
                                                    Rectangle()
                                                        .fill(Color.white.opacity(0.1))
                                                        .frame(width: 1, height: geometry.size.height - 30)
                                                    Spacer()
                                                }
                                            }

                                            // Bar chart - full width with cached data
                                            HStack(alignment: .bottom, spacing: 8) {
                                                let maxValue = chartData.map { $0.value }.max() ?? 1
                                                let minValue = chartData.map { $0.value }.min() ?? 0
                                                let valueRange = maxValue - minValue
                                                let chartHeight = geometry.size.height - 30

                                                ForEach(Array(chartData.enumerated()), id: \.offset) { _, point in
                                                    let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                                                    let barHeight = normalizedValue * chartHeight

                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(Self.getColorForMetric(metricTitle))
                                                        .frame(width: 16, height: max(4, barHeight))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }

                                    // X-axis labels with more spacing
                                    HStack(spacing: 0) {
                                        Spacer().frame(width: 30) // Align with chart area
                                        ForEach(Array(xAxisLabels.enumerated()), id: \.offset) { index, label in
                                            Text(label)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.6))

                                            if label != xAxisLabels.last {
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                }
                            }
                            .frame(height: 200)
                            .padding(.horizontal, 0)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Recommendations section
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height:12)

                        Text("Recommendations")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        // Recommendation card
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: Self.getIconForMetric(metricTitle))
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Self.getColorForMetric(metricTitle))
                                    .frame(width: 24, height: 24)

                                Text(metricTitle)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()
                            }

                            Text(Self.getRecommendationForMetric(metricTitle))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
                        )
                        .padding(.horizontal, 20)
                    }
                    // Action item
                    HStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Self.getColorForMetric(metricTitle))

                        Text(Self.getActionForMetric(metricTitle))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()
                    }

                    Spacer(minLength: 100) // Space for bottom navigation
                }
                .padding(.top, 20)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }

    // MARK: - Static Helper Functions (moved from DashboardView)

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
                    status: "↓ 2 mins lost",
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

    static func getChartDataForMetric(_ metricTitle: String, period: String) -> [ChartDataPoint] {
        switch metricTitle.lowercased() {
        case "sleep":
            return getSleepChartData(for: period)
        case "steps":
            return getStepsChartData(for: period)
        case "heart rate":
            return getHeartRateChartData(for: period)
        case "exercise":
            return getExerciseChartData(for: period)
        case "weight":
            return getWeightChartData(for: period)
        default:
            return getDefaultChartData(for: period)
        }
    }

    static func getYAxisLabels(for metricTitle: String) -> [String] {
        switch metricTitle.lowercased() {
        case "sleep":
            return ["9", "7", "5", "3"]
        case "steps":
            return ["15k", "10k", "5k", "0"]
        case "heart rate":
            return ["70", "65", "60", "55"]
        case "exercise":
            return ["60", "40", "20", "0"]
        case "weight":
            return ["75", "70", "65", "60"]
        default:
            return ["100", "75", "50", "25"]
        }
    }

    static func getXAxisLabels(for period: String) -> [String] {
        switch period {
        case "day":
            return ["12 AM", "6 AM", "12 PM", "6 PM", "11 PM"]
        case "month":
            return ["Week 1", "Week 2", "Week 3", "Week 4"]
        case "year":
            return ["Q1", "Q2", "Q3", "Q4"]
        default:
            return ["1", "2", "3", "4", "5"]
        }
    }

    static func getColorForMetric(_ metricTitle: String) -> Color {
        switch metricTitle.lowercased() {
        case "sleep":
            return .blue
        case "steps":
            return .green
        case "heart rate":
            return .red
        case "exercise":
            return .orange
        case "weight":
            return .purple
        default:
            return .gray
        }
    }

    static func getIconForMetric(_ metricTitle: String) -> String {
        switch metricTitle.lowercased() {
        case "sleep":
            return "moon.fill"
        case "steps":
            return "figure.walk"
        case "heart rate":
            return "heart.fill"
        case "exercise":
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
            return "Try to get 7-9 hours of quality sleep each night. Consider a consistent bedtime routine."
        case "steps":
            return "Aim for 10,000 steps daily. Take short walks throughout the day to increase activity."
        case "heart rate":
            return "Regular cardio exercise can help improve your resting heart rate over time."
        case "exercise":
            return "Include both cardio and strength training in your weekly routine for optimal health."
        case "weight":
            return "Maintain a balanced diet and regular exercise routine for healthy weight management."
        default:
            return "Focus on consistent healthy habits for the best long-term results."
        }
    }

    static func getActionForMetric(_ metricTitle: String) -> String {
        switch metricTitle.lowercased() {
        case "sleep":
            return "Set a bedtime reminder"
        case "steps":
            return "Take a 10-minute walk"
        case "heart rate":
            return "Do 5 minutes of cardio"
        case "exercise":
            return "Schedule workout time"
        case "weight":
            return "Log your meals"
        default:
            return "Track this metric"
        }
    }

    // Chart data helper functions
    static func getSleepChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 7.2, label: "Mon"),
                ChartDataPoint(value: 8.1, label: "Tue"),
                ChartDataPoint(value: 6.8, label: "Wed"),
                ChartDataPoint(value: 7.5, label: "Thu"),
                ChartDataPoint(value: 8.3, label: "Fri"),
                ChartDataPoint(value: 9.1, label: "Sat"),
                ChartDataPoint(value: 7.8, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 7.5, label: "Week 1"),
                ChartDataPoint(value: 8.0, label: "Week 2"),
                ChartDataPoint(value: 7.2, label: "Week 3"),
                ChartDataPoint(value: 7.8, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 7.3, label: "Q1"),
                ChartDataPoint(value: 7.8, label: "Q2"),
                ChartDataPoint(value: 8.1, label: "Q3"),
                ChartDataPoint(value: 7.6, label: "Q4")
            ]
        default:
            return []
        }
    }

    static func getStepsChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 8500, label: "Mon"),
                ChartDataPoint(value: 12000, label: "Tue"),
                ChartDataPoint(value: 9800, label: "Wed"),
                ChartDataPoint(value: 11500, label: "Thu"),
                ChartDataPoint(value: 13200, label: "Fri"),
                ChartDataPoint(value: 15800, label: "Sat"),
                ChartDataPoint(value: 9200, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 10500, label: "Week 1"),
                ChartDataPoint(value: 12000, label: "Week 2"),
                ChartDataPoint(value: 9800, label: "Week 3"),
                ChartDataPoint(value: 11200, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 9500, label: "Q1"),
                ChartDataPoint(value: 11200, label: "Q2"),
                ChartDataPoint(value: 12800, label: "Q3"),
                ChartDataPoint(value: 10500, label: "Q4")
            ]
        default:
            return []
        }
    }

    static func getHeartRateChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 65, label: "Mon"),
                ChartDataPoint(value: 62, label: "Tue"),
                ChartDataPoint(value: 68, label: "Wed"),
                ChartDataPoint(value: 64, label: "Thu"),
                ChartDataPoint(value: 61, label: "Fri"),
                ChartDataPoint(value: 59, label: "Sat"),
                ChartDataPoint(value: 66, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 66, label: "Week 1"),
                ChartDataPoint(value: 64, label: "Week 2"),
                ChartDataPoint(value: 63, label: "Week 3"),
                ChartDataPoint(value: 62, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 68, label: "Q1"),
                ChartDataPoint(value: 65, label: "Q2"),
                ChartDataPoint(value: 63, label: "Q3"),
                ChartDataPoint(value: 61, label: "Q4")
            ]
        default:
            return []
        }
    }

    static func getExerciseChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 25, label: "Mon"),
                ChartDataPoint(value: 45, label: "Tue"),
                ChartDataPoint(value: 30, label: "Wed"),
                ChartDataPoint(value: 50, label: "Thu"),
                ChartDataPoint(value: 35, label: "Fri"),
                ChartDataPoint(value: 60, label: "Sat"),
                ChartDataPoint(value: 20, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 35, label: "Week 1"),
                ChartDataPoint(value: 42, label: "Week 2"),
                ChartDataPoint(value: 38, label: "Week 3"),
                ChartDataPoint(value: 45, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 30, label: "Q1"),
                ChartDataPoint(value: 38, label: "Q2"),
                ChartDataPoint(value: 45, label: "Q3"),
                ChartDataPoint(value: 42, label: "Q4")
            ]
        default:
            return []
        }
    }

    static func getWeightChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 70.2, label: "Mon"),
                ChartDataPoint(value: 70.1, label: "Tue"),
                ChartDataPoint(value: 69.8, label: "Wed"),
                ChartDataPoint(value: 70.0, label: "Thu"),
                ChartDataPoint(value: 69.9, label: "Fri"),
                ChartDataPoint(value: 70.3, label: "Sat"),
                ChartDataPoint(value: 70.1, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 71.0, label: "Week 1"),
                ChartDataPoint(value: 70.5, label: "Week 2"),
                ChartDataPoint(value: 70.2, label: "Week 3"),
                ChartDataPoint(value: 70.0, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 72.5, label: "Q1"),
                ChartDataPoint(value: 71.8, label: "Q2"),
                ChartDataPoint(value: 70.5, label: "Q3"),
                ChartDataPoint(value: 70.0, label: "Q4")
            ]
        default:
            return []
        }
    }

    static func getDefaultChartData(for period: String) -> [ChartDataPoint] {
        switch period {
        case "day":
            return [
                ChartDataPoint(value: 85, label: "Mon"),
                ChartDataPoint(value: 92, label: "Tue"),
                ChartDataPoint(value: 78, label: "Wed"),
                ChartDataPoint(value: 88, label: "Thu"),
                ChartDataPoint(value: 95, label: "Fri"),
                ChartDataPoint(value: 90, label: "Sat"),
                ChartDataPoint(value: 82, label: "Sun")
            ]
        case "month":
            return [
                ChartDataPoint(value: 82, label: "Week 1"),
                ChartDataPoint(value: 88, label: "Week 2"),
                ChartDataPoint(value: 85, label: "Week 3"),
                ChartDataPoint(value: 90, label: "Week 4")
            ]
        case "year":
            return [
                ChartDataPoint(value: 80, label: "Q1"),
                ChartDataPoint(value: 85, label: "Q2"),
                ChartDataPoint(value: 88, label: "Q3"),
                ChartDataPoint(value: 90, label: "Q4")
            ]
        default:
            return []
        }
    }
}
