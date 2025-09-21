    import SwiftUI

struct ContentView: View {
    @State private var selectedView: AppView = .onboardingFlow
    @State private var showDebugControls: Bool = false
    @State private var showPaymentFromPaywall: Bool = false
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    enum AppView: String, CaseIterable, Identifiable {
        case welcome
        case personalizationIntro
        case questionnaire
        case payment
        case dashboard
        case onboardingFlow
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .welcome: return "Welcome"
            case .personalizationIntro: return "Personalization Intro"
            case .questionnaire: return "Questionnaire"
            case .payment: return "Payment"
            case .dashboard: return "Dashboard"
            case .onboardingFlow: return "Onboarding Flow"
            }
        }
    }
    
    var body: some View {
        // DEBUG development mode with view switcher controls
        ZStack {
                    // The main content view takes up the full screen
                    Group {
                        // PRODUCTION LOGIC: Show dashboard if onboarding is complete AND user has subscription
                        if appState.hasCompletedOnboarding && appState.isPremiumUser && !showDebugControls {
                            // Show main dashboard for subscribed users
                            if #available(iOS 16.0, *) {
                                NavigationStack {
                                    DashboardView()
                                }
                            } else {
                                NavigationView {
                                    DashboardView()
                                }
                                .navigationViewStyle(StackNavigationViewStyle())
                            }
                        } else if appState.hasCompletedOnboarding && !appState.isPremiumUser && !showDebugControls {
                            if showPaymentFromPaywall {
                                // Show payment screen when user clicks continue from paywall
                                PaymentView(onContinue: { 
                                    // Payment successful, update subscription status
                                    appState.updateSubscriptionStatus(true)
                                    showPaymentFromPaywall = false
                                })
                            } else {
                                // Show paywall for non-subscribers who completed onboarding
                                // Use PrePaywallTeaserView with a mock questionnaire view model for scoring
                                PrePaywallTeaserView(
                                    viewModel: QuestionnaireViewModel(startFresh: false),
                                    onContinue: {
                                        // Navigate to payment screen for subscription
                                        showPaymentFromPaywall = true
                                    }
                                )
                            }
                } else if !showDebugControls {
                    // Show onboarding flow for new users
                    OnboardingFlow()
                        .environmentObject(appState)
                } else {
                    // DEBUG MODE: Show selected view
                    switch selectedView {
                    case .welcome:
                        WelcomeView(onContinue: {})
                    case .personalizationIntro:
                        PersonalizationIntroView(onContinue: {})
                    case .questionnaire:
                        QuestionnaireView(
                            viewModel: QuestionnaireViewModel(),
                            exitToPersonalizationIntro: .constant(false), 
                            proceedToHealthPermissions: .constant(false)
                        )
                    case .payment:
                        PaymentView(onContinue: {})
                            .environmentObject(appState)
                    case .dashboard:
                        if #available(iOS 16.0, *) {
                            NavigationStack {
                                DashboardView()
                            }
                        } else {
                            NavigationView {
                                DashboardView()
                            }
                            .navigationViewStyle(StackNavigationViewStyle())
                        }
                    case .onboardingFlow:
                        OnboardingFlow()
                            .environmentObject(appState)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Hidden debug controls that can be shown by triple-tapping the corner
            if showDebugControls {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("DEBUG MODE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Select View", selection: $selectedView) {
                            ForEach(AppView.allCases) { view in
                                Text(view.displayName).tag(view)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        // Add button to reset onboarding state for testing
                        Button("Reset Onboarding") {
                            appState.resetOnboarding()
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                        
                        // Add button to complete onboarding for testing
                        Button("Complete Onboarding") {
                            appState.completeOnboarding()
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        // Add a tap gesture to the corner to show/hide debug controls
        .overlay(
            VStack {
                Spacer()
                
                HStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) {
                            showDebugControls.toggle()
                        }
                    
                    Spacer()
                }
            }
        )
    }
}

// For Xcode 15+ preview
#if swift(>=5.9)
#Preview {
    let themeManager = BatteryThemeManager()
    
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
        .environmentObject(themeManager)
        .accentColor(Color.ampedGreen)
        .withDeepBackground()
        .withBatteryTheme(themeManager)
}
#endif
