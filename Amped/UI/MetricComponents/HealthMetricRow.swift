import SwiftUI

/// A row component that displays a health metric and its impact on battery life
struct HealthMetricRow: View {
    // MARK: - Properties
    
    let metric: HealthMetric
    /// Optional parameter to indicate if this metric is showing averaged data
    let showingAverage: Bool
    
    // MARK: - Initialization
    
    init(metric: HealthMetric, showingAverage: Bool = false) {
        self.metric = metric
        self.showingAverage = showingAverage
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background - Rules: Subtle visual differentiation
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                
                // Add subtle ring for manual metrics
                if metric.source == .userInput {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                }
                
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconForegroundColor)
            }
            .accessibilityHidden(true)
            
            // Metric info
            VStack(alignment: .leading, spacing: 4) {
                // Metric name
                Text(metric.type.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // Value row - simplified without redundant units
                HStack(alignment: .center, spacing: 4) {
                    Text(metric.formattedValue)
                        .font(.system(size: 14))
                        .foregroundColor(valueTextColor)
                    
                    // Only show unit if it's not redundant with the metric name
                    if !metric.unitString.isEmpty && !isRedundantUnit {
                        Text(metric.unitString)
                            .font(.system(size: 14)) // Same size as value
                            .foregroundColor(valueTextColor.opacity(0.7))
                    }
                    
                    // Show (avg) indicator after value and unit
                    if showingAverage {
                        Text("(avg)")
                            .font(.system(size: 14))
                            .foregroundColor(valueTextColor.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Impact value
            HStack(spacing: 4) {
                if let impact = metric.impactDetails {
                    // Individual metrics now always contain daily impact values (fixed in HealthDataService)
                    // This ensures consistent display regardless of selected time period
                    let displayImpact: Double = impact.lifespanImpactMinutes
                    
                    // Show "No impact data" for zero/negligible impacts (< 1 minute)
                    if abs(displayImpact) < 1.0 {
                        Text("No impact data")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Text(formattedImpact(minutes: displayImpact))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(impactColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .accessibilityLabel(accessibilityImpactValue)
                    }
                } else {
                    Text("No impact data")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            // Clean glass background matching the recommendation section
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
        .contentShape(Rectangle()) // Make entire row tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityImpactValue)
        .accessibilityHint("Tap for details")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Visual Differentiation
    
    /// Icon background color based on source
    private var iconBackgroundColor: Color {
        if metric.source == .userInput {
            // Slightly darker/muted background for manual metrics
            return Color.lightCardBackground.opacity(0.6)
        } else {
            // Brighter background for HealthKit metrics
            return Color.lightCardBackground
        }
    }
    
    /// Icon name - use outlined icons for manual metrics
    private var iconName: String {
        if metric.source == .userInput {
            // Use alternative icon styles for manual metrics where available
            switch metric.type {
            case .nutritionQuality:
                return "leaf" // Instead of leaf.fill
            case .smokingStatus:
                return "smoke" // Instead of smoke.fill
            case .alcoholConsumption:
                return "wineglass" // Already outline style
            case .socialConnectionsQuality:
                return "person.2" // Instead of person.2.fill
            case .stressLevel:
                return "brain" // Instead of brain.head.profile
            default:
                return metric.type.symbolName
            }
        } else {
            // Use default (often filled) icons for HealthKit
            return metric.type.symbolName
        }
    }
    
    /// Icon foreground color based on source and impact
    private var iconForegroundColor: Color {
        // Grey out icons for metrics with no meaningful impact (< 1 minute)
        guard let impact = metric.impactDetails, abs(impact.lifespanImpactMinutes) >= 1.0 else {
            return .gray.opacity(0.5)
        }
        
        if metric.source == .userInput {
            // More muted color for manual metrics
            return impactColor.opacity(0.8)
        } else {
            // Full color for HealthKit metrics
            return impactColor
        }
    }
    
    /// Value text color based on source
    private var valueTextColor: Color {
        if metric.source == .userInput {
            // Slightly muted for manual metrics
            return Color.gray.opacity(0.9)
        } else {
            // Standard gray for HealthKit
            return Color.gray
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if the unit would be redundant with the metric name
    private var isRedundantUnit: Bool {
        switch metric.type {
        case .steps:
            return true // "steps" is already in the name
        case .sleepHours:
            return true // Already formatted as "6h 41m"
        default:
            return false
        }
    }
    
    /// Get impact color based on whether impact is positive or negative
    private var impactColor: Color {
        guard let impact = metric.impactDetails else { return .gray }
        
        // Grey out for negligible impacts (< 1 minute)
        guard abs(impact.lifespanImpactMinutes) >= 1.0 else { return .gray }
        
        // Always show proper color based on direction - following rule: ACCURATE DATA DISPLAYED TO THE USER IS KING
        return impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed
    }
    
    /// Format impact minutes into a readable string
    private func formattedImpact(minutes: Double) -> String {
        let absMinutes = abs(minutes)
        let direction = minutes >= 0 ? "gained" : "lost"
        
        // Define time conversions
        let minutesInHour = 60.0
        let minutesInDay = 1440.0 // 60 * 24
        let minutesInWeek = 10080.0 // 60 * 24 * 7
        let minutesInMonth = 43200.0 // 60 * 24 * 30 (approximate)
        let minutesInYear = 525600.0 // 60 * 24 * 365
        
        // Years
        if absMinutes >= minutesInYear {
            let years = absMinutes / minutesInYear
            if years >= 1.0 {
                let unit = years == 1.0 ? "year" : "years"
                let valueString = years.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", years) : String(format: "%.1f", years)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 1.0 {
                let unit = months == 1.0 ? "month" : "months"
                let valueString = months.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", months) : String(format: "%.1f", months)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 1.0 {
                let unit = weeks == 1.0 ? "week" : "weeks"
                let valueString = weeks.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weeks) : String(format: "%.1f", weeks)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 1.0 {
                let unit = days == 1.0 ? "day" : "days"
                let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 1.0 {
                let unit = hours == 1.0 ? "hour" : "hours"
                let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f hour %@", hours, direction)
            }
        }
        
        // Minutes - show exact value if 1 or more
        if absMinutes >= 1.0 {
            let roundedMinutes = Int(round(absMinutes))
            let unit = roundedMinutes == 1 ? "minute" : "minutes"
            return "\(roundedMinutes) \(unit) \(direction)"
        }
        
        // For values less than 1 minute, show as 0 for display purposes
        // (actual calculations remain unchanged)
        return "0 \(direction)"
    }
    
    /// Formatted impact value for accessibility
    private var accessibilityImpactValue: String {
        guard let impact = metric.impactDetails else { return "No impact data" }
        
        // Show "No impact data" for zero/negligible impacts (< 1 minute)
        if abs(impact.lifespanImpactMinutes) < 1.0 {
            return "No impact data"
        }
        
        let direction = impact.lifespanImpactMinutes >= 0 ? "Gaining" : "Losing"
        return "\(direction) \(formattedImpact(minutes: impact.lifespanImpactMinutes))"
    }
    
    /// Get appropriate accessibility label text
    private var accessibilityLabelText: String {
        // For sleep hours, the formattedValue already includes units (e.g., "7h 30m")
        // For other metrics, we need to append the unit
        if metric.type == .sleepHours || metric.unitString.isEmpty {
            return "\(metric.type.displayName), \(metric.formattedValue)"
        } else {
            return "\(metric.type.displayName), \(metric.formattedValue) \(metric.unitString)"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        // Positive impact
        HealthMetricRow(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: 7.5,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .sleepHours,
                    currentValue: 7.5,
                    baselineValue: 7.0,
                    studyReferences: [],
                    lifespanImpactMinutes: 30,
                    calculationMethod: .expertConsensus,
                    recommendation: "Good sleep duration for optimal health."
                )
            )
        )
        
        // Negative impact
        HealthMetricRow(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .stressLevel,
                value: 7.0,
                date: Date(),
                source: .userInput,
                impactDetails: MetricImpactDetail(
                    metricType: .stressLevel,
                    currentValue: 7.0,
                    baselineValue: 5.0,
                    studyReferences: [],
                    lifespanImpactMinutes: -15,
                    calculationMethod: .expertConsensus,
                    recommendation: "Consider stress management techniques to improve overall health."
                )
            )
        )
        
        // Very small positive impact (seconds)
        HealthMetricRow(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .activeEnergyBurned,
                value: 382,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .activeEnergyBurned,
                    currentValue: 382,
                    baselineValue: 300,
                    studyReferences: [],
                    lifespanImpactMinutes: 0.001, // 0.06 seconds
                    calculationMethod: .expertConsensus,
                    recommendation: "Great active energy burn! Keep up the excellent activity level."
                )
            )
        )
        
        // No data metric - following rule: show "No impact data" for unavailable metrics
        HealthMetricRow(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .vo2Max,
                value: 0,
                date: Date(),
                source: .healthKit,
                impactDetails: nil // No impact data
            )
        )
    }
    .padding()
    .background(Color.black)
}
