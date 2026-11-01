import SwiftUI

/// An app's colours and fonts. Every SliceUI component reads them from the
/// environment, so each app (or each part of an app) looks like itself.
///
/// Colours can follow light and dark mode (`Color(light:dark:)`, asset-catalog
/// colours) or be fixed; `appearance` pins the subtree to light or dark.
///
/// ```swift
/// // Follows the system:
/// let main = SliceTheme.system(accent: Color(hex: "#3D7BFF"))
/// // Always dark, lime on black:
/// let camera = SliceTheme.dark(accent: Color(hex: "#7FEE64"))
///
/// ContentView().sliceTheme(main)
/// CameraView().sliceTheme(camera)
/// ```
public struct SliceTheme: Sendable {
    /// Light, dark, or following the system.
    public enum Appearance: Sendable, Hashable {
        case system, light, dark

        /// The colour scheme to force, or nil to follow the system.
        public var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    public var appearance: Appearance

    // Brand
    /// Main actions, links, selected states.
    public var accent: Color
    /// Accent while pressed.
    public var accentPressed: Color
    /// Soft accent background (selected chip, info banner, small secondary button).
    public var accentSoft: Color
    /// Accent border (ghost button, selected chip).
    public var accentEdge: Color
    /// Text and icons on `accent` (white on indigo, black on lime).
    public var onAccent: Color

    // Surfaces
    /// Screen background behind cards.
    public var canvas: Color
    /// Cards and grouped sections.
    public var surface: Color
    /// Secondary surface (unselected chips, wells).
    public var surfaceAlt: Color
    /// Hairlines and borders.
    public var line: Color

    // Text
    public var ink: Color
    public var inkSecondary: Color
    public var inkTertiary: Color

    // States
    /// Positive: paid, done, saved.
    public var success: Color
    public var successSoft: Color
    /// Text on `success`.
    public var successInk: Color
    /// Positive text or icons on `successSoft`.
    public var successText: Color
    public var danger: Color
    public var dangerSoft: Color
    public var warning: Color
    public var warningSoft: Color

    // Icon tiles and avatars
    public var chipBackground: Color
    public var chipInk: Color

    // Fonts
    /// Body text, rows, buttons.
    public var text: SliceFontFamily
    /// Big titles and numbers (``SliceTextStyle`` with `display: true`).
    public var display: SliceFontFamily

    public init(
        appearance: Appearance = .system,
        accent: Color,
        accentPressed: Color? = nil,
        accentSoft: Color? = nil,
        accentEdge: Color? = nil,
        onAccent: Color = .white,
        canvas: Color,
        surface: Color,
        surfaceAlt: Color,
        line: Color,
        ink: Color,
        inkSecondary: Color,
        inkTertiary: Color,
        success: Color,
        successSoft: Color? = nil,
        successInk: Color = .black,
        successText: Color? = nil,
        danger: Color,
        dangerSoft: Color? = nil,
        warning: Color,
        warningSoft: Color? = nil,
        chipBackground: Color? = nil,
        chipInk: Color? = nil,
        text: SliceFontFamily = .system,
        display: SliceFontFamily? = nil
    ) {
        self.appearance = appearance
        self.accent = accent
        self.accentPressed = accentPressed ?? accent.opacity(0.85)
        self.accentSoft = accentSoft ?? accent.opacity(0.12)
        self.accentEdge = accentEdge ?? accent.opacity(0.35)
        self.onAccent = onAccent
        self.canvas = canvas
        self.surface = surface
        self.surfaceAlt = surfaceAlt
        self.line = line
        self.ink = ink
        self.inkSecondary = inkSecondary
        self.inkTertiary = inkTertiary
        self.success = success
        self.successSoft = successSoft ?? success.opacity(0.16)
        self.successInk = successInk
        self.successText = successText ?? success
        self.danger = danger
        self.dangerSoft = dangerSoft ?? danger.opacity(0.12)
        self.warning = warning
        self.warningSoft = warningSoft ?? warning.opacity(0.14)
        self.chipBackground = chipBackground ?? self.accentSoft
        self.chipInk = chipInk ?? accent
        self.text = text
        self.display = display ?? text
    }

