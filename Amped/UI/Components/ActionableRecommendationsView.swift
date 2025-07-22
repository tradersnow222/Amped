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
    private let recommendationService: RecommendationService
    private let userProfile: UserProfile
    
    init(metrics: [HealthMetric], selectedPeriod: ImpactDataPoint.PeriodType, onMetricTap: @escaping (HealthMetric) -> Void) {
        self.metrics = metrics
        self.selectedPeriod = selectedPeriod
        self.onMetricTap = onMetricTap
        
        // Initialize with actual user profile
        self.userProfile = UserProfile()
        self.lifeImpactService = LifeImpactService(userProfile: userProfile)
        self.recommendationService = RecommendationService(userProfile: userProfile)
    }
    
    // Get the most impactful metric to recommend improvement for
    private var primaryRecommendationMetric: HealthMetric? {
        // PRINCIPLE 1: If there are negative metrics, prioritize the worst one to bring to neutral
        let allNegativeMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) < 0 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let worstNegativeMetric = allNegativeMetrics.first {
            return worstNegativeMetric
        }
        
        // PRINCIPLE 2: If no negative metrics, take the lowest positive metric for 20% improvement
        let allPositiveMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) > 0 }
            .sorted { ($0.impactDetails?.lifespanImpactMinutes ?? 0) < ($1.impactDetails?.lifespanImpactMinutes ?? 0) } // LOWEST first
        
        if let lowestPositiveMetric = allPositiveMetrics.first {
            return lowestPositiveMetric
        }
        
        // Fallback: Neutral metrics or metrics without impact details
        let neutralOrUnknownMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) == 0 || $0.impactDetails == nil }
        
        return neutralOrUnknownMetrics.first
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
        // Use the RecommendationService for accurate, contextual recommendations
        return recommendationService.generateRecommendation(for: metric, selectedPeriod: selectedPeriod)
    }
    
    private func timeImpactText(for metric: HealthMetric) -> String {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else { return "" }
        
        let sign = impact >= 0 ? "+" : "-"
        return "\(sign)\(abs(impact).formattedAsTimeShort())"
    }
    
    private func benefitText(for metric: HealthMetric) -> String {
        // Since actionText now includes the benefit, return empty string
        // The RecommendationService handles all the calculation and formatting
        return ""
    }
    
    /// Calculate potential DAILY benefit for specific improvements using research-based models
    /// CRITICAL: Returns daily benefit only - no period scaling should be applied to non-linear models
    private func calculatePotentialBenefit(for metric: HealthMetric) -> Double {
        let currentImpact = lifeImpactService.calculateImpact(for: metric)
        
        // Create improved metric based on specific, achievable improvements
        let improvedMetric: HealthMetric
        
        switch metric.type {
        case .steps:
            // Calculate benefit of adding realistic step improvement (20-minute walk)
            let currentSteps = metric.value
            // 20-minute walk = ~2000-2500 steps. Use conservative 2000 for realistic calculation
            let stepImprovement: Double = 2000 
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .steps,
                value: currentSteps + stepImprovement,
                date: metric.date,
                source: metric.source
            )
            
        case .exerciseMinutes:
            // Calculate benefit of adding 30 minutes of exercise weekly
            // Convert to daily equivalent: 30 min/week = ~4.3 min/day
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .exerciseMinutes,
                value: metric.value + (30.0 / 7.0), // Weekly 30 min as daily average
                date: metric.date,
                source: metric.source
            )
            
        case .sleepHours:
            // Calculate benefit of improving sleep by realistic amount
            let currentSleep = metric.value
            let improvementAmount: Double
            if currentSleep < 6 {
                improvementAmount = 1.0 // Bigger improvement for very poor sleep
            } else if currentSleep < 7.5 {
                improvementAmount = 0.5 // Moderate improvement
            } else {
                improvementAmount = 0.25 // Small optimization for already good sleep
            }
            
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: min(9.0, currentSleep + improvementAmount), // Cap at 9 hours
                date: metric.date,
                source: metric.source
            )
            
        case .restingHeartRate:
            // Calculate benefit of reducing RHR by achievable amount
            let currentRHR = metric.value
            let reduction: Double
            if currentRHR > 80 {
                reduction = 10.0 // Larger reduction for high RHR
            } else if currentRHR > 70 {
                reduction = 5.0 // Moderate reduction
            } else {
                reduction = 2.0 // Small improvement for already good RHR
            }
            
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: .restingHeartRate,
                value: max(50, currentRHR - reduction), // Don't go below 50 bpm
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
            // Generic 5% improvement for other metrics (more conservative)
            improvedMetric = HealthMetric(
                id: UUID().uuidString,
                type: metric.type,
                value: metric.value * 1.05,
                date: metric.date,
                source: metric.source
            )
        }
        
        // Calculate impact difference using the research-based formulas
        let improvedImpact = lifeImpactService.calculateImpact(for: improvedMetric)
        let benefitMinutes = improvedImpact.lifespanImpactMinutes - currentImpact.lifespanImpactMinutes
        
        // CRITICAL: This returns DAILY benefit only - never scale for non-linear models
        return max(0.0, benefitMinutes)
    }
    
    /// Format time impact for display
    private func formatTimeImpact(_ minutes: Double) -> String {
        return minutes.formattedAsTimeShort()
    }
    
    /// Build one elegant sentence using the RecommendationService with colored benefit text
    private func buildActionSentence(for metric: HealthMetric) -> Text {
        let recommendationText = actionText(for: metric)
        
        // Parse the recommendation text to identify and color the benefit portion
        return parseAndColorRecommendationText(recommendationText)
    }
    
    /// Parse recommendation text and apply green color to positive benefit portions
    private func parseAndColorRecommendationText(_ text: String) -> Text {
        // Pattern: "Action to add X time" where X time should be green
        let patterns = [
            " to add ", " to gain ", " benefit of "
        ]
        
        var result = Text("")
        var remainingText = text
        
        // Find the pattern that splits the action from the benefit
        for pattern in patterns {
            if let range = remainingText.range(of: pattern) {
                let beforePattern = String(remainingText[..<range.lowerBound])
                let afterPattern = String(remainingText[range.upperBound...])
                
                // Add the text before the pattern (action part)
                result = result + Text(beforePattern).style(.body)
                
                // Add the pattern itself
                result = result + Text(pattern).style(.body)
                
                // Parse the benefit part and color positive values green
                let benefitText = parseBenefitText(afterPattern)
                result = result + benefitText
                
                return result
            }
        }
        
        // If no pattern found, return the original text
        return Text(text).style(.body)
    }
    
    /// Parse benefit text and apply green color to positive time values
    private func parseBenefitText(_ benefitText: String) -> Text {
        // Combined pattern to match all time values in one regex
        let timePattern = #"\d+\.?\d*\s+(min|mins|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years)\b"#
        
        var result = Text("")
        var remainingText = benefitText
        var lastProcessedIndex = benefitText.startIndex
        
        do {
            let regex = try NSRegularExpression(pattern: timePattern, options: [.caseInsensitive])
            let range = NSRange(benefitText.startIndex..., in: benefitText)
            let matches = regex.matches(in: benefitText, options: [], range: range)
            
            for match in matches {
                guard let matchRange = Range(match.range, in: benefitText) else { continue }
                
                // Add text before the match (in default color)
                let beforeMatch = String(benefitText[lastProcessedIndex..<matchRange.lowerBound])
                if !beforeMatch.isEmpty {
                    result = result + Text(beforeMatch).style(.body)
                }
                
                // Add the matched time value in green
                let timeValue = String(benefitText[matchRange])
                result = result + Text(timeValue).style(.body, color: .ampedGreen)
                
                lastProcessedIndex = matchRange.upperBound
            }
            
            // Add any remaining text after the last match
            let remainingAfterLastMatch = String(benefitText[lastProcessedIndex...])
            if !remainingAfterLastMatch.isEmpty {
                result = result + Text(remainingAfterLastMatch).style(.body)
            }
            
            return result
            
        } catch {
            // If regex fails, return original text
            return Text(benefitText).style(.body)
        }
    }
}
