import SwiftUI

/// A plan as the paywall shows it.
public struct PaywallPlanInfo: Identifiable, Equatable, Sendable {
    public enum Period: Sendable, Hashable { case week, month, year, lifetime }

    public let id: String
    public let period: Period
    /// Localised price, e.g. "£59.99".
    public let price: String
    /// Price per month (yearly plans).
    public let monthlyPrice: String?
    public let trialDays: Int?

    public init(id: String, period: Period, price: String, monthlyPrice: String? = nil, trialDays: Int? = nil) {
        self.id = id
        self.period = period
        self.price = price
        self.monthlyPrice = monthlyPrice
        self.trialDays = trialDays
    }
}

/// What happened when the user tapped buy.
public enum PaywallOutcome: Sendable, Equatable { case purchased, cancelled, pending, failed }

/// The app's words and look for the paywall.
public struct PaywallContent {
    /// The big line; usually depends on the placement ("Send this invoice", "Unlock unlimited scans").
    public var headline: String
    /// A line of context under it, per placement or fixed. Markdown (`**bold**`) works.
    public var subtitle: LocalizedStringKey?
    /// What Premium includes, one short line each.
    public var benefits: [String]
    /// Header background; defaults to the theme's canvas with ink text.
    public var headerBackground: Color?
    /// Text colour on `headerBackground`.
    public var headerForeground: Color
    /// Shows "How your free trial works" (today / reminder / billing day) when the selected plan has a trial.
    public var showsTrialTimeline: Bool
    /// Adds the "we remind you the day before" step to the timeline. Only if the app (or Superwall) really sends one.
    public var trialReminder: Bool
    /// The close button appears after this delay (hard paywalls). Zero = straight away.
    public var closeButtonDelay: Duration
    public var termsURL: URL
    public var privacyURL: URL

    public init(
        headline: String, subtitle: LocalizedStringKey? = nil, benefits: [String] = [], headerBackground: Color? = nil,
        headerForeground: Color = .white, showsTrialTimeline: Bool = false, trialReminder: Bool = false,
        closeButtonDelay: Duration = .zero, termsURL: URL, privacyURL: URL
    ) {
        self.headline = headline
        self.subtitle = subtitle
        self.benefits = benefits
        self.headerBackground = headerBackground
        self.headerForeground = headerForeground
        self.showsTrialTimeline = showsTrialTimeline
        self.trialReminder = trialReminder
        self.closeButtonDelay = closeButtonDelay
        self.termsURL = termsURL
        self.privacyURL = privacyURL
    }

    public init(headline: String, subtitle: LocalizedStringKey? = nil, benefits: [String] = [], app: AppIdentity) {
        self.init(headline: headline, subtitle: subtitle, benefits: benefits, termsURL: app.termsURL, privacyURL: app.privacyURL)
    }
}

