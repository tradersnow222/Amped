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
                // Header if needed
                // MetricDetailSections.HeaderSection(
                //    metric: metric, 
                //    powerLevel: viewModel.powerLevel,
                //    powerColor: viewModel.powerColor
                // )
                
                // Metric card
                BatteryMetricCard(metric: metric, showDetails: true)
                    .padding(.horizontal)
                
                // Impact section
                MetricDetailSections.ImpactSection(metric: metric)
                
                // Chart section
                MetricDetailSections.ChartSection(
                    metric: metric,
                    historyData: viewModel.historyData,
                    getChartYRange: viewModel.getChartYRange
                )
                
                // Research section
                MetricDetailSections.ResearchSection(metric: metric)
                
                // Recommendations section
                MetricDetailSections.RecommendationsSection(
                    recommendations: viewModel.recommendations,
                    logAction: viewModel.logRecommendationAction
                )
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle(metric.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .withDeepBackground()
        .onAppear {
            // Configure navigation bar appearance to match dark theme
            let scrolledAppearance = UINavigationBarAppearance()
            scrolledAppearance.configureWithDefaultBackground()
            scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = scrolledAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
            UINavigationBar.appearance().compactAppearance = scrolledAppearance
            
            viewModel.loadData(for: metric)
            AnalyticsService.shared.trackMetricSelected(metric.type.rawValue)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Details for \(metric.type.displayName)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
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
        // Generate mock data for the last 30 days
        let calendar = Calendar.current
        let now = Date()
        
        // Clear existing data
        historyData.removeAll()
        
        // Generate basic trend with some randomness
        var baseValue: Double
        var trendDirection: Double
        
        switch metric.type {
        case .steps:
            baseValue = 8000
            trendDirection = 100
        case .exerciseMinutes:
            baseValue = 30
            trendDirection = 0.5
        case .sleepHours:
            baseValue = 7
            trendDirection = 0.05
        case .heartRateVariability:
            baseValue = 50
            trendDirection = 0.2
        case .restingHeartRate:
            baseValue = 65
            trendDirection = -0.1
        case .bodyMass:
            baseValue = 75
            trendDirection = -0.05
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality:
            // Manual metrics - use constant value with minor fluctuations
            baseValue = metric.value
            trendDirection = 0
        case .activeEnergyBurned:
            baseValue = 400
            trendDirection = 10
        case .vo2Max:
            baseValue = 40
            trendDirection = 0.2
        case .oxygenSaturation:
            baseValue = 98
            trendDirection = 0.05
        case .stressLevel:
            baseValue = 5
            trendDirection = -0.1
        }
        
        // Generate data points
        for i in (0..<30).reversed() {
            let day = calendar.date(byAdding: .day, value: -i, to: now)!
            
            // Calculate value with trend and some random noise
            let trendFactor = Double(i) * trendDirection
            let randomFactor = Double.random(in: -0.1...0.1) * baseValue
            let value = max(0, baseValue + trendFactor + randomFactor)
            
            historyData.append(HistoryDataPoint(date: day, value: value))
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
                description: "Try to walk for at least 30 minutes each day, ideally reaching 10,000 steps for optimal cardiovascular benefits.",
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
                description: "Mix cardio, strength training, and flexibility exercises for best results. Aim for at least 150 minutes per week.",
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

// Sample chart view - in a real app, this would use Swift Charts
struct ChartView: View {
    let metric: HealthMetric
    let period: ImpactDataPoint.PeriodType
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        // Placeholder for chart
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardBackground)
            
            Text("Chart for \(metric.type.displayName) over \(period.rawValue)")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        MetricDetailView(metric: HealthMetric.sample(type: .steps, value: 8750))
    }
} 