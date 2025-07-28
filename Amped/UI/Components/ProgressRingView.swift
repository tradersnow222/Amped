import SwiftUI

/// A customizable progress ring view inspired by fitness tracking apps
/// Rule: Simplicity is KING - Clean, reusable component for visual progress indication
struct ProgressRingView: View {
    // MARK: - Properties
    
    /// Progress value from 0.0 to 1.0
    let progress: Double
    
    /// Width of the ring stroke
    let ringWidth: CGFloat
    
    /// Diameter of the ring
    let size: CGFloat
    
    /// Gradient colors for the progress ring
    let gradientColors: [Color]
    
    /// Background ring color
    let backgroundColor: Color
    
    /// Optional icon to display in the center
    var centerContent: AnyView?
    
    // MARK: - Initialization
    
    init(
        progress: Double,
        ringWidth: CGFloat = 20,
        size: CGFloat = 150,
        gradientColors: [Color] = [.ampedGreen],
        backgroundColor: Color = Color.white.opacity(0.2),
        centerContent: AnyView? = nil
    ) {
        self.progress = max(0, min(1, progress)) // Clamp to 0-1
        self.ringWidth = ringWidth
        self.size = size
        self.gradientColors = gradientColors
        self.backgroundColor = backgroundColor
        self.centerContent = centerContent
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: ringWidth)
                .frame(width: size - ringWidth, height: size - ringWidth) // Inset by stroke width
            
            // Progress ring with gradient
            if gradientColors.count == 1 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        gradientColors[0],
                        style: StrokeStyle(
                            lineWidth: ringWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: size - ringWidth, height: size - ringWidth) // Inset by stroke width
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            } else {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270 * progress - 90)
                        ),
                        style: StrokeStyle(
                            lineWidth: ringWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: size - ringWidth, height: size - ringWidth) // Inset by stroke width
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
            
            // Optional center content
            if let content = centerContent {
                content
            }
        }
        .frame(width: size, height: size) // CRITICAL: Enforce perfect square constraint
        .aspectRatio(1.0, contentMode: .fit) // CRITICAL: Maintain perfect circle aspect ratio
        .drawingGroup() // Rule: Performance optimization for smooth animations
    }

}

// MARK: - Convenience Initializers

extension ProgressRingView {
    /// Creates a progress ring with impact-based coloring
    /// Rule: Consistent visual language for health impacts
    static func impactRing(
        impactMinutes: Double,
        size: CGFloat = 150,
        ringWidth: CGFloat = 20
    ) -> ProgressRingView {
        // Map -120 to +120 range to 0.0 to 1.0
        let normalizedProgress = (impactMinutes + 120) / 240
        
        // Determine colors based on impact
        let colors: [Color] = {
            if impactMinutes < -60 {
                return [.ampedRed.opacity(0.8), .ampedRed]
            } else if impactMinutes < 0 {
                return [.ampedRed, .ampedYellow]
            } else if impactMinutes < 60 {
                return [.ampedYellow, .ampedGreen]
            } else {
                return [.ampedGreen.opacity(0.8), .ampedGreen]
            }
        }()
        
        return ProgressRingView(
            progress: normalizedProgress,
            ringWidth: ringWidth,
            size: size,
            gradientColors: colors,
            backgroundColor: Color.white.opacity(0.15)
        )
    }
}

// MARK: - Preview

#Preview("Progress Ring Variations") {
    VStack(spacing: 40) {
        // Basic progress ring
        ProgressRingView(
            progress: 0.75,
            gradientColors: [.ampedGreen]
        )
        
        // Impact-based ring with negative impact
        ProgressRingView.impactRing(
            impactMinutes: -45,
            size: 120
        )
        
        // Impact-based ring with positive impact
        ProgressRingView.impactRing(
            impactMinutes: 90,
            size: 120
        )
        
        // Ring with center content
        ProgressRingView(
            progress: 0.6,
            ringWidth: 12,
            size: 100,
            gradientColors: [.ampedYellow, .ampedGreen],
            centerContent: AnyView(
                Text("60%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
        )
    }
    .padding()
    .background(Color.black)
} 