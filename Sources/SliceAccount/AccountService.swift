import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import SlicePurchases

#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseCore
#endif

/// What an app passes in at launch.
public struct AccountConfig: Sendable {
    /// Shown in the help text when Apple's link to the app needs resetting.
    public var appName: String
    /// Links purchases to the account (`PurchaseManager.logIn/logOut`), so Premium follows the user.
    public var linksPurchases: Bool
    /// Prefix for console lines about failures.
    public var logPrefix: String

    public init(appName: String, linksPurchases: Bool = true, logPrefix: String = "[account]") {
        self.appName = appName
        self.linksPurchases = linksPurchases
        self.logPrefix = logPrefix
    }
}

/// Optional Sign in with Apple via Firebase Auth. The Firebase user ID becomes
/// the RevenueCat app user ID (so Premium follows the user to a new phone).
/// Delete account revokes the Apple token (Apple requires it) and deletes the
/// Firebase user. Needs the app's `GoogleService-Info.plist`, Firebase started
/// (SliceAnalytics does it), Apple enabled in Firebase Auth, and the "Sign in
/// with Apple" capability.
@MainActor
@Observable
public final class AccountService {
    public static let shared = AccountService()

    public private(set) var userID: String?
    public private(set) var email: String?
    public private(set) var config = AccountConfig(appName: "")
    private var currentNonce: String?
    #if canImport(FirebaseAuth)
    private var listener: AuthStateDidChangeListenerHandle?
    #endif

    init() {}

    /// Firebase is set up in this build (its file is bundled and it has started).
    public var isAvailable: Bool {
        #if canImport(FirebaseAuth)
        // Check the file first: asking Firebase before it starts logs a warning.
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return false }
        return FirebaseApp.app() != nil
        #else
        return false
        #endif
    }

    public var isSignedIn: Bool { userID != nil }

    /// Call once at launch, after Firebase has started (after `AppAnalytics.shared.configure`).
    public func start(_ config: AccountConfig) {
        self.config = config
        #if canImport(FirebaseAuth)
        guard isAvailable, listener == nil else { return }
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let id = user?.uid
            let mail = user?.email
            Task { @MainActor in
                guard let self else { return }
                self.userID = id
                self.email = mail
                if let id, self.config.linksPurchases { await PurchaseManager.shared.logIn(userID: id) }
            }
        }
        #endif
    }

    // MARK: Sign in with Apple

    /// Use in `SignInWithAppleButton(onRequest:)`.
    public func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = Self.sha256(nonce)
    }

    /// Use in `SignInWithAppleButton(onCompletion:)`. Throws on failure.
    public func complete(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()
        #if canImport(FirebaseAuth)
        guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = apple.identityToken, let token = String(data: tokenData, encoding: .utf8),
            let nonce = currentNonce
        else { throw AccountError.missingToken }
        let credential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: apple.fullName)
        _ = try await Auth.auth().signIn(with: credential)
        #else
        _ = authorization
        throw AccountError.missingToken
        #endif
    }

    public func signOut() async {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        if config.linksPurchases { await PurchaseManager.shared.logOut() }
    }

    /// Deletes the account. Needs a fresh Apple sign-in (for the authorization
    /// code Apple requires to revoke the token). The app's local data stays.
    public func deleteAccount(with result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()
        #if canImport(FirebaseAuth)
        guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = apple.authorizationCode, let code = String(data: codeData, encoding: .utf8),
            let tokenData = apple.identityToken, let token = String(data: tokenData, encoding: .utf8),
            let nonce = currentNonce, let user = Auth.auth().currentUser
        else { throw AccountError.missingToken }
        let credential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: nil)
        _ = try await user.reauthenticate(with: credential)
        try await Auth.auth().revokeToken(withAuthorizationCode: code)
        try await user.delete()
        #else
        _ = authorization
        throw AccountError.missingToken
        #endif
        if config.linksPurchases { await PurchaseManager.shared.logOut() }
    }

    // MARK: Errors

    /// The message for an alert, or nil when the user cancelled Apple's sheet
    /// (nothing to show). The full error (domain, code, Firebase's reason,
    /// underlying errors) goes to the console; debug builds also show it in the alert.
    public static func report(_ error: Error, step: String) -> String? {
        let ns = error as NSError
        let detail = describe(ns)
        print("\(shared.config.logPrefix) \(step) failed: \(detail)")
        let message: String
        switch (ns.domain, ns.code) {
        case (ASAuthorizationError.errorDomain, ASAuthorizationError.canceled.rawValue):
            return nil
        case (ASAuthorizationError.errorDomain, ASAuthorizationError.unknown.rawValue):
            // Error 1000 (often AKAuthenticationError -7071): Apple's link to the app needs resetting.
            message = appleResetHelp(appName: shared.config.appName)
        default:
            message = error.localizedDescription
        }
        #if DEBUG
        return message + "\n\n" + detail
        #else
        return message
        #endif
    }

    /// How to reset Apple's link to the app (Settings > Sign in with Apple > Stop Using Apple ID).
    public static func appleResetHelp(appName: String) -> String {
        String(localized: "Apple couldn't confirm it's you. On your iPhone, open Settings > [your name] > Sign-In & Security > Sign in with Apple > \(appName) and tap Stop Using Apple ID. Then come back to \(appName) and try again.", bundle: .module)
    }

    /// "domain code | key=value … | underlying: …", up to three levels deep.
    nonisolated public static func describe(_ error: NSError, depth: Int = 0) -> String {
        var parts = ["\(error.domain) \(error.code)"]
        for (key, value) in error.userInfo where key != NSUnderlyingErrorKey {
            parts.append("\(key)=\(value)")
        }
        if depth < 3, let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            parts.append("underlying: " + describe(underlying, depth: depth + 1))
        }
        return parts.joined(separator: " | ")
    }

    public enum AccountError: LocalizedError {
        case missingToken
        public var errorDescription: String? { String(localized: "Sign in with Apple didn't finish. Please try again.", bundle: .module) }
    }

    // MARK: Nonce (Firebase docs)

    nonisolated public static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in charset[Int.random(in: 0..<charset.count, using: &generator)] })
    }

    nonisolated public static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
