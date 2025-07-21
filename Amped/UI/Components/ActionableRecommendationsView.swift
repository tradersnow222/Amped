import SwiftUI
import CoreHaptics

/// Actionable Recommendations View - Redesigned for Apple-level sophistication
struct ActionableRecommendationsView: View {
    let metrics: [HealthMetric]
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onMetricTap: (HealthMetric) -> Void
    @State private var showContent = false
    @Environment(\.glassTheme) private var glassTheme
    
    // Initialize services for accurate calculations
    private let lifeImpactService: LifeImpactService
    private let userProfile: UserProfile
    
    init(metrics: [HealthMetric], selectedPeriod: ImpactDataPoint.PeriodType, onMetricTap: @escaping (HealthMetric) -> Void) {
        self.metrics = metrics
        self.selectedPeriod = selectedPeriod
        self.onMetricTap = onMetricTap
        
        // Initialize with actual user profile
        self.userProfile = UserProfile()
        self.lifeImpactService = LifeImpactService(userProfile: userProfile)
    }
    
    // Get the most impactful metric to recommend improvement for
    private var primaryRecommendationMetric: HealthMetric? {
        // First, prioritize HealthKit metrics with significant negative impact (> 30 minutes lost)
        let significantNegativeHealthKitMetrics = metrics
            .filter { $0.source != .userInput && ($0.impactDetails?.lifespanImpactMinutes ?? 0) < -30 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let worstHealthKitMetric = significantNegativeHealthKitMetrics.first {
            return worstHealthKitMetric
        }
        
        // If no significant negative HealthKit metrics, look for any negative HealthKit metrics
        let negativeHealthKitMetrics = metrics
            .filter { $0.source != .userInput && ($0.impactDetails?.lifespanImpactMinutes ?? 0) < 0 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let negativeHealthKitMetric = negativeHealthKitMetrics.first {
            return negativeHealthKitMetric
        }
        
        // If all metrics are positive, find the best one to improve further
        let positiveHealthKitMetrics = metrics
            .filter { $0.source != .userInput && ($0.impactDetails?.lifespanImpactMinutes ?? 0) > 0 }
            .sorted { ($0.impactDetails?.lifespanImpactMinutes ?? 0) > ($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let bestPositiveMetric = positiveHealthKitMetrics.first {
            return bestPositiveMetric
        }
        
        // Fall back to questionnaire metrics that could be improved (rating < 8)
        let improvableQuestionnaireMetrics = metrics
            .filter { $0.source == .userInput && $0.value < 8 }
            .sorted { $0.value < $1.value } // Lowest rating first
        
        return improvableQuestionnaireMetrics.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let metric = primaryRecommendationMetric {
                recommendationCard(for: metric)
            }
        }
    }
    
    // MARK: - Component Views
    
    private func recommendationCard(for metric: HealthMetric) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Today's Focus")
                .style(.headlineBold)
                .padding(.bottom, 16)
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                // First line: Icon + Metric Name + Impact
                HStack(spacing: 12) {
                    Image(systemName: iconName(for: metric.type))
                        .foregroundColor(iconColor(for: metric))
                        .font(.system(size: 20))
                        .frame(width: 24, height: 24)
                    
                    Text(metric.type.displayName)
                        .style(.bodyMedium)
                    
                    Text(timeImpactText(for: metric))
                        .style(.bodyMedium, color: timeImpactColor(for: metric))
                    
                    Spacer()
                }
                
                // Second line: Complete action sentence
                HStack {
                    buildActionSentence(for: metric)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .opacity(showContent ? 1.0 : 0.0)
        .scaleEffect(showContent ? 1.0 : 0.95, anchor: .top)
        .animation(.easeOut(duration: 0.6), value: showContent)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showContent = true
            }
        }
        .onTapGesture {
            onMetricTap(metric)
            HapticManager.shared.playSelection()
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconName(for type: HealthMetricType) -> String {
        switch type {
        case .steps: return "figure.walk"
        case .exerciseMinutes: return "figure.run"
        case .sleepHours: return "moon.fill"
        case .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .bodyMass: return "scalemass.fill"
        case .nutritionQuality: return "leaf.fill"
        case .smokingStatus: return "lungs.fill"
        case .alcoholConsumption: return "wineglass.fill"
        case .socialConnectionsQuality: return "person.2.fill"
        case .stressLevel: return "brain.head.profile"
        default: return "circle.fill"
        }
    }
    
    private func iconColor(for metric: HealthMetric) -> Color {
        let impact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        return impact >= 0 ? .ampedGreen : .ampedRed
    }
    
    private func timeImpactColor(for metric: HealthMetric) -> Color {
        let impact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        return impact >= 0 ? .ampedGreen : .ampedRed
    }
    
    private func benefitColor(for metric: HealthMetric) -> Color {
        // For the benefit text, we want to show green if there's a potential positive impact
        return .ampedGreen
    }
    
    private func actionText(for metric: HealthMetric) -> String {
        let baseAction: String
        
        switch metric.type {
        case .steps:
            baseAction = selectedPeriod == .day ? 
                "Take a 20-minute walk today to add" :
                "Walk 20 minutes daily to add"
        case .exerciseMinutes:
            baseAction = selectedPeriod == .day ?
                "Add 30 minutes of exercise today to add" :
                "Exercise 30 minutes daily to add"
        case .sleepHours:
            baseAction = selectedPeriod == .day ?
                "Get better sleep tonight to add" :
                "Improve sleep quality daily to add"
        case .restingHeartRate:
            baseAction = selectedPeriod == .day ?
                "Practice deep breathing today to add" :
                "Practice daily breathing exercises to add"
        case .nutritionQuality:
            baseAction = selectedPeriod == .day ?
                "Eat nutritious meals today to add" :
                "Maintain healthy eating daily to add"
        case .smokingStatus:
            baseAction = selectedPeriod == .day ?
                "Take steps to quit smoking to add" :
                "Work on quitting smoking to add"
        case .alcoholConsumption:
            baseAction = selectedPeriod == .day ?
                "Reduce alcohol today to add" :
                "Limit alcohol daily to add"
        case .socialConnectionsQuality:
            baseAction = selectedPeriod == .day ?
                "Connect with others today to add" :
                "Maintain social connections to add"
        case .stressLevel:
            baseAction = selectedPeriod == .day ?
                "Try meditation today to add" :
                "Practice stress management daily to add"
        default:
            baseAction = selectedPeriod == .day ?
                "Improve your \(metric.type.displayName.lowercased()) today to add" :
                "Maintain better \(metric.type.displayName.lowercased()) daily to add"
        }
        
        return baseAction
    }
    
    private func timeImpactText(for metric: HealthMetric) -> String {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else { return "" }
        
        // Individual metrics now always contain daily impact (fixed in HealthDataService)
        let absMinutes = abs(impact)
        let sign = impact >= 0 ? "+" : "-"
        
        if absMinutes >= 60 {
            let hours = absMinutes / 60
            return String(format: "%@%.1f h", sign, hours)
        } else if absMinutes >= 1 {
            let roundedMinutes = Int(round(absMinutes))
            return "\(sign)\(roundedMinutes) min"
        } else {
            return "\(sign)1 min"
        }
    }
    
    private func benefitText(for metric: HealthMetric) -> String {
        let dailyBenefit = calculatePotentialBenefit(for: metric)
        
        // Scale benefit based on selected period
        let scaledBenefit: Double
        let periodSuffix: String
        
        switch selectedPeriod {
        case .day:
            scaledBenefit = dailyBenefit
            periodSuffix = ""
        case .month:
            scaledBenefit = dailyBenefit * 30
            periodSuffix = " over the next month"
        case .year:
            scaledBenefit = dailyBenefit * 365
            periodSuffix = " over the next year"
        }
        
        // Format the time appropriately
        let timeText = formatTimeImpact(scaledBenefit)
        return "+\(timeText)\(periodSuffix)"
    }
    
    /// Calculate realistic potential benefit for specific improvements
    private func calculatePotentialBenefit(for metric: HealthMetric) -> Double {
        // Create a hypothetical improved metric to calculate benefit
        let improvedMetric: HealthMetric
        
        switch metric.type {
        case .steps:
            // Calculate benefit of adding ~3000 steps (20-minute walk)
            let currentSteps = metric.value
            let improvedSteps = currentSteps + 3000 // Approximate steps in 20-minute walk
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .steps,
                value: improvedSteps,
                date: metric.date,
                source: metric.source
            )
            
        case .exerciseMinutes:
            // Calculate benefit of adding 30 minutes of exercise
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .exerciseMinutes,
                value: metric.value + 30,
                date: metric.date,
                source: metric.source
            )
            
        case .sleepHours:
            // Calculate benefit of improving sleep by 1 hour (if currently < 8)
            let improvementAmount = metric.value < 8 ? min(1.0, 8.0 - metric.value) : 0.5
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: metric.value + improvementAmount,
                date: metric.date,
                source: metric.source
            )
            
        case .restingHeartRate:
            // Calculate benefit of reducing RHR by 5 bpm (achievable with conditioning)
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .restingHeartRate,
                value: max(50, metric.value - 5),
                date: metric.date,
                source: metric.source
            )
            
        case .nutritionQuality:
            // Calculate benefit of improving nutrition score by 1 point
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .nutritionQuality,
                value: min(10, metric.value + 1),
                date: metric.date,
                source: metric.source
            )
            
