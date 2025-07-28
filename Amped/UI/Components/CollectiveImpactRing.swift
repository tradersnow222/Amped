import SwiftUI

/// FitBit-inspired collective impact ring visualization
/// Rule: Simplicity is KING - intuitive progress visualization
struct CollectiveImpactRing: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    
    @Environment(\.glassTheme) private var glassTheme
    @State private var isAnimating = false
    
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
        @unknown default:
            return baseValue // Fallback to raw value
        }
    }
    
    /// Normalize impact to 0-1 range for ring progress
    private var normalizedProgress: Double {
        // Map -120 to +120 range to 0.0 to 1.0
        // 0.0 = -120 minutes (critical)
        // 0.5 = 0 minutes (neutral)
        // 1.0 = +120 minutes (optimal)
        let clamped = max(-120, min(120, impactMinutes))
        return (clamped + 120) / 240
    }
    
    /// Battery level as percentage
    private var batteryLevel: Int {
        Int(normalizedProgress * 100)
    }
    
    /// Ring gradient colors based on impact
    private var ringColors: [Color] {
        if impactMinutes < -60 {
            return [.ampedRed.opacity(0.8), .ampedRed]
        } else if impactMinutes < 0 {
            return [.ampedRed, .ampedYellow]
        } else if impactMinutes < 60 {
            return [.ampedYellow, .ampedGreen]
        } else {
            return [.ampedGreen.opacity(0.8), .ampedGreen]
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) { // Reduced spacing for better fit
            // Main ring visualization
            GeometryReader { geometry in
                // Use the smaller dimension to ensure perfect circle
                let availableSize = min(geometry.size.width, geometry.size.height)
                let ringSize = availableSize * 0.85 // Leave 15% margin for labels
                
                ZStack {
                    // Progress ring
                    ProgressRingView(
                        progress: normalizedProgress,
                        ringWidth: ringSize * 0.12,
                        size: ringSize,
                        gradientColors: ringColors,
                        backgroundColor: Color.white.opacity(0.15)
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // Reference marks
                    ReferenceMarksView(
                        ringSize: ringSize,
                        showLabels: ringSize > 150
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    
                    // Center content with battery
                    VStack(spacing: 12) {
                        BatteryIconView(
                            level: batteryLevel,
                            size: CGSize(
                                width: ringSize * 0.3,
                                height: ringSize * 0.15
                            )
                        )
                        
                        Text("\(batteryLevel)%")
                            .font(.system(
                                size: ringSize * 0.12,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: batteryLevel)
                        
                        // Small impact indicator
                        if let lifeImpactData = viewModel.lifeImpactData {
                            HStack(spacing: 4) {
                                Image(systemName: lifeImpactData.totalImpact.direction == .positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: ringSize * 0.06))
                                
                                Text(lifeImpactData.totalImpact.displayString)
                                    .font(.system(
                                        size: ringSize * 0.06,
                                        weight: .medium,
                                        design: .rounded
                                    ))
                            }
                            .foregroundColor(lifeImpactData.totalImpact.direction == .positive ? .ampedGreen : .ampedRed)
                        }
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                }
                .frame(width: ringSize, height: ringSize)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipped() // Ensure reference marks don't extend beyond bounds
            
            // Impact summary below ring
            if let lifeImpactData = viewModel.lifeImpactData {
                ImpactSummaryView(
                    impact: lifeImpactData.totalImpact,
                    period: selectedPeriod
                )
                .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimating = true
            }
        }
        .onChange(of: viewModel.lifeImpactData?.id) { _ in
            // Animate when data updates
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
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

#Preview("Collective Impact Ring") {
    VStack(spacing: 40) {
        // Positive impact
        CollectiveImpactRing(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 45,
                        unit: .minutes,
                        direction: .positive
                    ),
                    batteryLevel: 75,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day
        )
        .frame(height: 300)
        
        // Negative impact
        CollectiveImpactRing(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 30,
                        unit: .minutes,
                        direction: .negative
                    ),
                    batteryLevel: 35,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day
        )
        .frame(height: 300)
    }
    .padding()
    .background(Color.black)
} 