import SwiftUI

/// A row component that displays a health metric and its impact on battery life
struct HealthMetricRow: View {
    // MARK: - Properties
    
    let metric: HealthMetric
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.lightCardBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: metric.type.symbolName)
                    .font(.system(size: 16))
                    .foregroundColor(impactColor)
            }
            .accessibilityHidden(true)
            
            // Metric info
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.type.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // Value row
                HStack(alignment: .center, spacing: 6) {
                    Text(metric.formattedValue)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    if !metric.unitString.isEmpty {
                        Text(metric.unitString)
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Impact value
            if let impact = metric.impactDetails {
                HStack(spacing: 4) {
                    Image(systemName: impact.lifespanImpactMinutes >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(impactColor)
                        .accessibilityHidden(true)
                    
                    Text(formattedImpact(minutes: impact.lifespanImpactMinutes))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(impactColor)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .contentShape(Rectangle()) // Make entire row tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityValue(accessibilityImpactValue)
        .accessibilityHint("Tap for details")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Helper Methods
    
    /// Get impact color based on whether impact is positive or negative
    private var impactColor: Color {
        guard let impact = metric.impactDetails else { return .gray }
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
            if years >= 2 {
                return String(format: "%.0f years %@", years, direction)
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 2 {
                return String(format: "%.0f months %@", months, direction)
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 2 {
                return String(format: "%.0f weeks %@", weeks, direction)
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 2 {
                return String(format: "%.0f days %@", days, direction)
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 2 {
                return String(format: "%.0f hours %@", hours, direction)
            } else {
                return String(format: "%.1f hour %@", hours, direction)
            }
        }
        
        // Minutes
        return "\(Int(absMinutes)) min \(direction)"
    }
    
    /// Formatted impact value for accessibility
    private var accessibilityImpactValue: String {
        guard let impact = metric.impactDetails else { return "No impact data" }
        
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
                    lifespanImpactMinutes: 30,
                    comparisonToBaseline: .better
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
                    lifespanImpactMinutes: -15,
                    comparisonToBaseline: .worse
                )
            )
        )
    }
    .padding()
    .background(Color.black)
} 