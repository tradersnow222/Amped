import SwiftUI

/// Mini progress ring for individual health metrics
/// Rule: Consistent visual language with main collective impact ring
struct MetricProgressRing: View {
    // MARK: - Properties
    
    let metric: HealthMetric
    let size: CGFloat
    
    // MARK: - Initialization
    
    init(metric: HealthMetric, size: CGFloat = 36) {
        self.metric = metric
        self.size = size
    }
    
    // MARK: - Computed Properties
    
    /// Calculate progress based on metric value relative to baseline and target
    private var progress: Double {
        // For metrics without a target, show 50% (neutral)
        guard let targetValue = metric.type.targetValue else { return 0.5 }
        
        let baselineValue = metric.type.baselineValue
        
        if metric.type.isHigherBetter {
            // Higher is better: progress from baseline to target
            if targetValue <= baselineValue { return 0.5 } // Avoid division by zero
            
            let range = targetValue - baselineValue
            let currentProgress = (metric.value - baselineValue) / range
            
            // Map to 0-1 range where 0.5 is baseline
            return 0.5 + (currentProgress * 0.5)
        } else {
            // Lower is better: invert the calculation
            if baselineValue <= targetValue { return 0.5 } // Avoid division by zero
            
            let range = baselineValue - targetValue
            let currentProgress = (baselineValue - metric.value) / range
            
            // Map to 0-1 range where 0.5 is baseline
            return 0.5 + (currentProgress * 0.5)
        }
    }
    
    /// Determine ring color based on impact
    private var ringColor: Color {
        // Use impact if available
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            if abs(impact) < 1.0 {
                // Minimal impact is still positive
                return .ampedGreen.opacity(0.8)
            }
            return impact >= 0 ? .ampedGreen : .ampedRed
        }
        
        // Fallback to progress-based color
        if progress >= 0.7 {
            return .ampedGreen
        } else if progress >= 0.5 {
            return .ampedYellow
        } else {
            return .ampedRed
        }
    }
    
    /// Background opacity based on data availability
    private var backgroundOpacity: Double {
        metric.impactDetails != nil ? 0.15 : 0.08
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(backgroundOpacity), lineWidth: size * 0.08)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: size * 0.08,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Center icon
            Image(systemName: metric.type.symbolName)
                .font(.system(size: size * 0.4))
                .foregroundColor(ringColor)
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size) // Enforce perfect square constraint
        .aspectRatio(1.0, contentMode: .fit) // Maintain perfect circle aspect ratio
        .drawingGroup() // Performance optimization
    }
}

// MARK: - Simplified Battery for Row Display

/// Simple battery indicator for use in metric rows - vertical battery visualization
/// Rule: Battery-themed visualization that accurately reflects metric impact
struct SimpleMetricBattery: View {
    let metric: HealthMetric
    
    // MARK: - Constants
    private let batteryWidth: CGFloat = 16
    private let batteryHeight: CGFloat = 28
    private let batteryCornerRadius: CGFloat = 3
    private let terminalWidth: CGFloat = 8
    private let terminalHeight: CGFloat = 2
    private let fillPadding: CGFloat = 2.0  // Increased padding to ensure fill stays within bounds
    
    // MARK: - Computed Properties
    
    /// Calculate battery charge level based on impact
    private var chargeLevel: Double {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else { return 0.5 }
        
        // Map impact to battery charge level
        // Positive impact = higher charge, negative impact = lower charge
        // -60 to +60 minutes mapped to 0.1 to 0.9 (keeping some visual charge even at worst)
        let normalizedImpact = max(-60, min(60, impact)) / 60.0  // -1.0 to 1.0
        return 0.5 + (normalizedImpact * 0.4)  // 0.1 to 0.9 range
    }
    
    /// Battery color based on impact
    private var batteryColor: Color {
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            // Show green for minimal impacts (< 1 minute) since "No change" is positive
            // This matches the logic in HealthMetricRow for consistency
            if abs(impact) < 1.0 {
                return .ampedGreen.opacity(0.8)  // No change is good
            } else if impact > 0 {
                return .ampedGreen
            } else {
                return .ampedRed  // Meaningful negative impact
            }
        }
        return .gray.opacity(0.6)  // No data
    }
    
    /// Battery outline color
    private var outlineColor: Color {
        return .white.opacity(0.6)
    }
    
    /// Calculate fill height (charging from bottom up)
    private var fillHeight: CGFloat {
        let availableHeight = batteryHeight - (fillPadding * 2)
        return availableHeight * CGFloat(chargeLevel)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Battery terminal/cap at top
            RoundedRectangle(cornerRadius: 1)
                .fill(outlineColor)
                .frame(width: terminalWidth, height: terminalHeight)
            
            // Main battery body
            ZStack {
                // Battery outline
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(outlineColor, lineWidth: 1)
                    .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery fill (fills from bottom up) - simplified with proper clipping
                VStack {
                    Spacer(minLength: 0)
                    
                    RoundedRectangle(cornerRadius: max(0, batteryCornerRadius - 1.5))
                        .fill(batteryColor)
                        .frame(
                            width: batteryWidth - (fillPadding * 2), 
                            height: fillHeight
                        )
                        .animation(.easeInOut(duration: 0.3), value: chargeLevel)
                }
                .padding(.horizontal, fillPadding)
                .padding(.vertical, fillPadding)
                .frame(width: batteryWidth, height: batteryHeight)
                .clipped()
            }
            .offset(y: -0.5) // Slight overlap for connection
        }
        .frame(width: batteryWidth, height: batteryHeight + terminalHeight)
        .aspectRatio(contentMode: .fit)
    }
}

