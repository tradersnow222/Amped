import SwiftUI
import StoreKit
import OSLog

/// ViewModel for payment screen - NEW subscriptions only (following Apple best practices)
@MainActor
final class PaymentViewModel: ObservableObject {
    // MARK: - Types
    
    enum SubscriptionPlan {
        case monthly
        case annual
        
        var productIdentifier: String {
            switch self {
            case .monthly: return "amped_monthly_subscription"
            case .annual: return "amped_annual_subscription"
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published var selectedPlan: SubscriptionPlan = .annual
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isProcessing: Bool = false
    
    // MARK: - Private Properties
    
    private let storeKitManager: StoreKitManager
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "PaymentViewModel")
    
    // Reference to app state for completing onboarding
    var appState: AppState?
    
    // MARK: - Computed Properties
    
    /// Whether products are loaded and available
    var areProductsLoaded: Bool {
        !storeKitManager.products.isEmpty
    }
    
    /// Monthly subscription product (convenience accessor)
    var monthlyProduct: Product? {
        storeKitManager.products.first { $0.id == SubscriptionPlan.monthly.productIdentifier }
    }
    
    /// Annual subscription product (convenience accessor)
    var annualProduct: Product? {
        storeKitManager.products.first { $0.id == SubscriptionPlan.annual.productIdentifier }
    }
    
    /// Get the currently selected product
    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly:
            return monthlyProduct
        case .annual:
            return annualProduct
        }
    }
    
    /// Whether user has an active subscription
    var hasActiveSubscription: Bool {
        switch storeKitManager.subscriptionStatus {
        case .subscribed:
            return true
        case .notSubscribed, .unknown:
            return false
        }
    }
    
    /// Available products from StoreKit
    var products: [Product] {
        storeKitManager.products
    }
    
    // MARK: - Initialization
    
    init() {
        self.storeKitManager = StoreKitManager()
        loadProducts()
    }
    
    // MARK: - Public Methods
    
    /// Load subscription products
    func loadProducts() {
        Task {
            await storeKitManager.loadProducts()
        }
    }
    
    /// Process the purchase for the selected plan
    func processPurchase(completion: @escaping () -> Void) {
        guard let product = selectedProduct else {
            showError(message: "Please select a subscription plan")
            return
        }
        
        guard !hasActiveSubscription else {
            // User already has a subscription, just complete onboarding
            logger.info("User already has active subscription, completing onboarding")
            appState?.completeOnboarding()
            completion()
            return
        }
        
        isProcessing = true
        
        Task {
            let result = await storeKitManager.purchase(product)
            
            await MainActor.run {
                self.isProcessing = false
                
                switch result {
                case .success(_):
                    logger.info("Purchase successful")
                    // Complete onboarding and continue
                    appState?.completeOnboarding()
                    completion()
                    
                case .cancelled:
                    logger.info("Purchase cancelled by user")
                    // Don't show error for user cancellation
                    
                case .failed(let error):
                    logger.error("Purchase failed: \(error.localizedDescription)")
                    showError(message: getErrorMessage(for: error))
                    
                case .pending:
                    logger.info("Purchase pending")
                    showError(message: "Your purchase is pending approval. You'll receive access once it's processed.")
                }
            }
        }
    }
    
    /// Skip payment and continue with free version
    func skipPayment(completion: @escaping () -> Void) {
        logger.info("User skipped payment")
        // Don't complete onboarding for free users - they can upgrade later
        completion()
    }
    
    // MARK: - Private Methods
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func getErrorMessage(for error: Error) -> String {
        // Handle different types of errors appropriately
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .purchaseInProgress:
                return "A purchase is already in progress. Please wait a moment."
            case .noProductsAvailable:
                return "Subscription options are temporarily unavailable. Please try again later."
            case .transactionNotVerified:
                return "Unable to verify your purchase. Please contact support."
            case .unknownResult:
                return "An unexpected error occurred. Please try again."
            }
        }
        
        // Handle system StoreKit errors
        if let skError = error as? StoreKit.StoreKitError {
            switch skError {
            case .notAvailableInStorefront:
                return "Subscriptions are not available in your region."
            case .notEntitled:
                return "You don't have permission to make this purchase."
            default:
                return "Purchase failed. Please try again."
            }
        }
        
        // Generic error message
        return "Something went wrong. Please try again later."
    }
    
    /// Get display price for a subscription plan
    func getDisplayPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly:
            return monthlyProduct?.formattedPrice ?? "$9.99"
        case .annual:
            return annualProduct?.formattedPrice ?? "$39.99"
        }
    }
    
    /// Get period description for a subscription plan
    func getPeriodDescription(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly:
            return monthlyProduct?.periodDescription ?? "month"
        case .annual:
            return annualProduct?.periodDescription ?? "year"
        }
    }
} 