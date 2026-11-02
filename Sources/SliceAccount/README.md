# SliceAccount

Optional **Sign in with Apple** through Firebase Auth, and **Delete account**
with Apple token revocation (App Store rule 5.1.1(v)). The Firebase user ID
becomes the RevenueCat app user ID, so Premium follows the user to a new phone.
Clear messages for Apple's errors (including the "reset Apple's link" help for
error 1000). Translated: English, French, German, Spanish (Mexico, Spain).

## Needs (in the app)

- `GoogleService-Info.plist`, and Firebase started first (`AppAnalytics.shared.configure` from SliceAnalytics does it).
- Firebase console: Authentication > Sign-in method > **Apple** enabled.
- Xcode: **Sign in with Apple** capability.
- Firebase 12.19.x (same pin as SliceAnalytics).

## Use

```swift
import SliceAccount

// Launch, after analytics:
AccountService.shared.start(AccountConfig(appName: "Scanly"))   // linksPurchases: true by default

// Settings (StandardSettings from SliceUI):
StandardSettings(…, account: AnyView(AccountRows())) { … }

// Anywhere else (e.g. a "sign in to keep your Premium" prompt):
SignInWithAppleButton(.signIn) { AccountService.shared.prepare($0) } onCompletion: { result in
    Task {
        do { try await AccountService.shared.complete(result) }
        catch { message = AccountService.report(error, step: "Sign in") }   // nil = user cancelled
    }
}
```

## API

| Call | What it does |
|---|---|
| `AccountConfig(appName:linksPurchases:logPrefix:)` | Launch settings |
| `AccountService.shared` | `start(_:)`, `isAvailable`, `isSignedIn`, `userID`, `email`, `prepare(_:)`, `complete(_:)`, `signOut()`, `deleteAccount(with:)` |
| `AccountService.report(_:step:)` | Alert text for an error (nil when cancelled); full detail in the console and in debug alerts |
| `AccountService.appleResetHelp(appName:)`, `describe(_:)`, `randomNonce()`, `sha256(_:)` | Helpers |
| `AccountRows(account:deleteExplanation:)` | Settings rows: Sign in with Apple / Signed in + Delete account / "Available once set up" |
| `DeleteAccountSheet(account:explanation:failed:)` | Confirm with a fresh Apple sign-in, then delete |

`deleteExplanation`: what deleting does in your app's words, e.g. "…Your scans
stay on this device…" (looked up in the app's own strings). Nil = a generic one.

Used by: Duly (Settings account rows and the first-send sign-in prompt).
