import SwiftUI

/// The frame of a step-by-step onboarding: progress dots, scrolling content and
/// a footer bar for the buttons. The app owns the steps and what happens on
/// each button (including the soft paywall at the end, e.g.
/// `PaywallService.shared.gate(.onboardingEnd, onFinished: …) {}`).
///
/// ```swift
/// OnboardingShell(step: step.rawValue, of: 4, showsProgress: step != .welcome) {
///     OnboardingTitle("What do you scan?")
///     OnboardingLead("We'll set things up for you.")
/// } footer: {
///     Button("Continue") { next() }.buttonStyle(.primary)
/// }
/// ```
public struct OnboardingShell<Content: View, Footer: View>: View {
    let step: Int
    let count: Int
    let showsProgress: Bool
    let content: Content
    let footer: Footer

    @Environment(\.sliceTheme) private var theme

    /// - Parameters:
    ///   - step: The current step, from 1.
    ///   - count: How many steps the dots show.
    public init(step: Int, of count: Int, showsProgress: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.step = step
        self.count = count
        self.showsProgress = showsProgress
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if showsProgress { OnboardingDots(step: step, count: count) }
                    content
                }
                .padding(24)
            }
            VStack(spacing: 8) { footer }
                .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 12)
                .background(.bar)
        }
        .background(theme.canvas)
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

/// Progress dots: the current step is a wider accent capsule.
public struct OnboardingDots: View {
    let step: Int
    let count: Int
    @Environment(\.sliceTheme) private var theme

    public init(step: Int, count: Int) {
        self.step = step
        self.count = count
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(1...max(count, 1), id: \.self) { i in
                Capsule().fill(i == step ? theme.accent : theme.line).frame(width: i == step ? 18 : 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A step's big title.
public struct OnboardingTitle: View {
    let text: Text
    @Environment(\.sliceTheme) private var theme

    public init(_ key: LocalizedStringKey) { text = Text(key) }
    public init(_ text: Text) { self.text = text }

    public var body: some View {
        text.textStyle(.largeTitle).foregroundStyle(theme.ink).fixedSize(horizontal: false, vertical: true)
    }
}

/// A step's explanation under the title.
public struct OnboardingLead: View {
    let text: Text
    @Environment(\.sliceTheme) private var theme

    public init(_ key: LocalizedStringKey) { text = Text(key) }
    public init(_ text: Text) { self.text = text }

    public var body: some View {
        text.font(theme.font(.body)).foregroundStyle(theme.inkSecondary).fixedSize(horizontal: false, vertical: true)
    }
}

/// A labelled input on a card.
public struct OnboardingField<Field: View>: View {
    let label: LocalizedStringKey
    let field: Field
    @Environment(\.sliceTheme) private var theme

    public init(_ label: LocalizedStringKey, @ViewBuilder field: () -> Field) {
        self.label = label
        self.field = field()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(theme.font(.footnote, weight: .medium)).foregroundStyle(theme.inkSecondary)
            field
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.line))
        }
    }
}

/// A selectable card with an icon, title and detail (e.g. "What do you do?").
public struct OnboardingChoice: View {
    let icon: String
    let title: Text
    let detail: Text
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.sliceTheme) private var theme

    public init(icon: String, title: Text, detail: Text, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconChip(systemName: icon, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    title.font(theme.font(.body, weight: .semibold)).foregroundStyle(theme.ink)
                    detail.font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isSelected ? theme.accent : theme.line, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
