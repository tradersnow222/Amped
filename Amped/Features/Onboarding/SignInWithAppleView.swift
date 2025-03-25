import SwiftUI
import AuthenticationServices

/// View for Sign in with Apple authentication
struct SignInWithAppleView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = SignInWithAppleViewModel()
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Create Your Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            
            Text("Sign in to secure your data and access premium features")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Benefits
            VStack(alignment: .leading, spacing: 24) {
                benefitRow(
                    icon: "lock.shield.fill",
                    title: "Secure Your Data",
                    description: "Keep your health insights private and accessible"
                )
                
                benefitRow(
                    icon: "icloud.fill",
                    title: "Cross-Device Sync",
                    description: "Access your battery data on all your devices"
                )
                
                benefitRow(
                    icon: "chart.bar.xaxis",
                    title: "Advanced Analytics",
                    description: "Unlock detailed health trend reports"
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
                    handleSignInWithAppleResult(result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)
            .cornerRadius(8)
            
            // Skip button
            Button("I'll do this later") {
                onContinue?()
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
        .withDeepBackground()
    }
    
    // MARK: - Helper Methods
    
    private func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            // Handle successful authorization
            // In a real app, we would process the credentials here
            
            if let _ = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Process Apple ID credential and create user account
                onContinue?()
            } else {
                viewModel.errorMessage = "Unable to get proper authorization credentials."
                viewModel.showError = true
            }
            
        case .failure(let error):
            // Handle error
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
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
        SignInWithAppleView(onContinue: {})
    }
} 