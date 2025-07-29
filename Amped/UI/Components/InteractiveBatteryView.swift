import SwiftUI
import OSLog

// MARK: - Extensions

extension Color {
    /// Linear interpolation between two colors
    static func lerp(start: Color, end: Color, t: Double) -> Color? {
        let t = max(0, min(1, t)) // Clamp t to 0-1 range
        
        // Convert to UIColor to access RGB components
        let startUIColor = UIColor(start)
        let endUIColor = UIColor(end)
        
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
        
        guard startUIColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha),
              endUIColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha) else {
            return nil
        }
        
        let red = startRed + (endRed - startRed) * t
        let green = startGreen + (endGreen - startGreen) * t
        let blue = startBlue + (endBlue - startBlue) * t
        let alpha = startAlpha + (endAlpha - startAlpha) * t
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // MARK: - Bright Fluorescent Colors for Battery Gradient
    
    /// Bright fluorescent red for worst case scenario
    static var brightFluorescentRed: Color {
        Color(red: 1.0, green: 0.1, blue: 0.1) // Bright fluorescent red
    }
    
    /// Bright fluorescent green for best case scenario  
    static var brightFluorescentGreen: Color {
        Color(red: 0.0, green: 1.0, blue: 0.2) // Bright fluorescent green
    }
    
    /// White for neutral (no time impact)
    static var neutralWhite: Color {
        Color.white // Pure white for zero impact
    }
}

// MARK: - Supporting Views

/// Simple dotted line shape for battery markers
struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

