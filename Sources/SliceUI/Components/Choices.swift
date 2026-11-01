import SwiftUI

/// Small selectable capsule, e.g. "Tax added" / "Tax included".
public struct ChoiceChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    @Environment(\.sliceTheme) private var theme

    public init(title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.font(.footnote, weight: isOn ? .semibold : .medium))
                .foregroundStyle(isOn ? theme.accent : theme.inkSecondary)
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(isOn ? theme.accentSoft : theme.surfaceAlt, in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? theme.accentEdge : theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A coloured message box with an icon and an optional action link.
public struct Banner: View {
    public enum Tone: Sendable, Hashable { case info, ok, warn, error }

    let tone: Tone
    let systemImage: String
    let text: Text
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.sliceTheme) private var theme

    public init(tone: Tone, systemImage: String, text: Text, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.tone = tone
        self.systemImage = systemImage
        self.text = text
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage).font(theme.font(.body, weight: .semibold))
            text.font(theme.font(.footnote)).frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(theme.font(.footnote, weight: .semibold))
                    .underline()
                    .buttonStyle(.plain)
            }
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(background, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var foreground: Color {
        switch tone {
        case .info: theme.accent
        case .ok: theme.successText
        case .warn: theme.warning
        case .error: theme.danger
        }
    }

    private var background: Color {
        switch tone {
        case .info: theme.accentSoft
        case .ok: theme.successSoft
        case .warn: theme.warningSoft
        case .error: theme.dangerSoft
        }
    }
}

/// A label + trailing field row for forms, inside a ``GroupedSection``.
public struct FieldRow<Field: View>: View {
    let label: LocalizedStringKey
    let field: Field

    @Environment(\.sliceTheme) private var theme

    public init(label: LocalizedStringKey, @ViewBuilder field: () -> Field) {
        self.label = label
        self.field = field()
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text(label).font(theme.font(.callout)).foregroundStyle(theme.ink)
            field
                .font(theme.font(.callout))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
    }
}
