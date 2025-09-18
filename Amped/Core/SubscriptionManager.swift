import Foundation
import RevenueCat
import OSLog

/// Manager for handling subscription-related operations with RevenueCat
@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var hasActiveSubscription = false
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.amped.subscription", category: "SubscriptionManager")
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupRevenueCat()
        checkSubscriptionStatus()
    }
    
    // MARK: - Setup
    private func setupRevenueCat() {
        RevenueCatConfig.configure()
        
        // Set up delegate to listen for subscription changes
        Purchases.shared.delegate = self
        
        logger.info("RevenueCat configured successfully")
    }
    
    // MARK: - Subscription Status
    
    /// Check current subscription status
    func checkSubscriptionStatus() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                await updateSubscriptionStatus(from: customerInfo)
            } catch {
                logger.error("Failed to check subscription status: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to check subscription status"
                }
            }
        }
    }
    
    /// Update subscription status from customer info
    private func updateSubscriptionStatus(from customerInfo: CustomerInfo) async {
        await MainActor.run {
            self.hasActiveSubscription = customerInfo.entitlements[RevenueCatConfig.EntitlementID.premiumAccess]?.isActive == true
            self.logger.info("Subscription status updated: \(self.hasActiveSubscription)")
        }
    }
    
    // MARK: - Offerings
    
    /// Load current offerings from RevenueCat
    func loadOfferings() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.currentOffering = offerings.current
                self.isLoading = false
                
                if offerings.current == nil {
                    self.logger.warning("No current offering found. Check StoreKit configuration or App Store Connect setup.")
                    self.errorMessage = "Subscription options not available. Please check your StoreKit configuration."
                } else {
                    self.logger.info("Offerings loaded successfully")
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load subscription options"
                self.isLoading = false
                self.logger.error("Failed to load offerings: \(error.localizedDescription)")
                
                // Log specific RevenueCat error for debugging
                if let rcError = error as? ErrorCode {
                    self.logger.error("RevenueCat error: \(rcError.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a subscription package
    func purchase(package: Package) async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let customerInfo = result.customerInfo
            
            await updateSubscriptionStatus(from: customerInfo)
            await MainActor.run {
                self.isLoading = false
            }
            
            logger.info("Purchase completed successfully")
            return true
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                
                // Handle specific RevenueCat errors
                if let rcError = error as? ErrorCode {
                    switch rcError {
                    case .purchaseCancelledError:
                        self.errorMessage = nil // User cancelled, don't show error
                    case .paymentPendingError:
                        self.errorMessage = "Payment is pending approval"
                    case .networkError:
                        self.errorMessage = "Network error. Please try again."
                    default:
                        self.errorMessage = "Purchase failed. Please try again."
                    }
                } else {
                    self.errorMessage = "Purchase failed. Please try again."
                }
                
                self.logger.error("Purchase failed: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(from: customerInfo)
            
            await MainActor.run {
                self.isLoading = false
                if !self.hasActiveSubscription {
                    self.errorMessage = "No previous purchases found"
                }
            }
            
            logger.info("Purchases restored successfully")
            return hasActiveSubscription
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to restore purchases"
                self.logger.error("Failed to restore purchases: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the weekly subscription package from current offering
    var weeklyPackage: Package? {
        return currentOffering?.availablePackages.first { package in
            package.storeProduct.productIdentifier == RevenueCatConfig.ProductID.weekly
        }
    }
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await updateSubscriptionStatus(from: customerInfo)
        }
    }
}