/// Even simpler ring for use in metric rows
/// @deprecated Use SimpleMetricBattery instead
struct SimpleMetricRing: View {
    let metric: HealthMetric
    
    private var impactProgress: Double {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else { return 0.5 }
        
        // Map impact to progress (similar to collective ring)
        // -60 to +60 minutes mapped to 0.0 to 1.0
        let clamped = max(-60, min(60, impact))
        return (clamped + 60) / 120
    }
    
    private var ringColor: Color {
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            if abs(impact) < 1.0 {
                return .ampedGreen.opacity(0.8)
            }
            return impact >= 0 ? .ampedGreen : .ampedRed
        }
        return .gray
    }
    
    var body: some View {
        ProgressRingView(
            progress: impactProgress,
            ringWidth: 2.5,
            size: 32,
            gradientColors: [ringColor.opacity(0.6), ringColor],
            backgroundColor: Color.white.opacity(0.1)
        )
        .aspectRatio(1.0, contentMode: .fit) // Ensure perfect circle
    }
}

// MARK: - Preview

#Preview("Metric Progress Rings") {
    VStack(spacing: 30) {
        // Different metric examples
        HStack(spacing: 20) {
            VStack {
                MetricProgressRing(
                    metric: HealthMetric(
                        id: UUID().uuidString,
                        type: .steps,
                        value: 12000,
                        date: Date(),
                        source: .healthKit,
                        impactDetails: MetricImpactDetail(
                            metricType: .steps,
                            currentValue: 12000,
                            baselineValue: 7500,
                            studyReferences: [],
                            lifespanImpactMinutes: 25,
                            calculationMethod: .directStudyMapping,
                            recommendation: "Great step count!"
                        )
                    )
                )
                Text("Steps")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            VStack {
                MetricProgressRing(
                    metric: HealthMetric(
                        id: UUID().uuidString,
                        type: .sleepHours,
                        value: 6.5,
                        date: Date(),
                        source: .healthKit,
                        impactDetails: MetricImpactDetail(
                            metricType: .sleepHours,
                            currentValue: 6.5,
                            baselineValue: 7,
                            studyReferences: [],
                            lifespanImpactMinutes: -10,
                            calculationMethod: .directStudyMapping,
                            recommendation: "Try to get more sleep."
                        )
                    )
                )
                Text("Sleep")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            VStack {
                MetricProgressRing(
                    metric: HealthMetric(
                        id: UUID().uuidString,
                        type: .heartRateVariability,
                        value: 45,
                        date: Date(),
                        source: .healthKit,
                        impactDetails: nil
                    )
                )
                Text("HRV")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        
        Divider()
            .background(Color.white.opacity(0.3))
        
        // Simple batteries for row display
        VStack(alignment: .leading, spacing: 16) {
            Text("Simple Batteries for Rows")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack {
                    SimpleMetricBattery(
                        metric: HealthMetric(
                            id: UUID().uuidString,
                            type: .steps,
                            value: 10000,
                            date: Date(),
                            source: .healthKit,
                            impactDetails: MetricImpactDetail(
                                metricType: .steps,
                                currentValue: 10000,
                                baselineValue: 7500,
                                studyReferences: [],
                                lifespanImpactMinutes: 15,
                                calculationMethod: .directStudyMapping,
                                recommendation: "Good job!"
                            )
                        )
                    )
                    Text("Positive")
                        .font(.caption2)
                        .foregroundColor(.ampedGreen)
                }
                
                VStack {
                    SimpleMetricBattery(
                        metric: HealthMetric(
                            id: UUID().uuidString,
                            type: .restingHeartRate,
                            value: 75,
                            date: Date(),
                            source: .healthKit,
                            impactDetails: MetricImpactDetail(
                                metricType: .restingHeartRate,
                                currentValue: 75,
                                baselineValue: 70,
                                studyReferences: [],
                                lifespanImpactMinutes: -8,
                                calculationMethod: .directStudyMapping,
                                recommendation: "Try to lower your resting heart rate."
                            )
                        )
                    )
                    Text("Negative")
                        .font(.caption2)
                        .foregroundColor(.ampedRed)
                }
                
                VStack {
                    SimpleMetricBattery(
                        metric: HealthMetric(
                            id: UUID().uuidString,
                            type: .heartRateVariability,
                            value: 45,
                            date: Date(),
                            source: .healthKit,
                            impactDetails: nil
                        )
                    )
                    Text("No Data")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    .padding()
    .background(Color.black)
} 