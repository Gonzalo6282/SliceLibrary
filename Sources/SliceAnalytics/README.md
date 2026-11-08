# SliceAnalytics

Firebase Analytics, Crashlytics and Remote Config behind the user's consent.
No advertising ID, ever. Each app keeps its own event list; the library only
knows the protocol.

Firebase is pinned to **12.19.x** (newer needs a newer Xcode than 26.1.1).
The app adds its own `GoogleService-Info.plist`; without it nothing starts and
nothing is sent. Crashlytics' dSYM upload run script stays in the app.

## Set up (at launch, before purchases)

```swift
import SliceAnalytics

enum Event: String, AnalyticsEventType {
    case scanSaved = "scan_saved"
    case paywallView = "paywall_view"
}

AppAnalytics.shared.configure(AnalyticsConfig(
    consentKey: "analyticsEnabled",            // the Settings switch uses the same key
    consentPolicy: .askInEuropeOnly,           // or .askEveryone
    remoteDefaults: ["onboarding_soft_paywall": .bool(true)]
))
```

### Consent policies

| Policy | EEA, UK, Switzerland (or unknown country) | Everyone else |
|---|---|---|
| `.askEveryone` | Off until they tap Allow | Off until they tap Allow |
| `.askInEuropeOnly` | Off until they tap Allow | On until they turn it off in Settings |

The country is the App Store storefront (the device region until it loads).

## Ask the question (your wording, your alert)

```swift
@State private var consent = ConsentPrompt.shared

content
    .alert("Help improve the app?", isPresented: $consent.isShowing) {
        Button("Allow") { AppAnalytics.shared.setConsent(true) }
        Button("Don't Allow", role: .cancel) { AppAnalytics.shared.setConsent(false) }
    } message: { Text("Anonymous usage data and crash reports…") }

// When the user is in the app with nothing else on screen (not during onboarding or over a paywall):
ConsentPrompt.shared.askIfNeeded()
```

Settings switch: `Toggle(isOn: Binding(get: { AppAnalytics.shared.isEnabled }, set: { AppAnalytics.shared.setConsent($0) }))`.

## Log

```swift
AppAnalytics.shared.log(Event.scanSaved, ["type": "url"])   // + app_version and country
AppAnalytics.shared.record(error)                           // Crashlytics non-fatal
AppAnalytics.shared.remoteBool("onboarding_soft_paywall")
```

Tip: a typed overload lets call sites write `log(.scanSaved)`:

```swift
extension AppAnalytics {
    func log(_ e: Event, _ p: [String: Any] = [:]) { log(e as any AnalyticsEventType, p) }
}
```

## API

| Call | What it does |
|---|---|
| `AnalyticsConfig(consentKey:consentPolicy:remoteDefaults:appVersion:addsCountry:)` | Launch settings |
| `ConsentPolicy` | `.askEveryone`, `.askInEuropeOnly` |
| `ConsentRegion.requiresConsent(countryCode:)` | EEA + UK + Switzerland check (alpha-2 or alpha-3) |
| `AppAnalytics.shared` | `configure(_:)`, `isConfigured`, `storedConsent`, `isEnabled`, `needsConsentPrompt`, `requiresConsent`, `setConsent(_:)`, `log(_:_:)`, `record(_:)`, `remoteBool/remoteString/remoteNumber(_:)`, `country`, `appInstanceID` (nil without Firebase or consent) |
| `AppAnalytics.hasFirebaseFile` | `GoogleService-Info.plist` is in the bundle |
| `AnalyticsEventType` | Protocol for the app's event enum (`String` raw values work automatically) |
| `RemoteValue` | `.bool`, `.int`, `.double`, `.string` defaults |
| `ConsentPrompt.shared` | `askIfNeeded()`, `isShowing` |

Used by: Duly (`.askEveryone`, its 15 events, key `analyticsEnabled`).
