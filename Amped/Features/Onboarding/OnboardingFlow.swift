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
    @State private var isButtonNavigating: Bool = false
    @State private var isProgrammaticNavigation: Bool = false
    
    // Add binding for questionnaire navigation
    @State private var shouldExitQuestionnaire: Bool = false
    @State private var shouldCompleteQuestionnaire: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Using conditional rendering with proper transitions
                if currentStep == .welcome {
                    WelcomeView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.personalizationIntro) 
                    })
                    .transition(.opacity)
                    .zIndex(currentStep == .welcome ? 1 : 0)
                }
                
                if currentStep == .personalizationIntro {
                    PersonalizationIntroView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.questionnaire) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : 0)
                    .transition(getTransition(forNavigatingTo: .personalizationIntro))
                    .zIndex(currentStep == .personalizationIntro ? 1 : 0)
                }
                
                if currentStep == .questionnaire {
                    QuestionnaireView(
                        exitToPersonalizationIntro: $shouldExitQuestionnaire,
                        proceedToHealthPermissions: $shouldCompleteQuestionnaire
                    )
                    .onChange(of: shouldExitQuestionnaire) { newValue in
                        if newValue {
                            // Reset flag first
                            shouldExitQuestionnaire = false
                            
                            // Important: First set drag direction, then navigate
                            isButtonNavigating = false
                            dragDirection = .trailing
                            
                            // Navigate back with trailing edge animation
                            // Use a slight delay to ensure the direction is set properly
                            DispatchQueue.main.async {
                                navigateTo(.personalizationIntro)
                                
                                // Reset drag direction after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragDirection = nil
                                }
                            }
                        }
                    }
                    .onChange(of: shouldCompleteQuestionnaire) { newValue in
                        if newValue {
                            // Reset flag first
                            shouldCompleteQuestionnaire = false
                            
                            // Navigate forward with leading edge animation
                            isButtonNavigating = false
                            dragDirection = .leading
                            
                            // Use a slight delay to ensure the direction is set properly
                            DispatchQueue.main.async {
                                navigateTo(.healthKitPermissions)
                                
                                // Reset drag direction after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragDirection = nil
                                }
                            }
                        }
                    }
                    .transition(getTransition(forNavigatingTo: .questionnaire))
                    .zIndex(currentStep == .questionnaire ? 1 : 0)
                }
                
                if currentStep == .healthKitPermissions {
                    HealthKitPermissionsView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.signInWithApple) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                    .transition(getTransition(forNavigatingTo: .healthKitPermissions))
                    .zIndex(currentStep == .healthKitPermissions ? 1 : 0)
                }
                
                if currentStep == .signInWithApple {
                    SignInWithAppleView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.payment) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                    .transition(getTransition(forNavigatingTo: .signInWithApple))
                    .zIndex(currentStep == .signInWithApple ? 1 : 0)
                }
                
                if currentStep == .payment {
                    PaymentView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.dashboard) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                    .transition(getTransition(forNavigatingTo: .payment))
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
                        appState.completeOnboarding()
                    }
                }
            }
            .animation(isProgrammaticNavigation || dragDirection == nil ? .easeInOut(duration: 0.4) : nil, value: currentStep)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // Skip gesture handling entirely when in questionnaire
                        if currentStep == .questionnaire {
                            return
                        }
                        
                        // Reset button navigation flag when user starts dragging
                        isButtonNavigating = false
                        isProgrammaticNavigation = false
                        
                        // Skip gesture handling for welcome screen and when transitioning to dashboard
                        guard currentStep != .welcome && currentStep != .dashboard else { return }
                        
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            // Determine drag direction
                            if gesture.translation.width < 0 {
                                // Dragging to the left (forward)
                                // Skip handling forward gestures in questionnaire (let child view handle it)
                                if currentStep == .questionnaire {
                                    return
                                }
                                
                                dragDirection = .leading
                                let nextStep = getNextStep(after: currentStep)
                                if nextStep != nil {
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = max(gesture.translation.width, -geometry.size.width) * resistance
                                    print("🔍 DRAG: Forward drag, offset=\(dragOffset), nextStep=\(String(describing: nextStep))")
                                }
                            } else if gesture.translation.width > 0 {
                                // Dragging to the right (backward)
                                // Don't allow swiping back to welcome view
                                if currentStep == .personalizationIntro {
                                    // Do nothing - prevent going back to welcome
                                    print("🔍 DRAG: Backward drag prevented - at personalizationIntro")
                                    return
                                }
                                
                                // For questionnaire, we want the child view to handle backward navigation
                                // UNLESS we're at the first question and need to go back to personalization intro
                                // But that's handled via notifications from the child
                                if currentStep == .questionnaire {
                                    return
                                }
                                
                                dragDirection = .trailing
                                let previousStep = getPreviousStep(before: currentStep)
                                if previousStep != nil && previousStep != .welcome {
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                                    print("🔍 DRAG: Backward drag, offset=\(dragOffset), previousStep=\(String(describing: previousStep))")
                                }
                            }
                        }
                    }
                    .onEnded { gesture in
                        // Skip gesture handling entirely when in questionnaire
                        if currentStep == .questionnaire {
                            return
                        }
                        
                        guard dragDirection != nil else { return }
                        
                        // Calculate if the drag was significant enough to trigger navigation
                        let threshold: CGFloat = geometry.size.width * 0.2 // Reduced threshold for easier swiping
                        
                        if dragDirection == .leading && abs(dragOffset) > threshold {
                            // Dragged left past threshold - move forward
                            if let nextStep = getNextStep(after: currentStep) {
                                print("🔍 DRAG ENDED: Completing forward navigation to \(nextStep)")
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    dragOffset = 0
                                }
                                // Important: Keep dragDirection set during navigation
                                navigateTo(nextStep)
                                // Reset dragDirection after navigation animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragDirection = nil
                                }
                            }
                        } else if dragDirection == .trailing && abs(dragOffset) > threshold {
                            // Dragged right past threshold - move backward
                            if let previousStep = getPreviousStep(before: currentStep), previousStep != .welcome {
                                print("🔍 DRAG ENDED: Completing backward navigation to \(previousStep)")
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    dragOffset = 0
                                }
                                // Important: Keep dragDirection set during navigation
                                navigateTo(previousStep)
                                // Reset dragDirection after navigation animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragDirection = nil
                                }
                            }
                        } else {
                            // Reset drag state with animation if threshold not met
                            print("🔍 DRAG ENDED: Threshold not met, canceling drag")
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                dragOffset = 0
                            }
                            dragDirection = nil
                        }
                    }
            )
        }
    }
    
    // Helper method to determine the correct transition based on navigation direction
    private func getTransition(forNavigatingTo step: OnboardingStep) -> AnyTransition {
        print("🔍 DEBUG: Getting transition for navigating to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // For button-initiated navigation
        if isButtonNavigating {
            print("🔍 DEBUG: Using button-initiated transition (forward)")
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        
        // For gesture-based navigation
        if let dragDir = dragDirection {
            switch dragDir {
            case .leading:
                // Forward swipe (left to right on screen)
                print("🔍 DEBUG: Using leading edge transition (forward swipe)")
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            case .trailing:
                // Backward swipe (right to left on screen)
                print("🔍 DEBUG: Using trailing edge transition (backward swipe)")
                return .asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                )
            default:
                // Default forward transition
                print("🔍 DEBUG: Using default transition (unknown drag direction)")
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            }
        }
        
        // Default transition for programmatic navigation
        print("🔍 DEBUG: Using default transition (no drag direction)")
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    private func navigateTo(_ step: OnboardingStep) {
        print("🔍 DEBUG: Navigating from \(currentStep) to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // Use spring animation for smoother transitions
        isProgrammaticNavigation = true
        
        // Log the transition being used
        if dragDirection == .trailing {
            print("🔍 DEBUG: Using BACKWARD transition (trailing edge) - current screen should exit RIGHT")
        } else if dragDirection == .leading {
            print("🔍 DEBUG: Using FORWARD transition (leading edge) - current screen should exit LEFT")
        } else if isButtonNavigating {
            print("🔍 DEBUG: Using BUTTON-INITIATED transition - current screen should exit LEFT")
        } else {
            print("🔍 DEBUG: Using DEFAULT transition - current screen should exit LEFT")
        }
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            currentStep = step
        }
    }
    
    /// Get the next step in the onboarding flow
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
    
    /// Get the previous step in the onboarding flow
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
    
    // Remove notification handlers that are no longer needed
    private func setupQuestionnnaireNavigationNotifications() {
        // This method can be removed or left empty as we're using bindings now
    }
    
    // These can be removed as they're replaced by the onChange handlers
    private func navigateBackFromQuestionnaire() { }
    private func navigateForwardFromQuestionnaire() { }
}

// Preview
struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
            .environmentObject(AppState())
    }
} 