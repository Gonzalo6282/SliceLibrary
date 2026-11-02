#if canImport(SuperwallKit)
import Foundation
import RevenueCat
import SuperwallKit

/// Superwall buys and restores through RevenueCat (Superwall docs, "Using RevenueCat").
nonisolated final class RCPurchaseController: PurchaseController, @unchecked Sendable {
    enum PurchasingError: LocalizedError {
        case productNotFound
        var errorDescription: String? { "Superwall didn't pass a StoreKit 2 product." }
    }

    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2 = product.sk2Product else { throw PurchasingError.productNotFound }
            let result = try await Purchases.shared.purchase(product: RevenueCat.StoreProduct(sk2Product: sk2))
            if !result.userCancelled { await PurchaseManager.shared.refreshStoreKitEntitlement() }
            return result.userCancelled ? .cancelled : .purchased
        } catch let error as RevenueCat.ErrorCode {
            return error == .paymentPendingError ? .pending : .failed(error)
        } catch {
            return .failed(error)
        }
    }

    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            await PurchaseManager.shared.refreshStoreKitEntitlement()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
#endif
