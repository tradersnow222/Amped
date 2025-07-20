import SwiftUI
import CoreHaptics

/// Actionable Recommendations View - Redesigned for Apple-level sophistication
struct ActionableRecommendationsView: View {
    let metrics: [HealthMetric]
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onMetricTap: (HealthMetric) -> Void
    @State private var showContent = false
    @Environment(\.glassTheme) private var glassTheme
    
    // Initialize recommendation service
    private let recommendationService = RecommendationService(userProfile: UserProfile())
    
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
                
                // Second line: Action text + Benefit
                HStack(spacing: 4) {
                    Text(actionText(for: metric))
                        .style(.body, color: .primary)
                    
                    Text(benefitText(for: metric))
                        .style(.body, color: benefitColor(for: metric))
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .glassBackground(.ultraThin, cornerRadius: 16)
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
        switch metric.type {
        case .steps:
            return "Take a 30-minute walk today"
        case .exerciseMinutes:
            return "Add 30 minutes of exercise"
        case .sleepHours:
            return "Get better sleep tonight"
        case .restingHeartRate:
            return "Practice deep breathing"
        case .nutritionQuality:
            return "Eat more nutritious meals"
        case .smokingStatus:
            return "Consider quitting smoking"
        case .alcoholConsumption:
            return "Reduce alcohol intake"
        case .socialConnectionsQuality:
            return "Connect with others today"
        case .stressLevel:
            return "Try meditation or yoga"
        default:
            return "Improve your \(metric.type.displayName.lowercased())"
        }
    }
    
    private func timeImpactText(for metric: HealthMetric) -> String {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else { return "" }
        
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
        // Calculate potential benefit based on metric type
        switch metric.type {
        case .steps:
            return "+13 min"
        case .exerciseMinutes:
            return "+30 min"
        case .sleepHours:
            return "+45 min"
        case .restingHeartRate:
            return "+13 min"
        case .nutritionQuality:
            return "+20 min"
        case .smokingStatus:
            return "+2 hours"
        case .alcoholConsumption:
            return "+15 min"
        case .socialConnectionsQuality:
            return "+25 min"
        case .stressLevel:
            return "+20 min"
        default:
            return "+15 min"
        }
    }
} 