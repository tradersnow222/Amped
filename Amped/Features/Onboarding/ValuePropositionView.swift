import SwiftUI

/// Value proposition screen explaining how Amped helps users live longer
struct ValuePropositionView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    @State private var batteryFillLevel: CGFloat = 0.0
    @State private var iconScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0.3
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background - follows PersonalizationIntroView pattern
            Color.clear.withDeepBackground()
            
            VStack(spacing: 0) {
                // Main content - no scroll view needed
                VStack(spacing: 40) {
                    // Header section - positioned for rule of thirds
                    VStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("Live Longer.")
                                .font(.system(size: 38, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text("Live Stronger.")
                                .font(.system(size: 38, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.9), value: animateElements)
                        
                        Text("See exactly how your habits affect your lifespan.")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 15)
                            .animation(.easeOut(duration: 0.9).delay(0.15), value: animateElements)
                    }
                    .padding(.top, 80)
                    
                    // Animated battery visualization
                    batteryVisualizationView
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .animation(.spring(response: 0.72, dampingFraction: 0.978).delay(0.25), value: animateElements)
                    
                    // Value propositions - simplified
                    VStack(spacing: 24) {
                        valuePropositionItem(
                            icon: "heart.fill",
                            title: "Track Impact",
                            description: "See which habits add or cut years from your life",
                            delay: 0.3
                        )
                        
                        valuePropositionItem(
                            icon: "clock.fill",
                            title: "Live Guidance",
                            description: "View the results of your choices in real-time",
                            delay: 0.4
                        )
                        
                        valuePropositionItem(
                            icon: "lightbulb.fill",
                            title: "Smart Actions",
                            description: "Get steps to live longer, tailored to you",
                            delay: 0.5
                        )
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                // Bottom section with button
                VStack(spacing: 0) {
                    Button(action: {
                        onContinue?()
                    }) {
                        Text("Get Started")
                            .fontWeight(.bold)
                            .font(.system(.title3, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.ampedGreen)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .cornerRadius(14)
                    }
                    .hapticFeedback(.medium)
                    .padding(.horizontal, 40)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .opacity(animateElements ? 1 : 0)
                    .scaleEffect(animateElements ? 1 : 0.9)
                    .animation(.spring(response: 0.72, dampingFraction: 0.978).delay(0.7), value: animateElements)
                    .withButtonInitiatedTransition()
                    
                    // Add spacer to match other onboarding screens
                    Spacer().frame(height: 120)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            // Trigger animations
            withAnimation {
                animateElements = true
            }
            
            // Start battery fill animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.8)) {
                    batteryFillLevel = 0.85
                }
                
                // Add subtle glow pulse animation
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.7
                    iconScale = 1.1
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var batteryVisualizationView: some View {
        VStack(spacing: 16) {
            // Battery container with fill animation
            ZStack {
                // Battery outline
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ampedGreen, lineWidth: 4)
                    .frame(width: 140, height: 80)
                
                // Battery fill that animates from empty to filled
                GeometryReader { geometry in
                    let fillWidth = (140 - 8) * batteryFillLevel // Account for stroke width
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.ampedGreen.opacity(0.8),
                                    Color.ampedGreen
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 72)
                        .position(x: 4 + fillWidth/2, y: geometry.size.height/2)
                }
                .frame(width: 140, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Battery tip
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.ampedGreen)
                    .frame(width: 8, height: 40)
                    .offset(x: 78)
                
                // Glow effect
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ampedGreen.opacity(glowOpacity), lineWidth: 2)
                    .frame(width: 150, height: 90)
                    .blur(radius: 4)
                
                // Heart icon in center
                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .scaleEffect(iconScale)
            }
        }
    }
    
    private func valuePropositionItem(icon: String, title: String, description: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(Color.ampedGreen.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.ampedGreen)
            }
            .scaleEffect(animateElements ? 1 : 0.8)
            .animation(.spring(response: 0.72, dampingFraction: 0.978).delay(delay), value: animateElements)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
            .opacity(animateElements ? 1 : 0)
            .offset(x: animateElements ? 0 : 20)
            .animation(.easeOut(duration: 0.9).delay(delay + 0.15), value: animateElements)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct ValuePropositionView_Previews: PreviewProvider {
    static var previews: some View {
        ValuePropositionView(onContinue: {})
            .preferredColorScheme(.dark)
    }
} 