    /// A font for a text style in the body family: `theme.font(.callout, weight: .semibold)`.
    public func font(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        text.font(style, weight: weight)
    }
}

extension SliceTheme {
    /// Follows light and dark mode, with iOS-like greys around your accent.
    public static func system(
        accent: Color = .blue, onAccent: Color = .white, text: SliceFontFamily = .system, display: SliceFontFamily? = nil
    ) -> SliceTheme {
        SliceTheme(
            appearance: .system,
            accent: accent,
            onAccent: onAccent,
            canvas: Color(light: "#F2F2F7", dark: "#000000"),
            surface: Color(light: "#FFFFFF", dark: "#1C1C1E"),
            surfaceAlt: Color(light: "#F2F2F7", dark: "#2C2C2E"),
            line: Color(light: "#E3E3E8", dark: "#38383A"),
            ink: Color(light: "#0B0B0F", dark: "#FFFFFF"),
            inkSecondary: Color(light: "#6C6C72", dark: "#AEAEB2"),
            inkTertiary: Color(light: "#A1A1A6", dark: "#6C6C70"),
            success: Color(light: "#1F9D55", dark: "#34C759"),
            successInk: .white,
            danger: Color(light: "#D92D20", dark: "#FF453A"),
            warning: Color(light: "#C26A00", dark: "#FF9F0A"),
            text: text,
            display: display
        )
    }

    /// Always dark (camera, onboarding, paywall), whatever the system setting.
    /// `onAccent` defaults to black, for bright accents like lime.
    public static func dark(
        accent: Color, onAccent: Color = .black, background: Color = .black,
        text: SliceFontFamily = .system, display: SliceFontFamily? = nil
    ) -> SliceTheme {
        SliceTheme(
            appearance: .dark,
            accent: accent,
            accentSoft: accent.opacity(0.16),
            accentEdge: accent.opacity(0.45),
            onAccent: onAccent,
            canvas: background,
            surface: Color(hex: "#16161A"),
            surfaceAlt: Color(hex: "#232328"),
            line: Color.white.opacity(0.12),
            ink: .white,
            inkSecondary: Color.white.opacity(0.66),
            inkTertiary: Color.white.opacity(0.42),
            success: accent,
            successInk: onAccent,
            danger: Color(hex: "#FF5A5F"),
            warning: Color(hex: "#FFB020"),
            text: text,
            display: display
        )
    }

    /// The default until the app sets ``appDefault``.
    public static let standard = SliceTheme.system()

    /// The theme components use when no `.sliceTheme(_:)` is set above them
    /// (sheets, previews, UIKit-hosted views). Set it once at launch.
    nonisolated(unsafe) public static var appDefault: SliceTheme = .standard
}

private struct SliceThemeKey: EnvironmentKey {
    static var defaultValue: SliceTheme { SliceTheme.appDefault }
}

extension EnvironmentValues {
    /// The current SliceUI theme.
    public var sliceTheme: SliceTheme {
        get { self[SliceThemeKey.self] }
        set { self[SliceThemeKey.self] = newValue }
    }
}

extension View {
    /// Uses `theme` for this view and everything inside it: colours, fonts and
    /// tint, and forces light or dark when the theme's `appearance` says so.
    /// For a full-screen view that must be dark, also use
    /// `.preferredColorScheme(theme.appearance.colorScheme)` so the status bar matches.
    public func sliceTheme(_ theme: SliceTheme) -> some View {
        modifier(SliceThemeModifier(theme: theme))
    }
}

private struct SliceThemeModifier: ViewModifier {
    let theme: SliceTheme

    func body(content: Content) -> some View {
        if let scheme = theme.appearance.colorScheme {
            content.environment(\.sliceTheme, theme).tint(theme.accent).environment(\.colorScheme, scheme)
        } else {
            content.environment(\.sliceTheme, theme).tint(theme.accent)
        }
    }
}
