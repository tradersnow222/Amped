import SwiftUI
import CoreHaptics
import OSLog

/// Actionable Recommendations View - Redesigned for instant comprehension
struct ActionableRecommendationsView: View {
    let metrics: [HealthMetric]
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onMetricTap: (HealthMetric) -> Void
    @State private var showContent = false
    @GestureState private var isPressed = false
    @Environment(\.glassTheme) private var glassTheme
    
    // MARK: - Logging
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "ActionableRecommendationsView")
    
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
        logger.info("🎯 Finding primary recommendation metric from \(metrics.count) available metrics")
        
        // PRINCIPLE 1: If there are negative metrics, prioritize the worst one to bring to neutral
        let allNegativeMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) < 0 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        logger.info("📉 Found \(allNegativeMetrics.count) negative impact metrics:")
        for (index, metric) in allNegativeMetrics.enumerated() {
            let impact = metric.impactDetails?.lifespanImpactMinutes ?? 0
            logger.info("  \(index + 1). \(metric.type.displayName): \(String(format: "%.1f", impact)) min/day")
        }
        
        if let worstNegativeMetric = allNegativeMetrics.first {
            let impact = worstNegativeMetric.impactDetails?.lifespanImpactMinutes ?? 0
            logger.info("✅ Selected worst negative metric: \(worstNegativeMetric.type.displayName) (\(String(format: "%.1f", impact)) min/day)")
            return worstNegativeMetric
        }
        
        // PRINCIPLE 2: If no negative metrics, take the lowest positive metric for 20% improvement
        let allPositiveMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) > 0 }
            .sorted { ($0.impactDetails?.lifespanImpactMinutes ?? 0) < ($1.impactDetails?.lifespanImpactMinutes ?? 0) } // LOWEST first
        
        logger.info("📈 Found \(allPositiveMetrics.count) positive impact metrics:")
        for (index, metric) in allPositiveMetrics.enumerated() {
            let impact = metric.impactDetails?.lifespanImpactMinutes ?? 0
            logger.info("  \(index + 1). \(metric.type.displayName): \(String(format: "%.1f", impact)) min/day")
        }
        
        if let lowestPositiveMetric = allPositiveMetrics.first {
            let impact = lowestPositiveMetric.impactDetails?.lifespanImpactMinutes ?? 0
            logger.info("✅ Selected lowest positive metric: \(lowestPositiveMetric.type.displayName) (\(String(format: "%.1f", impact)) min/day)")
            return lowestPositiveMetric
        }
        
        // Fallback: Neutral metrics or metrics without impact details
        let neutralOrUnknownMetrics = metrics
            .filter { ($0.impactDetails?.lifespanImpactMinutes ?? 0) == 0 || $0.impactDetails == nil }
        
        logger.info("⚪ Found \(neutralOrUnknownMetrics.count) neutral/unknown impact metrics")
        
        if let fallbackMetric = neutralOrUnknownMetrics.first {
            logger.info("✅ Selected fallback metric: \(fallbackMetric.type.displayName)")
            return fallbackMetric
        }
        
        logger.warning("⚠️ No suitable metric found for recommendations")
        return nil
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
            // Dynamic Header based on selected period
            Text(focusHeaderText())
                .style(.headlineBold)
                .padding(.bottom, 20)
            
            // Main content with clear visual separation
            VStack(alignment: .leading, spacing: 16) {
                // Top section: Current status (if negative impact)
                if let impact = metric.impactDetails?.lifespanImpactMinutes, impact < 0 {
                    currentStatusSection(for: metric, impact: impact)
                }
                
                // Bottom section: Action recommendation
                actionRecommendationSection(for: metric)
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
        .scaleEffect(
            showContent ? (isPressed ? 0.95 : 1.0) : 0.95, 
            anchor: .top
        )
        .animation(.easeOut(duration: 0.6), value: showContent)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showContent = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
                .onEnded { _ in
                    onMetricTap(metric)
                    HapticManager.shared.playSelection()
                }
        )
    }
    
    /// Current status section (only shown for negative impact metrics)
    private func currentStatusSection(for metric: HealthMetric, impact: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon with warning color
                Image(systemName: iconName(for: metric.type))
                    .foregroundColor(.ampedRed)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)
                
                // Specific problem statement
                VStack(alignment: .leading, spacing: 2) {
                    Text(getSpecificProblemTitle(for: metric))
                        .style(.body)
                        .foregroundColor(.white)
                    
                    Text("Costing you \(formatImpactWithUnit(abs(impact)))")
                        .style(.body, color: .ampedRed)
                }
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Subtle divider
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    /// Action recommendation section
    private func actionRecommendationSection(for metric: HealthMetric) -> some View {
        HStack(spacing: 12) {
            // Icon with positive color
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.ampedGreen)
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
            
            // Action text
            buildActionText(for: metric)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generate dynamic header text based on selected time period
    private func focusHeaderText() -> String {
        switch selectedPeriod {
        case .day:
            return "Today's Focus"
        case .month:
            return "This Month's Focus"
        case .year:
            return "This Year's Focus"
        }
    }
    
    /// Get specific problem title that's instantly understandable
    private func getSpecificProblemTitle(for metric: HealthMetric) -> String {
        switch metric.type {
        case .steps:
            if metric.value < 3000 {
                return "Very Low Step Count"
            } else if metric.value < 5000 {
                return "Low Step Count"
            } else {
                return "Need More Steps"
            }
            
        case .exerciseMinutes:
            if metric.value < 10 {
                return "Minimal Exercise"
            } else if metric.value < 20 {
                return "Low Exercise"
            } else {
                return "Need More Exercise"
            }
            
        case .sleepHours:
            if metric.value < 6 {
                return "Poor Sleep Duration"
            } else if metric.value > 9 {
                return "Excessive Sleep"
            } else {
                return "Suboptimal Sleep"
            }
            
        case .restingHeartRate:
            return "Elevated Heart Rate"
            
        case .heartRateVariability:
            return "Low Heart Variability"
            
        case .bodyMass:
            return "Weight Impact"
            
        case .nutritionQuality:
            return "Poor Nutrition Quality"
            
        case .stressLevel:
            return "High Stress Level"
            
        case .socialConnectionsQuality:
            return "Weak Social Connections"
            
        case .smokingStatus:
            return "Smoking Impact"
            
        case .alcoholConsumption:
            return "Excessive Drinking"
            
        default:
            return "Poor \(metric.type.displayName)"
        }
    }
    
    /// Build clear, specific action text
    private func buildActionText(for metric: HealthMetric) -> Text {
        let recommendationText = actionText(for: metric)
        return parseAndColorBenefitText(recommendationText)
    }
    
    /// Parse recommendation text and highlight positive benefits in green
    private func parseAndColorBenefitText(_ text: String) -> Text {
        // Pattern to find all benefit numbers (time units, steps, calories, etc.)
        let benefitPattern = #"\d+(?:,\d{3})*(?:\.\d+)?\s+(?:min|mins|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years|steps|calories|points?)\b"#
        
        var result = Text("")
        var lastIndex = text.startIndex
        
        do {
            let regex = try NSRegularExpression(pattern: benefitPattern, options: [.caseInsensitive])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                guard let matchRange = Range(match.range, in: text) else { continue }
                
                // Add text before the match
                let beforeMatch = String(text[lastIndex..<matchRange.lowerBound])
                if !beforeMatch.isEmpty {
                    result = result + Text(beforeMatch).style(.body)
                }
                
                // Add the benefit value in green with non-breaking spaces
                let benefitValue = String(text[matchRange])
                let nonBreakingBenefit = benefitValue.replacingOccurrences(of: " ", with: "\u{00A0}")
                result = result + Text(nonBreakingBenefit).style(.body, color: .ampedGreen)
                
                lastIndex = matchRange.upperBound
            }
            
            // Add remaining text
            let remaining = String(text[lastIndex...])
            if !remaining.isEmpty {
                result = result + Text(remaining).style(.body)
            }
            
            return result
            
        } catch {
            // Fallback to original text
            return Text(text).style(.body)
        }
    }
    
    /// Format impact time with appropriate units
    private func formatImpactWithUnit(_ minutes: Double) -> String {
        let result: String
        
        if minutes < 60 {
            result = "\(Int(minutes)) min"
        } else if minutes < 1440 { // Less than 24 hours
            let hours = minutes / 60
            if hours < 2 {
                result = String(format: "%.0f hr", hours)
            } else {
                result = String(format: "%.0f hrs", hours)
            }
        } else if minutes < 43200 { // Less than 30 days
            let days = minutes / 1440
            if days < 2 {
                result = String(format: "%.0f day", days)
            } else {
                result = String(format: "%.0f days", days)
            }
        } else if minutes < 525600 { // Less than 365 days  
            let months = minutes / 43200
            if months < 2 {
                result = String(format: "%.0f month", months)
            } else {
                result = String(format: "%.0f months", months)
            }
        } else {
            let years = minutes / 525600
            if years < 2 {
                result = String(format: "%.1f year", years)
            } else {
                result = String(format: "%.1f years", years)
            }
        }
        
        // Replace spaces with non-breaking spaces to prevent line breaks
        return result.replacingOccurrences(of: " ", with: "\u{00A0}")
    }
    
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
    
    private func actionText(for metric: HealthMetric) -> String {
        // Use the RecommendationService for accurate, contextual recommendations
        return recommendationService.generateRecommendation(for: metric, selectedPeriod: selectedPeriod)
    }
}
