import Foundation
import OSLog

/// Analytics event types
enum AnalyticsEvent {
    case appLaunch
    case appBackground
    case onboardingStep(String)
    case dashboardViewed
    case metricViewed(String)
    case settingsChanged(String, Any)
    case paymentInitiated
    case paymentCompleted
    case paymentFailed(String)
    case errorOccurred(String)
    case signIn(method: String) // Rules: Added new sign-in event
    case featureUsed // Rules: Added missing featureUsed event
    
    /// Event name for logging
    var name: String {
        switch self {
        case .appLaunch: return "app_launch"
        case .appBackground: return "app_background"
        case .onboardingStep: return "onboarding_step"
        case .dashboardViewed: return "dashboard_viewed"
        case .metricViewed: return "metric_viewed"
        case .settingsChanged: return "settings_changed"
        case .paymentInitiated: return "payment_initiated"
        case .paymentCompleted: return "payment_completed"
        case .paymentFailed: return "payment_failed"
        case .errorOccurred: return "error_occurred"
        case .signIn: return "sign_in" // Rules: Track sign-in events
        case .featureUsed: return "feature_used" // Rules: Track feature usage
        }
    }
    
    /// Event parameters
    var parameters: [String: Any] {
        switch self {
        case .onboardingStep(let step):
            return ["step": step]
        case .metricViewed(let metric):
            return ["metric": metric]
        case .settingsChanged(let key, let value):
            return ["key": key, "value": String(describing: value)]
        case .paymentFailed(let reason):
            return ["reason": reason]
        case .errorOccurred(let error):
            return ["error": error]
        case .signIn(let method): // Rules: Include sign-in method
            return ["method": method]
        default:
            return [:]
        }
    }
}

/// Privacy-focused analytics service for tracking app usage
final class AnalyticsService {
    // MARK: - Properties
    
    static let shared = AnalyticsService()
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "Analytics")
    
    /// Whether analytics collection is enabled
    private var isEnabled: Bool {
        // Only enable analytics if user has explicitly opted in
        UserDefaults.standard.bool(forKey: "analytics_enabled")
    }
    
    /// Anonymous user ID for session tracking
    private lazy var anonymousUserId: String = {
        if let storedId = UserDefaults.standard.string(forKey: "anonymous_user_id") {
            return storedId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "anonymous_user_id")
            return newId
        }
    }()
    
    // MARK: - Initialization
    
    private init() {
        logger.info("📊 Analytics service initialized")
    }
    
    // MARK: - Public Methods
    
    /// Track an analytics event
    /// - Parameter event: The event to track
    func trackEvent(_ event: AnalyticsEvent) {
        guard isEnabled else {
            logger.debug("📊 Analytics disabled - not tracking event: \(event.name)")
            return
        }
        
        // Log to console for development
        logger.info("📊 Event: \(event.name), params: \(String(describing: event.parameters))")
        
        // In a production app, this would send to an analytics backend
        // For MVP, we just log locally
        
        // Future: Send to analytics backend
        // sendToBackend(event: event)
    }
    
    /// Track an analytics event with custom parameters - Rules: Support parameters
    /// - Parameters:
    ///   - event: The event to track
    ///   - parameters: Additional custom parameters
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]) {
        guard isEnabled else {
            logger.debug("📊 Analytics disabled - not tracking event: \(event.name)")
            return
        }
        
        // Merge event's default parameters with custom parameters
        var allParams = event.parameters
        parameters.forEach { allParams[$0.key] = $0.value }
        
        // Log to console for development
        logger.info("📊 Event: \(event.name), params: \(String(describing: allParams))")
        
        // In a production app, this would send to an analytics backend
        // For MVP, we just log locally
    }
    
    /// Track a custom event
    /// - Parameters:
    ///   - name: Event name
    ///   - parameters: Event parameters
    func trackCustomEvent(name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else {
            logger.debug("📊 Analytics disabled - not tracking custom event: \(name)")
            return
        }
        
        logger.info("📊 Custom event: \(name), params: \(String(describing: parameters))")
        
        // Future: Send to analytics backend
    }
    
    /// Track onboarding step
    /// - Parameter step: The onboarding step name
    func trackOnboardingStep(_ step: String) {
        trackEvent(.onboardingStep(step))
    }
    
    /// Track screen view
    /// - Parameter screenName: Name of the screen
    func trackScreenView(_ screenName: String) {
        trackCustomEvent(name: "screen_view", parameters: ["screen_name": screenName])
    }
    
    /// Track when a metric is selected for details - Rules: Added missing method
    /// - Parameter metricName: Name of the selected metric
    func trackMetricSelected(_ metricName: String) {
        trackEvent(.metricViewed(metricName))
    }
    
    /// Track user property
    /// - Parameters:
    ///   - name: Property name
    ///   - value: Property value
    func setUserProperty(name: String, value: String) {
        guard isEnabled else { return }
        
        logger.info("📊 User property: \(name) = \(value)")
        
        // Future: Send to analytics backend
    }
    
    /// Enable or disable analytics collection
    /// - Parameter enabled: Whether to enable analytics
    func setAnalyticsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        logger.info("📊 Analytics \(enabled ? "enabled" : "disabled")")
        
        if enabled {
            // Track opt-in event
            trackCustomEvent(name: "analytics_opted_in")
        }
    }
    
    /// Reset anonymous user ID (e.g., on sign out)
    func resetAnonymousUserId() {
        UserDefaults.standard.removeObject(forKey: "anonymous_user_id")
        _ = anonymousUserId // This will generate a new ID
        logger.info("📊 Anonymous user ID reset")
    }
    
    // MARK: - Private Methods
    
    /// Send event to analytics backend (future implementation)
    /// - Parameter event: Event to send
    private func sendToBackend(event: AnalyticsEvent) {
        // Future implementation:
        // 1. Batch events for efficient network usage
        // 2. Send to privacy-focused analytics service
        // 3. Handle offline storage and retry
        // 4. Ensure all data is anonymized
    }
} 