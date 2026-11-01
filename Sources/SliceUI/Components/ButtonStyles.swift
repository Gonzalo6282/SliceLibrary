import SwiftUI

/// Accent capsule, 52pt tall, full width: the main action on a screen.
public struct PrimaryButtonStyle: ButtonStyle {
    public enum Role: Sendable { case normal, destructive, dark }

    public var role: Role

    public init(role: Role = .normal) { self.role = role }

    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration, role: role)
    }

    private struct PrimaryButton: View {
        let configuration: ButtonStyleConfiguration
        let role: Role
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.sliceTheme) private var theme

        var body: some View {
            configuration.label
                .font(theme.font(.body, weight: .semibold))
                .foregroundStyle(role == .normal ? theme.onAccent : .white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 24)
                .background(background, in: Capsule())
                .opacity(isEnabled ? 1 : 0.45)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
                .contentShape(Capsule())
        }

        private var background: Color {
            switch role {
            case .normal: configuration.isPressed ? theme.accentPressed : theme.accent
            case .destructive: theme.danger
            case .dark: .black
            }
        }
    }
}

/// Outlined capsule: the secondary action, paired with primary.
public struct GhostButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        GhostButton(configuration: configuration)
    }

    private struct GhostButton: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.sliceTheme) private var theme

        var body: some View {
            configuration.label
                .font(theme.font(.body, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 24)
                .background(theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.accentEdge, lineWidth: 1.5))
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
                .contentShape(Capsule())
        }
    }
}

/// Small capsule (36pt), e.g. an action inside a row.
public struct SmallButtonStyle: ButtonStyle {
    public var prominent: Bool

    public init(prominent: Bool = true) { self.prominent = prominent }

    public func makeBody(configuration: Configuration) -> some View {
        SmallButton(configuration: configuration, prominent: prominent)
    }

    private struct SmallButton: View {
        let configuration: ButtonStyleConfiguration
        let prominent: Bool
        @Environment(\.sliceTheme) private var theme

        var body: some View {
            configuration.label
                .font(theme.font(.subheadline, weight: .semibold))
                .foregroundStyle(prominent ? theme.onAccent : theme.accent)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(prominent ? theme.accent : theme.accentSoft, in: Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    public static var destructivePrimary: PrimaryButtonStyle { PrimaryButtonStyle(role: .destructive) }
}

extension ButtonStyle where Self == GhostButtonStyle {
    public static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

extension ButtonStyle where Self == SmallButtonStyle {
    public static var small: SmallButtonStyle { SmallButtonStyle() }
}
