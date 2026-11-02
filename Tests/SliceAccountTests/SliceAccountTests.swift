import AuthenticationServices
import Foundation
import SliceUI
import SwiftUI
import Testing

@testable import SliceAccount

@Test func noncesAreRandomAndHashed() {
    let a = AccountService.randomNonce()
    #expect(a.count == 32)
    #expect(a != AccountService.randomNonce())
    #expect(AccountService.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
}

@Test @MainActor func cancellingAppleSignInShowsNothing() {
    let domain = ASAuthorizationError.errorDomain
    #expect(AccountService.report(NSError(domain: domain, code: ASAuthorizationError.canceled.rawValue), step: "test") == nil)
}

@Test @MainActor func error1000ExplainsHowToResetApplesLink() throws {
    AccountService.shared.start(AccountConfig(appName: "Scanly"))
    let message = try #require(AccountService.report(NSError(domain: ASAuthorizationError.errorDomain, code: 1000), step: "test"))
    #expect(message.hasPrefix(AccountService.appleResetHelp(appName: "Scanly")))
    #expect(AccountService.appleResetHelp(appName: "Scanly").contains("Sign in with Apple > Scanly and tap Stop Using Apple ID. Then come back to Scanly"))
}

@Test func errorDetailsIncludeUnderlyingErrors() {
    let inner = NSError(domain: "FIRAuthErrorDomain", code: 17999, userInfo: ["reason": "invalid"])
    let outer = NSError(domain: "Outer", code: 1, userInfo: [NSUnderlyingErrorKey: inner])
    let text = AccountService.describe(outer)
    #expect(text.hasPrefix("Outer 1"))
    #expect(text.contains("underlying: FIRAuthErrorDomain 17999"))
    #expect(text.contains("reason=invalid"))
}

@Test func missingTokenHasAMessage() {
    #expect(AccountService.AccountError.missingToken.errorDescription == "Sign in with Apple didn't finish. Please try again.")
}

@Test func translationsShip() throws {
    for (language, expected) in [("fr", "Se connecter avec Apple"), ("de", "Mit Apple anmelden"), ("es-ES", "Ajustes")] {
        let path = try #require(Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
        #expect(try String(contentsOfFile: path, encoding: .utf8).contains(expected), "\(language)")
    }
}

@Test @MainActor func withoutFirebaseItIsNotAvailable() {
    #expect(!AccountService.shared.isAvailable)
    #expect(!AccountService.shared.isSignedIn)
}

@Test @MainActor func rowsAndDeleteSheetRender() {
    for view in [AnyView(VStack { AccountRows() }), AnyView(DeleteAccountSheet { _ in })] {
        let renderer = ImageRenderer(content: view.frame(width: 390).sliceTheme(.standard))
        #expect(renderer.cgImage != nil)
    }
}
