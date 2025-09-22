import SwiftUI

/// Before/After transformation screen showing the journey from basic to enhanced health tracking
struct BeforeAfterTransformationView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Full screen linear gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red:0/255, green:146/255, blue:69/255), location: 0.0),
                    .init(color: Color(red:252/255, green:238/255, blue:33/255), location: 0.8)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Black gradient overlay from transparent to black at bottom
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color.black.opacity(0.8), location: 0.5),
                        .init(color: Color.black.opacity(0.9), location: 0.6),
                        .init(color: Color.black.opacity(1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: .infinity) // Adjust height as needed
            }
            .edgesIgnoringSafeArea(.all)
            
             // Main content
             VStack(spacing: 0) {
                 Image("beforeafter")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                 Spacer()
                     .frame(height:40)
                Spacer()
                
                // Before/After illustration
                VStack(spacing: 40) {
                    
                    // Main headline
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            Text("Add time to your ")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Life")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color.green)
                        }
                        
//                        Text("You!")
//                            .font(.system(size: 32, weight: .bold))
//                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: animateElements)
                    
                    // Subtitle
                    Text("This app can enhance your health and extend your life. Dive in to discover all the ways it can help you reach your full potential.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(1.4), value: animateElements)
                    
                    // Research backing
                    Text("Fully backed by research")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(1.6), value: animateElements)
                }
                .padding(.bottom, 30)
                
                // Get Started button
                Button(action: {
                    onContinue?()
                }) {
                    HStack(spacing: 8) {
                        Text("Get started")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                }
                .padding(.horizontal, 28)
                .opacity(animateElements ? 1 : 0)
                .scaleEffect(animateElements ? 1 : 0.9)
                .animation(.easeOut(duration: 0.8).delay(1.8), value: animateElements)
                
                Spacer()
                    .frame(height: 40)
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

struct BeforeAfterTransformationView_Previews: PreviewProvider {
    static var previews: some View {
        BeforeAfterTransformationView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
