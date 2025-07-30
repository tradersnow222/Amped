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
    
    /// Background health manager for automatic data updates
    @StateObject private var backgroundHealthManager = BackgroundHealthManager.shared
    
    /// Analytics service for tracking app usage
    private let analyticsService = AnalyticsService.shared
    
    /// Feature flag manager for controlled feature rollout
    private let featureFlagManager = FeatureFlagManager.shared
    
    // MARK: - Scene Phase Tracking for Intro Animations
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // OPTIMIZATION: Use LaunchOptimizer for deferred initialization
        // Rules: Minimize main thread blocking during app launch
        LaunchOptimizer.shared.performCriticalInitialization()
        LaunchOptimizer.shared.performDeferredInitialization()
    }
    
    // MARK: - Scene Configuration
    
    /// Main app scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                backgroundView
                
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .environmentObject(glassTheme)
                    .environmentObject(batteryTheme)
                    .environmentObject(backgroundHealthManager)
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(to: newPhase)
            }
        }
        // SwiftUI background task for health data refresh
        .backgroundTask(.appRefresh("ai.ampedlife.amped.health-refresh")) {
            await BackgroundHealthManager.shared.handleHealthDataRefreshTask()
        }
    }
    
    // MARK: - Background View
    
    /// Deep, immersive background for the app - Rules: Split into computed property for readability
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
            
            // Start background health updates if permissions are available AND setting is enabled
            Task {
                let healthKitManager = HealthKitManager.shared
                if (healthKitManager.hasAllPermissions || healthKitManager.hasCriticalPermissions) && 
                   settingsManager.backgroundRefreshEnabled {
                    await backgroundHealthManager.startBackgroundUpdates()
                }
            }
            
        case .background:
            // App went to background - schedule background tasks only if setting is enabled
            analyticsService.trackEvent(.appBackground)
            if settingsManager.backgroundRefreshEnabled {
                backgroundHealthManager.scheduleHealthProcessing()
            }
            
        default:
            break
        }
    }
}



/// Application-wide state - Rules: Adding authentication tracking and persistence
@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var shouldShowIntroAnimations: Bool = true
    @Published var shouldTriggerIntroAnimations: Bool = false
    @Published var isFirstDashboardViewAfterOnboarding: Bool = false
    @Published var hasShownSignInPopupThisSession: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Defer loading to avoid main thread I/O during launch
        Task {
            await loadOnboardingState()
        }
    }
    
    // MARK: - Persistence Methods
    
    /// Load onboarding completion state from UserDefaults
    private func loadOnboardingState() async {
        // Check both UserDefaults keys for onboarding completion
        let hasCompletedFromDefaults = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Also check UserProfile for consistency
        if let profileData = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            hasCompletedOnboarding = hasCompletedFromDefaults || profile.hasCompletedOnboarding
        } else {
            hasCompletedOnboarding = hasCompletedFromDefaults
        }
    }
    
    /// Save onboarding completion state to UserDefaults
    private func saveOnboardingState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        
        // Also update UserProfile if it exists
        if let profileData = UserDefaults.standard.data(forKey: "user_profile"),
           var profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            profile.completeOnboarding()
            if let updatedData = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(updatedData, forKey: "user_profile")
            }
        }
    }
    
    // MARK: - State Management Methods
    
    /// Handle app return from background to trigger intro animations
    func handleAppReturnFromBackground() {
        // Rules: Only show intro animations if user hasn't disabled them
        shouldShowIntroAnimations = true
    }
    
    /// Mark onboarding as completed and persist to UserDefaults
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveOnboardingState()
    }
    
    /// Set authentication status
    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
    }
    
    /// Mark dashboard animations as shown
    func markDashboardAnimationsShown() {
        shouldTriggerIntroAnimations = false
        isFirstDashboardViewAfterOnboarding = false
    }
    
    /// Reset onboarding state (for testing/debugging)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        
        // CRITICAL FIX: Also clear questionnaire data to ensure fresh start
        // Clear the saved questionnaire progress
        UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
        UserDefaults.standard.removeObject(forKey: "userName")
        
        // Clear any saved questionnaire data using QuestionnaireManager
        QuestionnaireManager().clearAllData()
        
        saveOnboardingState()
    }
}
