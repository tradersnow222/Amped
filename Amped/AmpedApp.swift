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
import HealthKit

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
    
    // MARK: - Scene Phase Tracking for Intro Animations
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // OPTIMIZATION: Pre-warm HealthKit to make authorization instant
        if HKHealthStore.isHealthDataAvailable() {
            // Create the store first
            _ = HKHealthStore()
            
            // Pre-warm the authorization system by checking if it's available
            // This forces iOS to load the HealthKit authorization UI framework
            _ = HKHealthStore.isHealthDataAvailable()
            
            // Pre-initialize the HealthKitManager shared instance synchronously
            // This ensures everything is ready before any UI appears
            Task { @MainActor in
                _ = HealthKitManager.shared
                
                // Pre-cache the authorization status to warm up the system
                _ = HealthKitManager.shared.hasCriticalPermissions
            }
        }
    }
    
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
                
                // Rules: Track app launch count for sign-in popup timing
                let currentLaunchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
                UserDefaults.standard.set(currentLaunchCount + 1, forKey: "appLaunchCount")
                
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
    
    /// Handle app lifecycle phase changes
    /// - Parameters:
    ///   - newPhase: New scene phase
    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            analyticsService.trackEvent(.appLaunch)
            // Rules: Trigger intro animations when returning from background
            appState.handleAppReturnFromBackground()
        case .background:
            // App went to background
            analyticsService.trackEvent(.appBackground)
        default:
            break
        }
    }
}

/// Application-wide state - Rules: Adding authentication tracking
class AppState: ObservableObject {
    /// Whether the user has completed onboarding
    @Published var hasCompletedOnboarding: Bool
    
    /// Whether the user has signed in with Apple or Google - Rules: Track authentication status
    @Published var isAuthenticated: Bool
    
    /// User's unique identifier - Rules: Store user ID after authentication
    @Published var userID: String?
    
    /// Whether the sign-in popup has been shown in the current session - Rules: Track per-session popup state
    @Published var hasShownSignInPopupThisSession: Bool = false
    
    /// Whether to trigger intro animations on dashboard - Rules: Smart animation triggering
    @Published var shouldTriggerIntroAnimations: Bool = false
    
    /// Track if this is the first dashboard view after onboarding completion - Rules: First-time animation
    @Published var isFirstDashboardViewAfterOnboarding: Bool = false
    
    init() {
        // Check UserDefaults to determine if the user has completed onboarding
        if let value = UserDefaults.standard.object(forKey: "hasCompletedOnboarding") as? Bool {
            self.hasCompletedOnboarding = value
        } else {
            self.hasCompletedOnboarding = false
        }
        
        // Check authentication status - Rules: Load authentication state from UserDefaults
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        self.userID = UserDefaults.standard.string(forKey: "userID")
        
        // Check if this is the first dashboard view after onboarding completion - Rules: First-time animation
        self.isFirstDashboardViewAfterOnboarding = UserDefaults.standard.bool(forKey: "isFirstDashboardViewAfterOnboarding")
        
        // Don't trigger animations on app launch - only after background/foreground cycle
        self.shouldTriggerIntroAnimations = false
    }
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Mark that this will be the first dashboard view after onboarding - Rules: First-time animation
        isFirstDashboardViewAfterOnboarding = true
        UserDefaults.standard.set(true, forKey: "isFirstDashboardViewAfterOnboarding")
    }
    
    /// Update authentication status - Rules: Track when user signs in
    func setAuthenticated(userID: String) {
        self.isAuthenticated = true
        self.userID = userID
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(userID, forKey: "userID")
    }
    
    /// Sign out user - Rules: Clear authentication status
    func signOut() {
        self.isAuthenticated = false
        self.userID = nil
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userID")
    }
    
    /// Handle app returning from background - Rules: Trigger intro animations
    func handleAppReturnFromBackground() {
        // Only trigger animations if user has completed onboarding and is on dashboard
        if hasCompletedOnboarding {
            shouldTriggerIntroAnimations = true
        }
    }
    
    /// Mark that dashboard animations have been shown - Rules: Reset animation flags
    func markDashboardAnimationsShown() {
        shouldTriggerIntroAnimations = false
        
        // If this was the first dashboard view after onboarding, clear that flag
        if isFirstDashboardViewAfterOnboarding {
            isFirstDashboardViewAfterOnboarding = false
            UserDefaults.standard.set(false, forKey: "isFirstDashboardViewAfterOnboarding")
        }
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
