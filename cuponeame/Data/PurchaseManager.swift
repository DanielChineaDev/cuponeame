import Foundation
import StoreKit
import Observation

/// Compra única "Cuponéame Premium" con StoreKit 2: quita los anuncios y
/// desbloquea las creaciones ilimitadas. Producto no consumible; el estado se
/// persiste y se restaura desde los entitlements al arrancar (política Apple).
@MainActor
@Observable
final class PurchaseManager {
    private let monetization: MonetizationStore

    private(set) var product: Product?
    private(set) var isWorking = false
    var priceLabel: String? { product?.displayPrice }
    var available: Bool { product != nil }

    private var updatesTask: Task<Void, Never>?

    init(monetization: MonetizationStore) {
        self.monetization = monetization
        updatesTask = Task { await listenForTransactions() }
    }

    func load() async {
        guard product == nil else { return }
        product = try? await Product.products(for: [AppConfig.premiumProductId]).first
    }

    /// Restauración silenciosa al arrancar.
    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == AppConfig.premiumProductId,
               transaction.revocationDate == nil {
                monetization.setPremium(true)
            }
        }
    }

    @discardableResult
    func buy() async -> Bool {
        guard let product else { return false }
        isWorking = true
        defer { isWorking = false }
        guard let result = try? await product.purchase() else { return false }
        if case .success(let verification) = result,
           case .verified(let transaction) = verification {
            monetization.setPremium(true)
            await transaction.finish()
            return true
        }
        return false
    }

    /// "Restaurar compras" (Apple lo exige visible).
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == AppConfig.premiumProductId {
                monetization.setPremium(transaction.revocationDate == nil)
                await transaction.finish()
            }
        }
    }
}
