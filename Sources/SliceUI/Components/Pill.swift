import SwiftUI

/// A small status tag (22pt capsule): Draft, Paid, Saved, New…
/// Use a ``Tone`` or your own colours.
public struct Pill: View {
    public enum Tone: Sendable, Hashable {
        /// Grey text on the canvas, with a hairline border.
        case neutral
        case accent
        /// Solid success colour.
        case success
        case successSoft
        case danger
        case warning
        case custom(foreground: Color, background: Color, bordered: Bool)

        func colors(in theme: SliceTheme) -> (foreground: Color, background: Color, bordered: Bool) {
            switch self {
            case .neutral: (theme.inkSecondary, theme.canvas, true)
            case .accent: (theme.accent, theme.accentSoft, false)
            case .success: (theme.successInk, theme.success, false)
            case .successSoft: (theme.successText, theme.successSoft, false)
            case .danger: (theme.danger, theme.dangerSoft, false)
            case .warning: (theme.warning, theme.warningSoft, false)
            case .custom(let foreground, let background, let bordered): (foreground, background, bordered)
            }
        }
    }

    let title: Text
    let tone: Tone
    var accessibilityName: Text?

    @Environment(\.sliceTheme) private var theme

    /// - Parameter accessibilityName: Spoken before the value, e.g. "Status".
    public init(_ title: Text, tone: Tone, accessibilityName: Text? = nil) {
        self.title = title
        self.tone = tone
        self.accessibilityName = accessibilityName
    }

    public init(_ title: LocalizedStringKey, tone: Tone, accessibilityName: Text? = nil) {
        self.init(Text(title), tone: tone, accessibilityName: accessibilityName)
    }

    public var body: some View {
        let c = tone.colors(in: theme)
        let pill = title
            .textStyle(.pill)
            .foregroundStyle(c.foreground)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(c.background, in: Capsule())
            .overlay {
                if c.bordered { Capsule().strokeBorder(theme.line, lineWidth: 1) }
            }
            .fixedSize()
        if let accessibilityName {
            pill.accessibilityLabel(accessibilityName).accessibilityValue(title)
        } else {
            pill
        }
    }
}