/// The app's own paywall: headline and context line, benefits, plans, an
/// optional trial timeline, one buy button, the renewal terms and Restore,
/// Terms and Privacy on every paywall. The close button can appear after a
/// delay for hard paywalls (swiping the sheet down is blocked until then).
///
/// With SlicePurchases, `PaywallTemplate(request:content:)` wires it to
/// `PurchaseManager`; otherwise pass plans and actions yourself.
public struct PaywallTemplate: View {
    let content: PaywallContent
    let plans: @MainActor () -> [PaywallPlanInfo]
    let loadPlans: @MainActor () async -> Void
    let buy: @MainActor (PaywallPlanInfo) async -> PaywallOutcome
    let restore: @MainActor () async -> Bool
    let onUnlock: @MainActor () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.sliceTheme) private var theme
    @State private var selectedID: String?
    @State private var busy = false
    @State private var message: String?
    @State private var canClose = false

    /// - Parameters:
    ///   - plans: Read inside the view, so an `@Observable` source updates it.
    ///   - onUnlock: After a purchase or restore (continues the action the user tapped).
    public init(
        content: PaywallContent, plans: @escaping @MainActor () -> [PaywallPlanInfo],
        loadPlans: @escaping @MainActor () async -> Void = {},
        buy: @escaping @MainActor (PaywallPlanInfo) async -> PaywallOutcome,
        restore: @escaping @MainActor () async -> Bool, onUnlock: @escaping @MainActor () -> Void
    ) {
        self.content = content
        self.plans = plans
        self.loadPlans = loadPlans
        self.buy = buy
        self.restore = restore
        self.onUnlock = onUnlock
        _canClose = State(initialValue: content.closeButtonDelay <= .zero)
    }

    private var available: [PaywallPlanInfo] { plans() }
    private var selected: PaywallPlanInfo? { available.first { $0.id == selectedID } ?? available.first }
    private var headerInk: Color { content.headerBackground == nil ? theme.ink : content.headerForeground }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    plansList.padding(.horizontal, 22).padding(.top, 18)
                    if content.showsTrialTimeline, let plan = selected, let days = plan.trialDays {
                        TrialTimeline(plan: plan, days: days, reminder: content.trialReminder)
                            .padding(.horizontal, 22).padding(.top, 18)
                    }
                    if let message {
                        Banner(tone: .error, systemImage: "xmark.circle.fill", text: Text(message)).padding(.horizontal, 6)
                    }
                }
            }
            footer
        }
        .background(theme.canvas)
        .task {
            if available.isEmpty { await loadPlans() }
            selectedID = selectedID ?? available.first { $0.period == .year }?.id
        }
        .task {
            guard !canClose else { return }
            try? await Task.sleep(for: content.closeButtonDelay)
            withAnimation { canClose = true }
        }
        .interactiveDismissDisabled(!canClose)
        #if os(iOS)
        .presentationDetents([.large])
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(theme.font(.subheadline, weight: .bold)).foregroundStyle(headerInk.opacity(0.8))
                        .frame(width: 32, height: 32).background(headerInk.opacity(0.12), in: Circle())
                }
                .accessibilityLabel(Text(ui("Close")))
                .opacity(canClose ? 1 : 0)
                .disabled(!canClose)
                .accessibilityHidden(!canClose)
                .accessibilityIdentifier("paywallClose")
            }
            Text(content.headline).textStyle(.headline).foregroundStyle(headerInk)
            if let subtitle = content.subtitle {
                Text(subtitle).font(theme.font(.subheadline)).foregroundStyle(headerInk.opacity(0.8))
            }
            if !content.benefits.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(content.benefits, id: \.self) { text in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(theme.successInk)
                                .frame(width: 20, height: 20).background(theme.success, in: Circle())
                            Text(text).font(theme.font(.subheadline)).foregroundStyle(headerInk)
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(content.headerBackground ?? theme.canvas)
    }

    @ViewBuilder private var plansList: some View {
        if available.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(30)
        } else {
            VStack(spacing: 10) {
                ForEach(available) { plan in
                    Button { selectedID = plan.id } label: { planRow(plan) }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(plan.id == selected?.id ? .isSelected : [])
                }
            }
        }
    }

    private func planRow(_ plan: PaywallPlanInfo) -> some View {
        let on = plan.id == selected?.id
        return HStack(spacing: 12) {
            Image(systemName: on ? "largecircle.fill.circle" : "circle").font(theme.font(.title2)).foregroundStyle(on ? theme.accent : theme.inkTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text(PaywallWords.name(plan)).font(theme.font(.body, weight: .bold)).foregroundStyle(theme.ink)
                Text(PaywallWords.detail(plan)).font(theme.font(.footnote)).foregroundStyle(theme.inkSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(plan.monthlyPrice ?? plan.price).font(theme.font(.body, weight: .heavy)).monospacedDigit().foregroundStyle(theme.ink)
                Text(PaywallWords.per(plan)).font(theme.font(.caption)).foregroundStyle(theme.inkSecondary)
            }
        }
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(on ? theme.accent : theme.line, lineWidth: on ? 2 : 1))
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(action: purchase) {
                if busy { ProgressView().tint(theme.onAccent) } else { Text(PaywallWords.button(selected)) }
            }
            .buttonStyle(.primary)
            .disabled(busy || selected == nil)
            .accessibilityIdentifier("paywallBuy")
            Text(PaywallWords.terms(selected)).font(theme.font(.caption2)).foregroundStyle(theme.inkSecondary).multilineTextAlignment(.center)
            HStack(spacing: 22) {
                Button(ui("Restore"), action: restorePurchases)
                Button(ui("Terms")) { openURL(content.termsURL) }
                Button(ui("Privacy")) { openURL(content.privacyURL) }
            }
            .font(theme.font(.footnote, weight: .semibold))
            .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 10)
        .background(.bar)
    }

    private func purchase() {
        guard let plan = selected else { return }
        busy = true
        message = nil
        Task {
            let outcome = await buy(plan)
            busy = false
            switch outcome {
            case .purchased:
                dismiss()
                onUnlock()
            case .pending:
                message = ui("Your purchase is waiting for approval. Premium unlocks as soon as it's approved.")
            case .cancelled:
                break
            case .failed:
                message = ui("The payment didn't go through and you weren't charged. Check your payment method in the App Store and try again.")
            }
        }
    }

    private func restorePurchases() {
        busy = true
        Task {
            let restored = await restore()
            busy = false
            if restored {
                dismiss()
                onUnlock()
            } else {
                message = ui("No active subscription found for this Apple ID.")
            }
        }
    }
}

