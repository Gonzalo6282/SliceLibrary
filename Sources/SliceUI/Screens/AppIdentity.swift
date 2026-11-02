import Foundation

/// Who the app is: name, company, App Store ID, support email and legal
/// links. Passed to the standard screens so nothing app-specific lives in the library.
public struct AppIdentity: Sendable, Hashable {
    /// Shown in "Rate …", "Share …", reports and the version line.
    public var name: String
    public var company: String
    /// The numeric App Store ID, e.g. "6824285908".
    public var appStoreID: String
    public var supportEmail: String
    public var privacyURL: URL
    public var termsURL: URL
    public var version: String
    public var build: String

    public init(
        name: String, company: String, appStoreID: String, supportEmail: String, privacyURL: URL, termsURL: URL,
        version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
        build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    ) {
        self.name = name
        self.company = company
        self.appStoreID = appStoreID
        self.supportEmail = supportEmail
        self.privacyURL = privacyURL
        self.termsURL = termsURL
        self.version = version
        self.build = build
    }

    /// The App Store page.
    public var appStoreURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)") ?? termsURL }
    /// The App Store "Write a Review" page.
    public var writeReviewURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") ?? termsURL }
    /// "Duly 1.2 (3) · Slice of Life Ltd".
    public var versionLine: String { "\(name) \(version) (\(build)) · \(company)" }
}

/// A string from SliceUI's own catalog (English, French, German, Spanish).
func ui(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
