import SwiftUI

/// Before/After transformation screen showing the journey from basic to enhanced health tracking
struct BeforeAfterTransformationView: View {
    // MARK: - Properties
    
    @State private var animateElements = false
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    // MARK: - Body
    
    var body: some View {
        let isRegular = hSizeClass == .regular
        let bottomButtonPadding: CGFloat = isRegular ? 450 : 30
        
        ZStack {
            
            Image("femaleBg")
                .resizable()
                .scaledToFill()
                .opacity(0.40)
                .ignoresSafeArea()
            
            LinearGradient.ampBlueGradient
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // MARK: Text Content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Powered by \nReal Science, \nNot Guesswork.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.1), value: animateElements)
                        .padding(.leading, 30)
                    
                    
                    Text("Science-backed insights from Harvard \n& AHA on how your habits impact your \nlifespan.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.poppins(18))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 40)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        .padding(.leading, 30)
                }
                
                OnboardingContinueButton(
                    title: "Continue",
                    isEnabled: true,
                    animateIn: animateElements,
                    bottomPadding: 50
                ) {
                    onContinue?()
                }
            }
            .padding(.bottom, bottomButtonPadding)
        }
        .onAppear {
            // Trigger animation when the view appears
            animateElements = true
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
