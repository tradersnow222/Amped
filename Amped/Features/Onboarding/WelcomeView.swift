import SwiftUI

/// Initial welcoming screen for the onboarding flow
struct WelcomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = WelcomeViewModel()
    @State private var isAnimating = false
    @State private var glowOpacity = 0.7
    @State private var scale = 1.0
    @State private var isAppeared = false
    @State private var autoAdvanceTask: Task<Void, Never>? = nil
    
    // Animation constants
    private let pulseAnimationDuration: Double = 1.0
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Battery image as full-screen background
                Image("BatteryBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        // Overlay to ensure text readability
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.2)
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipped()
                
                VStack {
                    // Battery content area
                    // This positions the content to appear within the green battery section
                    GeometryReader { innerGeometry in
                        // Main content - Amped and lightning bolt
                        VStack(spacing: 16) {
                            Text("Amped")
                                .font(.system(size: 42, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .shadow(color: Color.ampedGreen, radius: 1.8, x: 0, y: 0)
                                .shadow(color: Color.white.opacity(0.5), radius: 0.4, x: 0, y: 0)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .frame(maxWidth: innerGeometry.size.width * 0.8)
                                .padding(.bottom, 6)
                            
                            // Lightning bolt icon - much bigger with animation
                            ZStack {
                                // Glow effect
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(glowOpacity))
                                    .shadow(color: Color.ampedGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                                
                                // Main icon
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(scale)
                            .padding(.vertical, 8)
                        }
                        .frame(width: innerGeometry.size.width)
                        // Restore the original position for Amped and lightning bolt
                        .position(x: innerGeometry.size.width / 2, y: innerGeometry.size.height * 0.48)
                        
                        // Tagline positioned lower in the view (rule of thirds)
                        VStack(spacing: 8) {
                            Text("Your")
                                .font(.callout.monospaced())
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                            
                            Text("LIFE BATTERY")
                                .font(.callout.monospaced())
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: Color.ampedGreen, radius: 1.5, x: 0, y: 0)
                                .shadow(color: Color.white.opacity(0.5), radius: 0.3, x: 0, y: 0)
                                .lineLimit(1)
                            
                            Text("in real-time")
                                .font(.callout.monospaced())
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: innerGeometry.size.width * 0.75)
                        // Position at approximately 2/3 down the battery (rule of thirds)
                        .position(x: innerGeometry.size.width / 2, y: innerGeometry.size.height * 0.7)
                    }
                    
                    Spacer()
                    
                    // Invisible spacer to maintain text positioning where button used to be
                    // This accounts for the button height + padding + bottom spacer that was removed
                    Spacer().frame(height: 180) // Button area + bottom spacing that was removed
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .withWelcomeTransition(isPresented: isAppeared)
        .onTapGesture {
            // Cancel auto-advance and navigate immediately when user taps
            autoAdvanceTask?.cancel()
            onContinue?()
        }
        .onAppear {
            // Trigger the fade-in animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAppeared = true
                
                // Start lightning bolt pulse animation after elements appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: pulseAnimationDuration).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.95
                        scale = 1.15
                    }
                }
                
                // Auto-advance to next screen after 4 seconds
                autoAdvanceTask = Task {
                    try? await Task.sleep(for: .seconds(4.0))
                    if !Task.isCancelled {
                        await MainActor.run {
                            onContinue?()
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Clean up the auto-advance task when view disappears
            autoAdvanceTask?.cancel()
        }
    }
}

// MARK: - Progress Indicator

/// Battery-styled progress indicator showing completion steps
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    // MARK: - UI Constants
    private let barHeight: CGFloat = 16
    private let horizontalMargin: CGFloat = 40
    private let borderWidth: CGFloat = 1.5
    private let segmentSpacing: CGFloat = 2
    private let cornerRadius: CGFloat = 3
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalMargin * 2)
            let segmentWidth = (availableWidth / CGFloat(totalSteps)) - segmentSpacing
            
            HStack(spacing: 2) {
                Spacer(minLength: horizontalMargin)
                
                // Main battery body
                ZStack(alignment: .leading) {
                    // Empty battery background with outline
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.ampedGreen.opacity(0.05))
                        .frame(width: availableWidth, height: barHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(Color.ampedGreen, lineWidth: borderWidth)
                        )
                    
                    // Battery segments - one segment per onboarding step (including individual questions)
                    HStack(spacing: segmentSpacing) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            // Each segment has a chevron or forward-pointing shape
                            ChevronSegment(
                                isComplete: index < currentStep,
                                width: segmentWidth,
                                height: barHeight - (borderWidth * 2),
                                isFirstSegment: index == 0
                            )
                        }
                    }
                    .padding(.horizontal, borderWidth)
                    .background(Color.ampedGreen.opacity(0.08)) // More subtle background for dividers
                }
                .frame(height: barHeight)
                
                Spacer(minLength: horizontalMargin)
            }
        }
        .frame(height: barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(currentStep) of \(totalSteps) steps completed")
    }
}

/// A chevron-shaped segment for the battery progress indicator
struct ChevronSegment: View {
    let isComplete: Bool
    let width: CGFloat
    let height: CGFloat
    let isFirstSegment: Bool
    
    var body: some View {
        ZStack {
            // Base segment
            ForwardShape(isFirstSegment: isFirstSegment)
                .fill(isComplete ? Color.ampedGreen : Color.gray.opacity(0.2))
                .frame(width: width, height: height)
        }
    }
}

/// A custom shape with a pronounced forward/chevron appearance
struct ForwardShape: Shape {
    var isFirstSegment: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a more pronounced forward-pointing shape
        let chevronOffset: CGFloat = rect.height * 0.4
        
        // First segment has a straight left edge
        if isFirstSegment {
            // Start at bottom left
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            
            // Straight line up to top left
            path.addLine(to: CGPoint(x: 0, y: rect.minY))
            
            // Line to top right 
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            
            // Line to bottom right with inward angle
            path.addLine(to: CGPoint(x: rect.maxX - chevronOffset, y: rect.maxY))
        } else {
            // Start at bottom left
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            
            // Line to top left with inward angle
            path.addLine(to: CGPoint(x: chevronOffset, y: rect.minY))
            
            // Line to top right
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            
            // Line to bottom right with inward angle
            path.addLine(to: CGPoint(x: rect.maxX - chevronOffset, y: rect.maxY))
        }
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

// MARK: - ViewModel

final class WelcomeViewModel: ObservableObject {
    // Keep the ViewModel minimal since we're using callbacks for navigation
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: {})
            .preferredColorScheme(.light)
        
        WelcomeView(onContinue: {})
            .preferredColorScheme(.dark)
    }
} 