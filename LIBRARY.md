# Library index

Read this before writing new code in any app. **Status:** `planned` = not
moved yet (still lives in the app named), `in library` = import it.

## SliceKit (engine)

| Module | What it does | Status | Comes from (Duly file) | Used by |
|---|---|---|---|---|
| SlicePurchases | RevenueCat set-up, Premium state from RevenueCat or Apple's verified transactions, restore, Superwall paywalls with a native fallback, placements | planned | `Services/PurchaseManager.swift`, `Services/PaywallService.swift` | Duly |
| SliceAnalytics | Firebase Analytics + Crashlytics + Remote Config behind consent, consent question, event logging with app version and country | planned | `Services/AppAnalytics.swift` (events stay in each app) | Duly |
| SliceAccount | Optional Sign in with Apple via Firebase, account deletion with Apple token revocation, clear error messages | planned | `Services/AccountService.swift` | Duly |
| SliceStorage | SwiftData + CloudKit container with local fallback, "waiting for iCloud" on reinstall, backup status | planned | `Data/ModelContainerFactory.swift`, `Data/CloudImportWatcher.swift` | Duly |
| SlicePDF | PDF page drawing helpers, preview, share item (off the main thread), watermark, "Made with …" line, page images | planned | `PDF/PDFRenderer.swift` (primitives only), `Features/Sending/SharePDF.swift`, `PDF/MadeWithDuly.swift` | Duly |
| SliceQR | Crisp QR code images | planned | `PDF/PDFRenderer.swift` (`QRCode`) | Duly |
| SliceRating | Rating prompt at spaced happy moments, once per version | planned | `Services/ReviewPrompt.swift` | Duly |
| SliceNotifications | Local notifications rebuilt from data, own prefix, permission only when the user turns something on | planned (v1.1) | `Services/Reminders.swift` | Duly v1.1 |
| SliceFormats | Money, dates and paper size by locale | planned | `InvoiceKit/MoneyFormat.swift`, `Data/Business+Formatting.swift` (generic parts) | Duly |
| SliceSharing | "Share the app" message and share-sheet events | planned | `Features/Settings/SettingsView.swift` (`ShareDuly`) | Duly |

## SliceUI (UI kit)

| Module | What it does | Status | Comes from (Duly file) | Used by |
|---|---|---|---|---|
| Theme | Colour, type and spacing tokens, set by each app (light and dark) | planned | `DesignSystem/Typography.swift`, colour assets | Duly |
| Components | Buttons, rows, grouped sections, chips, banners, field rows, status pills, empty states | planned | `DesignSystem/*.swift` | Duly |
| StandardSettings | Settings screen: Rate, Share, Restore purchases, Subscription, Account (Sign in with Apple, Delete account), Help, Report a problem, Terms, Privacy, analytics switch | planned | `Features/Settings/SettingsView.swift`, `AccountRows.swift`, `LegalView.swift`, `SimpleSettingsPages.swift` (generic parts) | Duly |
| Onboarding | Step-by-step onboarding shell with progress and a soft paywall at the end | planned | `Features/Onboarding/OnboardingView.swift` (shell only) | Duly |
| PaywallTemplate | Native fallback paywall (plans, trial wording, legal links) | planned | `Features/Paywall/NativePaywallView.swift` | Duly |
| ScreenshotFrames | App Store screenshot frames: headline + feature line + device frame, photo card (Python, `Tools/screenshots`) | planned | Duly's frame scripts | Duly |

Stays in each app (never moves): document models, invoice layout and
templates, tax logic (InvoiceKit), app copy, event names, keys.
