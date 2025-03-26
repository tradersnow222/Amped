import SwiftUI
import Charts

/// Detailed view for a specific health metric with charts and recommendations
struct MetricDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: MetricDetailViewModel
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    // Convenience property for accessing current metric
    private var metric: HealthMetric {
        viewModel.metric
    }
    
    // MARK: - Initialization
    
    init(metric: HealthMetric) {
        _viewModel = StateObject(wrappedValue: MetricDetailViewModel(metric: metric))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Metric card
                BatteryMetricCard(metric: metric, showDetails: true)
                    .padding(.horizontal)
                
                // Impact section
                impactSection
                
                // Chart section
                chartSection
                
                // Research section
                researchSection
                
                // Recommendations section
                recommendationsSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle(metric.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.loadData(for: metric)
            AnalyticsService.shared.trackMetricSelected(metric.type.rawValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Details for \(metric.type.displayName)")
    }
    
    // MARK: - Impact Section
    
    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Impact Details")
                .style(.headline)
                .padding(.horizontal)
            
            if let impact = metric.impactDetail {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your \(metric.type.displayName.lowercased()) is \(impact.comparisonToBaseline.description).")
                        .style(.body)
                    
                    Text("This impacts your lifespan by approximately \(impact.formattedImpact).")
                        .style(.body)
                    
                    if impact.lifespanImpactMinutes > 0 {
                        Text("This is a positive impact on your health! 🎉")
                            .style(.bodyMedium, color: .ampedGreen)
                    } else if impact.lifespanImpactMinutes < 0 {
                        Text("This is currently reducing your projected lifespan.")
                            .style(.bodyMedium, color: .ampedRed)
                    } else {
                        Text("This is in line with typical health outcomes.")
                            .style(.bodyMedium)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal)
            } else {
                Text("Impact data unavailable")
                    .style(.bodySecondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History")
                .style(.headline)
                .padding(.horizontal)
            
            if !viewModel.historyData.isEmpty {
                metricHistoryChart
                    .frame(height: 200)
                    .padding(.horizontal)
            } else {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var metricHistoryChart: some View {
        Chart {
            ForEach(viewModel.historyData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(metric.type.displayName, dataPoint.value)
                )
                .foregroundStyle(metric.impactDetail?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red)
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(metric.type.displayName, dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            (metric.impactDetail?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red).opacity(0.3),
                            (metric.impactDetail?.lifespanImpactMinutes ?? 0 >= 0 ? Color.green : Color.red).opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            if let targetValue = metric.type.targetValue {
                RuleMark(y: .value("Target", targetValue))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.index)")
            }
        }
        .chartYScale(domain: viewModel.getChartYRange(for: metric))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chart showing \(metric.type.displayName) history over time")
    }
    
    // MARK: - Research Section
    
    private var researchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Research Reference")
                .style(.headline)
                .padding(.horizontal)
            
            if let study = metric.impactDetail?.studyReference {
                VStack(alignment: .leading, spacing: 8) {
                    Text(study.title)
                        .style(.subheadlineBold)
                    
                    Text(study.shortCitation)
                        .style(.caption)
                    
                    Text(study.summary)
                        .style(.body)
                        .padding(.top, 4)
                    
                    if let studyUrl = study.url, !studyUrl.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Link("Read More", destination: studyUrl)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal)
            } else {
                Text("No research reference available")
                    .style(.bodySecondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .style(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.recommendations) { recommendation in
                recommendationCard(recommendation)
            }
        }
    }
    
    private func recommendationCard(_ recommendation: MetricRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendation.iconName)
                    .foregroundColor(themeManager.accentColor)
                
                Text(recommendation.title)
                    .style(.headlineBold)
            }
            
            Text(recommendation.description)
                .style(.body)
            
            if !recommendation.actionText.isEmpty {
                Button {
                    // In a real app, this would perform the action
                    // For MVP, just log it
                    viewModel.logRecommendationAction(recommendation)
                } label: {
                    Text(recommendation.actionText)
                        .style(.buttonLabel, color: .white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 8).fill(themeManager.accentColor))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    private var powerLevelIndicator: some View {
        // Breaking down the complex expression
        PowerLevelIndicatorView(powerLevel: viewModel.powerLevel, powerColor: viewModel.powerColor)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: metric.type.symbolName)
                            .foregroundColor(metric.type.color)
                            .textStyle(.title)
                        
                        Text(metric.type.displayName)
                            .style(.title)
                    }
                    
                    Text(metric.formattedValue)
                        .style(.metricValue, color: themeManager.getThemeColor(for: .metricValue))
                }
                
                Spacer()
                
                // Power level indicator
                powerLevelIndicator
            }
            .padding(.horizontal)
        }
    }
}