/// Interactive battery view showing collective lifespan impact
/// Replaces CollectiveImpactRing with battery-themed visualization
/// Rule: Simplicity is KING - Battery-themed visualization with clear impact messaging
struct InteractiveBatteryView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onTapToDrillIn: () -> Void
    
    @Environment(\.glassTheme) private var glassTheme
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var fillAnimation = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "InteractiveBatteryView")
    
    // MARK: - Constants
    
    private let batteryWidth: CGFloat = 150
    private let batteryHeight: CGFloat = 220
    private let batteryCornerRadius: CGFloat = 20
    private let terminalWidth: CGFloat = 50
    private let terminalHeight: CGFloat = 12
    private let terminalCornerRadius: CGFloat = 6
    private let chargePadding: CGFloat = 6
    private let maxImpactMinutes: Double = 240 // 4 hours max expected daily impact
    
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
    
    /// Impact ratio normalized to -1.0 to +1.0 range for color calculation
    private var impactRatio: Double {
        let periodMultiplier: Double
        switch selectedPeriod {
        case .day:
            periodMultiplier = 1.0
        case .month:
            periodMultiplier = 30.0
        case .year:
            periodMultiplier = 365.0
        }
        
        let maxExpectedImpact = maxImpactMinutes * periodMultiplier
        return max(-1.0, min(1.0, impactMinutes / maxExpectedImpact))
    }
    
    /// Battery color based on impact with bright fluorescent gradient
    private var batteryColor: Color {
        // Debug: Force red for any negative impact text
        if impactMinutes < 0 || impactText.contains("reduced") {
            // Strong red for negative impact - amplify the color intensity
            let intensity = max(0.3, min(1.0, abs(impactRatio) * 3.0))
            return Color.lerp(
                start: Color.neutralWhite,
                end: Color.brightFluorescentRed,
                t: intensity
            ) ?? Color.brightFluorescentRed
        } else if impactMinutes > 0 {
            // Strong green for positive impact
            let intensity = max(0.3, min(1.0, abs(impactRatio) * 3.0))
            return Color.lerp(
                start: Color.neutralWhite,
                end: Color.brightFluorescentGreen,
                t: intensity
            ) ?? Color.brightFluorescentGreen
        } else {
            // Neutral
            return Color.neutralWhite
        }
    }
    
    /// Impact direction arrow
    private var impactArrow: String {
        if abs(impactMinutes) < 1.0 {
            return "minus" // Neutral
        }
        return impactMinutes >= 0 ? "arrow.up" : "arrow.down"
    }
    
    /// Dynamic metrics text based on selected period
    private var periodMetricsText: String {
        switch selectedPeriod {
        case .day:
            return "today's metrics"
        case .month:
            return "this month's metrics"
        case .year:
            return "this year's metrics"
        }
    }
    
    /// Formatted impact text
    private var impactText: String {
        let absValue = abs(impactMinutes)
        
        if absValue < 1.0 {
            return "< 1 minute"
        } else if absValue < 60 {
            return "\(Int(absValue)) minute\(Int(absValue) == 1 ? "" : "s")"
        } else {
            let hours = absValue / 60
            if hours < 24 {
                return String(format: "%.1f hour\(hours < 2 ? "" : "s")", hours)
            } else {
                let days = hours / 24
                return String(format: "%.1f day\(days < 2 ? "" : "s")", days)
            }
        }
    }
    
    /// Period-specific header text
    private var periodText: String {
        switch selectedPeriod {
        case .day:
            return "Today, your habits collectively"
        case .month:
            return "This month, your habits collectively"
        case .year:
            return "This year, your habits collectively"
        }
    }
    
    /// Impact verb based on direction
    private var impactVerb: String {
        if abs(impactMinutes) < 1.0 {
            return "maintained"
        }
        return impactMinutes >= 0 ? "added" : "reduced"
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Interactive Battery with Tooltips - Centered layout with overlaid tooltips
            ZStack {
                // Centered Battery
                batteryView
                    .onTapGesture {
                        // Haptic feedback for battery tap
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        onTapToDrillIn()
                    }
                    .scaleEffect(isAnimating ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isAnimating)
                    .onAppear {
                        startAnimations()
                    }
                    .onChange(of: impactMinutes) { _ in
                        startAnimations()
                    }
                

            }
            
            // Tap hint
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Tap to see \(periodMetricsText)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Battery View
    
    @ViewBuilder
    private var batteryView: some View {
        // Main battery visualization - CENTERED and SIMPLIFIED
        ZStack {
            // Battery outline
            RoundedRectangle(cornerRadius: batteryCornerRadius)
                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                .frame(width: batteryWidth, height: batteryHeight)
            
            // Battery terminal (top)
            RoundedRectangle(cornerRadius: terminalCornerRadius)
                .fill(Color.white.opacity(0.3))
                .frame(width: terminalWidth, height: terminalHeight)
                .offset(y: -(batteryHeight/2 + terminalHeight/2))
            
            // MARK: - Enhanced Battery Fill Content - Always 100% filled
            
            // Always fill entire battery, color indicates impact value
            ZStack(alignment: .bottom) {
                // Full battery fill with color based on impact value
                RoundedRectangle(cornerRadius: batteryCornerRadius - 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor,
                                batteryColor.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: batteryHeight - (chargePadding * 2)) // Always fill entire height
                    .animation(.easeOut(duration: 1.2), value: fillAnimation)
            }
            .frame(width: batteryWidth - (chargePadding * 2), height: batteryHeight - (chargePadding * 2))
            .padding(chargePadding)
            .clipped()
            
            // MARK: - Charging Particles
            
            chargingParticles
            floatingParticles
        }
        .frame(width: batteryWidth, height: batteryHeight)
    }
    
    // MARK: - Charging Particles
    
    @ViewBuilder
    private var chargingParticles: some View {
        if abs(impactMinutes) > 1.0 {
            // Tighter bounds - particles stay strictly within battery
            let batteryContentHeight = batteryHeight - (chargePadding * 2)
            let batteryContentWidth = batteryWidth - (chargePadding * 2)
            
            // Much tighter bounds with significant margin from edges
            let particleAreaTop = -(batteryContentHeight / 2) + 25
            let particleAreaBottom = (batteryContentHeight / 2) - 25  
            let particleAreaLeft = -(batteryContentWidth / 2) + 20
            let particleAreaRight = (batteryContentWidth / 2) - 20
            
            // Reduced to 8 particles for better performance
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(batteryColor.opacity(0.7))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat.random(in: particleAreaLeft...particleAreaRight),
                        y: CGFloat.random(in: particleAreaTop...particleAreaBottom)
                    )
                    .scaleEffect(pulseAnimation ? 1.3 : 0.6)
                    .opacity(pulseAnimation ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: 2.4)  // Slower: 1.2 → 2.4 seconds
                        .delay(Double(index) * 0.3)  // More staggered: 0.15 → 0.3 seconds
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    // MARK: - Floating Particles
    
    @ViewBuilder
    private var floatingParticles: some View {
        if abs(impactMinutes) > 1.0 {
            let batteryContentHeight = batteryHeight - (chargePadding * 2)
            let batteryContentWidth = batteryWidth - (chargePadding * 2)
            
            // Even tighter bounds for floating particles
            let particleAreaTop = -(batteryContentHeight / 2) + 30
            let particleAreaBottom = (batteryContentHeight / 2) - 30
            let particleAreaLeft = -(batteryContentWidth / 2) + 25  
            let particleAreaRight = (batteryContentWidth / 2) - 25
            
            // Only 4 floating particles
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(batteryColor.opacity(0.5))
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat.random(in: particleAreaLeft...particleAreaRight),
                        y: CGFloat.random(in: particleAreaTop...particleAreaBottom)
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 0.8)
                    .opacity(pulseAnimation ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 3.2)  // Slower: 1.5 → 3.2 seconds
                        .delay(Double(index) * 0.4)  // More staggered: 0.2 → 0.4 seconds  
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
        }
    }

    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            isAnimating = true
        }
        
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            pulseAnimation = true
        }
        
        // Start fill animation after a short delay
        withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
            fillAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = false
            }
        }
    }
}

// MARK: - Container

/// Container for the interactive battery view with navigation functionality
struct InteractiveBatteryContainer: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    let onTapToDrillIn: (() -> Void)?
    
    var body: some View {
        InteractiveBatteryView(
            viewModel: viewModel,
            selectedPeriod: selectedPeriod,
            onTapToDrillIn: {
                onTapToDrillIn?()
            }
        )
    }
}

// MARK: - Preview

#Preview("Interactive Battery View") {
    VStack(spacing: 40) {
        // Positive impact example
        InteractiveBatteryView(
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
            selectedPeriod: .day,
            onTapToDrillIn: {}
        )
        .frame(height: 400)
        
        // Negative impact example
        InteractiveBatteryView(
            viewModel: {
                let vm = DashboardViewModel()
                vm.lifeImpactData = LifeImpactData(
                    timePeriod: .day,
                    totalImpact: ImpactValue(
                        value: 35,
                        unit: .minutes,
                        direction: .negative
                    ),
                    batteryLevel: 25,
                    metricContributions: [:]
                )
                return vm
            }(),
            selectedPeriod: .day,
            onTapToDrillIn: {}
        )
        .frame(height: 400)
    }
    .padding()
    .background(Color.black)
} 