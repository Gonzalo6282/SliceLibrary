# SlicePurchases

Premium state, plans, buying and paywalls:

- **RevenueCat** for purchases (StoreKit 2 directly when there's no key).
  Premium = RevenueCat's entitlement OR Apple's own verified transactions,
  so a purchase unlocks even if RevenueCat lags.
- **Superwall** paywalls, buying through RevenueCat (RevenueCat is the
  purchase controller), and identified with the same user ID.
- **Native fallback**: when Superwall isn't set up, fails, or has no campaign
  for a placement, the app's own paywall shows instead. The library sets a
  request; the app presents it with its own view.
- **Continue after buying**: `gate` runs the action the user tapped once
  they've bought or restored (hard paywalls), and never if they close it.

No keys in the library: the app passes them in.

## Set up (at launch, in this order)

```swift
import SlicePurchases

enum Placement: String, PaywallPlacementType {
    case scan, export, onboardingEnd = "onboarding_end"
}

PurchaseManager.shared.configure(PurchaseConfig(
    revenueCatAPIKey: AppKey.infoPlist("RevenueCatAPIKey", prefix: "appl_"),
    entitlement: "pro",
    productIDs: ["qr_pro_yearly", "qr_pro_weekly"],          // display order
    forcePremium: ProcessInfo.processInfo.arguments.contains("-premium")
))
PaywallService.shared.onPaywallShown = { placement, paywallID in
    Analytics.log("paywall_view", ["placement": placement, "paywall_id": paywallID])
}
PaywallService.shared.configure(superwallAPIKey: AppKey.infoPlist("SuperwallAPIKey", prefix: "pk_"))
```

## Gate a Premium action

```swift
PaywallService.shared.gate(Placement.scan) {
    startScan()            // runs now if Premium, or after they buy/restore
}

// Something to do once the paywall has closed, bought or not:
PaywallService.shared.gate(Placement.onboardingEnd, onFinished: { askForNotifications() }) {}
```

Tip: add a typed overload so call sites can write `gate(.scan)`:

```swift
extension PaywallService {
    func gate(_ p: Placement, params: [String: Any] = [:], onFinished: (() -> Void)? = nil, feature: @escaping () -> Void) {
        gate(p as any PaywallPlacementType, params: params, onFinished: onFinished, feature: feature)
    }
}
```

## Show the app's own paywall when asked

```swift
@State private var paywalls = PaywallService.shared

RootView()
    .sheet(item: $paywalls.nativePaywall) { request in
        MyPaywall(placement: request.placement as? Placement, onUnlock: request.onUnlock)
            .onDisappear { request.onClose() }
    }
```

Inside the paywall, use `PurchaseManager.shared.plans`, `purchase(_:)` and
`restore()`; call `onUnlock()` after `.purchased` or a successful restore.

## Firebase / Google Analytics link

For RevenueCat's Firebase integration, after both are configured (and again when
the user changes the analytics switch):

```swift
PurchaseManager.shared.setFirebaseAppInstanceID(AppAnalytics.shared.appInstanceID)
```

## API

| Call | What it does |
|---|---|
| `PurchaseConfig(revenueCatAPIKey:entitlement:productIDs:forcePremium:adServicesAttribution:logPrefix:)` | Launch settings |
| `AppKey.infoPlist(_:prefix:)` | Reads a key from Info.plist; nil if empty or unexpanded |
| `PurchaseManager.shared` | `isPremium`, `usesRevenueCat`, `plans`, `configure(_:)`, `loadPlans()`, `purchase(_:) -> PurchaseOutcome`, `restore() -> Bool`, `refreshStoreKitEntitlement()`, `logIn(userID:)`, `logOut()`, `setFirebaseAppInstanceID(_:)`, `diagnostics()` |
| `PurchaseManager.Plan` | `id`, `period` (`.week`, `.month`, `.year`, `.lifetime`, `.days(n)`), `price`, `monthlyPrice` (yearly), `trialDays`, `isYearly` |
| `PurchaseManager.PurchaseOutcome` | `.purchased`, `.cancelled`, `.pending`, `.failed(message)` |
| `PaywallService.shared` | `configure(superwallAPIKey:)`, `gate(_:params:onFinished:feature:)`, `nativePaywall`, `onPaywallShown`, `identify(userID:)`, `resetIdentity()`, `usesSuperwall`, `statusDescription` |
| `PaywallPlacementType` | Protocol for the app's placement enum (`String` raw values work automatically) |
| `PaywallService.NativePaywallRequest` | `placement`, `placementName`, `onUnlock`, `onClose` |

Requirements: RevenueCat 5.96+ and Superwall 4.18.x (same ranges as Duly).
Superwall is iOS-only; on macOS the app's own paywall is always used.

Used by: Duly (entitlement `pro`, 8 placements, its own native paywall).
