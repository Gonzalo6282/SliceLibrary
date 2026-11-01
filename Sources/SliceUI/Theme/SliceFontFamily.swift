import SwiftUI

/// The typeface an app uses: the system font (any design) or a bundled font.
/// Every size follows Dynamic Type.
public struct SliceFontFamily: Sendable, Hashable {
    enum Kind: Sendable, Hashable {
        case system(Font.Design)
        case custom(name: String, weights: [Font.Weight: String])
    }

    let kind: Kind

    /// San Francisco.
    public static let system = SliceFontFamily(kind: .system(.default))

    /// San Francisco in another design (`.rounded`, `.serif`, `.monospaced`).
    public static func system(design: Font.Design) -> SliceFontFamily {
        SliceFontFamily(kind: .system(design))
    }

    /// A font bundled with the app (listed under `UIAppFonts` in Info.plist).
    /// - Parameters:
    ///   - name: PostScript name of the regular face, e.g. `"Inter-Regular"`.
    ///   - weights: PostScript names of other faces, e.g. `[.bold: "Inter-Bold"]`.
    ///     A weight without its own face uses `name` with `.weight(_:)` (fine for variable fonts).
    public static func custom(_ name: String, weights: [Font.Weight: String] = [:]) -> SliceFontFamily {
        SliceFontFamily(kind: .custom(name: name, weights: weights))
    }

    /// A font for a system text style, e.g. `.font(theme.text.font(.callout, weight: .semibold))`.
    public func font(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        switch kind {
        case .system(let design):
            let base = design == .default ? Self.systemFont(style) : Font.system(style, design: design)
            return weight.map { base.weight($0) } ?? base
        case .custom(let name, let weights):
            let face = weight.flatMap { weights[$0] }
            let font = Font.custom(face ?? name, size: Self.defaultSize(style), relativeTo: style)
            return face == nil ? (weight.map { font.weight($0) } ?? font) : font
        }
    }

    /// A font at a size that has already been scaled for Dynamic Type (see ``SliceTextStyle``).
    public func font(fixedSize size: CGFloat, weight: Font.Weight) -> Font {
        switch kind {
        case .system(let design):
            return .system(size: size, weight: weight, design: design)
        case .custom(let name, let weights):
            if let face = weights[weight] { return .custom(face, fixedSize: size) }
            return .custom(name, fixedSize: size).weight(weight)
        }
    }

    static func systemFont(_ style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        @unknown default: .body
        }
    }

    /// Point sizes of the text styles at the default Dynamic Type size (iOS).
    static func defaultSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}
