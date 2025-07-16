import SwiftUI

/// Jobs-inspired animated battery showing life energy flow - Simple, elegant, meaningful
/// Rules: Following simplicity and clean design principles
struct LifeEnergyFlowBattery: View {
    // MARK: - Properties
    
    /// Whether to show the animation
    let isAnimating: Bool
    
    /// Time impact in minutes (positive = gained, negative = lost)
    let timeImpactMinutes: Double
    
    /// Current battery charge level (0.0 to 1.0)
    var chargeLevel: Double {
        // Convert time impact to meaningful charge level
        let maxImpactMinutes: Double = 240 // 4 hours max impact
        let normalizedImpact = max(-maxImpactMinutes, min(maxImpactMinutes, timeImpactMinutes))
        let baseCharge = 0.5 // 50% baseline
        let impactRange = 0.4 // ±40% range
        
        let chargeAdjustment = (normalizedImpact / maxImpactMinutes) * impactRange
        return max(0.1, min(1.0, baseCharge + chargeAdjustment))
    }
    
    /// Battery color based on impact
    var batteryColor: Color {
        if timeImpactMinutes > 0 {
            return .ampedGreen
        } else if timeImpactMinutes < 0 {
            return .ampedRed
        } else {
            return .ampedYellow
        }
    }
    
    /// Direction of energy flow
    var energyDirection: EnergyDirection {
        timeImpactMinutes >= 0 ? .upward : .downward
    }
    
    // MARK: - Animation States
    
    @State private var animationPhase: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.3
    @State private var showContent = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Main battery with energy flow
            ZStack {
                // Background battery shell
                batteryShell
                
                // Energy flow particles
                if isAnimating && showContent {
                    energyFlowParticles
                }
                
                // Battery charge fill
                batteryChargeFill
                
                // Glow effect overlay
                if isAnimating && showContent {
                    glowOverlay
                }
            }
            .frame(width: 120, height: 160)
            .scaleEffect(pulseScale)
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }
    
    // MARK: - Battery Components
    
    /// Clean, minimalist battery shell
    private var batteryShell: some View {
        ZStack {
            // Main battery body
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            
            // Battery terminal (top nub) - iconic Apple design
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.gray.opacity(0.8),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 10)
                .offset(y: -85)
                .shadow(color: Color.white.opacity(0.4), radius: 3, y: 1)
        }
    }
    
    /// Battery charge fill with smooth animation
    private var batteryChargeFill: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            batteryColor,
                            batteryColor.opacity(0.8),
                            batteryColor.opacity(0.6)
                        ],
                        startPoint: energyDirection == .upward ? .bottom : .top,
                        endPoint: energyDirection == .upward ? .top : .bottom
                    )
                )
                .frame(height: geometry.size.height * chargeLevel)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 1.2), value: chargeLevel)
                .animation(.easeOut(duration: 0.8), value: showContent)
        }
        .padding(4)
    }
    
    /// Flowing energy particles - inspired by Jobs' attention to detail
    private var energyFlowParticles: some View {
        GeometryReader { geometry in
            ForEach(0..<8, id: \.self) { index in
                EnergyParticle(
                    index: index,
                    phase: animationPhase,
                    direction: energyDirection,
                    color: batteryColor,
                    containerSize: CGSize(width: geometry.size.width, height: geometry.size.height)
                )
            }
        }
    }
    
    /// Subtle glow effect for premium feel
    private var glowOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [
                        batteryColor.opacity(glowIntensity),
                        Color.clear,
                        batteryColor.opacity(glowIntensity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .blur(radius: 2)
            .shadow(color: batteryColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    

    
    // MARK: - Animation Methods
    
    private func startAnimations() {
        // Content reveal animation
        withAnimation(.easeOut(duration: 0.6)) {
            showContent = true
        }
        
        // Energy flow animation
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
        
        // Subtle pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            glowIntensity = 0.6
        }
    }
    
    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
            glowIntensity = 0.3
        }
    }
}

// MARK: - Energy Particle

/// Individual energy particle for the flow animation
private struct EnergyParticle: View {
    let index: Int
    let phase: Double
    let direction: EnergyDirection
    let color: Color
    let containerSize: CGSize
    
    @State private var particlePosition: CGPoint = .zero
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color,
                        color.opacity(0.6),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 3
                )
            )
            .frame(width: 6, height: 6)
            .position(particlePosition)
            .opacity(particleOpacity)
            .onChange(of: phase) { newPhase in
                updateParticle(phase: newPhase)
            }
            .onAppear {
                updateParticle(phase: 0)
            }
    }
    
    private func updateParticle(phase: Double) {
        // Calculate particle position based on phase and index
        let adjustedPhase = (phase + Double(index) * 0.125).truncatingRemainder(dividingBy: 1.0)
        
        // Vertical movement based on direction
        let yProgress = direction == .upward ? (1.0 - adjustedPhase) : adjustedPhase
        let yPosition = containerSize.height * 0.8 * yProgress + containerSize.height * 0.1
        
        // Slight horizontal variation for natural movement
        let xOffset = sin(adjustedPhase * .pi * 2 + Double(index)) * 8
        let xPosition = containerSize.width * 0.5 + xOffset
        
        // Fade in/out based on position
        let opacity = sin(adjustedPhase * .pi) * 0.8
        
        withAnimation(.linear(duration: 0.1)) {
            particlePosition = CGPoint(x: xPosition, y: yPosition)
            particleOpacity = opacity
        }
    }
}

// MARK: - Supporting Types

/// Energy flow direction
enum EnergyDirection {
    case upward
    case downward
}

// MARK: - Preview

struct LifeEnergyFlowBattery_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Positive impact
                LifeEnergyFlowBattery(
                    isAnimating: true,
                    timeImpactMinutes: 120
                )
                
                // Negative impact
                LifeEnergyFlowBattery(
                    isAnimating: true,
                    timeImpactMinutes: -60
                )
                
                // Neutral
                LifeEnergyFlowBattery(
                    isAnimating: true,
                    timeImpactMinutes: 0
                )
            }
        }
    }
} 