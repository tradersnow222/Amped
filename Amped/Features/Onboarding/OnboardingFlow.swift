import SwiftUI

/// Main enum to track the onboarding state - Rules: Streamlined flow removing redundant screens
enum OnboardingStep:Equatable {
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
//    case notificationPermission // Moved: Right after goal setting for logical flow
    case valueProposition // Position 5: Reinforce value after notifications
//    case prePaywallTease // Position 6: Personalized score right before paywall
//    case payment
//    case attribution // New: How did you hear about us?
    case dashboard
    case subscription
    
}

extension OnboardingStep {
    var name: String {
        switch self {
        case .welcome:
            return "welcome"
        case .personalizationIntro:
            return "personalizationIntro"
        case .beforeAfterTransformation:
            return "beforeAfterTransformation"
        case .mascotIntroduction:
            return "mascotIntroduction"
        case .mascotNaming:
            return "mascotNaming"
        case .genderSelection:
            return "genderSelection"
        case .ageSelection:
            return "ageSelection"
        case .heightStats:
            return "heightStats"
        case .weightStats:
            return "weightStats"
        case .stressStats:
            return "stressStats"
        case .anxietyStats:
            return "anxietyStats"
        case .dietStats:
            return "dietStats"
        case .smokeStats:
            return "smokeStats"
        case .alcoholicStats:
            return "alcoholicStats"
        case .socialConnectionStats:
            return "socialConnectionStats"
        case .bloodPressureStats:
            return "bloodPressureStats"
        case .mainReasonStats:
            return "mainReasonStats"
        case .goalsStats:
            return "goalsStats"
        case .syncDeviceStats:
            return "syncDeviceStats"
        case .terms:
            return "terms"
        case .paywall:
            return "paywall"
        case .questionnaire:
            return "questionnaire"
        case .valueProposition:
            return "valueProposition"
        case .dashboard:
            return "dashboard"
        case .subscription:
            return "subscription"
        }
    }
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
    
    @State var isFromSettings: Bool = false
    
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
                        MascotNamingView(isFromSettings: isFromSettings, onContinue: { name in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userName, value: name)
                            // Persist profile/metrics so sheets can read immediately
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.genderSelection)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .mascotNaming ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .genderSelection {
                        GenderSelectionView(
                            isFromSettings: isFromSettings,
                            onContinue: { genderEnum in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userGender, value: genderEnum.rawValue)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                        AgeSelectionView (
                            isFromSettings: isFromSettings,
                            onContinue: { date in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDateOfBirth, value: "\(date)")
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                        HeightStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { height in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userHeight, value: height)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                        WeightStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { weight, weightUnit in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userWeight, value: weight)
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userWeightUnit, value: weightUnit)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                        StressStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { stressStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userStressLevel, value: stressStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.anxietyStats)
                        },onSelection: { stressStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userStressLevel, value: stressStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.weightStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .stressStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .anxietyStats {
                        AnxietyStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { anxietyStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAnxietyLevel, value: anxietyStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.dietStats)
                        },onSelection: { anxietyStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAnxietyLevel, value: anxietyStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.stressStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .anxietyStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .dietStats {
                        DietStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { dietStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDietLevel, value: dietStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.smokeStats)
                        },onSelection: { dietStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userDietLevel, value: dietStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.anxietyStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .dietStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .smokeStats {
                        SmokeStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { smokeStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSmokeStats, value: smokeStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.alcoholicStats)
                        }, onSelection: { smokeStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSmokeStats, value: smokeStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.dietStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .smokeStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .alcoholicStats {
                        AlcoholicStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { alcoholStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAlcoholStats, value: alcoholStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.socialConnectionStats)
                        }, onSelection: { alcoholStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userAlcoholStats, value: alcoholStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.smokeStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .alcoholicStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .socialConnectionStats {
                        SocialConnectionStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { socialConnectionStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSocialStats, value: socialConnectionStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.bloodPressureStats)
                        }, onSelection: { socialConnectionStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userSocialStats, value: socialConnectionStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.alcoholicStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .socialConnectionStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .bloodPressureStats {
                        BloodPressureReadingView(
                            isFromSettings: isFromSettings,
                            onContinue: {
                            bloodPressureStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userBloodPressureStats, value: bloodPressureStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.mainReasonStats)
                        }, onSelection: { bloodPressureStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userBloodPressureStats, value: bloodPressureStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.socialConnectionStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .bloodPressureStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .mainReasonStats {
                        MainReasonStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { mainReasonStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userMainReasonStats, value: mainReasonStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
                            isButtonNavigating = true
                            dragDirection = nil
                            navigateTo(.goalsStats)
                        }, onSelection: { mainReasonStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userMainReasonStats, value: mainReasonStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                        }, onBack: {
                            navigateTo(.bloodPressureStats)
                        })
                        .transition(getTransition(forNavigatingTo: appState.currentOnboardingStep))
                        .zIndex(appState.currentOnboardingStep == .mainReasonStats ? 1 : 0)
                    }
                    
                    if appState.currentOnboardingStep == .goalsStats {
                        GoalsStatsView(
                            isFromSettings: isFromSettings,
                            onContinue: { mainReasonStats in
                            appState.saveToUserDefault(keyname: UserDefaultsKeys.userGoalStats, value: mainReasonStats)
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                            // SyncDeviceView will save a full profile+metrics via completeQuestionnaire()
                            // For consistency, also persist here in case deviceSync skips permissions
                            QuestionnaireManager().saveOnboardingDataFromDefaults()
                            
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
                        PaywallScreen { goToSubscription in
                            if goToSubscription {
                                navigateTo(.subscription)
                            } else {
                                navigateTo(.dashboard)
                            }
                        }
                    }
                    
                    if appState.currentOnboardingStep == .subscription {
                        SubscriptionView(isFromOnboarding: true) { isSubscribed in
                            if isSubscribed {
                                appState.updateSubscriptionStatus(true)
                            }
                            
                            navigateTo(.dashboard)
                        }
                    }
                    
                    if appState.currentOnboardingStep == .dashboard {
                        NavigationView {
                            DashboardView()
                        }
                        .transition(getMaterializeTransition())
                        .zIndex({ if case .dashboard = appState.currentOnboardingStep { return 1 } else { return 0 } }())
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
