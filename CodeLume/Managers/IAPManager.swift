import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var creditPackages: [CreditPackageTable] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var lastErrorMessage: String?
    /// Product IDs present in the database but not returned by `Product.products(for:)` (common after App Store release if IDs mismatch or IAP isn’t cleared for sale).
    @Published var storeProductIdsMissingFromStoreKit: [String] = []

    private let supabase = SupabaseManager.shared
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadCreditProducts() async {
        isLoading = true
        defer { isLoading = false }
        storeProductIdsMissingFromStoreKit = []
        lastErrorMessage = nil

        do {
            let packages = try await supabase.getCreditPackages()
            creditPackages = packages

            let productIds = packages.map(\.productId)
            if productIds.isEmpty {
                products = []
                return
            }

            do {
                let loadedProducts = try await Product.products(for: productIds)
                products = loadedProducts.sorted { lhs, rhs in
                    lhs.price < rhs.price
                }
                let loadedIds = Set(loadedProducts.map(\.id))
                let missing = productIds.filter { !loadedIds.contains($0) }
                storeProductIdsMissingFromStoreKit = Array(Set(missing)).sorted()
                if !storeProductIdsMissingFromStoreKit.isEmpty {
                    let ids = storeProductIdsMissingFromStoreKit.joined(separator: ", ")
                    lastErrorMessage = String(localized: "App Store did not return these product IDs: \(ids). In App Store Connect, check that product identifiers match your database exactly, Paid Apps Agreement is active, and products are cleared for sale.")
                }
            } catch {
                lastErrorMessage = error.localizedDescription
                products = []
                storeProductIdsMissingFromStoreKit = Array(Set(productIds)).sorted()
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            products = []
            creditPackages = []
            storeProductIdsMissingFromStoreKit = []
        }
    }

    func purchase(product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            var options: Set<Product.PurchaseOption> = []
            if let userId = supabase.currentUser?.id {
                options.insert(.appAccountToken(userId))
            }
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verificationResult):
                let jwsRepresentation = verificationResult.jwsRepresentation
                let transaction = try checkVerified(verificationResult)
                let response = try await supabase.verifyIAPPurchase(signedTransactionInfo: jwsRepresentation)
                supabase.creditsBalance = response.balance
                supabase.isCreditsLoading = false
                await transaction.finish()
                lastErrorMessage = nil
                return true
            case .pending:
                lastErrorMessage = "Purchase is pending approval."
                return false
            case .userCancelled:
                return false
            @unknown default:
                lastErrorMessage = "Unknown purchase result."
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { @MainActor in
            for await verificationResult in Transaction.updates {
                do {
                    let jwsRepresentation = verificationResult.jwsRepresentation
                    let transaction = try checkVerified(verificationResult)
                    let response = try await supabase.verifyIAPPurchase(signedTransactionInfo: jwsRepresentation)
                    supabase.creditsBalance = response.balance
                    supabase.isCreditsLoading = false
                    await transaction.finish()
                } catch {
                    lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func checkVerified<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .unverified:
            throw NSError(domain: "IAP", code: 401, userInfo: [NSLocalizedDescriptionKey: "Purchase verification failed"])
        case .verified(let signedType):
            return signedType
        }
    }
}
