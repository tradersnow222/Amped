import SwiftUI
import AuthenticationServices
import OSLog

/// Popup view for sign-in that appears after payment completion - Rules: Following "little yesses" principle
struct SignInPopupView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = SignInPopupViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @EnvironmentObject var glassTheme: GlassThemeManager
    @Binding var isPresented: Bool
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "SignInPopup")
    
    // Animation states
    @State private var showContent = false
    @State private var animateAppleButton = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Glass-themed blurred background tap to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopupPermanently()
                }
                .allowsHitTesting(isPresented)
            
            // Main card content with glass theme
            VStack {
                Spacer()
                
                glassThemedSignInCard
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .zIndex(1)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateIn()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Sign In Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Glass-Themed Sign-In Card
    
    private var glassThemedSignInCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                // Apple logo icon to match theme
                Image(systemName: "applelogo")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Join Early Access")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Secure your account & future perks")
                        .font(.subheadline)
                        .foregroundColor(.ampedGreen)
                }
                
                Spacer()
            }
            
            // Benefits with icons
            VStack(alignment: .leading, spacing: 16) {
                // Benefit 1
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secure Account")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Your data stays private & secure")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Benefit 2
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.body)
                        .foregroundColor(.ampedYellow)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Early Perks")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Get exclusive features first")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Sign in with Apple button - styled to match theme
            VStack(spacing: 16) {
                SignInWithAppleButtonWrapper(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        logger.info("🍎 Requesting Apple Sign In")
                    },
                    onCompletion: { result in
                        handleSignInWithAppleResult(result)
                    }
                )
                .frame(height: 52)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .scaleEffect(animateAppleButton ? 1.0 : 0.95)
                .opacity(animateAppleButton ? 1.0 : 0.0)
                
                // Dismiss button - styled to match theme
                Button(action: {
                    dismissPopupPermanently()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Maybe later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .opacity(animateAppleButton ? 1.0 : 0.0)
                .hapticFeedback(.light)
            }
        }
        .padding(28)
        .frame(idealWidth: 340, maxWidth: 360)
        .glassBackground(.thick, cornerRadius: 20, withBorder: true, withShadow: true)
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
    }
    
    // MARK: - Helper Methods
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = true
        }
        
        // Stagger button animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                animateAppleButton = true
            }
        }
    }
    
    private func dismissPopupPermanently() {
        logger.info("📱 User permanently dismissed sign-in popup")
        
        // Mark as permanently dismissed in app state
        appState.markSignInPermanentlyDismissed()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
    
    private func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                logger.info("🍎 Apple Sign In successful - User ID: \(userID)")
                
                // Update app state with authentication - Rules: Track authentication
                appState.setAuthenticated(true)
                
                // Dismiss popup (authentication automatically marks as permanently dismissed)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
                
                // Track successful sign-in
                AnalyticsService.shared.trackEvent(.signIn(method: "apple"))
            }
            
        case .failure(let error):
            logger.error("🍎 Apple Sign In failed: \(error.localizedDescription)")
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}

// MARK: - ViewModel

final class SignInPopupViewModel: ObservableObject {
    @Published var showError = false
    @Published var errorMessage = ""
}

// MARK: - Sign In With Apple Button Wrapper

/// Wrapper for Sign in with Apple button to match the style
struct SignInWithAppleButtonWrapper: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .continue, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleButtonPress), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButtonWrapper
        
        init(_ parent: SignInWithAppleButtonWrapper) {
            self.parent = parent
        }
        
        @objc func handleButtonPress() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            parent.onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return UIWindow()
            }
            return window
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
    }
}

// MARK: - Preview

struct SignInPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            SignInPopupView(isPresented: .constant(true))
                .environmentObject(AppState())
                .environmentObject(BatteryThemeManager())
        }
    }
}
