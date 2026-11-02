import Foundation
import Observation

#if canImport(SuperwallKit)
import RevenueCat
import SuperwallKit
#endif

/// A place in the app where a paywall can appear. Apps make an enum:
/// `enum Placement: String, PaywallPlacementType { case scan, export }`.
public protocol PaywallPlacementType: Sendable {
    /// The placement name in Superwall's dashboard.
    var placementName: String { get }
}

extension PaywallPlacementType where Self: RawRepresentable, RawValue == String {
    public var placementName: String { rawValue }
}

/// Paywalls: Superwall's (designed in its dashboard, buying through RevenueCat)
/// with the app's own paywall as a fallback, so a Premium action never
/// dead-ends: no key, no connection, no campaign for the placement, or an
/// error shows ``nativePaywall`` instead. The app presents that request with
/// its own view (`.sheet(item: $paywalls.nativePaywall)`).
@MainActor
@Observable
public final class PaywallService {
    public static let shared = PaywallService()

    public private(set) var usesSuperwall = false
    /// Set when the app's own paywall should show. Present it, call
    /// `onUnlock` after a purchase or restore, and `onClose` when it closes.
    public var nativePaywall: NativePaywallRequest?
    /// Called each time a paywall shows: placement name, paywall ID (`"native"` for the app's own).
    public var onPaywallShown: ((_ placement: String, _ paywallID: String) -> Void)?

    public struct NativePaywallRequest: Identifiable {
        public let id = UUID()
        public let placement: any PaywallPlacementType
        /// Run after a purchase or restore: continues the action the user tapped.
        public let onUnlock: () -> Void
        /// Run when the sheet closes (bought or not).
        public var onClose: () -> Void = {}

        public var placementName: String { placement.placementName }
    }

    init() {}

    #if canImport(SuperwallKit)
    private var purchaseController: RCPurchaseController?
    #endif

    /// Call once at launch, after ``PurchaseManager/configure(_:)``. Superwall
    /// needs RevenueCat (it buys through it); without either key the app's own paywall is used.
    public func configure(superwallAPIKey: String?) {
        #if canImport(SuperwallKit)
        guard let key = superwallAPIKey, PurchaseManager.shared.usesRevenueCat else { return }
        let controller = RCPurchaseController()
        purchaseController = controller
        Superwall.configure(apiKey: key, purchaseController: controller)
        usesSuperwall = true
        updateSubscriptionStatus(isPremium: PurchaseManager.shared.isPremium)
        identify(userID: Purchases.shared.appUserID)
        #endif
    }

    /// Superwall and RevenueCat must share the user ID (RevenueCat → Superwall
    /// revenue tracking). Called at launch and after sign-in.
    public func identify(userID: String) {
        #if canImport(SuperwallKit)
        guard usesSuperwall, !userID.isEmpty else { return }
        Superwall.shared.identify(userId: userID)
        #endif
    }

    public func resetIdentity() {
        #if canImport(SuperwallKit)
        guard usesSuperwall else { return }
        Superwall.shared.reset()
        identify(userID: Purchases.shared.appUserID)
        #endif
    }

    public var statusDescription: String {
        #if canImport(SuperwallKit)
        return usesSuperwall ? String(describing: Superwall.shared.subscriptionStatus) : "not configured"
        #else
        return "not available"
        #endif
    }

    /// Superwall's status follows ``PurchaseManager`` (RevenueCat or Apple's transactions).
    func updateSubscriptionStatus(isPremium: Bool) {
        #if canImport(SuperwallKit)
        guard usesSuperwall else { return }
        Superwall.shared.subscriptionStatus =
            isPremium ? .active([Entitlement(id: PurchaseManager.shared.config.entitlement)]) : .inactive
        #endif
    }

    /// Runs `feature` if the user has Premium; otherwise shows a paywall and
    /// runs `feature` after a purchase or restore (so a hard paywall continues
    /// the action the user tapped). If they close it without buying, `feature`
    /// doesn't run. `onFinished` runs once, after any paywall shown for this
    /// tap has closed (or straight away when none was needed).
    public func gate(
        _ placement: any PaywallPlacementType, params: [String: Any] = [:], onFinished: (() -> Void)? = nil,
        feature: @escaping () -> Void
    ) {
        let attempt = GateAttempt()
        attempt.onFinished = onFinished
        if PurchaseManager.shared.isPremium {
            feature()
            attempt.finish()
            return
        }
        guard usesSuperwall else {
            showNative(placement, feature, attempt: attempt)
            return
        }
        #if canImport(SuperwallKit)
        let name = placement.placementName
        let handler = PaywallPresentationHandler()
        handler.onPresent { [weak self] info in
            let id = info.identifier
            Task { @MainActor in
                attempt.presented = true
                self?.onPaywallShown?(name, id)
            }
        }
        handler.onDismiss { _, _ in
            Task { @MainActor in attempt.finish() }
        }
        handler.onError { [weak self] _ in
            Task { @MainActor in self?.showNative(placement, feature, attempt: attempt) }
        }
        // No campaign for this placement yet (or a holdout): Superwall would just
        // run the feature, so fall back to the native paywall instead.
        handler.onSkip { [weak self] _ in
            Task { @MainActor in self?.unlockOrShowNative(placement, feature, attempt: attempt) }
        }
        Superwall.shared.register(placement: name, params: params, handler: handler) { [weak self] in
            Task { @MainActor in self?.unlockOrShowNative(placement, feature, attempt: attempt) }
        }
        #endif
    }

    /// One tap on a gated action (skip and feature callbacks can both arrive).
    @MainActor
    final class GateAttempt {
        var presented = false
        var resolved = false
        var onFinished: (() -> Void)?

        func finish() {
            let done = onFinished
            onFinished = nil
            done?()
        }
    }

    func unlockOrShowNative(_ placement: any PaywallPlacementType, _ feature: @escaping () -> Void, attempt: GateAttempt) {
        guard !attempt.resolved else { return }
        attempt.resolved = true
        if PurchaseManager.shared.isPremium || superwallSaysActive {
            feature()
            if !attempt.presented { attempt.finish() }  // shown: onDismiss finishes
        } else if !attempt.presented {
            // Nothing was shown (no campaign yet): show ours.
            showNative(placement, feature, attempt: attempt)
        }
        // A Superwall paywall was shown and closed without buying: do nothing.
    }

    private var superwallSaysActive: Bool {
        #if canImport(SuperwallKit)
        guard usesSuperwall else { return false }
        if case .active = Superwall.shared.subscriptionStatus { return true }
        #endif
        return false
    }

    private func showNative(_ placement: any PaywallPlacementType, _ feature: @escaping () -> Void, attempt: GateAttempt) {
        guard nativePaywall == nil else { return attempt.finish() }
        onPaywallShown?(placement.placementName, "native")
        nativePaywall = NativePaywallRequest(placement: placement, onUnlock: feature, onClose: { attempt.finish() })
    }
}
