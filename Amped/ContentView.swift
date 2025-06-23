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
        // DEBUG development mode with view switcher controls
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
                            appState.hasCompletedOnboarding = false
                            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
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
                            print("🐛 DEBUG: Triple-tap gesture triggered")
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
