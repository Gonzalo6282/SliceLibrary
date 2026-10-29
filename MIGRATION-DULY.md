# Moving Duly's reusable parts into the library

Start only after Duly v1.0 is approved and live (rule 1). One module per pull
request; Duly must behave exactly the same after each step, with its CI green.

Order (smallest risk first, most reuse for app 2, QR Scanner):

1. **SliceQR** and **SliceRating**: tiny, no dependencies. Proves the set-up
   (private package in Xcode and in Duly's CI with `SLICE_LIBRARY_TOKEN`).
2. **SliceUI Theme + Components**: tokens become a `SliceTheme` the app
   provides; Duly passes its navy/green/brand colours.
3. **SlicePurchases**: RevenueCat + Superwall + native fallback. Keys and the
   entitlement name come from the app.
4. **SliceAnalytics**: consent + Firebase; each app keeps its own event enum
   (a protocol in the library).
5. **SliceAccount** and **SliceUI StandardSettings**: together, since
   Settings shows the account rows.
6. **SliceStorage**: the container factory takes the app's schema and
   CloudKit container ID.
7. **SlicePDF**, **SliceFormats**, **SliceSharing**, **SliceUI Onboarding /
   PaywallTemplate**.
8. **SliceNotifications** after Duly v1.1 has shipped.
9. **ScreenshotFrames**: move the Python frame scripts into `Tools/screenshots`.

For each step:
- Copy the code in, remove anything named Duly/Invoice, add a README and tests.
- Tag a release (0.x.0), point Duly at it, delete Duly's copy, run Duly's tests
  on iPhone and iPad.
- Update LIBRARY.md (status `in library`, used by Duly).
