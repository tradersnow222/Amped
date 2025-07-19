import SwiftUI

/// A card that displays an individual health metric with battery power level visualization and intuitive context
struct BatteryMetricCard: View {
    // MARK: - Properties
    
    let metric: HealthMetric
    let showDetails: Bool
    
    @Environment(\.glassTheme) private var glassTheme
    
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
            // Metric name with contextual description
            headerSection
            
            // Metric value with battery description
            metricValueSection
                
            // Battery visualization
            batteryVisualization
                .frame(height: batteryHeight)
                .padding(.vertical, 4)
            
            // Impact information (if details are enabled)
            if showDetails, let impact = metric.impactDetails {
                Divider()
                    .padding(.vertical, 4)
                
                impactSection(impact)
            }
        }
        .padding()
        .frame(height: showDetails ? nil : cardHeight)
        .glassBackground(.regular, cornerRadius: glassTheme.glassCornerRadius)
    }
    
    // MARK: - UI Components
    
    /// Header with metric name and subtle context
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: metric.type.symbolName)
                    .font(.title3)
                    .foregroundColor(powerColor)
                
                Text(metric.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Subtle contextual description
            Text(metric.type.contextualDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 28) // Align with text above
        }
    }
    
    /// Metric value with intuitive battery description
    private var metricValueSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            metricValueText
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(powerColor)
            
            // Battery-themed status description
            Text(metric.type.batteryDescription(for: metric.powerLevel))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    /// Text view for the metric value, including qualitative label for manual metrics
    private var metricValueText: Text {
        let baseText = metric.formattedValue
        switch metric.type {
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            // For manual metrics, just show the qualitative label
            return Text(qualitativePowerLabel)
        default:
            return Text(baseText)
        }
    }
    
    /// Battery visualization with glass effects
    private var batteryVisualization: some View {
        HStack(spacing: 2) {
            // Battery body
            ZStack(alignment: .leading) {
                // Battery outline with glass effect
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
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
            
            // Battery terminal with glass effect
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: batteryTerminalWidth, height: batteryTerminalHeight)
        }
    }
    
    /// Individual battery segment with glass effects
    private func batterySegment(index: Int, totalWidth: CGFloat) -> some View {
        let segmentWidth = (totalWidth - (CGFloat(segmentCount - 1) * segmentSpacing) - 6) / CGFloat(segmentCount)
        let isFilled = index < powerLevel
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(
                isFilled ? 
                LinearGradient(
                    colors: [powerColor, powerColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                // Glass shine effect for filled segments
                isFilled ?
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5) : nil
            )
            .frame(width: segmentWidth, height: batteryHeight - 6)
    }
    
    /// Impact section with emotional context
    private func impactSection(_ impact: MetricImpactDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let symbolName = impact.lifespanImpactMinutes > 0 ? "arrow.up.circle.fill" : (impact.lifespanImpactMinutes < 0 ? "arrow.down.circle.fill" : "minus.circle.fill")
                Image(systemName: symbolName)
                    .foregroundColor(impactColor(for: impact))
                
                Text("Impact: \(impact.formattedImpact(for: .day))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Subtle emotional context about what this means
            Text(metric.type.outcomeDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .italic()
        }
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
    
    /// Get qualitative power level label
    private var qualitativePowerLabel: String {
        switch metric.powerLevel {
        case .full: return "Excellent"
        case .high: return "Good"
        case .medium: return "Fair"
        case .low: return "Poor"
        case .critical: return "Critical"
        }
    }
    
    /// Get impact color
    private func impactColor(for impact: MetricImpactDetail) -> Color {
        return impact.lifespanImpactMinutes >= 0 ? .fullPower : .criticalPower
    }
}

// MARK: - Preview

struct BatteryMetricCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // High power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    id: UUID().uuidString,
                    type: .steps,
                    value: 9500,
                    date: Date(),
                    source: .healthKit,
                    impactDetails: MetricImpactDetail(
                        metricType: .steps,
                        currentValue: 9500,
                        baselineValue: 8000,
                        studyReferences: [],
                        lifespanImpactMinutes: 10,
                        calculationMethod: .metaAnalysisSynthesis,
                        recommendation: "Excellent step count! Keep up the great work."
                    )
                ),
                showDetails: true
            )
            
            // Medium power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    id: UUID().uuidString,
                    type: .sleepHours,
                    value: 7.2,
                    date: Date(),
                    source: .healthKit
                )
            )
            
            // Low power metric
            BatteryMetricCard(
                metric: HealthMetric(
                    id: UUID().uuidString,
                    type: .heartRateVariability,
                    value: 25,
                    date: Date(),
                    source: .healthKit,
                    impactDetails: MetricImpactDetail(
                        metricType: .heartRateVariability,
                        currentValue: 25,
                        baselineValue: 35,
                        studyReferences: [],
                        lifespanImpactMinutes: -5,
                        calculationMethod: .expertConsensus,
                        recommendation: "Consider stress reduction and recovery activities to improve HRV."
                    )
                ),
                showDetails: true
            )
        }
        .padding()
        .withGlassTheme()
        .background(
            Image("DeepBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
    }
} 