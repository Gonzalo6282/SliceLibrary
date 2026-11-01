import SwiftUI

/// Small rounded tile with an SF Symbol, coloured by a ``Tint``.
public struct IconChip: View {
    /// Tile and glyph colours. Apps add their own:
    /// `extension IconChip.Tint { static let photo = Self.custom(tile: .orange.opacity(0.15), glyph: .orange) }`
    public enum Tint: Sendable, Hashable {
        case accent, success, danger, warning, neutral
        case custom(tile: Color, glyph: Color)

        public func tile(in theme: SliceTheme) -> Color {
            switch self {
            case .accent: theme.chipBackground
            case .success: theme.successSoft
            case .danger: theme.dangerSoft
            case .warning: theme.warningSoft
            case .neutral: theme.canvas
            case .custom(let tile, _): tile
            }
        }

        public func glyph(in theme: SliceTheme) -> Color {
            switch self {
            case .accent: theme.chipInk
            case .success: theme.successText
            case .danger: theme.danger
            case .warning: theme.warning
            case .neutral: theme.inkSecondary
            case .custom(_, let glyph): glyph
            }
        }
    }

    let systemName: String
    var tint: Tint
    var size: CGFloat

    @Environment(\.sliceTheme) private var theme

    public init(systemName: String, tint: Tint = .accent, size: CGFloat = 30) {
        self.systemName = systemName
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(tint.glyph(in: theme))
            .frame(width: size, height: size)
            .background(tint.tile(in: theme), in: RoundedRectangle(cornerRadius: size * 0.27))
            .accessibilityHidden(true)
    }
}

/// Initials in a circle (38pt), e.g. for a client or contact.
public struct Avatar: View {
    let name: String
    var size: CGFloat

    @Environment(\.sliceTheme) private var theme

    public init(name: String, size: CGFloat = 38) {
        self.name = name
        self.size = size
    }

    public var body: some View {
        Text(Self.initials(for: name))
            .font(.system(size: size * 0.37, weight: .bold))
            .foregroundStyle(theme.chipInk)
            .frame(width: size, height: size)
            .background(theme.chipBackground, in: Circle())
            .accessibilityHidden(true)
    }

    /// "Marlow & Finch Architects" → "MF"; "" → "?".
    nonisolated public static func initials(for name: String) -> String {
        let words = name.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let letters = words.prefix(2).compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
