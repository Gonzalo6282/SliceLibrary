import SwiftUI

/// A list row: optional icon chip, title + meta, trailing value, custom
/// trailing content, chevron. At least 48pt tall, 14pt side padding.
public struct Row<Trailing: View>: View {
    var icon: String?
    var iconTint: IconChip.Tint
    let title: Text
    var meta: String?
    var value: String?
    var titleColor: Color?
    var showsChevron: Bool
    let trailing: Trailing

    @Environment(\.sliceTheme) private var theme

    public init(
        icon: String? = nil, iconTint: IconChip.Tint = .accent, title: Text, meta: String? = nil, value: String? = nil,
        titleColor: Color? = nil, showsChevron: Bool = false, @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.meta = meta
        self.value = value
        self.titleColor = titleColor
        self.showsChevron = showsChevron
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let icon { IconChip(systemName: icon, tint: iconTint) }
            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(theme.font(.callout))
                    .foregroundStyle(titleColor ?? theme.ink)
                if let meta, !meta.isEmpty {
                    Text(meta)
                        .font(theme.font(.footnote))
                        .foregroundStyle(theme.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                Text(value)
                    .font(theme.font(.subheadline))
                    .foregroundStyle(theme.inkSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            trailing
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(theme.font(.footnote, weight: .semibold))
                    .foregroundStyle(theme.inkTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

extension Row {
    /// Localized title with trailing content.
    public init(
        icon: String? = nil, iconTint: IconChip.Tint = .accent, title: LocalizedStringKey, meta: String? = nil,
        value: String? = nil, titleColor: Color? = nil, showsChevron: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            icon: icon, iconTint: iconTint, title: Text(title), meta: meta, value: value, titleColor: titleColor,
            showsChevron: showsChevron, trailing: trailing)
    }

    /// User-entered title (shown as typed, never looked up as a translation key).
    public init(
        icon: String? = nil, iconTint: IconChip.Tint = .accent, verbatim: String, meta: String? = nil,
        value: String? = nil, titleColor: Color? = nil, showsChevron: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            icon: icon, iconTint: iconTint, title: Text(verbatim: verbatim), meta: meta, value: value,
            titleColor: titleColor, showsChevron: showsChevron, trailing: trailing)
    }
}

extension Row where Trailing == EmptyView {
    public init(
        icon: String? = nil, iconTint: IconChip.Tint = .accent, title: LocalizedStringKey, meta: String? = nil,
        value: String? = nil, titleColor: Color? = nil, showsChevron: Bool = false
    ) {
        self.init(
            icon: icon, iconTint: iconTint, title: Text(title), meta: meta, value: value, titleColor: titleColor,
            showsChevron: showsChevron) { EmptyView() }
    }

    public init(
        icon: String? = nil, iconTint: IconChip.Tint = .accent, verbatim: String, meta: String? = nil,
        value: String? = nil, titleColor: Color? = nil, showsChevron: Bool = false
    ) {
        self.init(
            icon: icon, iconTint: iconTint, title: Text(verbatim: verbatim), meta: meta, value: value,
            titleColor: titleColor, showsChevron: showsChevron) { EmptyView() }
    }
}
