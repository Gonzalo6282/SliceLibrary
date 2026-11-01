# SliceUI: Theme + Components

The shared look. Every component reads colours and fonts from a `SliceTheme`
the app provides, so the same code looks like each app.

## 1. Make your themes

```swift
import SliceUI

extension SliceTheme {
    /// Follows light/dark mode.
    static let main = SliceTheme.system(accent: Color(light: "#2B6BFF", dark: "#5C8DFF"))
    /// Always dark: lime on black (camera, onboarding, paywall).
    static let camera = SliceTheme.dark(accent: Color(hex: "#7FEE64"))  // onAccent defaults to black
}
```

Need full control? `SliceTheme(appearance:accent:…)` takes every colour
(asset-catalog colours work and follow light/dark by themselves). Unset soft
colours are made from the accent.

Fonts: `text:` and `display:` take `.system`, `.system(design: .rounded)` or
`.custom("Inter-Regular", weights: [.bold: "Inter-Bold"])`. Sizes follow Dynamic Type.

## 2. Apply them

```swift
@main struct MyApp: App {
    init() { SliceTheme.appDefault = .main }   // used by sheets, previews, UIKit-hosted views
    var body: some Scene {
        WindowGroup { RootView().sliceTheme(.main) }
    }
}

CameraView()
    .sliceTheme(.camera)                     // this subtree is dark, lime accent
    .preferredColorScheme(.dark)             // full-screen: status bar matches too
```

Read it anywhere: `@Environment(\.sliceTheme) private var theme`, then
`theme.accent`, `theme.ink`, `theme.font(.callout, weight: .semibold)`.

## Theme colours

| Group | Colours |
|---|---|
| Brand | `accent`, `accentPressed`, `accentSoft`, `accentEdge`, `onAccent` (text on accent) |
| Surfaces | `canvas` (screen), `surface` (cards), `surfaceAlt`, `line` (hairlines) |
| Text | `ink`, `inkSecondary`, `inkTertiary` |
| States | `success`, `successSoft`, `successInk` (text on success), `successText` (on soft), `danger`, `dangerSoft`, `warning`, `warningSoft` |
| Tiles | `chipBackground`, `chipInk` |
| Fonts | `text`, `display` |

Helpers: `Color(hex:)`, `Color(light:dark:)` (colours or hex strings).

## Components

| Component | Use |
|---|---|
| `Text(…).textStyle(.largeTitle)` | `SliceTextStyle`: `.largeTitle`, `.headline`, `.body`, `.secondary`, `.footnote`, `.pill`; add your own as static members |
| `.buttonStyle(.primary)` | Accent capsule, 52pt, full width. Also `.destructivePrimary`, `PrimaryButtonStyle(role: .dark)` |
| `.buttonStyle(.ghost)` | Outlined secondary capsule |
| `.buttonStyle(.small)` | 36pt capsule; `SmallButtonStyle(prominent: false)` for the soft one |
| `GroupedSection(header:footer:) { … }` | Card of rows, 14pt radius, hairline border |
| `RowDivider()` | Hairline between rows |
| `Row(icon:iconTint:title:meta:value:titleColor:showsChevron:) { trailing }` | List row; `verbatim:` instead of `title:` for user text |
| `FieldRow(label:) { TextField(…) }` | Label + trailing field |
| `IconChip(systemName:tint:size:)` | Rounded symbol tile; `Tint`: `.accent`, `.success`, `.danger`, `.warning`, `.neutral`, `.custom(tile:glyph:)` |
| `Avatar(name:size:)` | Initials in a circle |
| `Pill("Paid", tone: .success)` | 22pt status tag; tones `.neutral`, `.accent`, `.success`, `.successSoft`, `.danger`, `.warning`, `.custom(…)` |
| `ChoiceChip(title:isOn:action:)` | Selectable capsule |
| `Banner(tone:systemImage:text:actionTitle:action:)` | Message box: `.info`, `.ok`, `.warn`, `.error` |
| `DecimalField(_:value:)`, `IntField(_:value:)` | Number fields that save on every keystroke; `$decimal.zeroAsEmpty` |
| `ShareSheet(items:completion:)`, `SharedFile(url:)` | iOS share sheet for `.sheet` |

Used by: Duly (theme from its asset colours; its invoice-specific views such
as the status pill and the "Owed to you" card stay in the app).
