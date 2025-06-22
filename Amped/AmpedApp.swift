//
//  AmpedApp.swift
//  Amped
//
//  Created by Matt Snow on 3/23/25.
//
// Note: This app uses auto-generated Info.plist. Settings are defined in the Xcode build
// configuration. See InfoPlistManager.swift for documentation on key settings.

import SwiftUI
import OSLog

@main
struct AmpedApp: App {
    // MARK: - App State and Services
    
    /// Global app state
    @StateObject private var appState = AppState()
    
    /// Settings manager for app preferences
    @StateObject private var settingsManager = SettingsManager()
    
    /// Glass theme manager for consistent UI styling
    @StateObject private var glassTheme = GlassThemeManager()
    
    /// Battery theme manager for battery-themed UI components
    @StateObject private var batteryTheme = BatteryThemeManager()
    
    /// Analytics service for tracking app usage
    private let analyticsService = AnalyticsService.shared
    
    /// Feature flag manager for controlled feature rollout
    private let featureFlagManager = FeatureFlagManager.shared
    
    // MARK: - Scene Configuration
    
    /// Main app scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Deep background for glass effects
                backgroundView
                
                // Main content based on onboarding status
                if appState.hasCompletedOnboarding {
                    // User has completed onboarding - show main app
                    if #available(iOS 16.0, *) {
                        NavigationStack {
                            DashboardView()
                                .environmentObject(appState)
                                .environmentObject(settingsManager)
                                .environmentObject(batteryTheme)
                                .environment(\.glassTheme, glassTheme)
                        }
                    } else {
                        NavigationView {
                            DashboardView()
                                .environmentObject(appState)
                                .environmentObject(settingsManager)
                                .environmentObject(batteryTheme)
                                .environment(\.glassTheme, glassTheme)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    }
                } else {
                    // User needs onboarding - show different views for DEBUG vs PRODUCTION
                    #if DEBUG
                    // DEBUG mode: Show ContentView with debug controls
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(settingsManager)
                        .environmentObject(batteryTheme)
                        .environment(\.glassTheme, glassTheme)
                    #else
                    // PRODUCTION mode: Show OnboardingFlow directly
                    OnboardingFlow()
                        .environmentObject(appState)
                        .environmentObject(settingsManager)
                        .environmentObject(batteryTheme)
                        .environment(\.glassTheme, glassTheme)
                        .onAppear {
                            // Track onboarding start
                            analyticsService.trackOnboardingStep("welcome")
                        }
                    #endif
                }
            }
            // Apply glass theme styling to entire app
            .withGlassTheme()
            .tint(Color.ampedGreen) // Set app-wide tint color
            .onAppear {
                // Log app launch in analytics (if enabled)
                analyticsService.trackEvent(.appLaunch)
                
                // Refresh feature flags
                featureFlagManager.refreshFlags()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(to: newPhase)
        }
    }
    
    // MARK: - Background View
    
    /// Glass-compatible background view
    private var backgroundView: some View {
        ZStack {
            // Deep background image
            GeometryReader { geometry in
                Image("DeepBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            
            // Glass-compatible overlay for better material effects
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Scene Phase Handling
    
    /// Environment value for the current scene phase
    @Environment(\.scenePhase) private var scenePhase
    
    /// Handle app lifecycle phase changes
    /// - Parameters:
    ///   - newPhase: New scene phase
    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - no specific glass theme updates needed
            break
        case .background:
            // App went to background
            analyticsService.trackEvent(.appBackground)
        default:
            break
        }
    }
}

/// Application-wide state
class AppState: ObservableObject {
    /// Whether the user has completed onboarding
    @Published var hasCompletedOnboarding: Bool
    
    init() {
        // Check UserDefaults to determine if the user has completed onboarding
        if let value = UserDefaults.standard.object(forKey: "hasCompletedOnboarding") as? Bool {
            self.hasCompletedOnboarding = value
        } else {
            self.hasCompletedOnboarding = false
        }
    }
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Glass Theme Modifier

/// View modifier for applying glass theme throughout the app
struct GlassThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.font, .system(.body, design: .monospaced))
            .tint(.white) // Set tint color for buttons, toggles, etc.
    }
}
