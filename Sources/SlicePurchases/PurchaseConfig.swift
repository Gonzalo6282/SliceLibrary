import Foundation

/// What an app passes in at launch. No keys live in the library.
public struct PurchaseConfig: Sendable {
    /// RevenueCat public key (`appl_…`, or `test_…` in debug). Nil: StoreKit 2 directly.
    public var revenueCatAPIKey: String?
    /// The entitlement identifier, the same in RevenueCat and Superwall (for example `"pro"`).
    public var entitlement: String
    /// The app's subscription and lifetime product IDs, in the order plans are shown.
    /// Used for Apple's own entitlement check and the StoreKit-only fallback.
    public var productIDs: [String]
    /// Treat the user as Premium (UI tests, screenshots).
    public var forcePremium: Bool
    /// Collect the Apple Search Ads attribution token (RevenueCat).
    public var adServicesAttribution: Bool
    /// Prefix for console lines from ``PurchaseManager/diagnostics()``.
    public var logPrefix: String

    public init(
        revenueCatAPIKey: String?, entitlement: String, productIDs: [String], forcePremium: Bool = false,
        adServicesAttribution: Bool = true, logPrefix: String = "[purchases]"
    ) {
        self.revenueCatAPIKey = revenueCatAPIKey
        self.entitlement = entitlement
        self.productIDs = productIDs
        self.forcePremium = forcePremium
        self.adServicesAttribution = adServicesAttribution
        self.logPrefix = logPrefix
    }
}

/// Reads SDK keys from Info.plist (usually filled from an xcconfig that isn't committed).
public enum AppKey {
    /// The value of `key` when it starts with `prefix` and looks complete; otherwise nil
    /// (empty, or an unexpanded `$(VARIABLE)`), so that service stays off.
    public static func infoPlist(_ key: String, prefix: String, bundle: Bundle = .main) -> String? {
        value(bundle.object(forInfoDictionaryKey: key) as? String, prefix: prefix)
    }

    static func value(_ raw: String?, prefix: String) -> String? {
        guard let raw else { return nil }
        let v = raw.trimmingCharacters(in: .whitespaces)
        return v.hasPrefix(prefix) && v.count > prefix.count + 4 ? v : nil
    }
}
