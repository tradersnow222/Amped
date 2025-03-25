import SwiftUI

/// A card that displays an individual health metric with battery power level visualization
struct BatteryMetricCard: View {
    // MARK: - Properties
    
    let metric: HealthMetric
    let showDetails: Bool
    
    @Environment(\.themeManager) private var themeManager
    
    // MARK: - UI Constants
    
    private let cardHeight: CGFloat = 110
    private let batteryHeight: CGFloat = 20
    private let batteryWidth: CGFloat = 100
    private let batteryCornerRadius: CGFloat = 4
    private let batteryTerminalWidth: CGFloat = 5
    private let batteryTerminalHeight: CGFloat = 12
    private let segmentCount: Int = 5
    private let segmentSpacing: CGFloat = 2
    
    // MARK: - Initialization
    
    init(metric: HealthMetric, showDetails: Bool = false) {
        self.metric = metric
        self.showDetails = showDetails
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metric name and icon
            HStack {
                Image(systemName: metric.type.symbolName)
                    .font(.title3)
                    .foregroundColor(powerColor)
                
                Text(metric.type.displayName)
                    .style(.headline)
                
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
                .style(.metricValue, color: powerColor)
            
            // Battery visualization
            batteryVisualization
                .frame(height: batteryHeight)
                .padding(.vertical, 4)
            
            // Impact information (if details are enabled)
            if showDetails, let impact = metric.impactDetail {
                Divider()
                    .padding(.vertical, 4)
                
                HStack {
                    Image(systemName: impact.comparisonToBaseline.symbol)
                        .foregroundColor(Color(impact.comparisonToBaseline.color))
                    
                    Text(impact.formattedImpact)
                        .style(.callout, color: impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(height: showDetails ? nil : cardHeight)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - UI Components
    
    /// Battery visualization
    private var batteryVisualization: some View {
        HStack(spacing: 2) {
            // Battery body
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery fill with segments
                GeometryReader { geometry in
                    HStack(spacing: segmentSpacing) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            batterySegment(index: index, totalWidth: geometry.size.width)
                        }
                    }
                    .padding(3)
                }
                .frame(width: batteryWidth, height: batteryHeight)
            }
            
            // Battery terminal
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.gray)
                .frame(width: batteryTerminalWidth, height: batteryTerminalHeight)
        }
    }
    
    /// Individual battery segment
    private func batterySegment(index: Int, totalWidth: CGFloat) -> some View {
        let segmentWidth = (totalWidth - (CGFloat(segmentCount - 1) * segmentSpacing) - 6) / CGFloat(segmentCount)
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(index < powerLevel ? powerColor : Color.gray.opacity(0.2))
            .frame(width: segmentWidth, height: batteryHeight - 6)
    }
    
    // MARK: - Helper Methods
    
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

struct BatteryMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // High power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    type: .steps,
                    value: 9500,
                    impactDetail: MetricImpactDetail(
                        metricType: .steps,
                        lifespanImpactMinutes: 10,
                        comparisonToBaseline: .better
                    )
                ),
                showDetails: true
            )
            
            // Medium power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    type: .sleepHours,
                    value: 7.2
                )
            )
            
            // Low power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    type: .restingHeartRate,
                    value: 85,
                    impactDetail: MetricImpactDetail(
                        metricType: .restingHeartRate,
                        lifespanImpactMinutes: -30,
                        comparisonToBaseline: .worse
                    )
                ),
                showDetails: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 