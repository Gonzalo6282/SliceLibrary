# Library index

Read this before writing new code in any app. **Status:** `planned` = not
moved yet (still lives in the app named), `in library` = import it.

## SliceKit (engine)

| Module | What it does | Status | Comes from (Duly file) | Used by |
|---|---|---|---|---|
| SlicePurchases | RevenueCat set-up, Premium from RevenueCat or Apple's verified transactions, plans, buy, restore, Superwall paywalls buying through RevenueCat, native fallback request, `gate` that continues the tapped action after buying; keys, entitlement and placements from the app; `import SlicePurchases` | **in library** (0.4.0) | `Services/PurchaseManager.swift`, `Services/PaywallService.swift` | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| SliceAnalytics | Firebase Analytics + Crashlytics + Remote Config behind consent (ask everyone, or only in the EEA/UK/Switzerland), consent prompt, event logging with app version and country, Remote Config defaults; events stay in each app (`AnalyticsEventType`); Firebase 12.19.x; `import SliceAnalytics` | **in library** (0.5.0) | `Services/AppAnalytics.swift` | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| SliceAccount | Optional Sign in with Apple via Firebase, Delete account with Apple token revocation, purchases follow the account, clear error messages, `AccountRows`/`DeleteAccountSheet` for Settings; `import SliceAccount` | **in library** (0.7.0) | `Services/AccountService.swift`, `Features/Settings/AccountRows.swift` | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| SliceStorage | SwiftData + CloudKit container with local fallback, "waiting for iCloud" on reinstall, backup status | planned | `Data/ModelContainerFactory.swift`, `Data/CloudImportWatcher.swift` | Duly |
| SlicePDF | PDF page drawing helpers, preview, share item (off the main thread), watermark, "Made with …" line, page images | planned | `PDF/PDFRenderer.swift` (primitives only), `Features/Sending/SharePDF.swift`, `PDF/MadeWithDuly.swift` | Duly |
| SliceQR | Crisp QR code images for any text, sharp in PDFs; `import SliceQR` | **in library** (0.2.0) | `PDF/PDFRenderer.swift` (`QRCode`) | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| SliceRating | Rating prompt at spaced happy moments from a schedule the app gives, once per version; `import SliceRating` | **in library** (0.2.0) | `Services/ReviewPrompt.swift` | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| SliceNotifications | Local notifications rebuilt from data, own prefix, permission only when the user turns something on | planned (v1.1) | `Services/Reminders.swift` | Duly v1.1 |
| SliceFormats | Money, dates and paper size by locale | planned | `InvoiceKit/MoneyFormat.swift`, `Data/Business+Formatting.swift` (generic parts) | Duly |
| SliceSharing | "Share the app" row, share sheet and its events: part of StandardSettings (`SettingsShare`, `ShareSheet`) | **in library** (0.6.0, in SliceUI) | `Features/Settings/SettingsView.swift` (`ShareDuly`) | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |

## SliceUI (UI kit)

| Module | What it does | Status | Comes from (Duly file) | Used by |
|---|---|---|---|---|
| Theme | `SliceTheme`: colours and fonts set by each app; follows light/dark or always dark/light; `.sliceTheme(_:)`, `SliceTheme.appDefault`, `Color(hex:)`, `Color(light:dark:)`; `import SliceUI` | **in library** (0.3.0) | `DesignSystem/Typography.swift`, colour assets | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| Components | Text styles, primary/ghost/small buttons, `GroupedSection`, `Row`, `FieldRow`, `IconChip`, `Avatar`, `Pill`, `ChoiceChip`, `Banner`, `DecimalField`/`IntField`, `ShareSheet`; `import SliceUI` | **in library** (0.3.0) | `DesignSystem/*.swift` (not HeroCard, StatusPill mapping, AddressField, PhotoAccess: Duly-specific) | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| StandardSettings | Settings screen: the app's sections, optional account rows (slot), Restore purchases, Subscription page, Help page, Report a problem (Mail), Rate, Share, analytics switch, Privacy/Terms (bundled text), version line; `AppIdentity`; `import SliceUI` | **in library** (0.6.0) | `Features/Settings/SettingsView.swift`, `LegalView.swift`, `SimpleSettingsPages.swift` (generic parts) | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| Onboarding | `OnboardingShell` (dots, scrolling content, footer bar), `OnboardingTitle`, `OnboardingLead`, `OnboardingField`, `OnboardingChoice`; the soft paywall is a `gate` at the end; `import SliceUI` | **in library** (0.6.0) | `Features/Onboarding/OnboardingView.swift` (shell only) | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| PaywallTemplate | Native paywall: headline + context line per placement, benefits, week/month/year/lifetime plans, trial timeline, delayed close button, Restore/Terms/Privacy; `PaywallTemplate(request:content:)` with SlicePurchases | **in library** (0.6.0) | `Features/Paywall/NativePaywallView.swift` | Duly (on branch `library-migration`, merged after Duly 1.1.1 ships) |
| ScreenshotFrames | App Store screenshot frames: headline + feature line + device frame, photo card (Python, `Tools/screenshots`) | planned | Duly's frame scripts | Duly |

Stays in each app (never moves): document models, invoice layout and
templates, tax logic (InvoiceKit), app copy, event names, keys.
