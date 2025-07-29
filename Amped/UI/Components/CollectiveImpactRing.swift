import SwiftUI

/// Goal-oriented collective impact ring inspired by Apple Fitness and Fitbit
/// Rule: Simplicity is KING - clear goal visualization without redundant text
struct CollectiveImpactRing: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    
    @Environment(\.glassTheme) private var glassTheme
    @State private var isAnimating = false
    
    // MARK: - Constants
    
    private let ringWidth: CGFloat = 24
    private let outerRingWidth: CGFloat = 28
    private let minImpact: Double = -120 // Critical negative impact
    private let maxImpact: Double = 120  // Optimal positive impact
    private let neutralPoint: Double = 0  // Baseline neutral
    private let optimalThreshold: Double = 60 // Where "optimal" begins
    
    // MARK: - Computed Properties
    
    /// Get total impact minutes for the selected period
    private var impactMinutes: Double {
        guard let lifeImpactData = viewModel.lifeImpactData else { return 0 }
        let impact = lifeImpactData.totalImpact
        let baseValue = impact.value * (impact.direction == .positive ? 1 : -1)
        
        // Convert to minutes if needed
        switch impact.unit {
        case .minutes:
            return baseValue
        case .hours:
            return baseValue * 60
        case .days:
            return baseValue * 1440
        case .years:
            return baseValue * 525600
        }
    }
    
    /// Current progress position (0.0 to 1.0) - like Apple Fitness rings
    private var currentProgress: Double {
        let clamped = max(minImpact, min(maxImpact, impactMinutes))
        return (clamped - minImpact) / (maxImpact - minImpact)
    }
    
    /// Neutral position on the ring (where 0 minutes sits)
    private var neutralProgress: Double {
        return (neutralPoint - minImpact) / (maxImpact - minImpact)
    }
    
    /// Optimal zone start position
    private var optimalProgress: Double {
        return (optimalThreshold - minImpact) / (maxImpact - minImpact)
    }
    
    /// Ring color based on current impact - inspired by Apple Fitness
    private var ringColor: Color {
        if impactMinutes < -60 {
            return .ampedRed
        } else if impactMinutes < 0 {
            return .ampedYellow
        } else if impactMinutes < optimalThreshold {
            return .ampedGreen.opacity(0.8)
        } else {
            return .ampedGreen
        }
    }
    
    /// Status text for current position
    private var statusText: String {
        if impactMinutes < -30 {
            return "Critical"
        } else if impactMinutes < 0 {
            return "Below Neutral"
        } else if impactMinutes < optimalThreshold {
            return "Positive"
        } else {
            return "Optimal"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Background ring segments
                backgroundRingSegments(size: size)
                
                // Progress ring (current impact)
                progressRing(size: size)
                
                // Goal markers (neutral and optimal indicators)
                goalMarkers(size: size)
                
                // Center content - no redundant numbers, just status
                centerContent
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                isAnimating = true
            }
        }
        .onChange(of: viewModel.lifeImpactData?.id) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Components
    
    /// Background ring with three segments: negative, neutral, positive
    @ViewBuilder
    private func backgroundRingSegments(size: CGFloat) -> some View {
        ZStack {
            // Negative zone (red background)
            Circle()
                .trim(from: 0, to: neutralProgress)
                .stroke(Color.ampedRed.opacity(0.15), lineWidth: outerRingWidth)
                .rotationEffect(.degrees(-90))
            
            // Neutral to optimal zone (yellow background)
            Circle()
                .trim(from: neutralProgress, to: optimalProgress)
                .stroke(Color.ampedYellow.opacity(0.15), lineWidth: outerRingWidth)
                .rotationEffect(.degrees(-90))
                
            // Optimal zone (green background)
            Circle()
                .trim(from: optimalProgress, to: 1.0)
                .stroke(Color.ampedGreen.opacity(0.15), lineWidth: outerRingWidth)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
    
    /// Main progress ring showing current impact
    @ViewBuilder
    private func progressRing(size: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: isAnimating ? currentProgress : 0)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [ringColor.opacity(0.7), ringColor]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
            )
            .frame(width: size - outerRingWidth, height: size - outerRingWidth)
            .rotationEffect(.degrees(-90))
            .animation(.spring(response: 1.2, dampingFraction: 0.8), value: currentProgress)
    }
    
    /// Goal markers at neutral and optimal points - inspired by Fitbit
    @ViewBuilder
    private func goalMarkers(size: CGFloat) -> some View {
        ZStack {
            // Neutral marker (0 minutes)
            goalMarker(
                at: neutralProgress,
                color: .white,
                size: size,
                label: "0"
            )
            
            // Optimal marker (60+ minutes)
            goalMarker(
                at: optimalProgress,
                color: .ampedGreen,
                size: size,
                label: "⭐"
            )
        }
    }
    
    /// Individual goal marker
    @ViewBuilder
    private func goalMarker(at progress: Double, color: Color, size: CGFloat, label: String) -> some View {
        let angle = progress * 360 - 90 // Convert to degrees
        let radius = (size - outerRingWidth) / 2
        
        VStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .offset(y: -radius - 20)
        .rotationEffect(.degrees(angle))
    }
    
    /// Center content - status only, no redundant numbers
    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 8) {
            // Battery icon showing charge level
            Image(systemName: batteryIcon)
                .font(.system(size: 32))
                .foregroundColor(ringColor)
                .symbolRenderingMode(.hierarchical)
            
            // Status text
            Text(statusText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Time period context
            Text(periodText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .opacity(isAnimating ? 1.0 : 0.0)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
    }
    
    /// Battery icon based on current impact level
    private var batteryIcon: String {
        let level = currentProgress
        if level < 0.2 {
            return "battery.0"
        } else if level < 0.4 {
            return "battery.25"
        } else if level < 0.6 {
            return "battery.50"
        } else if level < 0.8 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    /// Period context text
    private var periodText: String {
        switch selectedPeriod {
        case .day:
            return "Today"
        case .month:
            return "This Month" 
        case .year:
            return "This Year"
        }
    }
}

/// Container view for managing state and data flow
/// Rule: Separation of concerns
struct CollectiveImpactRingContainer: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    
    var body: some View {
        CollectiveImpactRing(
            viewModel: viewModel,
            selectedPeriod: selectedPeriod
        )
    }
}

// MARK: - Preview

#Preview("Goal-Oriented Impact Ring") {
    VStack(spacing: 40) {
        // Positive impact example
        CollectiveImpactRing(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 22,
                        unit: .minutes,
                        direction: .positive
                    ),
                    batteryLevel: 65,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day
        )
        .frame(height: 200)
        
        // Optimal impact example
        CollectiveImpactRing(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 75,
                        unit: .minutes,
                        direction: .positive
                    ),
                    batteryLevel: 90,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day
        )
        .frame(height: 200)
        
        // Negative impact example
        CollectiveImpactRing(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 45,
                        unit: .minutes,
                        direction: .negative
                    ),
                    batteryLevel: 25,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day
        )
        .frame(height: 200)
    }
    .padding()
    .background(Color.black)
} 