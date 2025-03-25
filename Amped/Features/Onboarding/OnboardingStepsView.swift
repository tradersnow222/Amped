import SwiftUI

struct OnboardingStepsView: View {
    @State private var pageIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("ampedDark").opacity(0.9),
                    Color("ampedDark")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Bottom nature background
            Image("onboardingBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.2)
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.8)
            
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
                    .frame(height: 54) // Larger touch target for better UX
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Progress indicator
                ProgressView(value: 0.2, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("ampedGreen")))
                    .frame(width: UIScreen.main.bounds.width * 0.5)
                    .padding(.bottom, 20)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < 0 {
                        // Left swipe - do nothing
                    } else if value.translation.width > 0 {
                        // Right swipe - navigate to next screen
                        withAnimation {
                            pageIndex = 1
                        }
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