// Helper view to simplify complex expressions
struct PowerLevelIndicatorView: View {
    let powerLevel: Int
    let powerColor: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Power Level")
                .style(.caption)
            
            // Battery power level
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    PowerLevelBar(
                        isActive: i < powerLevel,
                        activeColor: powerColor,
                        height: 8 + CGFloat(i) * 2
                    )
                }
            }
            .padding(.top, 4)
        }
    }
}

struct PowerLevelBar: View {
    let isActive: Bool
    let activeColor: Color
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(isActive ? activeColor : Color.gray.opacity(0.3))
            .frame(width: 3, height: height)
    }
}

// MARK: - View Model

final class MetricDetailViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var historyData: [HistoryDataPoint] = []
    @Published var recommendations: [MetricRecommendation] = []
    @Published var metric: HealthMetric
    
    // Computed properties for the power level indicator
    var powerLevel: Int {
        // Simulate power level based on metric's impact
        if let impact = metric.impactDetail?.lifespanImpactMinutes {
            if impact > 120 { return 5 }
            else if impact > 60 { return 4 }
            else if impact > 0 { return 3 }
            else if impact > -60 { return 2 }
            else { return 1 }
        }
        return 3 // Default middle level
    }
    
    var powerColor: Color {
        if let impact = metric.impactDetail?.lifespanImpactMinutes, impact >= 0 {
            return .ampedGreen
        }
        return .ampedRed
    }
    
    // MARK: - Initialization
    
    init(metric: HealthMetric) {
        self.metric = metric
    }
    
    // MARK: - Methods
    
    func loadData(for metric: HealthMetric) {
        // In a real app, this would load actual historical data
        // For the MVP, we'll generate mock data
        generateMockHistoryData(for: metric)
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
    
    private func generateMockHistoryData(for metric: HealthMetric) {
        // Generate 30 days of mock data
        var mockData: [HistoryDataPoint] = []
        let calendar = Calendar.current
        let baseValue = metric.value
        
        for day in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // Random variation around the base value
            let variation = Double.random(in: -0.2...0.2)
            let adjustedValue = baseValue * (1 + variation)
            
            mockData.append(HistoryDataPoint(date: date, value: adjustedValue))
        }
        
        // Sort by date ascending
        mockData.sort { $0.date < $1.date }
        
        DispatchQueue.main.async {
            self.historyData = mockData
        }
    }
    
    private func generateRecommendations(for metric: HealthMetric) {
        // Generate appropriate recommendations based on the metric type
        var metricRecommendations: [MetricRecommendation] = []
        
        switch metric.type {
        case .steps:
            metricRecommendations = generateStepsRecommendations(metric)
        case .activeEnergyBurned:
            metricRecommendations = generateActiveEnergyRecommendations(metric)
        case .exerciseMinutes:
            metricRecommendations = generateExerciseRecommendations(metric)
        case .sleepHours:
            metricRecommendations = generateSleepRecommendations(metric)
        case .restingHeartRate:
            metricRecommendations = generateHeartRateRecommendations(metric)
        case .heartRateVariability:
            metricRecommendations = generateHRVRecommendations(metric)
        case .vo2Max:
            metricRecommendations = generateVO2MaxRecommendations(metric)
        case .oxygenSaturation:
            metricRecommendations = generateOxygenSaturationRecommendations(metric)
        case .nutritionQuality:
            metricRecommendations = generateNutritionRecommendations(metric)
        case .stressLevel:
            metricRecommendations = generateStressRecommendations(metric)
        @unknown default:
            metricRecommendations = [
                MetricRecommendation(
                    id: UUID(),
                    title: "Track Consistently",
                    description: "Regular monitoring helps identify trends and opportunities for improvement.",
                    iconName: "chart.line.uptrend.xyaxis",
                    actionText: "Set a reminder to check this metric"
                ),
                MetricRecommendation(
                    id: UUID(),
                    title: "Make Gradual Changes",
                    description: "Small, sustainable improvements compound over time for significant health benefits.",
                    iconName: "arrow.up.forward",
                    actionText: "Focus on one small change this week"
                )
            ]
        }
        
        DispatchQueue.main.async {
            self.recommendations = metricRecommendations
        }
    }
    
    private func generateStepsRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        if metric.value < 7000 {
            return [
                MetricRecommendation(
                    id: UUID(),
                    title: "Increase Daily Movement",
                    description: "Try to incorporate more walking into your daily routine. Even small increases can have significant benefits.",
                    iconName: "figure.walk",
                    actionText: "Set Step Goal"
                ),
                MetricRecommendation(
                    id: UUID(),
                    title: "Take Walking Meetings",
                    description: "Convert some of your seated meetings into walking ones when possible.",
                    iconName: "person.2.fill",
                    actionText: ""
                )
            ]
        } else {
            return [
                MetricRecommendation(
                    id: UUID(),
                    title: "Maintain Your Activity",
                    description: "You're doing well with your daily steps. Consider adding variety to your walking routes to keep it engaging.",
                    iconName: "checkmark.circle.fill",
                    actionText: ""
                )
            ]
        }
    }
    
    private func generateActiveEnergyRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Mix Up Your Activities",
                description: "Try different types of physical activities to engage different muscle groups and boost overall energy expenditure.",
                iconName: "flame.fill",
                actionText: "Find Activities"
            )
        ]
    }
    
    private func generateExerciseRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Schedule Exercise",
                description: "Block time in your calendar for physical activity to ensure you meet the recommended 150 minutes per week.",
                iconName: "timer",
                actionText: "Set Reminder"
            )
        ]
    }
    
    private func generateSleepRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Consistent Sleep Schedule",
                description: "Try to go to bed and wake up at the same time every day, even on weekends.",
                iconName: "bed.double.fill",
                actionText: "Set Sleep Reminder"
            )
        ]
    }
    
    private func generateHeartRateRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Consider Relaxation Techniques",
                description: "Regular relaxation practices like deep breathing or meditation can help optimize your resting heart rate.",
                iconName: "heart.fill",
                actionText: "Learn Techniques"
            )
        ]
    }
    
    private func generateHRVRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Mindfulness Practice",
                description: "Even 5 minutes of daily mindfulness can help reduce stress levels over time.",
                iconName: "brain.head.profile",
                actionText: "Try Guided Exercise"
            )
        ]
    }
    
    private func generateVO2MaxRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Interval Training",
                description: "High-intensity interval training (HIIT) can be particularly effective for improving VO2 Max.",
                iconName: "lungs.fill",
                actionText: "View HIIT Workouts"
            )
        ]
    }
    
    private func generateOxygenSaturationRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Maintain Good Air Quality",
                description: "Ensure proper ventilation in your living spaces and monitor indoor air quality.",
                iconName: "air.purifier",
                actionText: "Check your home's air quality"
            ),
            MetricRecommendation(
                id: UUID(),
                title: "Practice Deep Breathing",
                description: "Regular deep breathing exercises can help optimize oxygen intake and utilization.",
                iconName: "lungs.fill",
                actionText: "Try a 5-minute breathing exercise"
            ),
            MetricRecommendation(
                id: UUID(),
                title: "Stay Physically Active",
                description: "Regular exercise improves cardiovascular function and oxygen delivery throughout the body.",
                iconName: "figure.run",
                actionText: "Schedule a cardio workout"
            )
        ]
    }
    
    private func generateNutritionRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Plant-Based Focus",
                description: "Try to make plants the star of your meals. Aim for half your plate to be vegetables and fruits.",
                iconName: "leaf.fill",
                actionText: ""
            )
        ]
    }
    
    private func generateStressRecommendations(_ metric: HealthMetric) -> [MetricRecommendation] {
        // Implementation similar to steps recommendations
        return [
            MetricRecommendation(
                id: UUID(),
                title: "Mindfulness Practice",
                description: "Even 5 minutes of daily mindfulness can help reduce stress levels over time.",
                iconName: "brain.head.profile",
                actionText: "Try Guided Exercise"
            )
        ]
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

// Sample chart view - in a real app, this would use Swift Charts
struct ChartView: View {
    let metric: HealthMetric
    let period: ImpactDataPoint.PeriodType
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        // Placeholder for chart
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
            
            Text("Chart for \(metric.type.displayName) over \(period.rawValue)")
                .font(.caption)
        }
    }
}

#Preview {
    NavigationView {
        MetricDetailView(metric: HealthMetric.mockSteps)
    }
} 