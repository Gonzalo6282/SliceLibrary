import SwiftUI

/// A card of rows on the canvas: 14pt radius, 1pt hairline, no shadow, with an
/// optional header and footer. Put a ``RowDivider`` between rows.
public struct GroupedSection<Content: View>: View {
    var header: LocalizedStringKey?
    var footer: LocalizedStringKey?
    let content: Content

    @Environment(\.sliceTheme) private var theme

    public init(header: LocalizedStringKey? = nil, footer: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                Text(header)
                    .font(theme.font(.footnote, weight: .medium))
                    .foregroundStyle(theme.inkSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 7)
            }
            VStack(spacing: 0) { content }
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            if let footer {
                Text(footer)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.inkSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 7)
            }
        }
    }
}

/// Hairline between rows in a ``GroupedSection``, inset 14pt.
public struct RowDivider: View {
    @Environment(\.sliceTheme) private var theme

    public init() {}

    public var body: some View {
        Rectangle().fill(theme.line).frame(height: 1).padding(.leading, 14)
    }
}
