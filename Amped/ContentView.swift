import SwiftUI

struct ContentView: View {
    @State private var selectedView: AppView = .onboardingFlow
    @State private var showDebugControls: Bool = false
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    enum AppView: String, CaseIterable, Identifiable {
        case welcome
        case personalizationIntro
        case questionnaire
        case healthkitPermissions
        case signInWithApple
        case payment
        case dashboard
        case onboardingFlow
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .welcome: return "Welcome"
            case .personalizationIntro: return "Personalization Intro"
            case .questionnaire: return "Questionnaire"
            case .healthkitPermissions: return "HealthKit Permissions"
            case .signInWithApple: return "Sign In With Apple"
            case .payment: return "Payment"
            case .dashboard: return "Dashboard"
            case .onboardingFlow: return "Onboarding Flow"
            }
        }
    }
    
    var body: some View {
        #if DEBUG
        // Development preview mode
        ZStack {
            // The main content view takes up the full screen
            Group {
                switch selectedView {
                case .welcome:
                    WelcomeView(onContinue: {})
                case .personalizationIntro:
                    PersonalizationIntroView(onContinue: {})
                case .questionnaire:
                    QuestionnaireView(exitToPersonalizationIntro: .constant(false), proceedToHealthPermissions: .constant(false))
                case .healthkitPermissions:
                    HealthKitPermissionsView(onContinue: {})
                case .signInWithApple:
                    SignInWithAppleView(onContinue: {})
                case .payment:
                    PaymentView(onContinue: {})
                        .environmentObject(appState)
                case .dashboard:
                    DashboardView()
                        .navigationBarHidden(true)
                case .onboardingFlow:
                    OnboardingFlow()
                        .environmentObject(appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Hidden debug controls that can be shown by triple-tapping the corner
            if showDebugControls {
                VStack {
                    Spacer()
                    
                    Picker("Select View", selection: $selectedView) {
                        ForEach(AppView.allCases) { view in
                            Text(view.displayName).tag(view)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        // Add a tap gesture to the corner to show/hide debug controls
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) {
                            showDebugControls.toggle()
                        }
                }
                
                Spacer()
            }
        )
        #else
        // Production mode - follow normal app flow
        if appState.hasCompletedOnboarding {
            NavigationView {
                DashboardView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .accentColor(Color.ampedGreen)
        } else {
            OnboardingFlow()
        }
        #endif
    }
}

// For Xcode 15+ preview
#if swift(>=5.9)
#Preview {
    let themeManager = BatteryThemeManager()
    
    return ContentView()
        .environmentObject(AppState())
        .environmentObject(SettingsManager())
        .environmentObject(themeManager)
        .accentColor(Color.ampedGreen)
        .withDeepBackground()
        .withBatteryTheme(themeManager)
        .withFuturisticTheme()
}
#endif
