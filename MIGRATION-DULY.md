# Moving Duly's reusable parts into the library

Start only after Duly v1.0 is approved and live (rule 1). One module per pull
request; Duly must behave exactly the same after each step, with its CI green.

Order (smallest risk first, most reuse for app 2, QR Scanner):

1. ~~**SliceQR** and **SliceRating**~~: done in 0.2.0. The repo is public, so
   Duly's CI needs no token.
2. ~~**SliceUI Theme + Components**~~: done in 0.3.0 (`SliceTheme.duly` in
   Duly from its asset colours).
3. ~~**SlicePurchases**~~: done in 0.4.0. The native paywall view stays in
   Duly until PaywallTemplate (step 7).
4. ~~**SliceAnalytics**~~: done in 0.5.0 (Duly keeps `.askEveryone` and its
   event enum).
5. ~~**SliceUI StandardSettings**~~: done in 0.6.0 (account rows are a slot;
   **SliceAccount** still to move).
6. **SliceStorage**: the container factory takes the app's schema and
   CloudKit container ID.
7. **SlicePDF**, **SliceFormats**, **SliceSharing**; ~~**SliceUI Onboarding /
   PaywallTemplate**~~ done in 0.6.0.
8. **SliceNotifications** after Duly v1.1 has shipped.
9. **ScreenshotFrames**: move the Python frame scripts into `Tools/screenshots`.

For each step:
- Copy the code in, remove anything named Duly/Invoice, add a README and tests.
- Tag a release (0.x.0), point Duly at it, delete Duly's copy, run Duly's tests
  on iPhone and iPad.
- Update LIBRARY.md (status `in library`, used by Duly).
