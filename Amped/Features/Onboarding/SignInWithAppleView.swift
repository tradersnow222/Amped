import SwiftUI
import AuthenticationServices

/// Sign in with Apple view
struct SignInWithAppleView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = SignInWithAppleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Secure Your Progress")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            // Description
            Text("Create a secure account to save your health insights and battery status.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Benefits of account
            VStack(spacing: 30) {
                benefitRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Protection",
                    description: "Your data never leaves your device"
                )
                
                benefitRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sync Across Devices",
                    description: "Access your battery status anywhere"
                )
                
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Progress",
                    description: "See how your habits improve over time"
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Sign in with Apple button
            SignInWithAppleButton(
                onRequest: { request in
                    // Configure the request
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    // Handle the result
                    viewModel.handleSignInWithAppleResult(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)
            .cornerRadius(8)
            
            // Skip button
            Button("I'll do this later") {
                viewModel.skipSignIn()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 20)
            
            // Progress indicator
            ProgressIndicator(currentStep: 5, totalSteps: 7)
                .padding(.vertical, 30)
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Sign In Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $viewModel.showPaymentScreen) {
            // This would lead to payment screen
            PaymentView()
        }
    }
    
    // MARK: - UI Components
    
    /// Benefit row with icon and text
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.ampedGreen)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - ViewModel

final class SignInWithAppleViewModel: ObservableObject {
    // UI states
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Navigation
    @Published var showPaymentScreen = false
    
    // Handle Sign in with Apple result
    func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle successful authorization
            // In a real app, we would process the credentials here
            
            if let _ = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Process Apple ID credential and create user account
                showPaymentScreen = true
            } else {
                errorMessage = "Unable to get proper authorization credentials."
                showError = true
            }
            
        case .failure(let error):
            // Handle error
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Skip sign in
    func skipSignIn() {
        // Proceed without signing in
        showPaymentScreen = true
    }
}

// MARK: - Sign In With Apple Button

/// Custom Sign in with Apple button wrapper
struct SignInWithAppleButton: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    var buttonStyle: ASAuthorizationAppleIDButton.Style = .black
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: buttonStyle)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleButtonPress), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButton
        
        init(_ parent: SignInWithAppleButton) {
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
            // Return a window for the authorization UI using UIWindowScene.windows
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

struct SignInWithAppleView_Previews: PreviewProvider {
    static var previews: some View {
        SignInWithAppleView()
    }
} 