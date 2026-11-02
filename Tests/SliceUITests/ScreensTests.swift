import Foundation
import SwiftUI
import Testing

@testable import SliceUI

private let app = AppIdentity(
    name: "Scanly", company: "Slice of Life Ltd", appStoreID: "123", supportEmail: "help@example.com",
    privacyURL: URL(string: "https://example.com/privacy")!, termsURL: URL(string: "https://example.com/terms")!,
    version: "2.1", build: "7")

// MARK: Identity and translations

@Test func appIdentityLinks() {
    #expect(app.writeReviewURL.absoluteString == "https://apps.apple.com/app/id123?action=write-review")
    #expect(app.appStoreURL.absoluteString == "https://apps.apple.com/app/id123")
    #expect(app.versionLine == "Scanly 2.1 (7) · Slice of Life Ltd")
}

@Test func sliceUIShipsItsTranslations() throws {
    func table(_ language: String) throws -> String {
        let path = try #require(Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language), "\(language)")
        return try String(contentsOfFile: path, encoding: .utf8)
    }
    #expect(try table("fr").contains("\"Noter %@\""))
    #expect(try table("de").contains("\"%@ bewerten\""))
    #expect(try table("es").contains("Configuración"))
    #expect(try table("es-ES").contains("Ajustes"))  // Spain's wording, not Latin America's
    #expect(try table("en-US").contains("unless canceled"))
    #expect(try table("en").contains("unless cancelled"))
    #expect(ui("Rate \(app.name)") == "Rate Scanly")
}

// MARK: Legal

@Test func legalTextParsing() {
    #expect(LegalBlock.parse("# T\n\n## H\n### S\n- b\ntext\n") == [.title("T"), .heading("H"), .subheading("S"), .bullet("b"), .paragraph("text")])
}

@Test func legalTextPicksTheLanguageFile() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("legal-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try "# Terms\n## English".write(to: dir.appendingPathComponent("terms.txt"), atomically: true, encoding: .utf8)
    try "# Conditions\n## Français".write(to: dir.appendingPathComponent("terms.fr.txt"), atomically: true, encoding: .utf8)
    let bundle = try #require(Bundle(url: dir))
    #expect(LegalDocument.terms.blocks(language: "fr-FR", bundle: bundle).contains(.heading("Français")))
    #expect(LegalDocument.terms.blocks(language: "en", bundle: bundle).contains(.heading("English")))
    #expect(LegalDocument.terms.blocks(language: "it", bundle: bundle).contains(.heading("English")))
    #expect(LegalDocument.privacy.blocks(language: "en", bundle: bundle).isEmpty)
    #expect(LegalDocument.terms.title == "Terms of Use")
}

// MARK: Report a problem

@Test func problemReportEmail() throws {
    let url = try #require(ReportProblemPage.mailURL(app: app, topic: "Scanning", message: "It froze", diagnostics: "Scanly 2.1 (7)"))
    let parts = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(parts.scheme == "mailto" && parts.path == "help@example.com")
    #expect(parts.queryItems?.first { $0.name == "subject" }?.value == "Scanly: Scanning")
    #expect(parts.queryItems?.first { $0.name == "body" }?.value == "It froze\n\n—\nScanly 2.1 (7)")
    let plain = try #require(ReportProblemPage.mailURL(app: app, topic: "", message: "Hi", diagnostics: nil))
    #expect(URLComponents(url: plain, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "subject" }?.value == "Scanly")
}

// MARK: Paywall wording

private let yearly = PaywallPlanInfo(id: "y", period: .year, price: "£29.99", monthlyPrice: "£2.50", trialDays: 3)
private let weekly = PaywallPlanInfo(id: "w", period: .week, price: "£3.99")
private let monthly = PaywallPlanInfo(id: "m", period: .month, price: "£4.99")
private let lifetime = PaywallPlanInfo(id: "l", period: .lifetime, price: "£49.99")

