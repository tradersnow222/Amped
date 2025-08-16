import SwiftUI

/// Main enum to track the onboarding state - Rules: Streamlined flow removing redundant screens
enum OnboardingStep: String, Equatable, CaseIterable {
    case welcome
    case personalizationIntro // Position 2: Build trust before data collection
    case questionnaire
    case notificationPermission // Moved: Right after goal setting for logical flow
    case valueProposition // Position 5: Reinforce value after notifications
    case prePaywallTease // Position 6: Personalized score right before paywall
    case payment
    case attribution // New: How did you hear about us?
    case dashboard
}

/// Main container view for the entire onboarding flow
struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var dragDirection: Edge? = nil
    @State private var isButtonNavigating: Bool = false
    
    // DIRECT REFERENCE: Use appState.currentOnboardingStep directly in view conditions
    // This ensures SwiftUI properly reacts to @Published changes
    
    // Add binding for questionnaire navigation
    @State private var shouldExitQuestionnaire: Bool = false
    @State private var shouldCompleteQuestionnaire: Bool = false
    
    // ULTRA-PERFORMANCE FIX: Pre-initialize ViewModel in background during PersonalizationIntro
    @State private var questionnaireViewModel: QuestionnaireViewModel?
    @State private var isViewModelReady: Bool = false
    
    // Background initialization helper
    private func getQuestionnaireViewModel() -> QuestionnaireViewModel {
        if let existingViewModel = questionnaireViewModel {
            return existingViewModel
        } else {
            // Fallback synchronous creation if background init didn't complete
            let startTime = CFAbsoluteTimeGetCurrent()
            let newViewModel = QuestionnaireViewModel(startFresh: true)
            questionnaireViewModel = newViewModel
            isViewModelReady = true
            let initTime = CFAbsoluteTimeGetCurrent() - startTime
            return newViewModel
        }
    }
    
    // Pre-initialize ViewModel in background during PersonalizationIntro
    private func preInitializeQuestionnaireViewModel() {
        guard questionnaireViewModel == nil else { return }
        
        Task.detached(priority: .userInitiated) {
            let startTime = CFAbsoluteTimeGetCurrent()
            let newViewModel = QuestionnaireViewModel(startFresh: true)
            let initTime = CFAbsoluteTimeGetCurrent() - startTime
            
            await MainActor.run {
                self.questionnaireViewModel = newViewModel
                self.isViewModelReady = true
            }
        }
    }
    

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Conditional background based on current step
                // Welcome screen uses BatteryBackground, all others use DeepBackground
                if appState.currentOnboardingStep == .welcome {
                    Color.clear.withBatteryBackground()
                } else {
                    Color.clear.withDeepBackground()
                }
                
                // Transitioning content layer
                ZStack {
                if appState.currentOnboardingStep == .welcome {
                    WelcomeView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.personalizationIntro) 
                    })
                    .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                    .zIndex(appState.currentOnboardingStep == .welcome ? 1 : 0)
                }
                    
                if appState.currentOnboardingStep == .personalizationIntro {
                    PersonalizationIntroView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.questionnaire) 
                    })
                    .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                    .zIndex(appState.currentOnboardingStep == .personalizationIntro ? 1 : 0)
                    // REMOVED: Pre-initialization now handled by WelcomeView orchestration
                }
                    
                    if appState.currentOnboardingStep == .questionnaire {
                        // CRITICAL PERFORMANCE FIX: Pass lazy-initialized viewModel to prevent double initialization
                        QuestionnaireView(
                            viewModel: getQuestionnaireViewModel(),
                            exitToPersonalizationIntro: $shouldExitQuestionnaire,
                            proceedToHealthPermissions: $shouldCompleteQuestionnaire,
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
                                
                                // Questionnaire completed - go to notification permission
                                DispatchQueue.main.async {
                                    navigateTo(.notificationPermission)
                                    
                                    // Reset drag direction after animation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        dragDirection = nil
                                    }
                                }
                            }
                        }
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .questionnaire ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .notificationPermission {
                        NotificationPermissionView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.valueProposition)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .notificationPermission ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .valueProposition {
                        ValuePropositionView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.prePaywallTease) 
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .valueProposition ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .prePaywallTease {
                        PrePaywallTeaserView(
                            viewModel: getQuestionnaireViewModel(),
                            onContinue: {
                                isButtonNavigating = true
                                dragDirection = nil
                                navigateTo(.payment)
                            }
                        )
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .prePaywallTease ? 1 : 0)
                    }

                    if appState.currentOnboardingStep == .payment {
                        PaymentView(onContinue: { 
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.attribution) 
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .payment ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .attribution {
                        AttributionSourceView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.dashboard)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .attribution ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .dashboard {
                        NavigationView {
                            DashboardView()
                        }
                        .transition(getMaterializeTransition())
                        .zIndex(appState.currentOnboardingStep == .dashboard ? 1 : 0)
                        .onAppear {
                            // Mark onboarding as complete once dashboard is shown
                            appState.completeOnboarding()
                            
                            // 🧹 SMART CLEANUP: Clear onboarding caches to free memory after completion
                            Task.detached(priority: .background) {
                                await performPostOnboardingCleanup()
                            }
                        }
                    }
                }
            }
            // UX RULE: Simplicity is KING — gestures removed. Navigation is button-driven or
            // programmatic (e.g., questionnaire back/forward) with direction hints via dragDirection.
        }
        .onAppear {
            // ULTRA-PERFORMANCE FIX: Minimize onAppear work to prevent UI blocking
            // Move ALL expensive operations to background with lower priority
            Task.detached(priority: .utility) {
                // Only clear UserDefaults if starting fresh (at welcome step)
                if await MainActor.run(body: { appState.currentOnboardingStep }) == .welcome {
                    // Clear UserDefaults in background
                    UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    
                    // Move expensive clearAllData to background with even lower priority
                    QuestionnaireManager().clearAllData()
                }
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
        // Use consistent materializing effect across all onboarding screens for premium, unified feel
        return getMaterializeTransition()
    }
    
        private func navigateTo(_ step: OnboardingStep) {
        // Use spring animation for smoother transitions
        
        // Luxury slow — softer/longer spring for materialize transitions across onboarding
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
            appState.updateOnboardingStep(step)
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
    
    /// Get the next step in the onboarding flow - Rules: Streamlined flow removing redundant screens
    private func getNextStep(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return .personalizationIntro
        case .personalizationIntro: return .questionnaire
        case .questionnaire: return .valueProposition
        case .valueProposition: return .prePaywallTease
        case .prePaywallTease: return .payment
        case .payment: return .notificationPermission
        case .notificationPermission: return .attribution
        case .attribution: return .dashboard
        case .dashboard: return nil
        }
    }
    
    /// Get the previous step in the onboarding flow - Rules: Streamlined flow removing redundant screens
    private func getPreviousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return nil
        case .personalizationIntro: return .welcome
        case .questionnaire: return .personalizationIntro
        case .valueProposition: return .questionnaire
        case .prePaywallTease: return .valueProposition
        case .payment: return .prePaywallTease
        case .notificationPermission: return .payment
        case .attribution: return .notificationPermission
        case .dashboard: return .attribution
        }
    }
    
}

// MARK: - Smart Post-Onboarding Cleanup

/// 🧹 SMART CLEANUP: Free memory after onboarding completion
/// Clears caches and temporary data that are no longer needed
private func performPostOnboardingCleanup() async {
    // Clear any temporary onboarding-related UserDefaults
    UserDefaults.standard.removeObject(forKey: "onboarding_temp_data")
    UserDefaults.standard.removeObject(forKey: "questionnaire_cache")
    
    // Trigger memory cleanup
    autoreleasepool {
        // Force memory cleanup for temporary objects
    }
}

// Preview
struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
            .environmentObject(AppState())
    }
}
