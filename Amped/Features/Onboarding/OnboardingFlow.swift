import SwiftUI

/// Main enum to track the onboarding state - Rules: Streamlined flow removing redundant screens
enum OnboardingStep: String, Equatable, CaseIterable {
    case welcome
    case personalizationIntro // Position 2: Build trust before data collection
    case beforeAfterTransformation // Position 3: Show transformation journey
    case mascotIntroduction // Position 4: Introduce the mascot
    case mascotNaming // Position 5: Let user name the mascot
    case genderSelection
    case ageSelection
    case heightStats
    case weightStats
    case stressStats
    case anxietyStats
    case dietStats
    case smokeStats
    case alcoholicStats
    case socialConnectionStats
    case bloodPressureStats
    case mainReasonStats
    case goalsStats
    case syncDeviceStats
    case terms
    case paywall
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
    
    // Add binding for questionnaire navigation
    @State private var shouldExitQuestionnaire: Bool = false
    @State private var shouldCompleteQuestionnaire: Bool = false
    
    // ULTRA-PERFORMANCE FIX: Pre-initialize ViewModel in background during PersonalizationIntro
    @State private var questionnaireViewModel: QuestionnaireViewModel?
    @State private var isViewModelReady: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent black background for all onboarding screens to prevent flashing
                // Each individual view handles its own background content
                Color.black.ignoresSafeArea(.all)
                
                // Transitioning content layer
                ZStack {
                    if appState.currentOnboardingStep == .welcome {
                        WelcomeView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.valueProposition)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .welcome ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .valueProposition {
                        ValuePropositionView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.personalizationIntro)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .valueProposition ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .personalizationIntro {
                        PersonalizationIntroView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.beforeAfterTransformation)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .personalizationIntro ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .beforeAfterTransformation {
                        BeforeAfterTransformationView(onContinue: {
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.mascotNaming)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .beforeAfterTransformation ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .mascotNaming {
                        MascotNamingView(onContinue: { name in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userName, value: name)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.genderSelection)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .mascotNaming ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .genderSelection {
                        GenderSelectionView( onContinue: { genderEnum in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userGender, value: genderEnum.rawValue)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.ageSelection)
                        }, onBack: {
                            navigateTo(.mascotNaming)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .genderSelection ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .ageSelection {
                        AgeSelectionView (onContinue: { date in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDateOfBirth, value: "\(date)")
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.heightStats)
                        }, onBack: {
                            navigateTo(.genderSelection)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .ageSelection ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .heightStats {
                        HeightStatsView(onContinue: { height in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userHeight, value: height)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.weightStats)
                        }, onBack: {
                            navigateTo(.ageSelection)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .heightStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .weightStats {
                        WeightStatsView(onContinue: { weight, weightUnit in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userWeight, value: weight)
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userWeightUnit, value: weightUnit)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.stressStats)
                        }, onBack: {
                            navigateTo(.heightStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .weightStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .stressStats {
                        StressStatsView(onContinue: { stressStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userStressLevel, value: stressStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.anxietyStats)
                        }, onBack: {
                            navigateTo(.weightStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .stressStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .anxietyStats {
                        AnxietyStatsView(onContinue: { anxietyStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAnxietyLevel, value: anxietyStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.dietStats)
                        }, onBack: {
                            navigateTo(.stressStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .anxietyStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .dietStats {
                        DietStatsView(onContinue: { dietStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDietLevel, value: dietStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.smokeStats)
                        }, onBack: {
                            navigateTo(.anxietyStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .dietStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .smokeStats {
                        SmokeStatsView(onContinue: { smokeStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSmokeStats, value: smokeStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.alcoholicStats)
                        }, onBack: {
                            navigateTo(.dietStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .smokeStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .alcoholicStats {
                        AlcoholicStatsView(onContinue: { alcoholStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAlcoholStats, value: alcoholStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.socialConnectionStats)
                        }, onBack: {
                            navigateTo(.smokeStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .alcoholicStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .socialConnectionStats {
                        SocialConnectionStatsView(onContinue: { socialConnectionStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSocialStats, value: socialConnectionStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.bloodPressureStats)
                        }, onBack: {
                            navigateTo(.alcoholicStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .socialConnectionStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .bloodPressureStats {
                        BloodPressureReadingView(onContinue: {
                            bloodPressureStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userBloodPressureStats, value: bloodPressureStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.mainReasonStats)
                        }, onBack: {
                            navigateTo(.socialConnectionStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .bloodPressureStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .mainReasonStats {
                        MainReasonStatsView(onContinue: { mainReasonStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userMainReasonStats, value: mainReasonStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.goalsStats)
                        }, onBack: {
                            navigateTo(.bloodPressureStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .mainReasonStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .goalsStats {
                        GoalsStatsView(onContinue: { mainReasonStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userGoalStats, value: mainReasonStats)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.syncDeviceStats)
                        }, onBack: {
                            navigateTo(.mainReasonStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .goalsStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .syncDeviceStats {
                        SyncDeviceView(onContinue: { deviceSync in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDeviceSync, value: deviceSync)
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.terms)
                        }, onBack: {
                            navigateTo(.goalsStats)
                        })
                        .environmentObject(appState)
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .syncDeviceStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .terms {
                        TermsView {
                            isButtonNavigating = true
                            dragDirection = nil
                            if appState.isPremiumUser {
                                navigateTo(.dashboard)
                            } else {
                                navigateTo(.paywall)
                            }
                        } onBack: {
                            navigateTo(.syncDeviceStats)
                        }

                    }
                    
                    if appState.currentOnboardingStep == .paywall {
                        PaywallScreen {
                            navigateTo(.dashboard)
                        }
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
        }
        .onAppear {
            // Save initial onboarding progress when flow appears
            appState.saveOnboardingProgress()
            
            // ULTRA-PERFORMANCE FIX: Minimize onAppear work to prevent UI blocking
            // Move ALL expensive operations to background with lower priority
            Task.detached(priority: .utility) {
                // Only clear UserDefaults if starting fresh (at welcome step)
                let currentStep = await MainActor.run { appState.currentOnboardingStep }
                if currentStep == .welcome {
                    // Clear UserDefaults in background
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.questionnaireCurrentQuestion)
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userNameLegacy)
                    
                    // Move expensive clearAllData to background with even lower priority
                    QuestionnaireManager().clearAllData()
                }
            }
        }
        .onDisappear {
            // Save progress when flow disappears (user backgrounding app)
            appState.saveOnboardingProgress()
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
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
            appState.updateOnboardingStep(step)
        }
    }

    // MARK: - Fade Transition (Clean opacity only)
    private func getMaterializeTransition() -> AnyTransition {
        return .opacity
    }
    
}

// MARK: - Smart Post-Onboarding Cleanup

/// 🧹 SMART CLEANUP: Free memory after onboarding completion
/// Clears caches and temporary data that are no longer needed
private func performPostOnboardingCleanup() async {
    // Clear any temporary onboarding-related UserDefaults
    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.onboardingTempData)
    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.questionnaireCache)
    
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
