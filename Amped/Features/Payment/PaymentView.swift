import SwiftUI
import StoreKit

/// Payment screen with ValuePropositionBg background matching onboarding design pattern
struct PaymentView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Environment(\.presentationMode) private var presentationMode
    @State private var showExitOffer = false
    @State private var animateElements = false
    @State private var annualButtonPressed = false
    @State private var monthlyButtonPressed = false
    @State private var userProfile: UserProfile?
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Background image based on user's gender selection
    private var backgroundImageName: String {
        switch userProfile?.gender {
        case .female:
            return "femaleBg"
        case .male, .preferNotToSay, .none:
            return "ValuePropositionBg"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Background image with overlay - matching ValuePropositionView pattern
            GeometryReader { geometry in
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .offset(y: -100)
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipShape(
                        // Curved bottom shape
                        CurvedBottomShape()
                    )
            }
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .edgesIgnoringSafeArea(.all)
            
            // Main content - all content grouped together at bottom
            VStack {
                VStack(spacing: 48) {
                    VStack(spacing: 0) {
                        // Main headline with gradient text
                        Spacer()
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Text("Unlock")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.5),
                                                .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 1.9)  // #FCEE21 at 7.07%
                                                // #009245 at 80.26%
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text(" Your Life's")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                            }
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateElements)
                            .padding(.top,10)
                            
                            HStack(spacing: 0) {
                                Text("Full ")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                Text("Potential")
                                    .font(.system(size: 28, weight: .bold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.5),
                                                .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 1.9)      // #009245 at 80.26%
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        }
                        
                        // Subtitle
                        Text("Better Habits. Longer Life.")
                            .font(.system(size: 18, weight: .regular, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 28)
                            .padding(.top, 16)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: animateElements)
                        
                        // Scientific backing section
                        VStack(spacing: 8) {
                            
                            highlightedText(
                                fullText: "Our AI lifespan models are based on\n200+ peer-reviewed studies with over 10 million participants",
                                highlightedParts: ["200+ peer-reviewed", "10 million"],
                                highlightColor: Color(red: 250/255, green: 192/255, blue: 60/255)
                            )
                            .opacity(animateElements ? 1 : 0)
                            .padding(.horizontal,24)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 24)
                    
                    // Pricing buttons
                    VStack(spacing: 8) {
                        // Pricing information
                        VStack(spacing: 8) {
                            Text("Limited-time pricing. Cancel anytime")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1 : 0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.7), value: animateElements)
                        }
                        .padding(.top, 20)
                        // Main pricing button
                        Button(action: {
                            viewModel.selectedPlan = .monthly
                            processPurchase()
                        }) {
                            HStack {
                                Text("$3.99 per week")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color(red: 0/255, green: 146/255, blue: 69/255), location: 0.0),     // #009245
                                        .init(color: Color(red: 252/255, green: 238/255, blue: 33/255), location: 1.0)     // #FCEE21
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(monthlyButtonPressed ? 0.95 : 1.0)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                monthlyButtonPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    monthlyButtonPressed = false
                                }
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.9)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateElements)
                        
                        // Trial offer text
                        VStack(spacing: 4) {
                            Text("Try for 0 USD")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("3 days free trial then $3.99 per week")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.9), value: animateElements)
                        Spacer()
                        // Legal links
                        HStack(spacing: 16) {
                            Button("Privacy Policy") {
                                // Handle privacy policy
                            }
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            
                            Button("Terms of Use") {
                                // Handle terms of use
                            }
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
                    }
                    .padding(.horizontal, 28)
                    Spacer()
                }
            }
            .blur(radius: showExitOffer ? 8 : 0)
            .animation(.easeInOut(duration: 0.25), value: showExitOffer)
            
            // Processing overlay
            if viewModel.isProcessing {
                ProcessingOverlay()
            }
            
            // Exit offer modal
            if showExitOffer {
                ExitOfferModal(
                    onClaim: {
                        withAnimation(.spring(response: 0.3)) {
                            showExitOffer = false
                        }
                        viewModel.selectedPlan = .annual
                        processPurchase()
                    },
                    onDecline: {
                        withAnimation(.spring(response: 0.3)) {
                            showExitOffer = false
                        }
                        viewModel.skipPayment {
                            onContinue?()
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .background(Color.black)
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Oops!"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("Got it"))
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.appState = appState
            loadUserProfile()
            
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            // Exit button (X) - always visible but subtle
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showExitOffer = true
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(12)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .minTappableArea(44)
            .hapticFeedback(.heavy)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 44) // Fixed height to prevent layout shift
    }
    
    // MARK: - Helper Methods
    
    private func processPurchase() {
        // Skip actual payment processing and proceed as if successful
        onContinue?()
    }
    
    /// Load user profile from UserDefaults to determine background image
    private func loadUserProfile() {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else { return }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            userProfile = profile
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }
    
    private func highlightedText(fullText: String, highlightedParts: [String], highlightColor: Color) -> some View {
        let attributedString = NSMutableAttributedString(string: fullText)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.white
        ]
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(highlightColor)
        ]
        
        attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: fullText.count))
        
        for part in highlightedParts {
            let range = (fullText as NSString).range(of: part)
            if range.location != NSNotFound {
                attributedString.addAttributes(highlightAttributes, range: range)
            }
        }
        
        return Text(AttributedString(attributedString))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Curved Bottom Shape

struct CurvedBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height*0.9))
        
        // Curved bottom - goes to bottom of geometry
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height*0.9),
            control: CGPoint(x: rect.width * 0.5, y: rect.height*1.1)
        )
        
        // Left edge back to start
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

// MARK: - Preview

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(onContinue: {})
            .environmentObject(AppState())
            .environmentObject(BatteryThemeManager())
    }
} 
