import Foundation
import StoreKit
import SwiftUI
import OSLog

/// Service for managing subscription state throughout the app
@MainActor
final class SubscriptionService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance - nonisolated since it's just a reference to the singleton
    nonisolated static let shared = SubscriptionService()
    
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var subscriptionProduct: Product?
    @Published private(set) var expirationDate: Date?
    
    private let storeKitManager: StoreKitManager
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "SubscriptionService")
    
    // MARK: - Initialization
    
    /// Nonisolated private init to allow singleton creation
    nonisolated private init() {
        // Create StoreKitManager - both are nonisolated now for Swift 6 compliance
        self.storeKitManager = StoreKitManager()
        
        // Schedule main actor work asynchronously after initialization
        Task { @MainActor in
            await self.initializeAsync()
        }
    }
    
    /// Async initialization on main actor after singleton creation
    private func initializeAsync() async {
        logger.info("Initializing SubscriptionService")
        observeSubscriptionChanges()
        await checkSubscriptionStatus()
    }
    
    // MARK: - Public Methods
    
    /// Check current subscription status
    func checkSubscriptionStatus() async {
        logger.info("Checking subscription status")
        
        switch storeKitManager.subscriptionStatus {
        case .subscribed(let product, let expirationDate):
            isSubscribed = true
            subscriptionProduct = product
            self.expirationDate = expirationDate
            logger.info("User has active subscription: \(product.id)")
            
        case .notSubscribed:
            isSubscribed = false
            subscriptionProduct = nil
            expirationDate = nil
            logger.info("User has no active subscription")
            
        case .unknown:
            // Keep current state until we know for sure
            logger.info("Subscription status unknown, keeping current state")
        }
    }
    
    /// Purchase a subscription
    func purchaseProduct(_ product: Product) async -> StoreKitManager.PurchaseResult {
        logger.info("Attempting to purchase: \(product.id)")
        
        let result = await storeKitManager.purchase(product)
        
        // Update subscription status after purchase attempt
        await checkSubscriptionStatus()
        
        return result
    }
    
    /// Restore previous purchases
    func restorePurchases() async -> StoreKitManager.RestoreResult {
        logger.info("Attempting to restore purchases")
        
        let result = await storeKitManager.restorePurchases()
        
        // Update subscription status after restore attempt
        await checkSubscriptionStatus()
        
        return result
    }
    
    /// Get subscription status for UI display
    var subscriptionStatusDescription: String {
        if isSubscribed {
            if let product = subscriptionProduct {
                if let expiration = expirationDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    return "Active (\(product.displayName)) - Expires \(formatter.string(from: expiration))"
                } else {
                    return "Active (\(product.displayName))"
                }
            } else {
                return "Active"
            }
        } else {
            return "Not Subscribed"
        }
    }
    
    /// Check if user has access to premium features
    var hasPremiumAccess: Bool {
        return isSubscribed
    }
    
    /// Get the StoreKit manager for purchase operations
    var paymentManager: StoreKitManager {
        return storeKitManager
    }
    
    // MARK: - Private Methods
    
    /// Observe changes to subscription status from StoreKitManager
    private func observeSubscriptionChanges() {
        logger.info("Starting to observe subscription changes")
        
        // Use Task to continuously monitor status changes
        Task {
            while !Task.isCancelled {
                await checkSubscriptionStatus()
                
                // Check every 30 seconds
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether user has an active subscription
    var hasActiveSubscription: Bool {
        switch storeKitManager.subscriptionStatus {
        case .subscribed:
            return true
        case .notSubscribed, .unknown:
            return false
        }
    }
    
    /// Days remaining in subscription (if applicable)
    var daysRemaining: Int? {
        guard let expirationDate = expirationDate,
              expirationDate > Date() else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
    
    /// Formatted subscription status text
    var subscriptionStatusText: String {
        if hasActiveSubscription {
            if let product = subscriptionProduct {
                if let days = daysRemaining {
                    return "Active subscription to \(product.displayName) - \(days) days remaining"
                } else {
                    return "Active subscription to \(product.displayName)"
                }
            } else {
                return "Active subscription"
            }
        } else {
            return "No active subscription"
        }
    }
}

// MARK: - Environment Key

struct SubscriptionServiceKey: EnvironmentKey {
    nonisolated static let defaultValue = SubscriptionService.shared
}

extension EnvironmentValues {
    var subscriptionService: SubscriptionService {
        get { self[SubscriptionServiceKey.self] }
        set { self[SubscriptionServiceKey.self] = newValue }
    }
} 