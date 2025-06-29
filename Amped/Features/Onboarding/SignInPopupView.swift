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
                VStack(spacing: 8) {
                    // Simple, realistic messaging - Rules: Following user requirement for not overpromising
                    Text("Join early")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                    
                    // Vague but enticing subtitle
                    Text("Get future perks")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.ampedGreen)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                // Single sign-in button - Rules: Apple Sign-In only
                VStack(spacing: 20) {
                    // Sign in with Apple button - Rules: Only option for simplicity
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
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .scaleEffect(animateAppleButton ? 1.0 : 0.95)
                    .opacity(animateAppleButton ? 1.0 : 0.0)
                    
                    // Subtle skip option - Rules: Less prominent to encourage sign-up
                    Button(action: {
                        dismissPopup()
                    }) {
                        Text("Maybe later")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                    }
                    .opacity(animateAppleButton ? 1.0 : 0.0)
                    .hapticFeedback(.light)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
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