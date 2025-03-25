import SwiftUI

/// Main enum to track the onboarding state
enum OnboardingStep: Equatable {
    case welcome
    case personalizationIntro
    case questionnaire
    case healthKitPermissions
    case signInWithApple
    case payment
    case dashboard
}

/// Main container view for the entire onboarding flow
struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .welcome
    @EnvironmentObject var appState: AppState
    @State private var dragOffset: CGFloat = 0
    @State private var dragDirection: Edge? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Using conditional rendering with proper transitions
                if currentStep == .welcome {
                    WelcomeView(onContinue: { navigateTo(.personalizationIntro) })
                        .transition(.opacity)
                        .zIndex(currentStep == .welcome ? 1 : 0)
                }
                
                if currentStep == .personalizationIntro {
                    PersonalizationIntroView(onContinue: { navigateTo(.questionnaire) })
                        .offset(x: dragDirection == .leading ? dragOffset : 0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .zIndex(currentStep == .personalizationIntro ? 1 : 0)
                }
                
                if currentStep == .questionnaire {
                    QuestionnaireView(onContinue: { navigateTo(.healthKitPermissions) })
                        .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .zIndex(currentStep == .questionnaire ? 1 : 0)
                }
                
                if currentStep == .healthKitPermissions {
                    HealthKitPermissionsView(onContinue: { navigateTo(.signInWithApple) })
                        .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .zIndex(currentStep == .healthKitPermissions ? 1 : 0)
                }
                
                if currentStep == .signInWithApple {
                    SignInWithAppleView(onContinue: { navigateTo(.payment) })
                        .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .zIndex(currentStep == .signInWithApple ? 1 : 0)
                }
                
                if currentStep == .payment {
                    PaymentView(onContinue: { navigateTo(.dashboard) })
                        .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                        .zIndex(currentStep == .payment ? 1 : 0)
                }
                
                if currentStep == .dashboard {
                    NavigationView {
                        DashboardView()
                    }
                    .transition(.opacity)
                    .zIndex(currentStep == .dashboard ? 1 : 0)
                    .onAppear {
                        // Mark onboarding as complete once dashboard is shown
                        appState.hasCompletedOnboarding = true
                    }
                }
            }
            .animation(dragDirection == nil ? .easeInOut(duration: 0.4) : nil, value: currentStep)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Skip gesture handling for welcome screen and when transitioning to dashboard
                        guard currentStep != .welcome && currentStep != .dashboard else { return }
                        
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            // Determine drag direction
                            if gesture.translation.width < 0 {
                                // Dragging to the left (forward)
                                dragDirection = .leading
                                let nextStep = getNextStep(after: currentStep)
                                if nextStep != nil {
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = max(gesture.translation.width, -geometry.size.width) * resistance
                                }
                            } else if gesture.translation.width > 0 {
                                // Dragging to the right (backward)
                                // Don't allow swiping back to welcome view
                                if currentStep == .personalizationIntro {
                                    // Do nothing - prevent going back to welcome
                                    return
                                }
                                
                                dragDirection = .trailing
                                let previousStep = getPreviousStep(before: currentStep)
                                if previousStep != nil && previousStep != .welcome {
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                                }
                            }
                        }
                    }
                    .onEnded { gesture in
                        guard dragDirection != nil else { return }
                        
                        // Calculate if the drag was significant enough to trigger navigation
                        let threshold: CGFloat = geometry.size.width * 0.2 // Reduced threshold for easier swiping
                        
                        if dragDirection == .leading && abs(dragOffset) > threshold {
                            // Dragged left past threshold - move forward
                            if let nextStep = getNextStep(after: currentStep) {
                                dragDirection = nil
                                navigateTo(nextStep)
                            }
                        } else if dragDirection == .trailing && abs(dragOffset) > threshold {
                            // Dragged right past threshold - move backward
                            if let previousStep = getPreviousStep(before: currentStep), previousStep != .welcome {
                                dragDirection = nil
                                navigateTo(previousStep)
                            }
                        }
                        
                        // Reset drag state with animation
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            dragOffset = 0
                            dragDirection = nil
                        }
                    }
            )
        }
    }
    
    private func navigateTo(_ step: OnboardingStep) {
        // Use spring animation for smoother transitions
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            currentStep = step
        }
    }
    
    private func getNextStep(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return .personalizationIntro
        case .personalizationIntro: return .questionnaire
        case .questionnaire: return .healthKitPermissions
        case .healthKitPermissions: return .signInWithApple
        case .signInWithApple: return .payment
        case .payment: return .dashboard
        case .dashboard: return nil
        }
    }
    
    private func getPreviousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return nil
        case .personalizationIntro: return .welcome
        case .questionnaire: return .personalizationIntro
        case .healthKitPermissions: return .questionnaire
        case .signInWithApple: return .healthKitPermissions
        case .payment: return .signInWithApple
        case .dashboard: return .payment
        }
    }
}

// Preview
struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
            .environmentObject(AppState())
    }
} 