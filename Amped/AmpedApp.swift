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
    
    /// Notification manager for user engagement
    @StateObject private var notificationManager = NotificationManager.shared
    
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
    @Published var appLaunchCount: Int = 0
    
    // ONBOARDING PROGRESS TRACKING: Advanced persistence with soft/hard close detection
    @Published var currentOnboardingStep: OnboardingStep = .welcome
    
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
        
        // Set hasCompletedOnboarding immediately (UserProfile check can be deferred)
        hasCompletedOnboarding = hasCompletedFromDefaults
        
        // CRITICAL: Load onboarding progress using advanced persistence
        if !hasCompletedOnboarding {
            let closureType = persistenceManager.detectClosureType()
            if let restoredStep = persistenceManager.loadOnboardingProgress(closureType: closureType) {
                currentOnboardingStep = restoredStep
            }
        }
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
    
    /// Set authentication status
    func setAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
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
        currentOnboardingStep = .welcome
        
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
