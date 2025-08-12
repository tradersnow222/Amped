import SwiftUI

/// Main enum to track the onboarding state - Rules: Removed redundant healthKitPermissions screen and signInWithApple
enum OnboardingStep: Equatable {
    case welcome
    case valueProposition
    case beforeAfter // New: "You today" vs "In a week"
    case personalizationIntro
    case questionnaire
    case prePaywallTease
    case payment
    case attribution // New: How did you hear about us?
    case dashboard
}

/// Main container view for the entire onboarding flow
struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .welcome
    @EnvironmentObject var appState: AppState
    @State private var dragDirection: Edge? = nil
    @State private var isButtonNavigating: Bool = false
    
    // Add binding for questionnaire navigation
    @State private var shouldExitQuestionnaire: Bool = false
    @State private var shouldCompleteQuestionnaire: Bool = false
    
    // Shared questionnaire view model
    @StateObject private var questionnaireViewModel = QuestionnaireViewModel()
    

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Static background that doesn't transition
                Color.clear.withDeepBackground()
                
                // Transitioning content layer
                ZStack {
                    if currentStep == .welcome {
                        WelcomeView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.valueProposition) 
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .welcome ? 1 : 0)
                    }
                    
                    if currentStep == .valueProposition {
                        ValuePropositionView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.beforeAfter) 
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .valueProposition ? 1 : 0)
                    }
                    
                    if currentStep == .beforeAfter {
                        BeforeAfterComparisonView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.personalizationIntro)
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .beforeAfter ? 1 : 0)
                    }
                    
                    if currentStep == .personalizationIntro {
                        PersonalizationIntroView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.questionnaire) 
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .personalizationIntro ? 1 : 0)
                    }
                    
                    if currentStep == .questionnaire {
                        QuestionnaireView(
                            exitToPersonalizationIntro: $shouldExitQuestionnaire,
                            proceedToHealthPermissions: $shouldCompleteQuestionnaire,
                            startFresh: true,  // CRITICAL FIX: Always start fresh in onboarding flow
                            includeBackground: false  // Parent OnboardingFlow provides static background
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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
                                
                                // Questionnaire completed - go directly to pre-paywall tease (skipping Sign in)
                                DispatchQueue.main.async {
                                    navigateTo(.prePaywallTease)
                                    
                                    // Reset drag direction after animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        dragDirection = nil
                                    }
                                }
                            }
                        }
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .questionnaire ? 1 : 0)
                    }
                    

                    
                    if currentStep == .prePaywallTease {
                        PrePaywallTeaserView(
                            viewModel: questionnaireViewModel,
                            onContinue: {
                                isButtonNavigating = true
                                dragDirection = nil
                                navigateTo(.payment)
                            }
                        )
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .prePaywallTease ? 1 : 0)
                    }

                    if currentStep == .payment {
                        PaymentView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.attribution) 
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .payment ? 1 : 0)
                    }
                    
                    if currentStep == .attribution {
                        AttributionSourceView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.dashboard)
                        })
                        .transition(getTransition(forNavigatingTo: currentStep))
                        .zIndex(currentStep == .attribution ? 1 : 0)
                    }
                    
                    if currentStep == .dashboard {
                        NavigationView {
                            DashboardView()
                        }
                        .transition(getMaterializeTransition())
                        .zIndex(currentStep == .dashboard ? 1 : 0)
                        .onAppear {
                            // Mark onboarding as complete once dashboard is shown
                            appState.completeOnboarding()
                        }
                    }
                }
            }
            // UX RULE: Simplicity is KING — gestures removed. Navigation is button-driven or
            // programmatic (e.g., questionnaire back/forward) with direction hints via dragDirection.
        }
        .onAppear {
            // CRITICAL FIX: Clear any saved questionnaire state when starting onboarding
            // This ensures users always start from the beginning
            UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
            UserDefaults.standard.removeObject(forKey: "userName")
            
            // Only clear questionnaire data if we're truly starting fresh
            // (not just navigating back within the flow)
            if currentStep == .welcome {
                QuestionnaireManager().clearAllData()
            }
        }
        // Add a tap gesture to the corner to show/hide debug controls
        .overlay(
            VStack {
                Spacer()
                
            })
    }
    
        // Helper method to determine the correct transition based on navigation direction
    private func getTransition(forNavigatingTo step: OnboardingStep) -> AnyTransition {
        print("🔍 DEBUG: Getting transition for navigating to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // Use consistent slide + opacity across onboarding for a premium, unified feel
        
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
        
        // Default transition for programmatic navigation (forward)
        print("🔍 DEBUG: Using default transition (no drag direction)")
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
        private func navigateTo(_ step: OnboardingStep) {
        print("🔍 DEBUG: Navigating from \(currentStep) to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // Use spring animation for smoother transitions
        
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
        
        // Luxury slow — softer/longer spring for materialize transitions across onboarding
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
            currentStep = step
        }
    }

    // MARK: - Materialize Transition (Luxury feel)
    private func getMaterializeTransition() -> AnyTransition {
        let insertion = AnyTransition.opacity
            .combined(with: .scale(scale: 0.97, anchor: .center))
        let removal = AnyTransition.opacity
            .combined(with: .scale(scale: 1.03, anchor: .center))
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    /// Get the next step in the onboarding flow - Rules: Updated to skip redundant HealthKit screen
    private func getNextStep(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return .valueProposition
        case .valueProposition: return .beforeAfter
        case .beforeAfter: return .personalizationIntro
        case .personalizationIntro: return .questionnaire
        case .questionnaire: return .prePaywallTease
        case .prePaywallTease: return .payment
        case .payment: return .attribution
        case .attribution: return .dashboard
        case .dashboard: return nil
        }
    }
    
    /// Get the previous step in the onboarding flow - Rules: Updated to skip redundant HealthKit screen
    private func getPreviousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return nil
        case .valueProposition: return .welcome
        case .beforeAfter: return .valueProposition
        case .personalizationIntro: return .beforeAfter
        case .questionnaire: return .personalizationIntro
        case .prePaywallTease: return .questionnaire
        case .payment: return .prePaywallTease
        case .attribution: return .payment
        case .dashboard: return .attribution
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
