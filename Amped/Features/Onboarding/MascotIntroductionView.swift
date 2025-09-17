import SwiftUI

/// First mascot introduction screen - "Hi, I am Amped battery"
struct MascotIntroductionView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    @EnvironmentObject var appState: AppState
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    // Callback to skip naming and use default
    var onSkip: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 12) {
                    // Mascot character
                    Image("steptwo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                    
                    // Greeting text
                    Text("Hi, I am Amped battery.")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
                }
                .padding(.bottom, 12)
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary button - "Want to give me a name?"
                    Button(action: {
                        onContinue?()
                    }) {
                        Text("Want to give me a name?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red:0/255, green:146/255, blue:69/255),
                                        Color(red:252/255, green:238/255, blue:33/255)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 28)
                    .opacity(animateElements ? 1 : 0)
                    .scaleEffect(animateElements ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
                    
                    // Secondary button - "Skip & Continue"
                    Button(action: {
                        // Skip naming and continue with default name
                        onSkip?()
                    }) {
                        Text("Skip & Continue")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: animateElements)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
}

// MARK: - Preview

struct MascotIntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        MascotIntroductionView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
