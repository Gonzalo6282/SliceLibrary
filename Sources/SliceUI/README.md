# SliceUI: Theme + Components

The shared look. Every component reads colours and fonts from a `SliceTheme`
the app provides, so the same code looks like each app.

## 1. Make your themes

```swift
import SliceUI

extension SliceTheme {
    /// Follows light/dark mode.
    static let main = SliceTheme.system(accent: Color(light: "#2B6BFF", dark: "#5C8DFF"))
    /// Always dark: lime on black (camera, onboarding, paywall).
    static let camera = SliceTheme.dark(accent: Color(hex: "#7FEE64"))  // onAccent defaults to black
}
```

Need full control? `SliceTheme(appearance:accent:…)` takes every colour
(asset-catalog colours work and follow light/dark by themselves). Unset soft
colours are made from the accent.

Fonts: `text:` and `display:` take `.system`, `.system(design: .rounded)` or
`.custom("Inter-Regular", weights: [.bold: "Inter-Bold"])`. Sizes follow Dynamic Type.

## 2. Apply them

```swift
@main struct MyApp: App {
    init() { SliceTheme.appDefault = .main }   // used by sheets, previews, UIKit-hosted views
    var body: some Scene {
        WindowGroup { RootView().sliceTheme(.main) }
    }
}

CameraView()
    .sliceTheme(.camera)                     // this subtree is dark, lime accent
    .preferredColorScheme(.dark)             // full-screen: status bar matches too
```

Read it anywhere: `@Environment(\.sliceTheme) private var theme`, then
`theme.accent`, `theme.ink`, `theme.font(.callout, weight: .semibold)`.

## Theme colours

| Group | Colours |
|---|---|
| Brand | `accent`, `accentPressed`, `accentSoft`, `accentEdge`, `onAccent` (text on accent) |
| Surfaces | `canvas` (screen), `surface` (cards), `surfaceAlt`, `line` (hairlines) |
| Text | `ink`, `inkSecondary`, `inkTertiary` |
| States | `success`, `successSoft`, `successInk` (text on success), `successText` (on soft), `danger`, `dangerSoft`, `warning`, `warningSoft` |
| Tiles | `chipBackground`, `chipInk` |
| Fonts | `text`, `display` |

Helpers: `Color(hex:)`, `Color(light:dark:)` (colours or hex strings).

## Components

| Component | Use |
|---|---|
| `Text(…).textStyle(.largeTitle)` | `SliceTextStyle`: `.largeTitle`, `.headline`, `.body`, `.secondary`, `.footnote`, `.pill`; add your own as static members |
| `.buttonStyle(.primary)` | Accent capsule, 52pt, full width. Also `.destructivePrimary`, `PrimaryButtonStyle(role: .dark)` |
| `.buttonStyle(.ghost)` | Outlined secondary capsule |
| `.buttonStyle(.small)` | 36pt capsule; `SmallButtonStyle(prominent: false)` for the soft one |
| `GroupedSection(header:footer:) { … }` | Card of rows, 14pt radius, hairline border |
| `RowDivider()` | Hairline between rows |
| `Row(icon:iconTint:title:meta:value:titleColor:showsChevron:) { trailing }` | List row; `verbatim:` instead of `title:` for user text |
| `FieldRow(label:) { TextField(…) }` | Label + trailing field |
| `IconChip(systemName:tint:size:)` | Rounded symbol tile; `Tint`: `.accent`, `.success`, `.danger`, `.warning`, `.neutral`, `.custom(tile:glyph:)` |
| `Avatar(name:size:)` | Initials in a circle |
| `Pill("Paid", tone: .success)` | 22pt status tag; tones `.neutral`, `.accent`, `.success`, `.successSoft`, `.danger`, `.warning`, `.custom(…)` |
| `ChoiceChip(title:isOn:action:)` | Selectable capsule |
| `Banner(tone:systemImage:text:actionTitle:action:)` | Message box: `.info`, `.ok`, `.warn`, `.error` |
| `DecimalField(_:value:)`, `IntField(_:value:)` | Number fields that save on every keystroke; `$decimal.zeroAsEmpty` |
| `ShareSheet(items:completion:)`, `SharedFile(url:)` | iOS share sheet for `.sheet` |

Used by: Duly (theme from its asset colours; its invoice-specific views such
as the status pill and the "Owed to you" card stay in the app).

---

# SliceUI: Standard screens (0.6.0)

