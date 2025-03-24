import Foundation
import OSLog

/// Privacy-focused analytics service that respects user preferences
final class AnalyticsService {
    
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = AnalyticsService()
    
    /// Setting manager instance for checking opt-in status
    private let settingsManager: SettingsManager
    
    /// Anonymous device identifier
    private let deviceIdentifier: String
    
    /// Logger instance
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "Analytics")
    
    // MARK: - Event Types
    
    /// Analytics event types
    enum EventType: String {
        case appLaunch = "app_launch"
        case appBackground = "app_background"
        case screenView = "screen_view"
        case metricSelected = "metric_selected"
        case timeRangeChanged = "time_range_changed"
        case impactCalculated = "impact_calculated"
        case projectionCalculated = "projection_calculated"
        case settingsChanged = "settings_changed"
        case healthKitPermission = "healthkit_permission"
        case purchaseStarted = "purchase_started"
        case purchaseCompleted = "purchase_completed"
        case purchaseCancelled = "purchase_cancelled"
        case onboardingStep = "onboarding_step"
        case onboardingCompleted = "onboarding_completed"
        case featureUsed = "feature_used"
        case error = "error_occurred"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Use SettingsManager to check if analytics are enabled
        self.settingsManager = SettingsManager()
        
        // Create or retrieve anonymous device identifier
        if let storedIdentifier = UserDefaults.standard.string(forKey: "analytics_device_id") {
            self.deviceIdentifier = storedIdentifier
        } else {
            let newIdentifier = UUID().uuidString
            UserDefaults.standard.set(newIdentifier, forKey: "analytics_device_id")
            self.deviceIdentifier = newIdentifier
        }
    }
    
    // MARK: - Public Methods
    
    /// Track an analytics event if the user has opted in
    /// - Parameters:
    ///   - event: The type of event to track
    ///   - parameters: Optional additional parameters for the event
    func trackEvent(_ event: EventType, parameters: [String: Any]? = nil) {
        // Only track if user has opted in
        guard settingsManager.privacyAnalyticsEnabled else {
            return
        }
        
        // In a real app, this would send the event to an analytics service
        // For this MVP, we'll just log it locally
        var logParameters = parameters ?? [:]
        logParameters["event"] = event.rawValue
        logParameters["timestamp"] = ISO8601DateFormatter().string(from: Date())
        logParameters["device_id"] = deviceIdentifier
        
        // Log the event for development purposes
        logger.debug("Analytics event: \(event.rawValue, privacy: .public), params: \(logParameters)")
        
        // In a production app, this would batch events and send them periodically
        // sendEventToAnalyticsServer(event, parameters: logParameters)
    }
    
    /// Track a screen view event
    /// - Parameter screenName: The name of the screen being viewed
    func trackScreenView(_ screenName: String) {
        trackEvent(.screenView, parameters: ["screen_name": screenName])
    }
    
    /// Track when a metric is selected/viewed
    /// - Parameter metricType: The type of health metric selected
    func trackMetricSelected(_ metricType: String) {
        trackEvent(.metricSelected, parameters: ["metric_type": metricType])
    }
    
    /// Track when the time range for impact calculations changes
    /// - Parameter period: The selected time period
    func trackTimeRangeChanged(_ period: String) {
        trackEvent(.timeRangeChanged, parameters: ["period": period])
    }
    
    /// Track completion of an onboarding step
    /// - Parameter step: The onboarding step completed
    func trackOnboardingStep(_ step: String) {
        trackEvent(.onboardingStep, parameters: ["step": step])
    }
    
    /// Track an error event
    /// - Parameters:
    ///   - code: Error code or identifier
    ///   - message: Brief description of the error (no personal data)
    func trackError(code: String, message: String) {
        trackEvent(.error, parameters: [
            "error_code": code,
            "error_message": message
        ])
    }
    
    // MARK: - Private Methods
    
    /// In a real app, this would send the event data to an analytics server
    private func sendEventToAnalyticsServer(_ event: EventType, parameters: [String: Any]) {
        // Implementation for a real analytics service would go here
        // This would batch events and send them periodically to reduce network usage
    }
} 