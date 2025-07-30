import SwiftUI
import OSLog

// Import the DashboardViewModel
// Note: This import resolves the "cannot find type 'DashboardViewModel'" error

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

/// Triangle shape for tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// Left-pointing arrow shape for chat bubble
struct LeftArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Chat bubble arrow shape pointing diagonally down-left toward the battery
struct ChatBubbleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Create a diagonal arrow pointing down and left toward the battery
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - 2)) // Point (down and left)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // Top right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 2)) // Bottom right
        path.closeSubpath()
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
    
    @Environment(\.glassTheme) private var glassTheme: GlassThemeManager
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var fillAnimation = false
    @State private var tapIconScale: CGFloat = 1.0
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "InteractiveBatteryView")
    
    // MARK: - Constants
    
    private let batteryWidth: CGFloat = 150
    private let batteryHeight: CGFloat = 220
    private let batteryCornerRadius: CGFloat = 24
    private let terminalWidth: CGFloat = 55
    private let terminalHeight: CGFloat = 14
    private let terminalCornerRadius: CGFloat = 8
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
        GeometryReader { geometry in
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
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Personal color explanation positioned as chat bubble to the right of battery
                colorExplanationCallout
                    .position(
                        x: geometry.size.width / 2 + batteryWidth / 2 + 50, // Closer to battery
                        y: geometry.size.height / 2 + 20 - 40 - 40 - 10 - 8 // Just a pinch higher
                    )
            }
        }
        .frame(height: batteryHeight + 50) // Give enough height for the battery
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Battery View
    
    @ViewBuilder
    private var batteryView: some View {
        // Main battery visualization - REALISTIC and ENHANCED
        ZStack {
            // Battery body with depth and realistic shadows
            ZStack {
                // Background shadow for depth
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: batteryWidth, height: batteryHeight)
                    .offset(x: 2, y: 2)
                
                // Main battery body with subtle gradient
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery outline with realistic border
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: batteryWidth, height: batteryHeight)
            }
            
            // Enhanced battery terminal (top) with more realistic appearance
            ZStack {
                // Terminal shadow
                RoundedRectangle(cornerRadius: terminalCornerRadius)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: terminalWidth, height: terminalHeight)
                    .offset(x: 1, y: -(batteryHeight/2 + terminalHeight/2) + 1)
                
                // Main terminal body
                RoundedRectangle(cornerRadius: terminalCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: terminalWidth, height: terminalHeight)
                    .offset(y: -(batteryHeight/2 + terminalHeight/2))
                
                // Terminal outline
                RoundedRectangle(cornerRadius: terminalCornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: terminalWidth, height: terminalHeight)
                    .offset(y: -(batteryHeight/2 + terminalHeight/2))
            }
            
            // MARK: - Enhanced Battery Fill Content - Always 100% filled
            
            // Always fill entire battery, color indicates impact value
            ZStack(alignment: .bottom) {
                // Enhanced battery fill with realistic gradients and depth
                RoundedRectangle(cornerRadius: batteryCornerRadius - 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor.opacity(0.9),
                                batteryColor,
                                batteryColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Inner highlight for realistic lighting
                        RoundedRectangle(cornerRadius: batteryCornerRadius - 8)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        batteryColor.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                ),
                                lineWidth: 1
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
            
            // MARK: - Tap Hint Inside Battery
            tapHintInsideBattery
        }
        .frame(width: batteryWidth, height: batteryHeight)
    }
    
    // MARK: - Tap Hint Inside Battery
    
    @ViewBuilder
    private var tapHintInsideBattery: some View {
        VStack(spacing: 4) {
            Text("Tap to see your contributing habits")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .shadow(color: .white, radius: 2, x: 0, y: 0)
                .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0)
                .multilineTextAlignment(.center)
            
            // Animated tapping icon centered below text
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .shadow(color: .white, radius: 2, x: 0, y: 0)
                .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0)
                .scaleEffect(tapIconScale)
                .animation(
                    Animation
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: tapIconScale
                )
                .onAppear {
                    tapIconScale = 1.2
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .offset(y: 15) // Position in lower part of battery
    }
    
    // MARK: - Color Explanation Callout
    
    @ViewBuilder
    private var colorExplanationCallout: some View {
        HStack(spacing: 0) {
            // Chat bubble arrow pointing left toward the battery
            ChatBubbleArrow()
                .fill(.ultraThinMaterial.opacity(0.8))
                .frame(width: 35, height: 20)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .offset(y: 8) // Start arrow from lower position on tooltip
            
            // Chat bubble content
            VStack(spacing: 6) {
                // Compact color progression
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brightFluorescentRed)
                        .frame(width: 8, height: 8)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Circle()
                        .fill(Color.brightFluorescentGreen)
                        .frame(width: 8, height: 8)
                }
                
                // Compact message
                VStack(spacing: 2) {
                    Text("Watch colors")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("change as you")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("improve!")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
    }
    
    // MARK: - Charging Particles
    
    @ViewBuilder
    private var chargingParticles: some View {
        if abs(impactMinutes) > 1.0 {
            // Tighter bounds - particles stay strictly within battery
            let batteryContentHeight = batteryHeight - (chargePadding * 2)
            let batteryContentWidth = batteryWidth - (chargePadding * 2)
            
            // Much tighter bounds with significant margin from edges
            let particleAreaTop = -(batteryContentHeight / 2) + 30      // Increased margin
            let particleAreaBottom = (batteryContentHeight / 2) - 30    // Increased margin
            let particleAreaLeft = -(batteryContentWidth / 2) + 25
            let particleAreaRight = (batteryContentWidth / 2) - 25
            
            // Reduced to 4 particles for cleaner look (from 8)
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(batteryColor.opacity(0.5))  // Reduced opacity from 0.7
                    .frame(width: 3, height: 3)       // Reduced size from 4
                    .offset(
                        x: CGFloat.random(in: particleAreaLeft...particleAreaRight),
                        y: CGFloat.random(in: particleAreaTop...particleAreaBottom)
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 0.5)  // Reduced scale range
                    .opacity(pulseAnimation ? 0.6 : 0.3)      // Reduced opacity range
                    .animation(
                        .easeInOut(duration: 2.8)    // Slower: 2.4 → 2.8 seconds
                        .delay(Double(index) * 0.4)  // More staggered timing
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    // MARK: - Floating Particles
    
    @ViewBuilder
    private var floatingParticles: some View {
        let batteryContentHeight = batteryHeight - (chargePadding * 2)
        let batteryContentWidth = batteryWidth - (chargePadding * 2)
        
        // Even tighter bounds for floating particles
        let particleAreaTop = -(batteryContentHeight / 2) + 35      // Increased margin
        let particleAreaBottom = (batteryContentHeight / 2) - 35    // Increased margin
        let particleAreaLeft = -(batteryContentWidth / 2) + 30      // Increased margin
        let particleAreaRight = (batteryContentWidth / 2) - 30     // Increased margin
        
        // Reduced to 2 floating particles (from 4)
        ForEach(0..<2, id: \.self) { index in
            Circle()
                .fill(batteryColor.opacity(0.3))  // Reduced opacity from 0.5
                .frame(width: 2, height: 2)       // Reduced size from 3
                .offset(
                    x: CGFloat.random(in: particleAreaLeft...particleAreaRight),
                    y: CGFloat.random(in: particleAreaTop...particleAreaBottom)
                )
                .scaleEffect(pulseAnimation ? 1.0 : 0.6)  // Reduced scale range
                .opacity(pulseAnimation ? 0.4 : 0.2)      // Reduced opacity range
                .animation(
                    .easeInOut(duration: 3.8)    // Slower: 3.2 → 3.8 seconds
                    .delay(Double(index) * 0.6)  // More staggered timing
                    .repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
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