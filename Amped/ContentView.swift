import SwiftUI

struct ContentView: View {
    @State private var selectedView: AppView = .welcome
    
    @EnvironmentObject var appState: AppState
    
    enum AppView: String, CaseIterable, Identifiable {
        case welcome
        case personalizationIntro
        case questionnaire
        case healthkitPermissions
        case signInWithApple
        case payment
        case dashboard
        
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
            }
        }
    }
    
    var body: some View {
        #if DEBUG
        // Development preview mode - show only the selected view without picker
        Group {
            switch selectedView {
            case .welcome:
                WelcomeView()
            case .personalizationIntro:
                PersonalizationIntroView()
            case .questionnaire:
                QuestionnaireView()
            case .healthkitPermissions:
                HealthKitPermissionsView()
            case .signInWithApple:
                SignInWithAppleView()
            case .payment:
                PaymentView()
            case .dashboard:
                DashboardView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .withBatteryTheme(BatteryThemeManager())
        #else
        // Production mode - follow normal app flow
        if appState.hasCompletedOnboarding {
            NavigationView {
                DashboardView()
            }
        } else {
            WelcomeView()
        }
        #endif
    }
}

// Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SettingsManager())
            .environmentObject(BatteryThemeManager())
            .environmentObject(AppState())
            .accentColor(AmpedColors.green)
            .withBatteryTheme(BatteryThemeManager())
    }
}

// For Xcode 15+ preview
#if swift(>=5.9)
#Preview {
    ContentView()
        .environmentObject(SettingsManager())
        .environmentObject(BatteryThemeManager())
        .environmentObject(AppState())
        .accentColor(AmpedColors.green)
        .withBatteryTheme(BatteryThemeManager())
}
#endif