/// "How your free trial works": today, the reminder (optional), the billing day.
struct TrialTimeline: View {
    let plan: PaywallPlanInfo
    let days: Int
    let reminder: Bool
    @Environment(\.sliceTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ui("How your free trial works")).font(theme.font(.subheadline, weight: .semibold)).foregroundStyle(theme.ink)
            ForEach(Array(PaywallWords.timeline(plan: plan, days: days, reminder: reminder).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.icon).font(.system(size: 12, weight: .bold)).foregroundStyle(theme.onAccent)
                        .frame(width: 26, height: 26).background(index == 0 ? theme.accent : theme.inkTertiary, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.when).font(theme.font(.footnote, weight: .semibold)).foregroundStyle(theme.ink)
                        Text(step.what).font(theme.font(.footnote)).foregroundStyle(theme.inkSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(theme.line, lineWidth: 1))
    }
}

/// The paywall's wording (SliceUI's catalog), kept apart so it can be tested.
enum PaywallWords {
    static func name(_ plan: PaywallPlanInfo) -> String {
        switch plan.period {
        case .week: ui("Weekly")
        case .month: ui("Monthly")
        case .year: ui("Yearly")
        case .lifetime: ui("Lifetime")
        }
    }

    /// The small word under the big price.
    static func per(_ plan: PaywallPlanInfo) -> String {
        switch plan.period {
        case .week: ui("a week")
        case .month, .year: ui("a month")  // yearly shows its price per month
        case .lifetime: ui("once")
        }
    }

    static func detail(_ plan: PaywallPlanInfo) -> String {
        switch plan.period {
        case .year:
            if let days = plan.trialDays { return ui("\(days) days free, then \(plan.price) a year") }
            return ui("\(plan.price) a year")
        case .month:
            if let days = plan.trialDays { return ui("\(days) days free, then \(plan.price) a month") }
            return ui("Billed monthly, cancel any time")
        case .week:
            if let days = plan.trialDays { return ui("\(days) days free, then \(plan.price) a week") }
            return ui("Billed weekly, cancel any time")
        case .lifetime:
            return ui("One payment, no subscription")
        }
    }

    static func button(_ plan: PaywallPlanInfo?) -> String {
        if let days = plan?.trialDays { return ui("Start \(days)-day free trial") }
        return ui("Continue")
    }

    static func trialEnd(days: Int, from now: Date = .now) -> Date? {
        Calendar.current.date(byAdding: .day, value: days, to: now)
    }

    static func terms(_ plan: PaywallPlanInfo?, now: Date = .now) -> String {
        let renew = ui("Renews automatically unless cancelled at least 24 hours before the end of the period. Manage or cancel in Settings > [your name] > Subscriptions.")
        guard let plan else { return renew }
        if plan.period == .lifetime { return ui("One payment of \(plan.price). ") }
        if let days = plan.trialDays, let end = trialEnd(days: days, from: now) {
            let endText = end.formatted(.dateTime.day().month(.wide))
            switch plan.period {
            case .year: return ui("Free until \(endText), then \(plan.price) a year. ") + renew
            case .month: return ui("Free until \(endText), then \(plan.price) a month. ") + renew
            case .week: return ui("Free until \(endText), then \(plan.price) a week. ") + renew
            case .lifetime: break
            }
        }
        switch plan.period {
        case .year: return ui("\(plan.price) a year. ") + renew
        case .month: return ui("\(plan.price) a month. ") + renew
        case .week: return ui("\(plan.price) a week. ") + renew
        case .lifetime: return ""
        }
    }

    struct Step: Equatable {
        let icon: String
        let when: String
        let what: String
    }

    static func timeline(plan: PaywallPlanInfo, days: Int, reminder: Bool, now: Date = .now) -> [Step] {
        let calendar = Calendar.current
        let day = { (offset: Int) in
            (calendar.date(byAdding: .day, value: offset, to: now) ?? now).formatted(.dateTime.day().month(.wide))
        }
        var steps = [Step(icon: "lock.open.fill", when: ui("Today"), what: ui("Full access starts now. Cancel any time in Settings."))]
        if reminder, days > 1 {
            steps.append(Step(icon: "bell.fill", when: day(days - 1), what: ui("We remind you that your trial ends tomorrow.")))
        }
        steps.append(Step(icon: "creditcard.fill", when: day(days), what: ui("You're charged \(plan.price). Cancel before this day to pay nothing.")))
        return steps
    }
}
