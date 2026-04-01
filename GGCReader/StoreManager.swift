import StoreKit
import SwiftUI

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    // MARK: - Product IDs

    static let monthlyID  = "com.jason.ggcreader.pro.monthly"
    static let yearlyID   = "com.jason.ggcreader.pro.yearly"
    static let lifetimeID = "com.jason.ggcreader.pro.lifetime"

    private static let allProductIDs: Set<String> = [
        monthlyID, yearlyID, lifetimeID
    ]

    // MARK: - State

    var products: [Product] = []
    /// Cached for instant startup; always overwritten by entitlement check.
    var isPro: Bool = UserDefaults.standard.bool(forKey: "leaflet_isPro") {
        didSet { UserDefaults.standard.set(isPro, forKey: "leaflet_isPro") }
    }
    var isLoadingProducts = false
    var loadProductsError: String?
    var purchasedProductIDs: Set<String> = []

    private var transactionListener: Task<Void, Never>?

    // MARK: - Free Tier Limits

    static let freeBookLimit = 5

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    nonisolated deinit {
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoadingProducts = true
        loadProductsError = nil
        do {
            products = try await Product.products(for: Self.allProductIDs)
                .sorted { $0.price < $1.price }
        } catch {
            loadProductsError = error.localizedDescription
        }
        isLoadingProducts = false
    }

    // MARK: - Purchase

    enum PurchaseResult {
        case success, cancelled, pending
    }

    func purchase(_ product: Product) async throws -> PurchaseResult {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    // MARK: - Update Status

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
        isPro = !purchased.isEmpty
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    // MARK: - Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeID }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
