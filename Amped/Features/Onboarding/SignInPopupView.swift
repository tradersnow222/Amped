import SwiftUI
import AuthenticationServices
import OSLog

/// Popup view for sign-in that appears after payment completion - Rules: Following "little yesses" principle
struct SignInPopupView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = SignInPopupViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: BatteryThemeManager
    @Binding var isPresented: Bool
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "SignInPopup")
    
    // Animation states
    @State private var showContent = false
    @State private var animateAppleButton = false
    @State private var animateGoogleButton = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Blurred background tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
                .allowsHitTesting(isPresented)
            
            // Main card content - Rules: Similar style to battery info cards
            VStack(spacing: 0) {
                // Header section with title
                VStack(spacing: 12) {
                    // Title with brand emphasis
                    Text("Create an account to")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("save your progress.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Sign-in buttons section
                VStack(spacing: 16) {
                    // Sign in with Apple button - Rules: Primary option
                    SignInWithAppleButtonWrapper(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            logger.info("🍎 Requesting Apple Sign In")
                        },
                        onCompletion: { result in
                            handleSignInWithAppleResult(result)
                        }
                    )
                    .frame(height: 50)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .scaleEffect(animateAppleButton ? 1.0 : 0.95)
                    .opacity(animateAppleButton ? 1.0 : 0.0)
                    
                    // Sign in with Google button - Rules: Secondary option
                    Button(action: {
                        handleGoogleSignIn()
                    }) {
                        HStack(spacing: 12) {
                            // Rules: Use "G" text as placeholder until Google logo asset is added
                            Text("G")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.init(red: 0.25, green: 0.52, blue: 0.96)) // Google blue
                                .frame(width: 20, height: 20)
                            
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    }
                    .scaleEffect(animateGoogleButton ? 1.0 : 0.95)
                    .opacity(animateGoogleButton ? 1.0 : 0.0)
                    .hapticFeedback(.medium)
                    
                    // Continue with Email option - Rules: Tertiary option
                    Button(action: {
                        handleEmailSignIn()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                            
                            Text("Continue with Email")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .opacity(animateGoogleButton ? 1.0 : 0.0)
                    .hapticFeedback(.light)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.cardBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 20)
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
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
        .animation(.easeInOut(duration: 0.3), value: showContent)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                animateGoogleButton = true
            }
        }
    }
    
    private func dismissPopup() {
        logger.info("📱 User dismissed sign-in popup")
        withAnimation(.easeInOut(duration: 0.2)) {
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
                appState.setAuthenticated(userID: userID)
                
                // Dismiss popup
                dismissPopup()
                
                // Track successful sign-in
                AnalyticsService.shared.trackEvent(.signIn(method: "apple"))
            }
            
        case .failure(let error):
            logger.error("🍎 Apple Sign In failed: \(error.localizedDescription)")
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
    
    private func handleGoogleSignIn() {
        logger.info("🔍 Google Sign In tapped")
        
        // TODO: Implement Google Sign-In SDK integration
        // For now, show coming soon message
        viewModel.errorMessage = "Google Sign-In coming soon!"
        viewModel.showError = true
    }
    
    private func handleEmailSignIn() {
        logger.info("✉️ Email Sign In tapped")
        
        // TODO: Implement email sign-in flow
        // For now, show coming soon message
        viewModel.errorMessage = "Email Sign-In coming soon!"
        viewModel.showError = true
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