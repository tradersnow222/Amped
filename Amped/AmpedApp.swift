//
//  AmpedApp.swift
//  Amped
//
//  Created by Matt Snow on 3/23/25.
//
// Note: This app uses auto-generated Info.plist. Settings are defined in the Xcode build
// configuration. See InfoPlistManager.swift for documentation on key settings.

import SwiftUI

@main
struct AmpedApp: App {
    // MARK: - State Object Properties
    
    /// Main app state
    @StateObject private var appState = AppState()
    
    /// Settings manager for user preferences
    @StateObject private var settingsManager = SettingsManager()
    
    /// Theme manager for time-based theming
    @StateObject private var themeManager = BatteryThemeManager()
    
    // MARK: - Properties
    
    /// Analytics service
    private let analyticsService = AnalyticsService.shared
    
    /// Feature flag manager
    private let featureFlagManager = FeatureFlagManager.shared
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // For previews and development
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .environmentObject(themeManager)
                .accentColor(Color.ampedGreen) // Set app-wide accent color
                .withDeepBackground() // Apply deep background image
                .withBatteryTheme(themeManager) // Apply time-based background theme
                .withFuturisticTheme() // Apply futuristic text styling
                .onAppear {
                    // Log app launch in analytics (if enabled)
                    analyticsService.trackEvent(.appLaunch)
                    
                    // Refresh feature flags
                    featureFlagManager.refreshFlags()
                }
            #else
            // Production flow
            if appState.hasCompletedOnboarding {
                // User has completed onboarding, show dashboard
                NavigationView {
                    DashboardView()
                        .environmentObject(appState)
                        .environmentObject(settingsManager)
                        .environmentObject(themeManager)
                }
                .accentColor(Color.ampedGreen) // Set app-wide accent color
                .withDeepBackground() // Apply deep background image
                .withBatteryTheme(themeManager) // Apply time-based background theme
                .withFuturisticTheme() // Apply futuristic text styling
                .onAppear {
                    // Log app launch in analytics (if enabled)
                    analyticsService.trackEvent(.appLaunch)
                    
                    // Refresh feature flags
                    featureFlagManager.refreshFlags()
                }
            } else {
                // User needs onboarding, use the new OnboardingFlow
                OnboardingFlow()
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .environmentObject(themeManager)
                    .accentColor(Color.ampedGreen) // Set app-wide accent color
                    .withBatteryTheme(themeManager) // Apply time-based background theme
                    .withFuturisticTheme() // Apply futuristic text styling
                    .onAppear {
                        // Track onboarding start
                        analyticsService.trackOnboardingStep("welcome")
                    }
            }
            #endif
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Scene Phase Handling
    
    /// Environment value for the current scene phase
    @Environment(\.scenePhase) private var scenePhase
    
    /// Handle app lifecycle phase changes
    /// - Parameters:
    ///   - oldPhase: Previous scene phase
    ///   - newPhase: New scene phase
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            if oldPhase != .active {
                // Update theme based on current time
                themeManager.updateTheme()
            }
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
        // In a real app, we would check UserDefaults or other persistent storage
        // to determine if the user has completed onboarding
        // Using the UserDefaults extension from DashboardView
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

// MARK: - Futuristic Theme Modifier

/// View modifier for applying futuristic theme throughout the app
struct FuturisticThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.font, .system(.body, design: .monospaced))
            .tint(.white) // Set tint color for buttons, toggles, etc.
    }
}

extension View {
    /// Apply futuristic styling app-wide
    func withFuturisticTheme() -> some View {
        modifier(FuturisticThemeModifier())
    }
}
