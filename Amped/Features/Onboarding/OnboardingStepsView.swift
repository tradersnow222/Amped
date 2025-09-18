import SwiftUI

struct OnboardingStepsView: View {
    @State private var pageIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea(.all)
            
            // Simplified content - focused on questions message
            VStack(spacing: 0) {
                Spacer()
                
                // Central message - main focus
                VStack(spacing: 16) {
                    // Main message - larger and centered
                    Text("Let's go through a few questions")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    // Time explainer
                    Text("5-8 questions, takes about 1 minute")
                        .font(.system(size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 60)
                    
                    // Swipe button with arrow - larger touch target
                    HStack {
                        Text("Swipe right to begin")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color("ampedGreen"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color("ampedGreen").opacity(0.2))
                    )
                    .frame(height: 42) // Compact touch target for better UX
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Progress bar stepper - use the new design with 12 steps
                ProgressBarStepper(currentStep: 1, totalSteps: 12)
                    .padding(.bottom, 40)
            }
        }
        .gesture(
            // iOS-STANDARD: Improved gesture handling with proper thresholds and physics
            DragGesture(minimumDistance: 8, coordinateSpace: .local) // iOS-standard minimum distance
                .onEnded { value in
                    // iOS-STANDARD: Only respond to primarily horizontal gestures
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)
                    
                    // Must be more horizontal than vertical for page swiping
                    if horizontalDistance > verticalDistance * 1.5 && horizontalDistance > 60 { // iOS-standard threshold
                        if value.translation.width > 0 {
                            // Right swipe - navigate to next screen
                            withAnimation(.interpolatingSpring(
                                mass: 1.0,
                                stiffness: 200,
                                damping: 25,
                                initialVelocity: 0
                            )) {
                                pageIndex = 1
                            }
                            
                            // iOS-STANDARD: Immediate haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred(intensity: 0.6)
                        }
                        // Left swipe - do nothing (no backward navigation)
                    }
                }
        )
    }
}

struct OnboardingStepsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingStepsView()
    }
} 