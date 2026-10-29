# SliceLibrary

Private Swift packages shared by every Slice of Life app:

- **SliceKit**: the engine (purchases and paywalls, analytics and consent,
  Sign in with Apple and account deletion, iCloud storage, PDF render/preview/
  share/watermark, payment QR codes, rating prompt, notifications, local
  formats).
- **SliceUI**: the UI kit (design tokens themed per app, buttons, cards, rows,
  empty states, the standard Settings screen, onboarding and paywall
  templates, App Store screenshot frames).

Before writing new code in an app, read [LIBRARY.md](LIBRARY.md): reuse first,
write new only if nothing fits.

## Add it to an app

1. Xcode > Settings > Accounts: add the GitHub account that can read this repo.
2. File > Add Package Dependencies… > `https://github.com/Gonzalo6282/SliceLibrary`
3. Dependency rule: **Up to Next Minor Version** from the version you tested
   (for example 0.3.0 ..< 0.4.0). Upgrading is a deliberate step.
4. Add only the products the app uses (SliceKit, SliceUI, and later the single
   modules, for example `SlicePurchases`).
5. CI of the app: the app repo needs a read-only token for this repo, stored as
   the secret `SLICE_LIBRARY_TOKEN`, and this step before building:
   ```yaml
   - run: git config --global url."https://x-access-token:${{ secrets.SLICE_LIBRARY_TOKEN }}@github.com/".insteadOf "https://github.com/"
   ```

## Rules (Automation Master Plan, Phase 5)

1. **Build it in the app first, then move it.** A feature comes in only after
   it works in a shipped app. Nothing is written "just in case".
2. **No app names or colours inside the library.** Everything is themed from
   the app (`SliceTheme`, `AppIdentity`).
3. **Every module has tests and a short README**: what it does, how to call
   it, one example.
4. **LIBRARY.md lists every module**, what it does and which apps use it.
5. **Versioned releases.** Tag `vMAJOR.MINOR.PATCH`; each app pins a version.
   Breaking change = new minor while we're on 0.x, new major after 1.0.
6. **Security check before each release** (claude-security), same as the apps.
7. **Keys never live here.** Apps pass their own RevenueCat, Superwall and
   Firebase settings in at start-up.

## Release a version

1. Update `CHANGELOG.md` and the `version` constants.
2. Run the security check.
3. Open a pull request (CI runs), merge, then tag: `git tag v0.2.0 && git push --tags`.
4. In each app that should get it: raise the package version, run its tests.
