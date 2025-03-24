import SwiftUI

/// Battery animations including charging, discharging, and energy flow effects
struct BatteryAnimations {
    
    // MARK: - Charging Animation
    
    /// Animates the charging of a battery
    struct ChargingAnimation: View {
        // MARK: - Properties
        
        /// Current charge level (0-1)
        let chargeLevel: Double
        
        /// Whether to show the animation
        let isAnimating: Bool
        
        /// Optional color for the charging effect (defaults to green)
        var chargingColor: Color = .green
        
        /// State to track the phase of the animation
        @State private var animationPhase: Double = 0
        @State private var isRunning = false
        
        // MARK: - Body
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Battery silhouette
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    // Charging animation effect (small particles flowing upward)
                    if isAnimating && chargeLevel < 0.99 {
                        ForEach(0..<20) { index in
                            ChargingParticle(index: index, phase: animationPhase, height: geometry.size.height, width: geometry.size.width)
                                .foregroundStyle(chargingColor.opacity(0.7))
                        }
                    }
                }
                .onAppear {
                    isRunning = true
                    startAnimation()
                }
                .onDisappear {
                    isRunning = false
                }
            }
        }
        
        // MARK: - Methods
        
        private func startAnimation() {
            guard isRunning else { return }
            
            // Animate with a repeating pattern
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
    
    // MARK: - Charging Particle
    
    /// Individual particle in the charging animation
    struct ChargingParticle: View {
        let index: Int
        let phase: Double
        let height: CGFloat
        let width: CGFloat
        
        @State private var particleOffset: CGSize = .zero
        
        var body: some View {
            Circle()
                .frame(width: 4, height: 4)
                .offset(particleOffset)
                .opacity(particleOpacity())
                .onAppear {
                    // Randomize starting position for more natural effect
                    let xPos = CGFloat.random(in: 4...(width - 8))
                    let yPos = height + 10 - (height * CGFloat(phase) * randomFactor())
                    
                    particleOffset = CGSize(width: xPos, height: yPos)
                }
                .onChange(of: phase) { oldValue, newValue in
                    // Update position as animation phase changes
                    let xPos = CGFloat.random(in: 4...(width - 8))
                    let yPos = height + 10 - (height * CGFloat(newValue) * randomFactor())
                    
                    withAnimation(.linear(duration: 0.1)) {
                        particleOffset = CGSize(width: xPos, height: yPos)
                    }
                }
        }
        
        private func randomFactor() -> CGFloat {
            // Create different speeds for particles
            return CGFloat.random(in: 0.5...1.5)
        }
        
        private func particleOpacity() -> Double {
            // Vary the opacity for a more natural look
            return Double.random(in: 0.3...0.9)
        }
    }
    
    // MARK: - Energy Flow Animation
    
    /// Animates energy flowing between batteries
    struct EnergyFlowAnimation: View {
        // MARK: - Properties
        
        /// Whether to show the animation
        let isAnimating: Bool
        
        /// Start point of the flow (normalized coordinates)
        let startPoint: UnitPoint
        
        /// End point of the flow (normalized coordinates)
        let endPoint: UnitPoint
        
        /// Color of the energy flow
        var flowColor: Color = .green
        
        /// State to track the phase of the animation
        @State private var animationPhase: Double = 0
        @State private var isRunning = false
        
        // MARK: - Body
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Energy particles flowing along the path
                    if isAnimating {
                        ForEach(0..<10) { index in
                            FlowParticle(
                                index: index,
                                phase: animationPhase,
                                startPoint: CGPoint(
                                    x: startPoint.x * geometry.size.width,
                                    y: startPoint.y * geometry.size.height
                                ),
                                endPoint: CGPoint(
                                    x: endPoint.x * geometry.size.width,
                                    y: endPoint.y * geometry.size.height
                                )
                            )
                            .foregroundStyle(flowColor)
                        }
                    }
                }
                .onAppear {
                    isRunning = true
                    startAnimation()
                }
                .onDisappear {
                    isRunning = false
                }
            }
        }
        
        // MARK: - Methods
        
        private func startAnimation() {
            guard isRunning else { return }
            
            // Animate with a repeating pattern
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
    
    // MARK: - Flow Particle
    
    /// Individual particle in the energy flow animation
    struct FlowParticle: View {
        let index: Int
        let phase: Double
        let startPoint: CGPoint
        let endPoint: CGPoint
        
        @State private var particleOffset: CGPoint = .zero
        
        var body: some View {
            Circle()
                .frame(width: 6, height: 6)
                .position(particlePosition())
                .opacity(particleOpacity())
                .onChange(of: phase) { oldValue, newValue in
                    // Particle moves from start to end repeatedly
                    updatePosition(newValue)
                }
                .onAppear {
                    // Initial position
                    let initialPhase = Double(index) / 10.0
                    updatePosition(initialPhase)
                }
        }
        
        private func updatePosition(_ phase: Double) {
            // Calculate position along the path
            let adjustedPhase = (phase + Double(index) / 10.0).truncatingRemainder(dividingBy: 1.0)
            
            // Move along a straight line from start to end
            let x = startPoint.x + (endPoint.x - startPoint.x) * adjustedPhase
            let y = startPoint.y + (endPoint.y - startPoint.y) * adjustedPhase
            
            particleOffset = CGPoint(x: x, y: y)
        }
        
        private func particlePosition() -> CGPoint {
            return particleOffset
        }
        
        private func particleOpacity() -> Double {
            // Particles fade in and out as they move
            let distanceFromMiddle = abs((phase + Double(index) / 10.0).truncatingRemainder(dividingBy: 1.0) - 0.5) * 2
            return 1.0 - distanceFromMiddle * 0.8
        }
    }
    
    // MARK: - Pulse Animation
    
    /// Creates a pulsing animation for a battery that's actively charging or discharging
    struct PulseAnimation: View {
        // MARK: - Properties
        
        /// Whether the animation is active
        let isAnimating: Bool
        
        /// Color of the pulse effect
        var pulseColor: Color = .green
        
        /// State for the animation
        @State private var scale: CGFloat = 0.95
        @State private var opacity: Double = 0.8
        @State private var isRunning = false
        
        // MARK: - Body
        
        var body: some View {
            GeometryReader { geometry in
                if isAnimating {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(pulseColor)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            isRunning = true
                            startAnimation()
                        }
                        .onDisappear {
                            isRunning = false
                        }
                }
            }
        }
        
        // MARK: - Methods
        
        private func startAnimation() {
            guard isRunning else { return }
            
            // Create subtle pulsing effect
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.03
                opacity = 0.5
            }
        }
    }
} 