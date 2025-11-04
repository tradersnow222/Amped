import SwiftUI

struct ContentView: View {
    @State private var selectedView: AppView = .onboardingFlow
    @State private var showDebugControls: Bool = false
    @State private var showSplash: Bool = true
    
    @EnvironmentObject var appState: AppState
    
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
        // DEBUG development mode with view switcher controls
        ZStack {
            // The main content view takes up the full screen
            Group {
                if showSplash {
                    WelcomeView(onContinue: {
                        showSplash = false
                        appState.currentOnboardingStep = .valueProposition
                    })
                    .environmentObject(appState)
                } else {
                    if appState.hasCompletedOnboarding && !showDebugControls {
                        // Show main dashboard for completed users
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
                        // DEBUG MODE: Show selected view
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

