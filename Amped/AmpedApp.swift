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
import RevenueCat

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
    
    /// Notification manager for user engagement
    @StateObject private var notificationManager = NotificationManager.shared
    
    /// Subscription manager for RevenueCat integration
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    /// Shared DashboardViewModel for the entire app
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
    // MARK: - Scene Phase Tracking for Intro Animations
    @Environment(\.scenePhase) private var scenePhase
    
    /// Main app scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                
                ContentView()
                    .background(Color.black)
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .environmentObject(glassTheme)
                    .environmentObject(batteryTheme)
                    .environmentObject(backgroundHealthManager)
                    .environmentObject(subscriptionManager)
                    .environmentObject(dashboardViewModel) // Inject once for the whole app
            }
            .background(Color.clear)
            .onChange(of: scenePhase) { newPhase in
//                handleScenePhaseChange(to: newPhase)
            }
        }
        // SwiftUI background task for health data refresh
        .backgroundTask(.appRefresh("ai.ampedlife.amped.health-refresh")) {
//            await BackgroundHealthManager.shared.handleHealthDataRefreshTask()
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
            // Rules: Increment app launch count and trigger intro animations when returning from background
            appState.incrementAppLaunchCount()
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
            // Save current onboarding state when app goes to background (soft close)
            appState.markAppEnteringBackground()
            appState.saveOnboardingProgress()
            if settingsManager.backgroundRefreshEnabled {
                backgroundHealthManager.scheduleHealthProcessing()
            }
            
        case .inactive:
            // App is about to become inactive - save state
            appState.saveOnboardingProgress()
            
        @unknown default:
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
    @Published var hasUserPermanentlyDismissedSignIn: Bool = false
    @Published var appLaunchCount: Int = 0
    
    // ONBOARDING PROGRESS TRACKING: Advanced persistence with soft/hard close detection
    @Published var currentOnboardingStep: OnboardingStep = .valueProposition
    
    // MASCOT PERSONALIZATION: Store user's chosen mascot name globally
    @Published var mascotName: String = "Emma" // Default name
    
    // SUBSCRIPTION STATUS: Track premium subscription status
    @Published var isPremiumUser: Bool = false
    
    // ONBOARDING PERSISTENCE: Manager for handling soft vs hard close
    private let persistenceManager = OnboardingPersistenceManager()
    
    // MARK: - Initialization
    
    init() {
        // CRITICAL FIX: Load onboarding state SYNCHRONOUSLY to avoid race condition
        // The UI renders immediately, so we need the state available before first render
        self.loadOnboardingStateSynchronously()
        
        // Mark app launch start for persistence tracking
        self.persistenceManager.markAppLaunchStart()
        
        // Defer other expensive loading to avoid blocking launch
        Task {
            await loadRemainingState()
        }
    }
    
    // MARK: - Persistence Methods
    
    /// Load critical onboarding state synchronously during initialization
    private func loadOnboardingStateSynchronously() {
        // Check both UserDefaults keys for onboarding completion
        let hasCompletedFromDefaults = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Load app launch count
        appLaunchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
        
        // Load authentication and sign-in dismissal state
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        hasUserPermanentlyDismissedSignIn = UserDefaults.standard.bool(forKey: "hasUserPermanentlyDismissedSignIn")
        
        // Set hasCompletedOnboarding immediately (UserProfile check can be deferred)
        hasCompletedOnboarding = hasCompletedFromDefaults
        
        // CRITICAL: Load onboarding progress using advanced persistence
        if !hasCompletedOnboarding {
            let closureType = persistenceManager.detectClosureType()
            if let restoredStep = persistenceManager.loadOnboardingProgress(closureType: closureType) {
                currentOnboardingStep = restoredStep
            }
        }
        
        // Load saved mascot name
        if let savedMascotName = UserDefaults.standard.string(forKey: "mascot_name") {
            mascotName = savedMascotName
        }
        
        // Load subscription status
        isPremiumUser = UserDefaults.standard.bool(forKey: "is_premium_user")
    }
    
    /// Load remaining state asynchronously to avoid blocking launch
    private func loadRemainingState() async {
        // Check UserProfile for consistency (can be done async)
        if let profileData = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            await MainActor.run {
                let wasCompleted = self.hasCompletedOnboarding
                self.hasCompletedOnboarding = wasCompleted || profile.hasCompletedOnboarding
            }
        }
    }
    
    /// Save mascot name to UserDefaults
    func saveMascotName(_ name: String) {
        mascotName = name
        UserDefaults.standard.set(name, forKey: "mascot_name")
    }
    
    func saveToUserDefault(keyname: String, value: Any) {
        UserDefaults.standard.set(value, forKey: keyname)
    }
    
    func getFromUserDefault(key: String) -> String {
        return UserDefaults.standard.string(forKey: key) ?? ""
    }
    
    /// Update subscription status and save to UserDefaults
    func updateSubscriptionStatus(_ isPremium: Bool) {
        isPremiumUser = isPremium
        UserDefaults.standard.set(isPremium, forKey: "is_premium_user")
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
        // Rules: Only show intro animations if user haven't disabled them
        shouldShowIntroAnimations = true
        
        // CRITICAL FIX: Don't detect closure type again on app return
        // Detection already happened in init() - this would cause double detection
        // and incorrect soft close detection due to fresh timestamp
    }
    
    /// Mark onboarding as completed and persist to UserDefaults
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveOnboardingState()
    }
    
    /// Set authentication status and persist to UserDefaults
    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
        UserDefaults.standard.set(authenticated, forKey: "isAuthenticated")
        
        // If user authenticated, they've implicitly dismissed the sign-in popup permanently
        if authenticated {
            hasUserPermanentlyDismissedSignIn = true
            UserDefaults.standard.set(true, forKey: "hasUserPermanentlyDismissedSignIn")
        }
    }
    
    /// Mark that user has permanently dismissed the sign-in popup
    func markSignInPermanentlyDismissed() {
        hasUserPermanentlyDismissedSignIn = true
        UserDefaults.standard.set(true, forKey: "hasUserPermanentlyDismissedSignIn")
    }
    
    /// Mark dashboard animations as shown
    func markDashboardAnimationsShown() {
        shouldTriggerIntroAnimations = false
        isFirstDashboardViewAfterOnboarding = false
    }
    
    /// Increment app launch count
    func incrementAppLaunchCount() {
        appLaunchCount += 1
        UserDefaults.standard.set(appLaunchCount, forKey: "appLaunchCount")
    }
    
    /// Reset onboarding state (for testing/debugging)
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentOnboardingStep = .valueProposition
        
        // Use advanced persistence manager for comprehensive reset
        persistenceManager.resetAllData()
        
        // Clear any saved questionnaire data using QuestionnaireManager
        QuestionnaireManager().clearAllData()
        
        // Reset app launch count for testing
        appLaunchCount = 0
        UserDefaults.standard.removeObject(forKey: "appLaunchCount")
        
        saveOnboardingState()
    }
    
    // MARK: - Onboarding Progress Management
    
    /// Save current onboarding progress using advanced persistence
    func saveOnboardingProgress() {
        persistenceManager.saveOnboardingProgress(currentOnboardingStep, hasCompletedOnboarding: hasCompletedOnboarding)
    }
    
    /// Mark app as entering background (for soft close detection)
    func markAppEnteringBackground() {
        persistenceManager.markAppEnteringBackground()
    }
    
    /// Update current onboarding step and save progress
    func updateOnboardingStep(_ step: OnboardingStep) {
        currentOnboardingStep = step
        persistenceManager.saveOnboardingProgress(step, hasCompletedOnboarding: hasCompletedOnboarding)
    }
}

