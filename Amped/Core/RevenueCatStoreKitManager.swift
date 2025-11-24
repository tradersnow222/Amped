//
//  RevenueCatStoreKitManager.swift
//  Amped
//
//  Created by Sheraz Hussain on 24/11/2025.
//

import Foundation
import RevenueCat
import OSLog

// MARK: - Product Wrapper

/// Wrapper so your UI doesn't break (acts like StoreKit `Product`)
struct RevenueCatProduct: Identifiable, Equatable {
    let id: String
    let displayName: String
    let displayPrice: String
    let description: String
    let package: Package

    var isMonthly: Bool {
        id.lowercased().contains("month")
    }

    var isAnnual: Bool {
        id.lowercased().contains("year") || id.lowercased().contains("annual")
    }
}

// MARK: - Protocol (same shape as before)

@MainActor
protocol RevenueCatManaging: ObservableObject {
    var products: [RevenueCatProduct] { get }
    var subscriptionStatus: RevenueCatStoreKitManager.SubscriptionStatus { get }
    var isLoadingProducts: Bool { get }
    var isPurchasing: Bool { get }
    var isRestoring: Bool { get }

    func loadProducts() async
    func purchase(_ product: RevenueCatProduct) async -> RevenueCatStoreKitManager.PurchaseResult
    func restorePurchases() async -> RevenueCatStoreKitManager.RestoreResult
}

// MARK: - RevenueCat replacement for StoreKitManager

@MainActor
final class RevenueCatStoreKitManager: NSObject, RevenueCatManaging {
    
    // MARK: - Shared Instance
//    static let shared = RevenueCatStoreKitManager()

    // MARK: - Types

    enum SubscriptionStatus: Equatable {
        case unknown
        case notSubscribed
        case subscribed(expirationDate: Date?)
    }

    enum PurchaseResult {
        case success
        case cancelled
        case failed(Error)
        case pending
    }

    enum RestoreResult {
        case success
        case failed(Error)
        case noValidTransactions
    }

    // MARK: - Published State

    @Published private(set) var products: [RevenueCatProduct] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isRestoring: Bool = false

    // MARK: - Private

    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "RevenueCatManager")

    // MARK: - Init

    override init() {
        super.init()

        RevenueCatConfig.configure()
        Purchases.shared.delegate = self

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    // MARK: - Load Products (Offerings)

    func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        logger.info("Loading offerings from RevenueCat...")

        do {
            let offerings = try await Purchases.shared.offerings()

            guard let currentOffering = offerings.current else {
                logger.error("No current offering found in RevenueCat")
                products = []
                isLoadingProducts = false
                return
            }

            let mappedProducts = currentOffering.availablePackages.map { package in
                RevenueCatProduct(
                    id: package.storeProduct.productIdentifier,
                    displayName: package.storeProduct.localizedTitle,
                    displayPrice: package.storeProduct.localizedPriceString,
                    description: package.storeProduct.localizedDescription,
                    package: package
                )
            }

            products = mappedProducts
            logger.info("Loaded \(mappedProducts.count) RevenueCat products")

        } catch {
            logger.error("Failed to load offerings: \(error.localizedDescription)")
            products = []
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase(_ product: RevenueCatProduct) async -> PurchaseResult {
        guard !isPurchasing else {
            logger.warning("Purchase already in progress")
            return .failed(NSError(domain: "Purchase", code: 0))
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: product.package)

            if result.userCancelled {
                logger.info("Purchase cancelled")
                return .cancelled
            }

            await updateSubscriptionStatus()
            logger.info("Purchase successful: \(product.id)")
            return .success

        } catch {
            if let rcError = error as? ErrorCode {
                if rcError == .purchaseCancelledError {
                    return .cancelled
                }
                if rcError == .paymentPendingError {
                    return .pending
                }
            }

            logger.error("Purchase failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async -> RestoreResult {
        guard !isRestoring else {
            logger.warning("Restore already in progress")
            return .failed(NSError(domain: "Restore", code: 0))
        }

        isRestoring = true
        defer { isRestoring = false }

        do {
            let info = try await Purchases.shared.restorePurchases()

            let hasActive = info.entitlements.all
                .values
                .contains(where: { $0.isActive })

            await updateSubscriptionStatus()

            if hasActive {
                logger.info("Restore successful")
                return .success
            } else {
                logger.info("No valid transactions found")
                return .noValidTransactions
            }

        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            return .failed(error)
        }
    }

    // MARK: - Subscription Status

    private func updateSubscriptionStatus2() async {
        do {
            let info = try await Purchases.shared.customerInfo()

            if let entitlement = info.entitlements.all.values.first(where: { $0.isActive }) {
                subscriptionStatus = .subscribed(expirationDate: entitlement.expirationDate)
                logger.info("User is subscribed, expires: \(String(describing: entitlement.expirationDate))")
            } else {
                subscriptionStatus = .notSubscribed
            }

        } catch {
            logger.error("Failed to update subscription status")
            subscriptionStatus = .unknown
        }
    }
    
    private func updateSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()

            // Always target your exact entitlement ID
            guard let entitlement = info.entitlements[RevenueCatConfig.EntitlementID.premiumAccess] else {
                logger.info("No premium_access entitlement found")
                subscriptionStatus = .notSubscribed
                return
            }

            logger.info("""
            Entitlement State:
            active: \(entitlement.isActive)
            willRenew: \(entitlement.willRenew)
            expires: \(String(describing: entitlement.expirationDate))
            sandbox: \(entitlement.isSandbox)
            """)

            let now = Date()

            // Case 1: Normal active subscription
            if entitlement.isActive {
                subscriptionStatus = .subscribed(expirationDate: entitlement.expirationDate)
                logger.info("User is actively subscribed")
                return
            }

            // Case 2: Sandbox or Apple delay (still valid for a few moments)
            if let expiry = entitlement.expirationDate,
               entitlement.willRenew,
               expiry > now {
                
                logger.info("Treating subscription as active (sandbox / delayed activation)")
                subscriptionStatus = .subscribed(expirationDate: expiry)
                return
            }

            // Case 3: Truly expired / cancelled
            subscriptionStatus = .notSubscribed
            logger.info("User not subscribed or subscription expired")

        } catch {
            logger.error("Failed to update subscription status: \(error.localizedDescription)")
            subscriptionStatus = .unknown
        }
    }

}

// MARK: - RevenueCat Delegate

extension RevenueCatStoreKitManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
            await updateSubscriptionStatus()
        }
    }
}
