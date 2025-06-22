import Foundation
import StoreKit
import OSLog

/// Protocol defining StoreKit functionality for subscriptions
@MainActor
protocol StoreKitManaging: ObservableObject {
    /// Available subscription products
    var products: [Product] { get }
    
    /// Current subscription status
    var subscriptionStatus: StoreKitManager.SubscriptionStatus { get }
    
    /// Whether products are currently being loaded
    var isLoadingProducts: Bool { get }
    
    /// Whether a purchase is in progress
    var isPurchasing: Bool { get }
    
    /// Load available subscription products
    func loadProducts() async
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async -> StoreKitManager.PurchaseResult
    
    /// Restore previous purchases
    func restorePurchases() async -> StoreKitManager.RestoreResult
}

/// Manager for StoreKit operations following Apple best practices
@MainActor
final class StoreKitManager: StoreKitManaging, ObservableObject {
    
    // MARK: - Types
    
    enum SubscriptionStatus: Equatable {
        case unknown
        case notSubscribed
        case subscribed(product: Product, expirationDate: Date?)
    }
    
    enum PurchaseResult {
        case success(Product)
        case cancelled
        case failed(Error)
        case pending
    }
    
    enum RestoreResult {
        case success([Product])
        case failed(Error)
        case noValidTransactions
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var isPurchasing: Bool = false
    
    // MARK: - Private Properties
    
    private let productIdentifiers: Set<String> = [
        "amped_monthly_subscription",
        "amped_annual_subscription"
    ]
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "StoreKitManager")
    private var updateListenerTask: Task<Void, Error>?
    
    // Retry configuration following Apple's guidelines
    private let maxRetryAttempts = 3
    private var retryAttempts = 0
    
    // MARK: - Initialization
    
    /// Initialize StoreKit manager - nonisolated to allow singleton creation
    nonisolated init() {
        // Schedule main actor work asynchronously
        Task { @MainActor in
            await self.initializeAsync()
        }
    }
    
