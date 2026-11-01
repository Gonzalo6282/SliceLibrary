import SwiftUI

/// A text style: size, weight and tracking that scale with Dynamic Type.
/// Digits are always tabular. Apps add their own as static members:
///
/// ```swift
/// extension SliceTextStyle {
///     static let price = SliceTextStyle(size: 24, weight: .black, tracking: -0.03, relativeTo: .title2, display: true)
/// }
/// Text("$12.99").textStyle(.price)
/// ```
public struct SliceTextStyle: Sendable, Hashable {
    public var size: CGFloat
    public var weight: Font.Weight
    /// Tracking as a fraction of the size (-0.025 = -2.5%).
    public var tracking: CGFloat
    /// The system text style it scales with.
    public var relativeTo: Font.TextStyle
    /// Uses the theme's `display` family instead of `text`.
    public var display: Bool

    public init(size: CGFloat, weight: Font.Weight, tracking: CGFloat = 0, relativeTo: Font.TextStyle, display: Bool = false) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.relativeTo = relativeTo
        self.display = display
    }

    /// 34 Heavy, -2.5%: screen titles.
    public static let largeTitle = SliceTextStyle(size: 34, weight: .heavy, tracking: -0.025, relativeTo: .largeTitle, display: true)
    /// 30 Black, -3.5%: paywall and onboarding headlines.
    public static let headline = SliceTextStyle(size: 30, weight: .black, tracking: -0.035, relativeTo: .largeTitle, display: true)
    /// 17 Regular.
    public static let body = SliceTextStyle(size: 17, weight: .regular, relativeTo: .body)
    /// 15 Regular: row meta, footers.
    public static let secondary = SliceTextStyle(size: 15, weight: .regular, relativeTo: .subheadline)
    /// 13 Regular.
    public static let footnote = SliceTextStyle(size: 13, weight: .regular, relativeTo: .footnote)
    /// 12 Semibold: status pills and tags.
    public static let pill = SliceTextStyle(size: 12, weight: .semibold, relativeTo: .caption)
}

private struct SliceTextStyleModifier: ViewModifier {
    let style: SliceTextStyle
    @ScaledMetric private var size: CGFloat
    @Environment(\.sliceTheme) private var theme

    init(style: SliceTextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font((style.display ? theme.display : theme.text).font(fixedSize: size, weight: style.weight))
            .tracking(size * style.tracking)
            .monospacedDigit()
    }
}

extension View {
    /// Applies a ``SliceTextStyle`` in the current theme's fonts. Digits are always tabular.
    public func textStyle(_ style: SliceTextStyle) -> some View {
        modifier(SliceTextStyleModifier(style: style))
    }
}
