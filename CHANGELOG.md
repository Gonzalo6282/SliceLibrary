# Changelog

## 0.5.0
- **SliceAnalytics** (from Duly): `AppAnalytics` (Firebase Analytics,
  Crashlytics, Remote Config; ad storage always denied), consent with
  `.askEveryone` or `.askInEuropeOnly` (EEA, UK, Switzerland), `ConsentPrompt`,
  `AnalyticsEventType` for each app's events, `RemoteValue` defaults. Adds
  Firebase 12.19.x (iOS).

## 0.4.0
- **SlicePurchases** (from Duly): `PurchaseManager` (RevenueCat or StoreKit 2,
  Premium from RevenueCat OR Apple's verified transactions, plans, buy,
  restore, account link, diagnostics), `PaywallService` (Superwall buying
  through RevenueCat, native fallback request, `gate` that continues the
  tapped action after buying), `PurchaseConfig`, `AppKey`,
  `PaywallPlacementType`. Adds RevenueCat 5.96+ and Superwall 4.18.x.

## 0.3.0
- **SliceUI Theme**: `SliceTheme` (colours, fonts, light/dark/always-dark),
  `.sliceTheme(_:)`, `SliceTheme.appDefault`, `.system(accent:)` and
  `.dark(accent:)` presets, `SliceFontFamily`, `Color(hex:)`, `Color(light:dark:)`.
- **SliceUI Components** (from Duly): `SliceTextStyle` + `.textStyle(_:)`,
  primary/ghost/small button styles, `GroupedSection`, `RowDivider`, `Row`,
  `FieldRow`, `IconChip`, `Avatar`, `Pill`, `ChoiceChip`, `Banner`,
  `DecimalField`, `IntField`, `zeroAsEmpty`, `ShareSheet`, `SharedFile`.

## 0.2.0
- **SliceQR**: crisp QR code images (`SliceQR.cgImage`, `SliceQR.image`), from Duly.
- **SliceRating**: App Store rating prompt at spaced happy moments
  (`RatingPrompt`, `RatingStep`, `RatingMoment`), from Duly.
- The repo is public: apps no longer need a `SLICE_LIBRARY_TOKEN`.

## 0.1.0
- Empty SliceKit and SliceUI products, tests, CI, LIBRARY.md index and the plan
  for moving Duly's reusable parts in (after Duly v1.0 is live).
