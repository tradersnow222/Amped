import SwiftUI

/// A more visually appealing metric card component that displays health metric information
/// with power level indicators and impact details
struct EnhancedMetricCard: View {
    let metric: HealthMetric
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and power level
            HStack {
                Image(systemName: metric.type.symbolName)
                    .font(.title3)
                    .foregroundColor(powerColor)
                
                Text(metric.type.displayName)
                    .futuristicText(size: 16, weight: .medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Power level indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < powerLevel ? powerColor : Color.gray.opacity(0.3))
                            .frame(width: 3, height: 8 + CGFloat(i))
                    }
                }
            }
            
            // Metric value
            Text(metric.formattedValue)
                .futuristicText(size: 24, weight: .bold)
                .foregroundColor(powerColor)
            
            // Impact
            if let impact = metric.impactDetails {
                HStack(spacing: 4) {
                    Image(systemName: impact.lifespanImpactMinutes >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed)
                        .font(.caption)
                    
                    Text(impact.formattedImpact)
                        .futuristicText(size: 14, weight: .medium)
                        .foregroundColor(impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Simulate press/release for feedback
            withAnimation {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
    
    /// Get numeric power level (0-5)
    private var powerLevel: Int {
        switch metric.powerLevel {
        case .full: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .critical: return 1
        }
    }
    
    /// Get power level color
    private var powerColor: Color {
        switch metric.powerLevel {
        case .full: return .fullPower
        case .high: return .highPower
        case .medium: return .mediumPower
        case .low: return .lowPower
        case .critical: return .criticalPower
        }
    }
}

// MARK: - Preview
#Preview {
    // Create a sample metric for preview
    EnhancedMetricCard(
        metric: HealthMetric(
            id: UUID().uuidString,
            type: .sleepHours,
            value: 7.5,
            date: Date(),
            source: .healthKit,
            impactDetails: MetricImpactDetail(
                metricType: .sleepHours,
                lifespanImpactMinutes: 45,
                comparisonToBaseline: .better
            )
        )
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
} 