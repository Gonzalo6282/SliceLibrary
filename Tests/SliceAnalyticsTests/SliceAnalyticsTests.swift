import Foundation
import Testing

@testable import SliceAnalytics

private enum Event: String, AnalyticsEventType {
    case scanSaved = "scan_saved"
}

@Test func eventNamesComeFromTheRawValue() {
    #expect(Event.scanSaved.eventName == "scan_saved")
}

@Test func everyEventGetsTheVersionAndCountry() {
    let p = AppAnalytics.parameters(["kind": "url"], version: "1.2", country: "GBR")
    #expect(p["kind"] as? String == "url")
    #expect(p["app_version"] as? String == "1.2")
    #expect(p["country"] as? String == "GBR")
    #expect(AppAnalytics.parameters([:], version: "1.2", country: "")["country"] == nil)
}

// MARK: Consent region

@Test(arguments: ["GB", "gb", "FR", "DE", "IE", "NO", "IS", "LI", "CH", "GBR", "FRA", "NOR", "CHE", "ESP", "", nil] as [String?])
func europeNeedsConsent(code: String?) {
    #expect(ConsentRegion.requiresConsent(countryCode: code))
}

@Test(arguments: ["US", "AU", "CA", "MX", "JP", "USA", "AUS", "CAN", "MEX", "BRA"])
func restOfTheWorldDoesnt(code: String) {
    #expect(!ConsentRegion.requiresConsent(countryCode: code))
}

// MARK: Consent state

@Test func askEveryoneIsOffUntilAllowed() {
    var s = ConsentState(policy: .askEveryone, stored: nil, countryCode: "USA")
    #expect(!s.isEnabled && s.needsPrompt && s.requiresConsent)
    s.stored = true
    #expect(s.isEnabled && !s.needsPrompt)
    s.stored = false
    #expect(!s.isEnabled && !s.needsPrompt)
}

@Test func askInEuropeOnlyAsksInTheUK() {
    let s = ConsentState(policy: .askInEuropeOnly, stored: nil, countryCode: "GBR")
    #expect(!s.isEnabled && s.needsPrompt)
}

@Test func askInEuropeOnlyIsOnElsewhereUntilTurnedOff() {
    var s = ConsentState(policy: .askInEuropeOnly, stored: nil, countryCode: "USA")
    #expect(s.isEnabled && !s.needsPrompt && !s.requiresConsent)
    s.stored = false
    #expect(!s.isEnabled)
}

@Test func unknownCountryIsAsked() {
    let s = ConsentState(policy: .askInEuropeOnly, stored: nil, countryCode: nil)
    #expect(!s.isEnabled && s.needsPrompt)
}

// MARK: AppAnalytics without Firebase

@Test @MainActor func answersAreStoredUnderTheAppsKey() throws {
    let defaults = try #require(UserDefaults(suiteName: "slice-analytics-\(UUID().uuidString)"))
    let analytics = AppAnalytics(defaults: defaults)
    analytics.configure(AnalyticsConfig(consentKey: "myConsent", remoteDefaults: ["soft_paywall": .bool(true), "trial_days": .int(3), "headline": .string("Hi")]))
    #expect(!analytics.isConfigured)  // no GoogleService-Info.plist in the test bundle
    #expect(analytics.storedConsent == nil && analytics.needsConsentPrompt && !analytics.isEnabled)
    analytics.setConsent(true)
    #expect(defaults.object(forKey: "myConsent") as? Bool == true)
    #expect(analytics.isEnabled && !analytics.needsConsentPrompt)
    analytics.log(Event.scanSaved)  // no Firebase: does nothing, doesn't crash
    #expect(analytics.remoteBool("soft_paywall"))
    #expect(analytics.remoteNumber("trial_days") == 3)
    #expect(analytics.remoteString("headline") == "Hi")
    #expect(!analytics.remoteBool("missing"))
    #expect(analytics.appInstanceID == nil)  // no Firebase: nothing to link
}

@Test func remoteDefaultsBecomeFirebaseValues() {
    #expect(RemoteValue.bool(true).object as? NSNumber == true as NSNumber)
    #expect(RemoteValue.string("x").object as? String == "x")
    #expect(RemoteValue.double(1.5).object as? NSNumber == 1.5 as NSNumber)
}
