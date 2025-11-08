import SwiftUI

struct MetricDetailContentView: View {
    let metricTitle: String
    let period: String
    let periodType: ImpactDataPoint.PeriodType
    @Binding var navigationPath: NavigationPath
    
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @StateObject private var viewModel = DashboardViewModel()

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
        
        selectedPeriod = periodType
    }

    var body: some View {
        ZStack {
            
            Color.black.ignoresSafeArea(.all)
            // Subtle dark gradient background to match screenshot
            LinearGradient.grayGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (match MetricGridView style): profile, name, search
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

                    // Header
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
                        if let metric = metrics.first(where: { $0.title == metricTitle }) {
                            // Example: Oops, Today you've lost 5 minutes due to poor sleep.
                            let lostOrGained = metric.status.contains("↓") ? "lost" : "gained"
                            let minutesText = metric.status.replacingOccurrences(of: "↑ ", with: "").replacingOccurrences(of: "↓ ", with: "")
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("Oops, Today you've")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(lostOrGained == "lost" ? minutesText : minutesText)
                                    .foregroundColor(lostOrGained == "lost" ? .red : .green)
                                    .fontWeight(.semibold)
                                Text("due to poor \(metricTitle.lowercased()).")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                        }

                        // Big metric value
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                if let metric = metrics.first(where: { $0.title == metricTitle }) {
                                    Text(metric.value)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    if !metric.unit.isEmpty {
                                        Text(metric.unit)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
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

                        // Chart container
                        VStack(spacing: 0) {
                            // Y grid + zero dashed line
                            GeometryReader { geometry in
                                ZStack(alignment: .bottomLeading) {
                                    // grid lines
                                    VStack {
                                        ForEach(0..<5, id: \.self) { idx in
                                            Rectangle()
                                                .fill(Color.white.opacity(idx == 3 ? 0 : 0.06))
                                                .frame(height: 1)
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 24)

                                    // dashed zero line across middle
                                    Path { path in
                                        let y = geometry.size.height * 0.5
                                        path.move(to: CGPoint(x: 0, y: y))
                                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                    }
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4,4]))
                                    .foregroundColor(Color.white.opacity(0.25))

                                    // simple polyline chart from chartData
                                    let maxValue = chartData.map { $0.value }.max() ?? 1
                                    let minValue = chartData.map { $0.value }.min() ?? 0
                                    let range = max(maxValue - minValue, 1)
                                    let inset: CGFloat = 24
                                    let width = geometry.size.width - inset*2
                                    let height = geometry.size.height - 48
                                    let stepX = width / CGFloat(max(chartData.count - 1, 1))

                                    // Build points
                                    let points: [CGPoint] = chartData.enumerated().map { (idx, p) in
                                        let x = inset + CGFloat(idx) * stepX
                                        let norm = (p.value - minValue) / range
                                        let y = (height * CGFloat(1 - norm)) + 24
                                        return CGPoint(x: x, y: y)
                                    }

                                    // Red before last third, green after crossing last third (visual hint only)
                                    if points.count > 1 {
                                        let splitIndex = Int(Double(points.count) * 0.7)
                                        let redSlice = Array(points.prefix(max(splitIndex, 2)))
                                        let greenSlice = Array(points.suffix(from: max(splitIndex-1, 0)))

                                        Path { path in
                                            guard let first = redSlice.first else { return }
                                            path.move(to: first)
                                            redSlice.dropFirst().forEach { path.addLine(to: $0) }
                                        }
                                        .stroke(Color.red, lineWidth: 2)

                                        Path { path in
                                            guard let first = greenSlice.first else { return }
                                            path.move(to: first)
                                            greenSlice.dropFirst().forEach { path.addLine(to: $0) }
                                        }
                                        .stroke(Color.green, lineWidth: 2)
                                    }

                                    // X labels
                                    VStack { Spacer() }
                                }
                            }
                            .frame(height: 220)
                            .background(
                                LinearGradient(colors: [Color.white.opacity(0.03), Color.white.opacity(0.01)], startPoint: .top, endPoint: .bottom)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // X-axis labels
                            HStack(spacing: 0) {
                                ForEach(Array(xAxisLabels.enumerated()), id: \.offset) { index, label in
                                    Text(label)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    if index != xAxisLabels.count - 1 { Spacer() }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                        }

                        // Recommendations header
                        Text("Sleep Recommendations")
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

                            Text(Self.getRecommendationForMetric(metricTitle))
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

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 6)
                }
            }
        }
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
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: true)
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
        .padding(.vertical,12)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = abs(value.translation.height)
                    
                    // Only respond to horizontal swipes (not vertical)
                    if abs(horizontalAmount) > verticalAmount {
                        if horizontalAmount > 0 {
                            // Swipe right - go to previous period
                            swipeToPreviousPeriod()
                        } else {
                            // Swipe left - go to next period
                            swipeToNextPeriod()
                        }
                    }
                }
        )
    }
    
    private func changePeriod(to period: ImpactDataPoint.PeriodType) {
        // Prevent infinite loops by checking if period is already selected
        guard selectedPeriod != period else { return }
        
        // Prevent multiple updates per frame by using async dispatch
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.selectedPeriod = period
                let timePeriod = TimePeriod(from: period)
                // Only update if it's actually different to prevent subscription loops
                if self.viewModel.selectedTimePeriod != timePeriod {
                    self.viewModel.selectedTimePeriod = timePeriod
                }
            }
            
            // Add haptic feedback for period change
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    /// Swipe to the next period (Day → Month → Year → Day)
    private func swipeToNextPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let nextIndex = (currentIndex + 1) % periods.count
        let nextPeriod = periods[nextIndex]
        
        changePeriod(to: nextPeriod)
    }
    
    /// Swipe to the previous period (Year → Month → Day → Year)
    private func swipeToPreviousPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let previousIndex = currentIndex == 0 ? periods.count - 1 : currentIndex - 1
        let previousPeriod = periods[previousIndex]
        
        changePeriod(to: previousPeriod)
    }
}
