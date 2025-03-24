import Foundation
import Combine
import SwiftUI

/// Manager for feature flags to enable gradual rollout of new features
final class FeatureFlagManager: ObservableObject {
    
    // MARK: - Feature Flag Enum
    
    /// All available feature flags in the app
    enum FeatureFlag: String, CaseIterable {
        case enhancedBatteryAnimation = "enhanced_battery_animation"
        case additionalMetrics = "additional_metrics"
        case advancedCharts = "advanced_charts"
        case socialSharing = "social_sharing"
        case cloudSync = "cloud_sync"
        case darkModeTheme = "dark_mode_theme"
        case aiBatteryRecommendations = "ai_battery_recommendations"
        case customGoals = "custom_goals"
        case exportData = "export_data"
        case journalEntries = "journal_entries"
    }
    
    // MARK: - Properties
    
    /// Published map of feature flags and their status
    @Published private var featureFlags: [FeatureFlag: Bool] = [:]
    
    /// Whether remote flags have been fetched
    @Published private var remoteConfigFetched = false
    
    /// User ID for flag targeting
    private let userId: String
    
    /// Singleton instance
    static let shared = FeatureFlagManager()
    
    // MARK: - Initialization
    
    /// Initialize the feature flag manager with default flags
    private init() {
        // Generate a persistent anonymous ID for consistent feature targeting
        if let storedId = UserDefaults.standard.string(forKey: "feature_flag_user_id") {
            self.userId = storedId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "feature_flag_user_id")
            self.userId = newId
        }
        
        // Initialize with default values
        resetToDefaults()
        
        // Load any stored overrides from UserDefaults
        loadStoredFlags()
        
        // In a real app, we would fetch remote config here
        // fetchRemoteFlags()
    }
    
    // MARK: - Public Methods
    
    /// Check if a feature flag is enabled
    /// - Parameter flag: The feature flag to check
    /// - Returns: Whether the flag is enabled
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        return featureFlags[flag] ?? false
    }
    
    /// Enable or disable a feature flag locally (for testing)
    /// - Parameters:
    ///   - flag: The feature to enable/disable
    ///   - enabled: Whether the feature should be enabled
    func setOverride(for flag: FeatureFlag, enabled: Bool) {
        featureFlags[flag] = enabled
        
        // Store the override for persistence
        var storedOverrides = UserDefaults.standard.dictionary(forKey: "feature_flag_overrides") as? [String: Bool] ?? [:]
        storedOverrides[flag.rawValue] = enabled
        UserDefaults.standard.set(storedOverrides, forKey: "feature_flag_overrides")
    }
    
    /// Clear all local overrides
    func clearOverrides() {
        resetToDefaults()
        UserDefaults.standard.removeObject(forKey: "feature_flag_overrides")
    }
    
    /// Refresh flags from remote config
    func refreshFlags() {
        // This would call to a remote config service in a real app
        // For MVP, we'll simulate a fetch with local data
        simulateRemoteFetch()
    }
    
    /// Returns all feature flags for display in a settings screen
    func getAllFlags() -> [(FeatureFlag, Bool)] {
        return FeatureFlag.allCases.map { flag in
            (flag, isEnabled(flag))
        }
    }
    
    // MARK: - Private Methods
    
    /// Set default values for all feature flags
    private func resetToDefaults() {
        // Default all flags to disabled for MVP
        for flag in FeatureFlag.allCases {
            featureFlags[flag] = false
        }
        
        // Enable selected features for MVP
        featureFlags[.enhancedBatteryAnimation] = true
    }
    
    /// Load any stored flag overrides
    private func loadStoredFlags() {
        if let storedOverrides = UserDefaults.standard.dictionary(forKey: "feature_flag_overrides") as? [String: Bool] {
            for (flagString, enabled) in storedOverrides {
                if let flag = FeatureFlag(rawValue: flagString) {
                    featureFlags[flag] = enabled
                }
            }
        }
    }
    
    /// In a real app, this would fetch feature flags from a remote service
    private func fetchRemoteFlags() {
        // Implementation would make a network request to a remote config service
    }
    
    /// For MVP, simulate a fetch with local percentage-based rollout
    private func simulateRemoteFetch() {
        // Use a hash of the user ID for consistent flag assignment
        let userIdHash = userId.hash
        
        // Simulate different rollout percentages for each flag
        featureFlags[.enhancedBatteryAnimation] = isUserInRolloutGroup(userIdHash, percentage: 100)
        featureFlags[.additionalMetrics] = isUserInRolloutGroup(userIdHash, percentage: 50)
        featureFlags[.advancedCharts] = isUserInRolloutGroup(userIdHash, percentage: 25)
        featureFlags[.socialSharing] = isUserInRolloutGroup(userIdHash, percentage: 10)
        featureFlags[.cloudSync] = isUserInRolloutGroup(userIdHash, percentage: 5)
        featureFlags[.darkModeTheme] = isUserInRolloutGroup(userIdHash, percentage: 100)
        featureFlags[.aiBatteryRecommendations] = isUserInRolloutGroup(userIdHash, percentage: 15)
        featureFlags[.customGoals] = isUserInRolloutGroup(userIdHash, percentage: 30)
        featureFlags[.exportData] = isUserInRolloutGroup(userIdHash, percentage: 20)
        featureFlags[.journalEntries] = isUserInRolloutGroup(userIdHash, percentage: 15)
        
        remoteConfigFetched = true
    }
    
    /// Determine if a user is in a percentage-based rollout group
    /// - Parameters:
    ///   - userIdHash: Hash of the user ID for consistent grouping
    ///   - percentage: Percentage of users who should have the feature enabled (0-100)
    /// - Returns: Whether the user should have the feature enabled
    private func isUserInRolloutGroup(_ userIdHash: Int, percentage: Int) -> Bool {
        // Get an absolute hash value between 0-99
        let hashValue = abs(userIdHash) % 100
        
        // User is in the group if their hash is less than the percentage
        return hashValue < percentage
    }
}

// MARK: - View Extension

/// Extension to make feature flags accessible in SwiftUI views
extension View {
    /// Check if a feature flag is enabled
    /// - Parameter flag: The feature flag to check
    /// - Returns: Whether the flag is enabled
    func featureEnabled(_ flag: FeatureFlagManager.FeatureFlag) -> Bool {
        return FeatureFlagManager.shared.isEnabled(flag)
    }
} 