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
import Combine

@main
struct AmpedApp: App {
    // MARK: - App State and Services
    
    /// Bridge UIKit AppDelegate so quick actions and other delegate callbacks work
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
    @StateObject private var revenueCatManager = RevenueCatStoreKitManager.shared
    
    /// Shared DashboardViewModel for the entire app
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
    // MARK: - Scene Phase Tracking for Intro Animations
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Quick Action Feedback Sheet State
    @State private var showFeedbackSheet = false
    @State private var feedbackText: String = ""
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ai.ampedlife.amped", category: "AmpedApp")
    
    /// Main app scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Use ContentView so it can observe .showFeedback and present the sheet
                ContentView()
                    .background(Color.black)
                    .environmentObject(appState)
                    .environmentObject(settingsManager)
                    .environmentObject(glassTheme)
                    .environmentObject(batteryTheme)
                    .environmentObject(backgroundHealthManager)
                    .environmentObject(revenueCatManager)
                    .environmentObject(dashboardViewModel) // Inject once for the whole app
            }
            .background(Color.clear)
            // Ensure we pick up any pending quick action on first render
            .onAppear {
                consumePendingQuickActionIfAny(context: "onAppear")
            }
            .onChange(of: scenePhase) { newPhase in
//                handleScenePhaseChange(to: newPhase)
                if newPhase == .active {
                    // Also check when the scene becomes active (cold or warm)
                    consumePendingQuickActionIfAny(context: "scenePhase.active")
                }
            }
            // Listen for quick action selections and show Feedback dialog when requested.
            // Ensure delivery on the main thread so we can mutate @State safely.
            .onReceive(
                NotificationCenter.default
                    .publisher(for: NSNotification.Name("QuickActionSelected"))
                    .receive(on: RunLoop.main)
            ) { notification in
                let type = notification.userInfo?["type"] as? String ?? "nil"
                logger.info("📥 Received QuickActionSelected in SwiftUI: \(type, privacy: .public)")
                if type == "ai.ampedlife.amped.sendFeedback" {
                    // Small delay ensures the view hierarchy is fully ready to present.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        logger.info("🗳️ Setting showFeedbackSheet = true (notification)")
                        showFeedbackSheet = true
                    }
                }
            }
            // Present the feedback dialog sheet
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackDialog(
                    title: "Please share your feedback with us.",
                    text: $feedbackText,
                    onSubmit: { text in
                        // Handle submitted feedback (send to analytics/service, etc.)
//                        AnalyticsService.shared.trackEvent(.feedbackSubmitted(text: text))
                        logger.info("✅ Feedback submitted, dismissing sheet")
                        feedbackText = ""
                        showFeedbackSheet = false
                    },
                    onCancel: {
                        logger.info("🚫 Feedback canceled, dismissing sheet")
                        feedbackText = ""
                        showFeedbackSheet = false
                    }
                )
            }
        }
        // SwiftUI background task for health data refresh
        .backgroundTask(.appRefresh("ai.ampedlife.amped.health-refresh")) {
//            await BackgroundHealthManager.shared.handleHealthDataRefreshTask()
        }
    }
    
    // MARK: - Quick Action Consumption
    
    private func consumePendingQuickActionIfAny(context: String) {
        let pendingKey = "PendingQuickActionType"
        guard let type = UserDefaults.standard.string(forKey: pendingKey) else {
            return
        }
        logger.info("📦 Found pending quick action in UserDefaults (\(context, privacy: .public)): \(type, privacy: .public)")
        
        // Clear it immediately to avoid double handling
        UserDefaults.standard.removeObject(forKey: pendingKey)
        
        if type == "ai.ampedlife.amped.sendFeedback" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                logger.info("🗳️ Setting showFeedbackSheet = true (consumePendingQuickActionIfAny)")
                showFeedbackSheet = true
            }
        } else if type == "ai.ampedlife.amped.openDashboard" {
            // If you need to navigate to dashboard at app level, handle here
            logger.info("🧭 Pending action requested dashboard (not implemented at app level)")
        } else if type == "ai.ampedlife.amped.refreshHealthData" {
            // If you need to trigger a refresh globally, handle here
            logger.info("🔄 Pending action requested health data refresh (not implemented at app level)")
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
    func updateSubscriptionStatus(_ isPremium: Bool, inTrial: Bool = false) {
        let isPremiumUser = isPremium || inTrial
        UserDefaults.standard.set(isPremiumUser, forKey: "is_premium_user")
        self.isPremiumUser = isPremiumUser
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
