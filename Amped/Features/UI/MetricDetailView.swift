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
    @State private var selectedImpactDataPoint: ChartImpactDataPoint?  // For impact chart
    @State private var isDragging = false
    @State private var showingDescriptionToast = false
    
    // Convenience property for accessing current metric (always the original daily metric)
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
                .padding(.bottom, 16)
                
                // Compact "What is X?" button
                Button(action: {
                    showingDescriptionToast = true
                }) {
                    HStack(spacing: 6) {
                        Text("What \(metric.type.isPlural ? "are" : "is") \(metric.type.displayName.lowercased())?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .hapticFeedback()
                .padding(.bottom, 24)
                
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
        }
        .overlay {
            if showingDescriptionToast {
                DescriptionToast(
                    metricName: metric.type.displayName,
                    description: getMetricDescription(),
                    isPresented: $showingDescriptionToast
                )
            }
        }
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(spacing: 0) {
            // Metric value and impact integrated at top of chart
            HStack(alignment: .top) {
                // Current metric value with units
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatMetricValueWithUnit(viewModel.displayMetricValue))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(getMetricContext())
                        .style(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Impact display - simplified to show only the clear time impact
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatImpactDisplay(viewModel.totalImpactForPeriod))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.totalImpactForPeriod >= 0 ? .ampedGreen : .ampedRed)
                    
                    Text("total impact")
                        .style(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 20)
            
            // Impact chart - Rule: Simplicity is KING
            if !viewModel.impactChartDataPoints.isEmpty {
                ImpactMetricChart(
                    metricType: metric.type,
                    dataPoints: viewModel.impactChartDataPoints,
                    period: viewModel.selectedPeriod,
                    selectedDataPoint: $selectedImpactDataPoint,
                    isDragging: $isDragging
                )
                .frame(height: 200)
            } else {
                // Show loading or empty state
                Text("Loading impact data...")
                    .style(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(height: 200)
            }
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
                .fill(.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .onTapGesture {
            viewModel.logRecommendationAction(recommendation)
            HapticManager.shared.playSelection()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatMetricValueWithUnit(_ value: Double) -> String {
        // CRITICAL FIX: Simplify display - no totals, just clear values
        // Rule: Simplicity is KING - Steve Jobs principle
        
        switch metric.type {
        case .steps:
            return "\(Int(value)) steps"
        case .sleepHours:
            return String(format: "%.1f hrs", value)
        case .exerciseMinutes:
            return "\(Int(value)) min"
        case .heartRateVariability:
            return "\(Int(value)) ms"
        case .restingHeartRate:
            return "\(Int(value)) bpm"
        case .bodyMass:
            // Value is stored in kg internally, convert if user wants imperial
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            let displayValue = useMetric ? value : value * 2.20462
            let unit = useMetric ? "kg" : "lbs"
            return String(format: "%.1f %@", displayValue, unit)
        case .activeEnergyBurned:
            return "\(Int(value)) cal"
        case .vo2Max:
            return String(format: "%.1f mL/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.0f%%", value)
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return String(format: "%.1f score", value)
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
        } else if absMinutes >= 1.0 {
            let singularOrPlural = absMinutes == 1.0 ? "minute added" : "minutes added"
            if minutes < 0 {
                let singularOrPlural = absMinutes == 1.0 ? "minute lost" : "minutes lost"
                return String(format: "%.0f %@", absMinutes, singularOrPlural)
            }
            return String(format: "%@%.0f %@", sign, absMinutes, singularOrPlural)
        } else {
            // For values less than 1 minute, show as 0 for display purposes
            // (actual calculations remain unchanged)
            if minutes < 0 {
                return "0 lost"
            }
            return "0 added"
        }
    }
    
    private func formatImpactDisplay(_ minutes: Double) -> String {
        return formatImpactTime(minutes)
    }
    
    private func getMetricContext() -> String {
        switch metric.type {
        case .steps:
            switch viewModel.selectedPeriod {
            case .day: return "today"
            case .month: return "daily avg"
            case .year: return "daily avg"
            }
        case .sleepHours:
            switch viewModel.selectedPeriod {
            case .day: return "last night"
            case .month: return "nightly avg"
            case .year: return "nightly avg"
            }
        case .exerciseMinutes:
            switch viewModel.selectedPeriod {
            case .day: return "today"
            case .month: return "daily avg"
            case .year: return "daily avg"
            }
        case .heartRateVariability:
            switch viewModel.selectedPeriod {
            case .day: return "current"
            case .month: return "avg"
            case .year: return "avg"
            }
        case .restingHeartRate:
            switch viewModel.selectedPeriod {
            case .day: return "current"
            case .month: return "avg"
            case .year: return "avg"
            }
        case .bodyMass:
            switch viewModel.selectedPeriod {
            case .day: return "today"
            case .month: return "avg"
            case .year: return "avg"
            }
        case .activeEnergyBurned:
            switch viewModel.selectedPeriod {
            case .day: return "today"
            case .month: return "daily avg"
            case .year: return "daily avg"
            }
        case .vo2Max:
            return "fitness level"
        case .oxygenSaturation:
            return "current level"
        case .nutritionQuality:
            return "current score"
        case .smokingStatus:
            return "current score"
        case .alcoholConsumption:
            return "current score"
        case .socialConnectionsQuality:
            return "current score"
        case .stressLevel:
            return "current level"
        }
    }
    
    private func getMetricDescription() -> String {
        switch metric.type {
        case .steps:
            return "Steps track how much you walk and move around each day. Taking more steps helps keep your heart healthy, gives you energy, and can help you feel better overall. Every step counts toward a healthier you."
        case .sleepHours:
            return "Sleep hours show how long you slept last night. Getting enough good sleep helps your body heal, your brain work better, and keeps you feeling strong. Most adults need 7-9 hours of sleep each night to feel their best."
        case .exerciseMinutes:
            return "Exercise minutes track how much you moved your body today. Moving more makes your heart stronger, helps you feel happier, and gives you more energy. Even small amounts of movement like walking count toward better health."
        case .heartRateVariability:
            return "Heart rate variability measures how your heartbeat changes slightly between each beat. When this number is higher, it usually means your body is good at handling stress and recovering from exercise. It's like checking how flexible your heart is."
        case .restingHeartRate:
            return "Resting heart rate is how fast your heart beats when you're sitting quietly. A lower number usually means your heart is strong and doesn't have to work as hard to pump blood around your body. It's like measuring how efficient your heart engine is."
        case .bodyMass:
            return "Weight is how much your body weighs right now. Keeping a healthy weight helps protect you from heart disease, diabetes, and many other health problems. This number can change based on what you eat, how much you move, and how your body feels."
        case .activeEnergyBurned:
            return "Active calories show how much energy you burned by moving around today. This includes walking, exercise, and any activity that gets your body moving. Burning more active calories means you're giving your body the movement it needs to stay healthy."
        case .vo2Max:
            return "VO2 Max measures how well your body can use oxygen during exercise. Think of it like checking how powerful your body's engine is. A higher number means your heart, lungs, and muscles work really well together when you're active."
        case .oxygenSaturation:
            return "Oxygen saturation shows how much oxygen is in your blood right now. Your body needs oxygen to work properly, and healthy levels are usually between 95-100%. It's like checking how well your body is getting the air it needs."
        case .nutritionQuality:
            return "Nutrition quality looks at how healthy your food choices are. Eating more fruits, vegetables, and whole foods while having less processed food helps your body get the nutrients it needs to work its best and fight off illness."
        case .smokingStatus:
            return "Smoking status tracks your tobacco use. Not smoking is one of the best things you can do for your health. It helps your lungs work better, reduces your risk of cancer and heart disease, and helps you live longer."
        case .alcoholConsumption:
            return "Alcohol consumption tracks how much alcohol you drink. Having little to no alcohol helps your liver stay healthy, improves your sleep, and reduces your risk of many health problems. Your body works better when it doesn't have to process alcohol."
        case .socialConnectionsQuality:
            return "Social connections measure the quality of your relationships with family and friends. Having people you can talk to and spend time with helps you feel happier, less stressed, and can even help you live longer. Good relationships are like medicine for your mind and body."
        case .stressLevel:
            return "Stress level shows how much daily pressure and worry you feel. When stress is lower, your body can focus on healing, your sleep gets better, and you feel more relaxed. Managing stress helps your whole body work better."
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