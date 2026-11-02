import Foundation
import Observation
import RevenueCat
import StoreKit

/// Premium state, plans and buying.
///
/// RevenueCat when a key is set, otherwise StoreKit 2 directly (StoreKit
/// configuration file, sandbox). Premium is active when RevenueCat's
/// entitlement OR Apple's own verified transactions say so, so a purchase
/// unlocks even if RevenueCat lags or its products aren't set up yet.
@MainActor
@Observable
public final class PurchaseManager {
    public static let shared = PurchaseManager()

    public enum PurchaseOutcome: Sendable, Equatable { case purchased, cancelled, pending, failed(String) }

    public private(set) var isPremium = false
    public private(set) var usesRevenueCat = false
    /// Plans for the app's own paywall, in the app's product order.
    public private(set) var plans: [Plan] = []
    public private(set) var config = PurchaseConfig(revenueCatAPIKey: nil, entitlement: "pro", productIDs: [])

    private var revenueCatPremium = false
    private var storeKitPremium = false
    var forcedPremium = false

    init() {}

    /// Call once at launch, before ``PaywallService/configure(superwallAPIKey:)``.
    public func configure(_ config: PurchaseConfig) {
        self.config = config
        if config.forcePremium { forcedPremium = true; isPremium = true }
        if let key = config.revenueCatAPIKey {
            Purchases.logLevel = .warn
            Purchases.configure(with: Configuration.Builder(withAPIKey: key).with(storeKitVersion: .storeKit2).build())
            #if os(iOS)
            if config.adServicesAttribution { Purchases.shared.attribution.enableAdServicesAttributionTokenCollection() }
            #endif
            usesRevenueCat = true
            Task { await listenToRevenueCat() }
            // RevenueCat finishes transactions; we only read Apple's current entitlements.
            Task { await refreshStoreKitEntitlement() }
        } else {
            Task { await listenToStoreKit() }
        }
        Task { await loadPlans() }
    }

    // MARK: Entitlement

    func hasPremium(_ info: CustomerInfo?) -> Bool {
        info?.entitlements.active[config.entitlement] != nil
    }

    private func listenToRevenueCat() async {
        for await info in Purchases.shared.customerInfoStream {
            revenueCatPremium = hasPremium(info)
            await refreshStoreKitEntitlement()
        }
    }

    private func listenToStoreKit() async {
        await refreshStoreKitEntitlement()
        for await update in Transaction.updates {
            if case .verified(let transaction) = update { await transaction.finish() }
            await refreshStoreKitEntitlement()
        }
    }

