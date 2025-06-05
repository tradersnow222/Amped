import SwiftUI

/// A card that displays recent life impact visualized as a battery
struct BatteryLifeImpactCard: View {
    // MARK: - Properties
    
    let impactDataPoint: ImpactDataPoint
    let selectedPeriod: ImpactDataPoint.PeriodType
    @State private var batteryFillPercent: Double = 0.0
    
    // MARK: - UI Constants
    
    private let batteryHeight: CGFloat = 40
    private let batteryWidth: CGFloat = 180
    private let batteryCornerRadius: CGFloat = 6
    private let batteryTerminalWidth: CGFloat = 12
    private let batteryTerminalHeight: CGFloat = 20
    private let segmentCount: Int = 5
    private let segmentSpacing: CGFloat = 2
    
    // MARK: - Initialization
    
    init(impactDataPoint: ImpactDataPoint, selectedPeriod: ImpactDataPoint.PeriodType) {
        self.impactDataPoint = impactDataPoint
        self.selectedPeriod = selectedPeriod
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Text("Life Impact")
                    .font(.headline)
                
                Spacer()
                
                Text(selectedPeriod.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Impact Value
            Text(impactDataPoint.formattedImpact)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(impactColor)
            
            // Battery Visualization
            HStack(spacing: 0) {
                batteryVisualization
                
                // Period Selector not included here - will be a separate component
            }
            .padding(.vertical, 8)
            
            // Description
            Text(impactDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                batteryFillPercent = calculateBatteryFill()
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Battery visualization
    private var batteryVisualization: some View {
        HStack(spacing: 2) {
            // Battery body
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery fill with segments
                GeometryReader { geometry in
                    HStack(spacing: segmentSpacing) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            batterySegment(index: index, totalWidth: geometry.size.width)
                        }
                    }
                    .padding(4)
                }
                .frame(width: batteryWidth, height: batteryHeight)
            }
            
            // Battery terminal
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray)
                .frame(width: batteryTerminalWidth, height: batteryTerminalHeight)
        }
    }
    
    /// Individual battery segment
    private func batterySegment(index: Int, totalWidth: CGFloat) -> some View {
        let segmentWidth = (totalWidth - (CGFloat(segmentCount - 1) * segmentSpacing) - 8) / CGFloat(segmentCount)
        let segmentFillPercent = min(max(batteryFillPercent * Double(segmentCount) - Double(index), 0), 1)
        
        return RoundedRectangle(cornerRadius: 3)
            .fill(segmentColor(index: index))
            .frame(width: segmentWidth, height: batteryHeight - 8)
            .scaleEffect(y: CGFloat(segmentFillPercent), anchor: .bottom)
            .animation(.easeInOut(duration: 0.3), value: segmentFillPercent)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate battery fill percentage based on impact
    private func calculateBatteryFill() -> Double {
        // Scale the impact to a battery percentage
        // For positive impacts, fill more than 50%
        // For negative impacts, fill less than 50%
        
        // Get the maximum possible impact for the current period type (simplified)
        let maxPossibleImpact: Double
        switch selectedPeriod {
        case .day:
            maxPossibleImpact = 120.0 // 2 hours per day
        case .month:
            maxPossibleImpact = 120.0 * 30 // 2 hours per day * 30 days
        case .year:
            maxPossibleImpact = 120.0 * 365 // 2 hours per day * 365 days
        }
        
        // Calculate fill percentage, with 0.5 (50%) being neutral
        let impactRatio = impactDataPoint.totalImpactMinutes / maxPossibleImpact
        let fillPercent = 0.5 + (impactRatio / 2.0) // Map to 0-100%
        
        // Clamp between 0.05 (5%) and 0.95 (95%) for visual purposes
        return min(max(fillPercent, 0.05), 0.95)
    }
    
    /// Get the appropriate segment color based on index and fill percentage
    private func segmentColor(index: Int) -> Color {
        let fillThreshold = Double(index + 1) / Double(segmentCount)
        
        if batteryFillPercent < fillThreshold {
            return Color.gray.opacity(0.2)
        }
        
        // Define colors based on position in battery
        switch index {
        case 0, 1:
            return impactDataPoint.totalImpactMinutes < 0 ? .criticalPower : .lowPower
        case 2:
            return .mediumPower
        case 3, 4:
            return impactDataPoint.totalImpactMinutes > 0 ? .fullPower : .highPower
        default:
            return .mediumPower
        }
    }
    
    /// Generate impact description text
    private var impactDescription: String {
        if impactDataPoint.totalImpactMinutes > 60 {
            return "You're gaining significant time from your healthy habits!"
        } else if impactDataPoint.totalImpactMinutes > 0 {
            return "You're slightly increasing your lifespan with current habits."
        } else if impactDataPoint.totalImpactMinutes > -60 {
            return "Your habits are slightly reducing your lifespan."
        } else {
            return "Your current habits are significantly reducing your lifespan."
        }
    }
    
    /// Calculate impact color
    private var impactColor: Color {
        if impactDataPoint.totalImpactMinutes > 60 {
            return .ampedGreen
        } else if impactDataPoint.totalImpactMinutes > 0 {
            return .ampedGreen.opacity(0.8)
        } else if impactDataPoint.totalImpactMinutes > -60 {
            return .ampedYellow
        } else {
            return .ampedRed
        }
    }
}

// MARK: - Preview

struct BatteryLifeImpactCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Positive impact
            BatteryLifeImpactCard(
                impactDataPoint: ImpactDataPoint(
                    date: Date(),
                    periodType: .day,
                    totalImpactMinutes: 75,
                    metricImpacts: [.steps: 30, .sleepHours: 45]
                ),
                selectedPeriod: .day
            )
            
            // Negative impact
            BatteryLifeImpactCard(
                impactDataPoint: ImpactDataPoint(
                    date: Date(),
                    periodType: .day,
                    totalImpactMinutes: -60,
                    metricImpacts: [.steps: -30, .sleepHours: -30]
                ),
                selectedPeriod: .day
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 