import Foundation
import Observation
import StoreKit

#if canImport(FirebaseCore)
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import FirebaseRemoteConfig
#endif

/// An analytics event. Each app keeps its own list:
/// `enum Event: String, AnalyticsEventType { case scanSaved = "scan_saved" }`.
public protocol AnalyticsEventType: Sendable {
    /// The event name in Firebase (snake_case, up to 40 characters).
    var eventName: String { get }
}

extension AnalyticsEventType where Self: RawRepresentable, RawValue == String {
    public var eventName: String { rawValue }
}

/// A Remote Config default.
public enum RemoteValue: Sendable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    var object: NSObject {
        switch self {
        case .bool(let v): v as NSNumber
        case .int(let v): v as NSNumber
        case .double(let v): v as NSNumber
        case .string(let v): v as NSString
        }
    }
}

/// What an app passes in at launch.
public struct AnalyticsConfig: Sendable {
    /// Where the user's answer is stored (UserDefaults). Bind the Settings switch to the same key.
    public var consentKey: String
    public var consentPolicy: ConsentPolicy
    /// Remote Config keys with their in-app defaults.
    public var remoteDefaults: [String: RemoteValue]
    /// Added to every event as `app_version`.
    public var appVersion: String
    /// Adds the App Store country to every event as `country`.
    public var addsCountry: Bool

    public init(
        consentKey: String, consentPolicy: ConsentPolicy = .askEveryone, remoteDefaults: [String: RemoteValue] = [:],
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0",
        addsCountry: Bool = true
    ) {
        self.consentKey = consentKey
        self.consentPolicy = consentPolicy
        self.remoteDefaults = remoteDefaults
        self.appVersion = appVersion
        self.addsCountry = addsCountry
    }
}

/// Firebase Analytics + Crashlytics + Remote Config, behind the user's consent.
/// No advertising ID, ever (ad storage and ad personalisation are always denied).
/// Firebase starts only when the app's `GoogleService-Info.plist` is in its bundle.
@MainActor
@Observable
public final class AppAnalytics {
    public static let shared = AppAnalytics()

    public private(set) var isConfigured = false
    public private(set) var config = AnalyticsConfig(consentKey: "analyticsEnabled")
    /// The App Store country (alpha-3), once known.
    public private(set) var country = ""

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    /// True when the app has a Firebase configuration file.
    public static var hasFirebaseFile: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    /// Call once at launch. Without `GoogleService-Info.plist` nothing starts (and nothing is sent).
    public func configure(_ config: AnalyticsConfig) {
        self.config = config
        #if canImport(FirebaseCore)
        // A flag, not FirebaseApp.app(): asking Firebase before configure() logs "not yet been configured".
        guard Self.hasFirebaseFile, !isConfigured else { return }
        FirebaseApp.configure()
        isConfigured = true
        RemoteConfig.remoteConfig().setDefaults(config.remoteDefaults.mapValues(\.object))
        RemoteConfig.remoteConfig().fetchAndActivate { _, _ in }
        apply(enabled: isEnabled)
        Task {
            country = await Storefront.current?.countryCode ?? ""
            apply(enabled: isEnabled)  // the country can change the default under askInEuropeOnly
        }
        #endif
    }

    // MARK: Consent

    var state: ConsentState {
        ConsentState(
            policy: config.consentPolicy, stored: storedConsent,
            countryCode: country.isEmpty ? Locale.current.region?.identifier : country)
    }

    /// The user's answer; nil = never decided.
    public var storedConsent: Bool? { defaults.object(forKey: config.consentKey) as? Bool }
    /// Collecting right now.
    public var isEnabled: Bool { state.isEnabled }
    /// The question should be shown (no answer yet, and the policy needs one here).
    public var needsConsentPrompt: Bool { state.needsPrompt }
    /// The policy needs an answer before collecting, for this user's country.
    public var requiresConsent: Bool { state.requiresConsent }

    /// Saves the answer (question or Settings switch) and applies it.
    public func setConsent(_ granted: Bool) {
        defaults.set(granted, forKey: config.consentKey)
        apply(enabled: granted)
    }

    func apply(enabled: Bool) {
        #if canImport(FirebaseCore)
        guard isConfigured else { return }
        Analytics.setConsent([
            .analyticsStorage: enabled ? .granted : .denied,
            .adStorage: .denied, .adUserData: .denied, .adPersonalization: .denied,
        ])
        Analytics.setAnalyticsCollectionEnabled(enabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
        #endif
    }

    // MARK: Events

    /// Logs an event with `app_version` (and `country`) attached. Nothing is sent
    /// without consent or without Firebase.
    public func log(_ event: any AnalyticsEventType, _ parameters: [String: Any] = [:]) {
        guard isConfigured, isEnabled else { return }
        let params = Self.parameters(parameters, version: config.appVersion, country: config.addsCountry ? country : "")
        #if canImport(FirebaseCore)
        Analytics.logEvent(event.eventName, parameters: params)
        #endif
        _ = params
    }

    nonisolated static func parameters(_ parameters: [String: Any], version: String, country: String) -> [String: Any] {
        var params = parameters
        params["app_version"] = version
        if !country.isEmpty { params["country"] = country }
        return params
    }

    /// Records a non-fatal error in Crashlytics (only with consent).
    public func record(_ error: Error) {
        #if canImport(FirebaseCore)
        guard isConfigured, isEnabled else { return }
        Crashlytics.crashlytics().record(error: error)
        #endif
    }

    // MARK: Remote Config

    public func remoteBool(_ key: String) -> Bool {
        #if canImport(FirebaseCore)
        if isConfigured { return RemoteConfig.remoteConfig()[key].boolValue }
        #endif
        if case .bool(let v) = config.remoteDefaults[key] { return v }
        return false
    }

    public func remoteString(_ key: String) -> String {
        #if canImport(FirebaseCore)
        if isConfigured { return RemoteConfig.remoteConfig()[key].stringValue }
        #endif
        if case .string(let v) = config.remoteDefaults[key] { return v }
        return ""
    }

    public func remoteNumber(_ key: String) -> Double {
        #if canImport(FirebaseCore)
        if isConfigured { return RemoteConfig.remoteConfig()[key].numberValue.doubleValue }
        #endif
        switch config.remoteDefaults[key] {
        case .int(let v): return Double(v)
        case .double(let v): return v
        default: return 0
        }
    }
}

/// Shows the app's consent question once, when the user is in the app with
/// nothing else on screen (call `askIfNeeded()` then, never during onboarding
/// or over a paywall). Bind an alert to `isShowing`.
@MainActor
@Observable
public final class ConsentPrompt {
    public static let shared = ConsentPrompt()
    public var isShowing = false

    init() {}

    public func askIfNeeded() {
        guard AppAnalytics.shared.needsConsentPrompt, !isShowing else { return }
        Task {
            // Let a closing paywall or sheet finish its animation first.
            try? await Task.sleep(for: .milliseconds(700))
            if AppAnalytics.shared.needsConsentPrompt { isShowing = true }
        }
    }
}
