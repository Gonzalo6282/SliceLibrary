import SliceUI
import SwiftUI

extension PurchaseManager.Plan {
    /// The plan as SliceUI's paywall shows it.
    public var paywallInfo: PaywallPlanInfo {
        let period: PaywallPlanInfo.Period =
            switch self.period {
            case .week: .week
            case .month: .month
            case .year: .year
            case .lifetime: .lifetime
            case .days(let d): d <= 7 ? .week : d <= 31 ? .month : .year
            }
        return PaywallPlanInfo(id: id, period: period, price: price, monthlyPrice: monthlyPrice, trialDays: trialDays)
    }
}

extension PurchaseManager.PurchaseOutcome {
    var paywallOutcome: PaywallOutcome {
        switch self {
        case .purchased: .purchased
        case .cancelled: .cancelled
        case .pending: .pending
        case .failed: .failed
        }
    }
}

extension PaywallTemplate {
    /// SliceUI's paywall wired to ``PurchaseManager``, for a ``PaywallService/nativePaywall`` request:
    ///
    /// ```swift
    /// .sheet(item: $paywalls.nativePaywall) { request in
    ///     PaywallTemplate(request: request, content: content(for: request.placement))
    ///         .onDisappear { request.onClose() }
    /// }
    /// ```
    @MainActor
    public init(request: PaywallService.NativePaywallRequest, content: PaywallContent) {
        self.init(content: content, onUnlock: request.onUnlock)
    }

    /// SliceUI's paywall wired to ``PurchaseManager``.
    @MainActor
    public init(content: PaywallContent, onUnlock: @escaping @MainActor () -> Void) {
        let purchases = PurchaseManager.shared
        self.init(
            content: content,
            plans: { purchases.plans.map(\.paywallInfo) },
            loadPlans: { await purchases.loadPlans() },
            buy: { info in
                guard let plan = purchases.plans.first(where: { $0.id == info.id }) else { return .failed }
                return await purchases.purchase(plan).paywallOutcome
            },
            restore: { await purchases.restore() },
            onUnlock: onUnlock)
    }
}