Settings, onboarding and paywall screens every app needs. Their own words
(buttons, headers, paywall terms) are translated in SliceUI's catalog
(Resources/*.lproj: English incl. US spelling, French, German, Spanish for Mexico and Spain);
the app passes its own copy (FAQs, Premium text, headlines).

## AppIdentity

```swift
let app = AppIdentity(name: "Scanly", company: "Slice of Life Ltd", appStoreID: "1234567890",
                      supportEmail: "help@example.com",
                      privacyURL: URL(string: "https://…/privacy/")!, termsURL: URL(string: "https://…/terms/")!)
```

## StandardSettings

```swift
NavigationStack {
    StandardSettings(
        app: app,
        purchases: SettingsPurchases(                         // nil if the app sells nothing
            isPremium: { PurchaseManager.shared.isPremium },
            restore: { await PurchaseManager.shared.restore() },
            upgrade: { PaywallService.shared.gate(Placement.settings) {} },
            premiumText: "Unlimited scans are unlocked.",
            plansText: "Free: 3 scans a day. Premium: unlimited scans and exports.",
            diagnostics: { await PurchaseManager.shared.diagnostics() }),
        analytics: SettingsAnalytics(                          // nil = no switch
            isOn: { AppAnalytics.shared.isEnabled },
            setOn: { AppAnalytics.shared.setConsent($0) },
            askFirst: .init(title: "Help improve Scanly?", message: "…", allow: "Allow", deny: "Don't Allow")),
        help: SettingsHelp(faqs: [.init("Is it free?", "…")], reportTopics: ["Scanning", "Billing"],
                           reportFooter: "We reply within 24 hours."),
        share: SettingsShare(message: "Try Scanly: https://apps.apple.com/app/id1234567890"),
        legalFooter: nil,
        header: nil,            // AnyView, e.g. a plan card
        account: nil,           // AnyView rows above Restore, e.g. Sign in with Apple; nil = no account
        debug: nil
    ) {
        GroupedSection(header: "Scanner") { … }               // the app's own sections first
    }
}
```

Order: header, your sections, Account (account rows, Restore purchases,
Subscription), Help (Help and support, Report a problem, Rate, Share),
Privacy and legal (analytics switch, Privacy Policy, Terms of Use), debug, version line.
Pages it pushes: `HelpPage`, `ReportProblemPage` (Mail with topic, message,
app version and device), `SubscriptionPage` (manage, restore, Apple billing
text), `LegalView`.

Legal text: bundle `terms.txt` and `privacy.txt` in the app (translations
`terms.fr.txt`…); `LegalDocument.terms.blocks`, `LegalBlock.parse`.

## Onboarding shell

```swift
OnboardingShell(step: 2, of: 4, showsProgress: true) {
    OnboardingTitle("What do you scan?")
    OnboardingLead("We'll set things up for you.")
    OnboardingChoice(icon: "qrcode", title: Text("QR codes"), detail: Text("Links, Wi-Fi, contacts"),
                     isSelected: choice == .qr) { choice = .qr }
    OnboardingField("Name") { TextField("Your name", text: $name) }
} footer: {
    Button("Continue") { next() }.buttonStyle(.primary)
}
```

End with the soft paywall from SlicePurchases: `PaywallService.shared.gate(Placement.onboardingEnd, onFinished: { … }) {}`.

## PaywallTemplate

```swift
PaywallContent(
    headline: "Unlock unlimited scans",                     // per placement
    subtitle: "**Free:** 3 scans a day.",                    // context line (Markdown)
    benefits: ["Unlimited scans", "No ads", "Export to PDF"],
    headerBackground: .black, headerForeground: .white,      // nil = theme canvas + ink
    showsTrialTimeline: true, trialReminder: false,          // reminder only if one is really sent
    closeButtonDelay: .seconds(4),                           // hard paywall; swipe-down blocked until then
    termsURL: app.termsURL, privacyURL: app.privacyURL)
```

With SlicePurchases (wired to `PurchaseManager`):

```swift
.sheet(item: $paywalls.nativePaywall) { request in
    PaywallTemplate(request: request, content: content(for: request.placement))
        .onDisappear { request.onClose() }
}
```

Without it: `PaywallTemplate(content:plans:loadPlans:buy:restore:onUnlock:)`
with `PaywallPlanInfo` (`.week`, `.month`, `.year`, `.lifetime`, price,
monthly price, trial days) and `PaywallOutcome`.

Every paywall shows: the plans (yearly selected first), the price and
renewal terms with the trial end date, one buy button ("Start 3-day free
trial" / "Continue"), Restore, Terms and Privacy.