    /// Re-reads Apple's verified, unrevoked, unexpired purchases of the app's products.
    public func refreshStoreKitEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
                Self.isActive(productID: t.productID, revoked: t.revocationDate != nil, expires: t.expirationDate, products: config.productIDs)
            {
                active = true
            }
        }
        storeKitPremium = active
        recompute()
    }

    /// One of the app's products, not refunded, and not expired (lifetime has no expiry).
    nonisolated static func isActive(productID: String, revoked: Bool, expires: Date?, products: [String], now: Date = .now) -> Bool {
        products.contains(productID) && !revoked && (expires ?? .distantFuture) > now
    }

    func recompute() {
        isPremium = revenueCatPremium || storeKitPremium || forcedPremium
        PaywallService.shared.updateSubscriptionStatus(isPremium: isPremium)
    }

    // MARK: Plans

    /// Loads plans from RevenueCat's current offering, or from the App Store.
    public func loadPlans() async {
        if usesRevenueCat, let offering = try? await Purchases.shared.offerings().current {
            let packages = Plan.ordered(offering.availablePackages, by: config.productIDs) { $0.storeProduct.productIdentifier }
            plans = packages.map { package in
                let product = package.storeProduct
                let period = Self.period(of: package)
                return Plan(
                    id: product.productIdentifier, period: period, price: product.localizedPriceString,
                    monthlyPrice: period == .year ? product.localizedPricePerMonth : nil,
                    trialDays: product.introductoryDiscount.flatMap {
                        $0.paymentMode == .freeTrial ? Plan.days(unit: $0.subscriptionPeriod.planUnit, value: $0.subscriptionPeriod.value) : nil
                    },
                    rcPackage: package, skProduct: nil)
            }
        } else if let products = try? await Product.products(for: config.productIDs) {
            plans = Plan.ordered(products, by: config.productIDs, id: \.id).map { product in
                let period = product.subscription.map { Plan.period(unit: $0.subscriptionPeriod.planUnit, value: $0.subscriptionPeriod.value) } ?? .lifetime
                let trial = product.subscription?.introductoryOffer.flatMap { offer in
                    offer.paymentMode == .freeTrial ? Plan.days(unit: offer.period.planUnit, value: offer.period.value) : nil
                }
                return Plan(
                    id: product.id, period: period, price: product.displayPrice,
                    monthlyPrice: period == .year ? (product.price / 12).formatted(product.priceFormatStyle) : nil,
                    trialDays: trial, rcPackage: nil, skProduct: product)
            }
        }
    }

    private static func period(of package: RevenueCat.Package) -> Plan.Period {
        switch package.packageType {
        case .annual: return .year
        case .monthly: return .month
        case .weekly: return .week
        case .lifetime: return .lifetime
        default:
            guard let p = package.storeProduct.subscriptionPeriod else { return .lifetime }
            return Plan.period(unit: p.planUnit, value: p.value)
        }
    }

    // MARK: Buy / restore

    public func purchase(_ plan: Plan) async -> PurchaseOutcome {
        do {
            if let package = plan.rcPackage {
                let result = try await Purchases.shared.purchase(package: package)
                revenueCatPremium = hasPremium(result.customerInfo)
                await refreshStoreKitEntitlement()
                return result.userCancelled ? .cancelled : .purchased
            }
            guard let product = plan.skProduct else { return .failed("This plan isn't available right now.") }
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification { await transaction.finish() }
                await refreshStoreKitEntitlement()
                return .purchased
            case .userCancelled: return .cancelled
            case .pending: return .pending
            @unknown default: return .cancelled
            }
        } catch let error as RevenueCat.ErrorCode where error == .paymentPendingError {
            return .pending
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Restores purchases. Returns true if Premium is active afterwards.
    public func restore() async -> Bool {
        if usesRevenueCat {
            let info = try? await Purchases.shared.restorePurchases()
            revenueCatPremium = hasPremium(info)
        } else {
            try? await AppStore.sync()
        }
        await refreshStoreKitEntitlement()
        return isPremium
    }

    // MARK: Account link

    /// Links purchases to the app's account ID (for example after Sign in with Apple).
    public func logIn(userID: String) async {
        guard usesRevenueCat else { return }
        _ = try? await Purchases.shared.logIn(userID)
        PaywallService.shared.identify(userID: Purchases.shared.appUserID)
    }

    /// Unlinks the account. Premium stays if Apple still says the subscription is active
    /// (it belongs to the Apple ID, not the account).
    public func logOut() async {
        guard usesRevenueCat, !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
        PaywallService.shared.resetIdentity()
        await refreshStoreKitEntitlement()
    }

    // MARK: Diagnostics (debug builds)

    /// What each source says right now, for a debug panel and the console.
    public func diagnostics() async -> [String] {
        var lines = ["Premium (app): \(isPremium)  RevenueCat: \(revenueCatPremium)  Apple: \(storeKitPremium)"]
        if usesRevenueCat, let info = try? await Purchases.shared.customerInfo() {
            lines.append("RevenueCat user: \(Purchases.shared.appUserID)")
            lines.append("RevenueCat active entitlements: \(info.entitlements.active.keys.sorted())")
            lines.append("RevenueCat all entitlements: \(info.entitlements.all.keys.sorted())")
            lines.append("RevenueCat active subscriptions: \(info.activeSubscriptions.sorted())")
            lines.append("RevenueCat purchased products: \(info.allPurchasedProductIdentifiers.sorted())")
        } else {
            lines.append("RevenueCat: \(usesRevenueCat ? "customerInfo failed" : "not configured")")
        }
        var current = 0
        for await result in Transaction.currentEntitlements {
            current += 1
            switch result {
            case .verified(let t):
                lines.append("Apple entitlement ✓ \(t.productID) env=\(t.environment.rawValue) expires=\(t.expirationDate?.formatted() ?? "-") revoked=\(t.revocationDate != nil)")
            case .unverified(let t, let error):
                lines.append("Apple entitlement ✗ UNVERIFIED \(t.productID): \(error)")
            }
        }
        var all = 0
        for await _ in Transaction.all { all += 1 }
        lines.append("Apple current entitlements: \(current), all transactions: \(all)")
        lines.append("Superwall status: \(PaywallService.shared.statusDescription)")
        for line in lines { print("\(config.logPrefix) \(line)") }
        return lines
    }
}
