import SwiftUI
import OSLog

/// Habit goals layer showing individual metric contributions to the collective battery
/// Rule: Simplicity is KING - Clear visual hierarchy with goal-based color coding
struct HabitGoalsLayer: View {
    // MARK: - Properties
    
    let healthMetrics: [HealthMetric]
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onMetricTap: (HealthMetric) -> Void
    
    @Environment(\.glassTheme) private var glassTheme
    @State private var animateEntrance = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HabitGoalsLayer")
    
    // MARK: - Constants
    
    private let itemHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 10
    private let iconSize: CGFloat = 20
    
    // MARK: - Computed Properties
    
    /// Metrics sorted by impact (highest positive first, then least negative)
    private var sortedMetrics: [HealthMetric] {
        return healthMetrics
            .filter { $0.impactDetails != nil }
            .sorted { first, second in
                let firstImpact = first.impactDetails?.lifespanImpactMinutes ?? 0
                let secondImpact = second.impactDetails?.lifespanImpactMinutes ?? 0
                
                // Positive impacts first (highest to lowest), then negative impacts (least negative to most negative)
                if firstImpact >= 0 && secondImpact >= 0 {
                    return firstImpact > secondImpact
                } else if firstImpact < 0 && secondImpact < 0 {
                    return firstImpact > secondImpact
                } else {
                    return firstImpact > secondImpact
                }
            }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Habits list
            habitsList
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            startEntranceAnimation()
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.title2.bold())
                    .foregroundColor(.ampedGreen)
                
                Text("Contributing Habits")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(periodDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Habits List
    
    @ViewBuilder
    private var habitsList: some View {
        LazyVStack(spacing: 6) {
            ForEach(Array(sortedMetrics.enumerated()), id: \.element.id) { index, metric in
                HabitGoalRow(
                    metric: metric,
                    selectedPeriod: selectedPeriod,
                    onTap: { onMetricTap(metric) }
                )
                .opacity(animateEntrance ? 1.0 : 0.0)
                .offset(x: animateEntrance ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.4).delay(Double(index) * 0.1),
                    value: animateEntrance
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Computed Properties
    
    private var periodDescription: String {
        switch selectedPeriod {
        case .day:
            return "Today's impact on your lifespan"
        case .month:
            return "This month's impact on your lifespan"
        case .year:
            return "This year's impact on your lifespan"
        }
    }
    
    // MARK: - Animations
    
    private func startEntranceAnimation() {
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            animateEntrance = true
        }
    }
}

// MARK: - Habit Goal Row

/// Individual habit row showing goal status and impact
struct HabitGoalRow: View {
    let metric: HealthMetric
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    // MARK: - Constants
    
    private let rowHeight: CGFloat = 50
    private let iconSize: CGFloat = 20
    private let impactBarWidth: CGFloat = 3
    
    // MARK: - Computed Properties
    
    /// Goal status based on impact and target achievement
    private var goalStatus: GoalStatus {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else {
            return .neutral
        }
        
        if abs(impact) < 0.5 {
            return .neutral // Minimal impact
        }
        
        return impact >= 0 ? .met : .missed
    }
    
    /// Color based on goal status
    private var statusColor: Color {
        switch goalStatus {
        case .met:
            return .ampedGreen
        case .missed:
            return .ampedRed
        case .neutral:
            return .ampedYellow
        }
    }
    
    /// Formatted impact text
    private var impactText: String {
        guard let impact = metric.impactDetails?.lifespanImpactMinutes else {
            return "No data"
        }
        
        let absValue = abs(impact)
        let sign = impact >= 0 ? "+" : "-"
        
        if absValue < 1.0 {
            return "±0 min"
        } else if absValue < 60 {
            return "\(sign)\(Int(absValue)) min"
        } else {
            let hours = absValue / 60
            return "\(sign)\(String(format: "%.1f", hours))h"
        }
    }
    
    /// Status icon
    private var statusIcon: String {
        switch goalStatus {
        case .met:
            return "arrow.up.circle.fill"
        case .missed:
            return "arrow.down.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // Haptic feedback for habit row tap
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            onTap()
        }) {
            HStack(spacing: 12) {
                // Impact bar
                Rectangle()
                    .fill(statusColor)
                    .frame(width: impactBarWidth)
                    .cornerRadius(impactBarWidth / 2)
                
                // Metric icon
                Image(systemName: metric.type.symbolName)
                    .font(.system(size: iconSize))
                    .foregroundColor(statusColor)
                    .frame(width: iconSize, height: iconSize)
                
                // Metric info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(metric.type.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Status icon
                        Image(systemName: statusIcon)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                    
                    HStack {
                        Text(metric.formattedValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(impactText)
                            .font(.caption.bold())
                            .foregroundColor(statusColor)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(height: rowHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isPressed ? 0.1 : 0.05))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Goal Status

enum GoalStatus {
    case met     // Green - adds time
    case missed  // Red - subtracts time
    case neutral // Yellow - partial/no change
}

// MARK: - Preview

#Preview("Habit Goals Layer") {
    VStack {
        HabitGoalsLayer(
            healthMetrics: [
                // Sample positive impact metric
                HealthMetric(
                    id: UUID().uuidString,
                    type: .steps,
                    value: 8500,
                    date: Date(),
                    source: .healthKit,
                    impactDetails: MetricImpactDetail(
                        metricType: .steps,
                        currentValue: 8500,
                        baselineValue: 6000,
                        studyReferences: [],
                        lifespanImpactMinutes: 15.0,
                        calculationMethod: .directStudyMapping,
                        recommendation: "Great job! Keep up the active lifestyle."
                    )
                ),
                // Sample negative impact metric
                HealthMetric(
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
                        lifespanImpactMinutes: -12.0,
                        calculationMethod: .directStudyMapping,
                        recommendation: "Consider cardiovascular exercise to improve heart health."
                    )
                ),
                // Sample neutral impact metric
                HealthMetric(
                    id: UUID().uuidString,
                    type: .sleepHours,
                    value: 7.2,
                    date: Date(),
                    source: .healthKit,
                    impactDetails: MetricImpactDetail(
                        metricType: .sleepHours,
                        currentValue: 7.2,
                        baselineValue: 7.0,
                        studyReferences: [],
                        lifespanImpactMinutes: 0.3,
                        calculationMethod: .directStudyMapping,
                        recommendation: "Good sleep duration. Aim for 8 hours for optimal health."
                    )
                )
            ],
            selectedPeriod: .day,
            onMetricTap: { metric in
                print("Tapped metric: \(metric.type.displayName)")
            }
        )
        .padding()
        
        Spacer()
    }
    .background(Color.black)
} 