        case .stressLevel:
            // Calculate benefit of reducing stress by 1 point  
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .stressLevel,
                value: max(1, metric.value - 1),
                date: metric.date,
                source: metric.source
            )
            
        case .alcoholConsumption:
            // Calculate benefit of reducing alcohol by 0.5 drinks/day
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .alcoholConsumption,
                value: max(0, metric.value - 0.5),
                date: metric.date,
                source: metric.source
            )
            
        case .socialConnectionsQuality:
            // Calculate benefit of improving social connections by 0.5 points
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .socialConnectionsQuality,
                value: min(10, metric.value + 0.5),
                date: metric.date,
                source: metric.source
            )
            
        case .smokingStatus:
            // Calculate benefit of quitting smoking (if currently smoking)
            let quitValue: Double = metric.value > 5 ? 1 : metric.value // 1 = non-smoker
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .smokingStatus,
                value: quitValue,
                date: metric.date,
                source: metric.source
            )
            
        default:
            // Generic 10% improvement for other metrics
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: metric.type,
                value: metric.value * 1.1,
                date: metric.date,
                source: metric.source
            )
        }
        
        // Calculate impact difference
        let currentImpact = lifeImpactService.calculateImpact(for: metric)
        let improvedImpact = lifeImpactService.calculateImpact(for: improvedMetric)
        
        let benefitMinutes = improvedImpact.lifespanImpactMinutes - currentImpact.lifespanImpactMinutes
        
        // Ensure minimum realistic benefit (at least 5 minutes for any positive action)
        return max(5.0, benefitMinutes)
    }
    
    /// Format time impact for display
    private func formatTimeImpact(_ minutes: Double) -> String {
        let absMinutes = abs(minutes)
        
        if absMinutes >= 10080 { // More than a week
            let weeks = absMinutes / 10080
            return String(format: "%.1f weeks", weeks)
        } else if absMinutes >= 1440 { // More than a day
            let days = absMinutes / 1440
            return String(format: "%.1f days", days)
        } else if absMinutes >= 60 {
            let hours = absMinutes / 60
            return String(format: "%.1f h", hours)
        } else {
            let roundedMinutes = Int(round(absMinutes))
            return "\(roundedMinutes) min"
        }
    }
    
    /// Build one elegant sentence combining action and benefit with styled text
    private func buildActionSentence(for metric: HealthMetric) -> Text {
        let dailyBenefit = calculatePotentialBenefit(for: metric)
        
        // Scale benefit based on selected period
        let scaledBenefit: Double
        let periodSuffix: String
        
        switch selectedPeriod {
        case .day:
            scaledBenefit = dailyBenefit
            periodSuffix = ""
        case .month:
            scaledBenefit = dailyBenefit * 30
            periodSuffix = " over the next month"
        case .year:
            scaledBenefit = dailyBenefit * 365
            periodSuffix = " over the next year"
        }
        
        // Get action text without "to add"
        let baseAction: String
        
        switch metric.type {
        case .steps:
            baseAction = selectedPeriod == .day ? 
                "Take a 20-minute walk today" :
                "Walk 20 minutes daily"
        case .exerciseMinutes:
            baseAction = selectedPeriod == .day ?
                "Add 30 minutes of exercise today" :
                "Exercise 30 minutes daily"
        case .sleepHours:
            baseAction = selectedPeriod == .day ?
                "Get better sleep tonight" :
                "Improve sleep quality daily"
        case .restingHeartRate:
            baseAction = selectedPeriod == .day ?
                "Practice deep breathing today" :
                "Practice daily breathing exercises"
        case .nutritionQuality:
            baseAction = selectedPeriod == .day ?
                "Eat nutritious meals today" :
                "Maintain healthy eating daily"
        case .smokingStatus:
            baseAction = selectedPeriod == .day ?
                "Take steps to quit smoking" :
                "Work on quitting smoking"
        case .alcoholConsumption:
            baseAction = selectedPeriod == .day ?
                "Reduce alcohol today" :
                "Limit alcohol daily"
        case .socialConnectionsQuality:
            baseAction = selectedPeriod == .day ?
                "Connect with others today" :
                "Maintain social connections"
        case .stressLevel:
            baseAction = selectedPeriod == .day ?
                "Try meditation today" :
                "Practice stress management daily"
        default:
            baseAction = selectedPeriod == .day ?
                "Improve your \(metric.type.displayName.lowercased()) today" :
                "Maintain better \(metric.type.displayName.lowercased()) daily"
        }
        
        // Format the time benefit (without + sign)
        let timeText = formatTimeImpact(scaledBenefit)
        
        // Build the complete sentence with styled text
        return Text(baseAction + " to add ")
            .style(.body, color: .primary) +
        Text(timeText)
            .style(.body, color: .ampedGreen) +
        Text(periodSuffix)
            .style(.body, color: .primary)
    }
}
