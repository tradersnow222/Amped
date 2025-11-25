import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    // Launch flow stages: Splash (AmpedAnimatedView) → WelcomeView → Rest of app
    private enum LaunchStage {
        case splash
        case welcome
        case main
    }

    @State private var stage: LaunchStage = .splash

    // Existing debug state
    @State private var selectedView: AppView = .onboardingFlow
    @State private var showDebugControls: Bool = false
    @State private var showSplash: Bool = true

    enum AppView: String, CaseIterable, Identifiable {
        case dashboard
        case onboardingFlow

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .onboardingFlow: return "Onboarding Flow"
            }
        }
    }

    var body: some View {
        ZStack {
            Group {
                switch stage {
                case .splash:
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            stage = .welcome
                        }
                    }
                    .environmentObject(appState)

                case .welcome:
                    WelcomeView(onContinue: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            stage = .main
                            // Continue the existing onboarding path
                            appState.currentOnboardingStep = .valueProposition
                        }
                        
                    })
                    .environmentObject(appState)

                case .main:
                    if appState.hasCompletedOnboarding && !showDebugControls {
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
                    } else {
                        switch selectedView {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Triple-tap debug overlay toggle (unchanged)
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
