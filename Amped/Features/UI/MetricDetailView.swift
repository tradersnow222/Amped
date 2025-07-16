import SwiftUI
import Charts

/// Detailed view for a specific health metric with charts and recommendations
struct MetricDetailView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: MetricDetailViewModel
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // State for chart interaction
    @State private var selectedDataPoint: MetricDataPoint?
    @State private var isDragging = false
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                // Time period selector - matching dashboard style
                PeriodSelectorView(
                    selectedPeriod: $viewModel.selectedPeriod,
                    onPeriodChanged: { period in
                        // Update period with animation to match dashboard behavior
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedPeriod = period
                        }
                        HapticManager.shared.playSelection()
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 32) // More space between selector and chart
                
                // Chart section with integrated metric info
                chartSection
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                
                // Quick insight section - subtle card style
                if let insight = getQuickInsight() {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.min.fill")
                            .foregroundColor(.ampedYellow.opacity(0.8))
                            .font(.body)
                        
                        Text(insight)
                            .style(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                // Recommendations section - subtle card style
                if !viewModel.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommendations")
                            .style(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.recommendations.prefix(3)) { recommendation in
                                recommendationRow(for: recommendation)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle(metric.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .withDeepBackground()
        .onAppear {
            setupNavigationBar()
            viewModel.loadData(for: metric)
            AnalyticsService.shared.trackMetricSelected(metric.type.rawValue)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton(action: {
                    dismiss()
                }, showText: false)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.8))
            }
        }
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(spacing: 0) {
            // Metric value and impact integrated at top of chart
            HStack(alignment: .top) {
                // Current metric value
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatMetricValue(metric.value))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(getMetricContext())
                        .style(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Impact display
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatImpactDisplay(viewModel.totalImpactForPeriod))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.totalImpactForPeriod >= 0 ? .ampedGreen : .ampedRed)
                    
                    Text(percentageText)
                        .style(.caption)
                        .foregroundColor(viewModel.totalImpactForPeriod >= 0 ? .ampedGreen.opacity(0.8) : .ampedRed.opacity(0.8))
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 20)
            
            // Chart
            StyledMetricChart(
                metricType: metric.type,
                dataPoints: viewModel.chartDataPoints,
                period: viewModel.selectedPeriod,
                totalImpact: viewModel.totalImpactForPeriod,
                selectedDataPoint: $selectedDataPoint,
                isDragging: $isDragging
            )
            .frame(height: 200)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Helper Views
    
    private func recommendationRow(for recommendation: MetricRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendation.iconName)
                .foregroundColor(.white.opacity(0.5))
                .font(.body)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .style(.bodyMedium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(recommendation.description)
                    .style(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onTapGesture {
            viewModel.logRecommendationAction(recommendation)
            HapticManager.shared.playSelection()
        }
    }
    
    // MARK: - Helper Methods
    
    private var percentageText: String {
        // Calculate percentage relative to the period duration
        let periodMinutes: Double = {
            switch viewModel.selectedPeriod {
            case .day: return 24 * 60 // 1,440 minutes in a day
            case .month: return 30 * 24 * 60 // ~43,200 minutes in a month
            case .year: return 365 * 24 * 60 // ~525,600 minutes in a year
            }
        }()
        
        let percentage = (abs(viewModel.totalImpactForPeriod) / periodMinutes) * 100
        let sign = viewModel.totalImpactForPeriod >= 0 ? "+" : ""
        
        if percentage < 0.01 {
            return "\(sign)<0.01%"
        } else {
            return String(format: "%@%.2f%%", sign, percentage)
        }
    }
    
    private func formatMetricValue(_ value: Double) -> String {
        switch metric.type {
        case .steps:
            return "\(Int(value))"
        case .sleepHours:
            return String(format: "%.1f", value)
        case .exerciseMinutes:
            return "\(Int(value))"
        case .heartRateVariability:
            return "\(Int(value))"
        case .restingHeartRate:
            return "\(Int(value))"
        default:
            return String(format: "%.1f", value)
        }
    }
    
    private func formatImpactTime(_ minutes: Double) -> String {
        let absMinutes = abs(minutes)
        let sign = minutes >= 0 ? "+" : "-"
        
        if absMinutes >= 1440 { // Days
            let days = absMinutes / 1440
            let singularOrPlural = days == 1.0 ? "day added" : "days added"
            let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
            if minutes < 0 {
                let singularOrPlural = days == 1.0 ? "day lost" : "days lost"
                return "\(valueString) \(singularOrPlural)"
            }
            return "\(sign)\(valueString) \(singularOrPlural)"
        } else if absMinutes >= 60 { // Hours
            let hours = absMinutes / 60
            let singularOrPlural = hours == 1.0 ? "hour added" : "hours added"
            let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
            if minutes < 0 {
                let singularOrPlural = hours == 1.0 ? "hour lost" : "hours lost"
                return "\(valueString) \(singularOrPlural)"
            }
            return "\(sign)\(valueString) \(singularOrPlural)"
        } else {
            let singularOrPlural = absMinutes == 1.0 ? "minute added" : "minutes added"
            if minutes < 0 {
                let singularOrPlural = absMinutes == 1.0 ? "minute lost" : "minutes lost"
                return String(format: "%.0f %@", absMinutes, singularOrPlural)
            }
            return String(format: "%@%.0f %@", sign, absMinutes, singularOrPlural)
        }
    }
    
    private func formatImpactDisplay(_ minutes: Double) -> String {
        return formatImpactTime(minutes)
    }
    
    private func getMetricContext() -> String {
        switch metric.type {
        case .steps:
            switch viewModel.selectedPeriod {
            case .day: return "steps today"
            case .month: return "daily avg"
            case .year: return "daily avg per month"
            }
        case .sleepHours:
            switch viewModel.selectedPeriod {
            case .day: return "last night"
            case .month: return "nightly avg"
            case .year: return "nightly avg per month"
            }
        case .exerciseMinutes:
            switch viewModel.selectedPeriod {
            case .day: return "active today"
            case .month: return "daily avg"
            case .year: return "daily avg per month"
            }
        case .heartRateVariability:
            switch viewModel.selectedPeriod {
            case .day: return "current HRV"
            case .month: return "avg HRV"
            case .year: return "avg HRV per month"
            }
        case .restingHeartRate:
            switch viewModel.selectedPeriod {
            case .day: return "current rate"
            case .month: return "avg rate"
            case .year: return "avg rate per month"
            }
        case .bodyMass:
            return "current weight"
        case .activeEnergyBurned:
            switch viewModel.selectedPeriod {
            case .day: return "calories today"
            case .month: return "daily avg"
            case .year: return "daily avg per month"
            }
        case .vo2Max:
            return "fitness level"
        case .oxygenSaturation:
            return "oxygen level"
        case .nutritionQuality:
            return "nutrition score"
        case .smokingStatus:
            return "smoking score"
        case .alcoholConsumption:
            return "alcohol score"
        case .socialConnectionsQuality:
            return "social score"
        case .stressLevel:
            return "stress level"
        }
    }
    
    private func getUnitString() -> String {
        switch metric.type {
        case .steps:
            return "steps"
        case .sleepHours:
            return "hours"
        case .exerciseMinutes:
            return "minutes"
        case .heartRateVariability:
            return "ms"
        case .restingHeartRate:
            return "bpm"
        case .bodyMass:
            return "lbs"
        case .activeEnergyBurned:
            return "cal"
        case .vo2Max:
            return "mL/kg/min"
        case .oxygenSaturation:
            return "%"
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return "score"
        }
    }
    
    private func getQuickInsight() -> String? {
        // Provide a simple, understandable insight based on the metric
        switch metric.type {
        case .restingHeartRate:
            if metric.value < 60 {
                return "Great! Your heart is very efficient, like an athlete's."
            } else if metric.value > 80 {
                return "Your heart is working harder than optimal. Regular cardio can help."
            }
        case .steps:
            if metric.value < 5000 {
                return "You're below the recommended daily steps. Even small walks help!"
            } else if metric.value > 10000 {
                return "Excellent! You're exceeding the daily recommendation."
            }
        case .sleepHours:
            if metric.value < 6 {
                return "You're not getting enough sleep. Aim for 7-9 hours."
            } else if metric.value > 9 {
                return "You might be oversleeping. 7-9 hours is optimal for most adults."
            }
        default:
            return nil
        }
        return nil
    }
    
    private func setupNavigationBar() {
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
    }
}

#Preview {
    NavigationView {
        MetricDetailView(metric: HealthMetric.sample(type: .steps, value: 8750))
    }
} 