import SwiftUI

/// Second mascot screen - "What do you want to call me?" with text input
struct MascotNamingView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    @State private var mascotName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Callback to proceed to next step with the chosen name
    var onContinue: ((String) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 23) {
                    // Mascot character (smaller than previous screen)
                    Image("emma")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 174, height: 174)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                    
                    // Question text
                    Text("What do you want to call me?")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
                    
                    // Text input field
                    TextField("", text: $mascotName)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        .focused($isTextFieldFocused)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.9)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateElements)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 40)
                
                // Continue button
                Button(action: {
                    let finalName = mascotName.isEmpty ? "Emma" : mascotName
                    onContinue?(finalName)
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    mascotName.isEmpty ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red:0/255, green:146/255, blue:69/255),
                                            Color(red:252/255, green:238/255, blue:33/255)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 28)
                .opacity(animateElements ? 1 : 0)
                .scaleEffect(animateElements ? 1 : 0.9)
                .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateElements = true
            }
            // Auto-focus the text field after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTextFieldFocused = true
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isTextFieldFocused = false
        }
    }
}

// MARK: - Preview

struct MascotNamingView_Previews: PreviewProvider {
    static var previews: some View {
        MascotNamingView(onContinue: { name in
            print("Mascot named: \(name)")
        })
        .preferredColorScheme(.dark)
    }
}