@Test func planWording() {
    #expect(PaywallWords.name(yearly) == "Yearly" && PaywallWords.name(weekly) == "Weekly" && PaywallWords.name(lifetime) == "Lifetime")
    #expect(PaywallWords.detail(yearly) == "3 days free, then £29.99 a year")
    #expect(PaywallWords.detail(monthly) == "Billed monthly, cancel any time")
    #expect(PaywallWords.detail(weekly) == "Billed weekly, cancel any time")
    #expect(PaywallWords.detail(lifetime) == "One payment, no subscription")
    #expect(PaywallWords.per(yearly) == "a month" && PaywallWords.per(weekly) == "a week" && PaywallWords.per(lifetime) == "once")
    #expect(PaywallWords.button(yearly) == "Start 3-day free trial")
    #expect(PaywallWords.button(weekly) == "Continue")
}

@Test func renewalTerms() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    #expect(PaywallWords.terms(yearly, now: now).hasPrefix("Free until "))
    #expect(PaywallWords.terms(yearly, now: now).contains("then £29.99 a year. Renews automatically"))
    #expect(PaywallWords.terms(weekly, now: now).hasPrefix("£3.99 a week. Renews automatically"))
    #expect(PaywallWords.terms(lifetime, now: now) == "One payment of £49.99. ")
    #expect(PaywallWords.terms(nil).hasPrefix("Renews automatically"))
}

@Test func trialTimeline() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let withReminder = PaywallWords.timeline(plan: yearly, days: 3, reminder: true, now: now)
    #expect(withReminder.map(\.icon) == ["lock.open.fill", "bell.fill", "creditcard.fill"])
    #expect(withReminder[0].when == "Today")
    #expect(withReminder[2].what == "You're charged £29.99. Cancel before this day to pay nothing.")
    #expect(PaywallWords.timeline(plan: yearly, days: 3, reminder: false, now: now).count == 2)
}

// MARK: Rendering

@Test @MainActor func screensRender() throws {
    let purchases = SettingsPurchases(
        isPremium: { false }, restore: { false }, upgrade: {}, premiumText: "Unlocked.", plansText: "Free and Premium.")
    let help = SettingsHelp(faqs: [.init("Is it free?", "Yes.")], reportTopics: ["Scanning"], reportFooter: "We reply.")
    let screens: [AnyView] = [
        AnyView(NavigationStack {
            StandardSettings(app: app, purchases: purchases, analytics: SettingsAnalytics(isOn: { true }, setOn: { _ in }),
                             help: help, share: SettingsShare(message: "Try it")) {
                GroupedSection(header: "Scanner") { Row(title: "Auto-scan") }
            }
        }),
        AnyView(NavigationStack { StandardSettings(app: app, purchases: nil, analytics: nil, help: help, share: nil) { EmptyView() } }),
        AnyView(NavigationStack { HelpPage(app: app, help: help) }),
        AnyView(NavigationStack { SubscriptionPage(purchases: purchases) }),
        AnyView(OnboardingShell(step: 2, of: 4) {
            OnboardingTitle("Welcome")
            OnboardingLead("Let's go.")
            OnboardingField("Name") { Text("Slice") }
            OnboardingChoice(icon: "qrcode", title: Text("QR"), detail: Text("Scan codes"), isSelected: true) {}
        } footer: {
            Button("Continue") {}.buttonStyle(.primary)
        }),
        AnyView(PaywallTemplate(
            content: PaywallContent(headline: "Unlock everything", subtitle: "**Free:** 3 scans a day.", benefits: ["Unlimited scans"],
                                    headerBackground: .black, showsTrialTimeline: true, trialReminder: true,
                                    closeButtonDelay: .seconds(3), termsURL: app.termsURL, privacyURL: app.privacyURL),
            plans: { [yearly, weekly] }, buy: { _ in .purchased }, restore: { true }, onUnlock: {})),
    ]
    for (index, screen) in screens.enumerated() {
        for theme in [SliceTheme.system(accent: .indigo), .dark(accent: Color(hex: "#7fee64"))] {
            let renderer = ImageRenderer(content: screen.frame(width: 390, height: 844).sliceTheme(theme))
            #expect(renderer.cgImage != nil, "screen \(index)")
        }
    }
}
