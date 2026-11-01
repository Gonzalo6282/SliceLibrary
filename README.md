# SliceLibrary

Swift packages shared by every Slice of Life app:

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

1. File > Add Package Dependencies… > `https://github.com/Gonzalo6282/SliceLibrary`
2. Dependency rule: **Up to Next Minor Version** from the version you tested
   (for example 0.2.0 ..< 0.3.0). Upgrading is a deliberate step.
3. Add only the products the app uses, for example `SliceQR` and `SliceRating`.

The repo is public, so neither Xcode nor the app's CI needs a token.

## Products

| Product | Since | What it is |
|---|---|---|
| `SliceQR` | 0.2.0 | Crisp QR code images ([README](Sources/SliceQR/README.md)) |
| `SliceRating` | 0.2.0 | App Store rating prompt at spaced happy moments ([README](Sources/SliceRating/README.md)) |
| `SliceKit`, `SliceUI` | 0.1.0 | Umbrella names; modules arrive as their own products |

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
3. Open a pull request (CI runs) and merge it. The "Tag release" workflow then
   tags main with the new version (for example v0.2.0).
4. In each app that should get it: raise the package version, run its tests.
