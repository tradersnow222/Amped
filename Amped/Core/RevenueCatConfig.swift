import Foundation
import RevenueCat

/// Configuration for RevenueCat integration
struct RevenueCatConfig {
    /// RevenueCat API Key
    static let apiKey = "appl_XqcEEfuVlfVmcwuqTuCooOnQAMh"
    
    /// Product IDs
    enum ProductID {
        static let weekly = "ai.ampedlife.amped.weekly"
        static let monthly = "ai.ampedlife.amped.monthly"
    }
    
    /// Entitlement IDs
    enum EntitlementID {
        static let premiumAccess = "premium_access"
    }
    
    /// Configure RevenueCat on app launch
    static func configure() {
        Purchases.logLevel = .debug // Remove in production
        Purchases.configure(withAPIKey: apiKey)
    }
}