    /// Async initialization on main actor
    private func initializeAsync() async {
        logger.info("Initializing StoreKitManager")
        startTransactionListener()
        await loadProducts()
        await updateSubscriptionStatus()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load subscription products with retry logic
    func loadProducts() async {
        guard !isLoadingProducts else {
            logger.info("Product loading already in progress")
            return
        }
        
        isLoadingProducts = true
        retryAttempts = 0
        
        await loadProductsWithRetry()
        
        isLoadingProducts = false
    }
    
    /// Purchase a subscription product
    func purchase(_ product: Product) async -> PurchaseResult {
        guard !isPurchasing else {
            logger.warning("Purchase already in progress")
            return .failed(StoreKitError.purchaseInProgress)
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        logger.info("Starting purchase for product: \(product.id)")
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                logger.info("Purchase successful for product: \(product.id)")
                await handleVerificationResult(verification)
                return .success(product)
                
            case .userCancelled:
                logger.info("Purchase cancelled by user")
                return .cancelled
                
            case .pending:
                logger.info("Purchase pending approval")
                return .pending
                
            @unknown default:
                logger.error("Unknown purchase result")
                return .failed(StoreKitError.unknownResult)
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async -> RestoreResult {
        logger.info("Starting restore purchases")
        
        do {
            try await AppStore.sync()
            
            var restoredProducts: [Product] = []
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        restoredProducts.append(product)
                        logger.info("Restored product: \(product.id)")
                    }
                } catch {
                    logger.error("Failed to verify transaction during restore: \(error.localizedDescription)")
                }
            }
            
            await updateSubscriptionStatus()
            
            if restoredProducts.isEmpty {
                logger.info("No valid transactions found to restore")
                return .noValidTransactions
            } else {
                logger.info("Successfully restored \(restoredProducts.count) products")
                return .success(restoredProducts)
            }
        } catch {
            logger.error("Restore purchases failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Load products with retry logic and explicit self references (Swift 6 compliance)
    private func loadProductsWithRetry() async {
        do {
            logger.info("Loading products (attempt \(self.retryAttempts + 1)/\(self.maxRetryAttempts))")
            
            let loadedProducts = try await Product.products(for: productIdentifiers)
            
            if loadedProducts.isEmpty {
                throw StoreKitError.noProductsAvailable
            }
            
            // Sort products by price (ascending)
            self.products = loadedProducts.sorted { $0.price < $1.price }
            self.retryAttempts = 0 // Reset on success
            
            logger.info("Successfully loaded \(self.products.count) products")
            
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            
            self.retryAttempts += 1
            
            if self.retryAttempts < self.maxRetryAttempts {
                // Exponential backoff with explicit self references
                let delay = TimeInterval(pow(2.0, Double(self.retryAttempts)))
                logger.info("Retrying product load after error (attempt \(self.retryAttempts)/\(self.maxRetryAttempts))")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await loadProductsWithRetry()
            } else {
                logger.error("Max retry attempts reached for product loading")
                // Provide fallback products with estimated pricing
                self.products = createFallbackProducts()
            }
        }
    }
    
    /// Create fallback products when StoreKit fails
    private func createFallbackProducts() -> [Product] {
        logger.warning("Creating fallback products due to StoreKit failure")
        // Return empty array - let UI handle gracefully
        return []
    }
    
    /// Start listening for transaction updates
    private func startTransactionListener() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    await self?.handleTransaction(transaction)
                } catch {
                    self?.logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Handle verified transaction
    private func handleTransaction(_ transaction: Transaction?) async {
        guard let transaction = transaction else { return }
        
        logger.info("Processing transaction: \(transaction.productID)")
        
        // Update subscription status
        await updateSubscriptionStatus()
        
        // Finish the transaction
        await transaction.finish()
    }
    
    /// Handle verification result from purchase
    private func handleVerificationResult(_ verification: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(verification)
            await handleTransaction(transaction)
        } catch {
            logger.error("Failed to verify purchase transaction: \(error.localizedDescription)")
        }
    }
    
    /// Update current subscription status
    private func updateSubscriptionStatus() async {
        logger.info("Updating subscription status")
        
        var currentSubscription: (product: Product, expirationDate: Date?)?
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    let expirationDate = transaction.expirationDate
                    currentSubscription = (product: product, expirationDate: expirationDate)
                    logger.info("Found active subscription: \(product.id)")
                    break
                }
            } catch {
                logger.error("Failed to verify entitlement: \(error.localizedDescription)")
            }
        }
        
        if let subscription = currentSubscription {
            subscriptionStatus = .subscribed(
                product: subscription.product,
                expirationDate: subscription.expirationDate
            )
        } else {
            subscriptionStatus = .notSubscribed
            logger.info("No active subscription found")
        }
    }
    
    /// Verify transaction integrity
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.transactionNotVerified
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Custom Errors

enum StoreKitError: LocalizedError {
    case purchaseInProgress
    case noProductsAvailable
    case transactionNotVerified
    case unknownResult
    
    var errorDescription: String? {
        switch self {
        case .purchaseInProgress:
            return "A purchase is already in progress"
        case .noProductsAvailable:
            return "No subscription products are available"
        case .transactionNotVerified:
            return "Transaction could not be verified"
        case .unknownResult:
            return "An unknown error occurred during purchase"
        }
    }
}

// MARK: - StoreKit Product Extensions

extension Product {
    /// Get formatted price string
    var formattedPrice: String {
        return displayPrice
    }
    
    /// Get subscription period description
    var periodDescription: String {
        guard let subscription = subscription else { return "" }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            return "period"
        }
    }
    
    /// Check if this is the annual subscription
    var isAnnual: Bool {
        return id == "amped_annual_subscription"
    }
    
    /// Check if this is the monthly subscription
    var isMonthly: Bool {
        return id == "amped_monthly_subscription"
    }
} 