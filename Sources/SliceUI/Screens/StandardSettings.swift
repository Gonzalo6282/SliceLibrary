import SwiftUI

#if canImport(UIKit)
import StoreKit
import UIKit
#endif

/// Purchases in Settings (Restore, Subscription page). Nil = the app sells nothing.
public struct SettingsPurchases {
    /// Read inside views, so an `@Observable` source (e.g. PurchaseManager) updates them.
    public var isPremium: @MainActor () -> Bool
    public var restore: @MainActor () async -> Bool
    /// Opens the paywall (e.g. `PaywallService.shared.gate(.settingsUpgrade) {}`).
    public var upgrade: @MainActor () -> Void
    /// Subscription page: the line on the Premium card, e.g. "Scans and exports are unlocked."
    public var premiumText: LocalizedStringKey
    /// Subscription page: what Free and Premium include.
    public var plansText: LocalizedStringKey
    /// Subscription page: billing and cancelling. Defaults to SliceUI's (Apple handles payments…).
    public var billingText: LocalizedStringKey?
    /// Background of the Premium card; defaults to the accent.
    public var cardBackground: Color?
    /// Debug builds: lines from `PurchaseManager.shared.diagnostics()`.
    public var diagnostics: (@MainActor () async -> [String])?

    public init(
        isPremium: @escaping @MainActor () -> Bool, restore: @escaping @MainActor () async -> Bool,
        upgrade: @escaping @MainActor () -> Void, premiumText: LocalizedStringKey, plansText: LocalizedStringKey,
        billingText: LocalizedStringKey? = nil, cardBackground: Color? = nil,
        diagnostics: (@MainActor () async -> [String])? = nil
    ) {
        self.isPremium = isPremium
        self.restore = restore
        self.upgrade = upgrade
        self.premiumText = premiumText
        self.plansText = plansText
        self.billingText = billingText
        self.cardBackground = cardBackground
        self.diagnostics = diagnostics
    }
}

/// The analytics switch in Settings. Turning it on can ask first (the app's wording).
public struct SettingsAnalytics {
    public struct Question: Sendable {
        public var title: String, message: String, allow: String, deny: String
        public init(title: String, message: String, allow: String, deny: String) {
            self.title = title
            self.message = message
            self.allow = allow
            self.deny = deny
        }
    }

    public var isOn: @MainActor () -> Bool
    public var setOn: @MainActor (Bool) -> Void
    /// Shown before turning it on; nil = no question.
    public var askFirst: Question?

    public init(isOn: @escaping @MainActor () -> Bool, setOn: @escaping @MainActor (Bool) -> Void, askFirst: Question? = nil) {
        self.isOn = isOn
        self.setOn = setOn
        self.askFirst = askFirst
    }
}

/// Help page and problem report.
public struct SettingsHelp {
    public struct FAQ: Identifiable {
        public let id = UUID()
        public var question: LocalizedStringKey
        public var answer: LocalizedStringKey
        public init(_ question: LocalizedStringKey, _ answer: LocalizedStringKey) {
            self.question = question
            self.answer = answer
        }
    }

    public var faqs: [FAQ]
    /// Report topics (already localised); the first is selected.
    public var reportTopics: [String]
    /// Under the Send button, e.g. "We reply within 24 hours. Your scans are not attached."
    public var reportFooter: LocalizedStringKey

    public init(faqs: [FAQ], reportTopics: [String], reportFooter: LocalizedStringKey) {
        self.faqs = faqs
        self.reportTopics = reportTopics
        self.reportFooter = reportFooter
    }
}

/// "Share <app>" in Settings.
public struct SettingsShare {
    public var message: String
    public var onTap: @MainActor () -> Void
    /// Called when a share actually went out, with the activity type (e.g. "com.apple.UIKit.activity.Message").
    public var onShared: @MainActor (String) -> Void

    public init(message: String, onTap: @escaping @MainActor () -> Void = {}, onShared: @escaping @MainActor (String) -> Void = { _ in }) {
        self.message = message
        self.onTap = onTap
        self.onShared = onShared
    }
}

/// Pages the standard Settings pushes.
public enum StandardSettingsPage: Hashable {
    case help, report, subscription, terms, privacy
}

/// The standard Settings screen: the app's own sections first, then Account
/// (optional account rows, Restore purchases, Subscription), Help (Help and
/// support, Report a problem, Rate, Share), Privacy and legal (analytics
/// switch, Privacy Policy, Terms of Use) and the version line.
/// Put it inside a NavigationStack.
public struct StandardSettings<Content: View>: View {
    let app: AppIdentity
    let purchases: SettingsPurchases?
    let analytics: SettingsAnalytics?
    let help: SettingsHelp
    let share: SettingsShare?
    let legalFooter: LocalizedStringKey?
    let header: AnyView?
    let account: AnyView?
    let debug: AnyView?
    let content: Content

    @Environment(\.sliceTheme) private var theme
    @Environment(\.openURL) private var openURL
    @State private var sharing = false
    @State private var analyticsOn = false
    @State private var askingAnalytics = false
    @State private var restoring = false
    @State private var restoreMessage: String?

    /// - Parameters:
    ///   - header: Above everything (e.g. a plan card).
    ///   - account: Rows at the top of Account (e.g. Sign in with Apple); nil = none.
    ///   - debug: Shown after Privacy and legal (debug builds).
    ///   - content: The app's own sections.
    public init(
        app: AppIdentity, purchases: SettingsPurchases?, analytics: SettingsAnalytics?, help: SettingsHelp,
        share: SettingsShare?, legalFooter: LocalizedStringKey? = nil, header: AnyView? = nil, account: AnyView? = nil,
        debug: AnyView? = nil, @ViewBuilder content: () -> Content
    ) {
        self.app = app
        self.purchases = purchases
        self.analytics = analytics
        self.help = help
        self.share = share
        self.legalFooter = legalFooter
        self.header = header
        self.account = account
        self.debug = debug
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let header { header }
                content
                accountSection
                helpSection
                legalSection
                if let debug { debug }
                Text(verbatim: app.versionLine)
                    .font(theme.font(.caption)).foregroundStyle(theme.inkTertiary)
                    .frame(maxWidth: .infinity).padding(.top, 22)
            }
            .padding(.bottom, 24)
        }
        .background(theme.canvas)
        .navigationTitle(Text("Settings", bundle: .module))
        .navigationDestination(for: StandardSettingsPage.self) { page in destination(page) }
        #if canImport(UIKit)
        .sheet(isPresented: $sharing) {
            if let share {
                ShareSheet(items: [share.message]) { completed, activity in
                    if completed { share.onShared(activity?.rawValue ?? "unknown") }
                }
                .ignoresSafeArea()
            }
        }
        #endif
        .onAppear { analyticsOn = analytics?.isOn() ?? false }
        .alert(analytics?.askFirst?.title ?? "", isPresented: $askingAnalytics) {
            Button(analytics?.askFirst?.allow ?? "") { setAnalytics(true) }
            Button(analytics?.askFirst?.deny ?? "", role: .cancel) {}
        } message: {
            Text(analytics?.askFirst?.message ?? "")
        }
        .alert(Text("Restore purchases", bundle: .module), isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })) {
            Button(String("OK"), role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
    }

    // MARK: Sections

    @ViewBuilder private var accountSection: some View {
        if account != nil || purchases != nil {
            GroupedSection(headerText: Text(ui("Account"))) {
                if let account {
                    account
                    if purchases != nil { RowDivider() }
                }
                if let purchases {
                    // Always visible: Apple expects a Restore button wherever purchases can be bought.
                    Button(action: restore) {
                        Row(icon: "arrow.clockwise", iconTint: .accent, title: Text(ui("Restore purchases")),
                            value: restoring ? ui("Checking…") : nil) { EmptyView() }
                    }
                    .buttonStyle(.plain)
                    .disabled(restoring)
                    .accessibilityIdentifier("restorePurchases")
                    RowDivider()
                    link(.subscription, icon: "lock.fill", tint: .neutral, title: ui("Subscription"),
                         value: purchases.isPremium() ? ui("Premium") : ui("Free"))
                }
            }
        }
    }

    private var helpSection: some View {
        GroupedSection(headerText: Text(ui("Help"))) {
            link(.help, icon: "questionmark.circle.fill", title: ui("Help and support"), meta: ui("Replies within 24 hours"))
            RowDivider()
            link(.report, icon: "envelope.fill", tint: .success, title: ui("Report a problem"))
            RowDivider()
            Button { openURL(app.writeReviewURL) } label: {
                Row(icon: "star.fill", iconTint: .warning, title: Text(ui("Rate \(app.name)")), meta: ui("Leave a review on the App Store")) { EmptyView() }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("rateApp")
            if let share {
                RowDivider()
                Button {
                    share.onTap()
                    sharing = true
                } label: {
                    Row(icon: "square.and.arrow.up", iconTint: .accent, title: Text(ui("Share \(app.name)")), meta: ui("Tell a friend about the app")) { EmptyView() }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shareApp")
            }
        }
    }

    private var legalSection: some View {
        GroupedSection(headerText: Text(ui("Privacy and legal")), footerText: legalFooter.map { Text($0) }) {
            if analytics != nil {
                Toggle(isOn: Binding(get: { analyticsOn }, set: toggleAnalytics)) {
                    HStack(spacing: 12) {
                        IconChip(systemName: "chart.bar.fill", tint: .neutral)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ui("Anonymous analytics")).font(theme.font(.callout)).foregroundStyle(theme.ink)
                            Text(ui("Helps us fix what's slow or confusing")).font(theme.font(.footnote)).foregroundStyle(theme.inkSecondary)
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                RowDivider()
            }
            link(.privacy, icon: "hand.raised.fill", tint: .neutral, title: ui("Privacy Policy"))
            RowDivider()
            link(.terms, icon: "doc.text.fill", tint: .neutral, title: ui("Terms of Use"))
        }
    }

    private func link(_ page: StandardSettingsPage, icon: String, tint: IconChip.Tint = .accent, title: String, meta: String? = nil, value: String? = nil) -> some View {
        NavigationLink(value: page) {
            Row(icon: icon, iconTint: tint, title: Text(title), meta: meta, value: value, showsChevron: true) { EmptyView() }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func destination(_ page: StandardSettingsPage) -> some View {
        switch page {
        case .help: HelpPage(app: app, help: help)
        case .report: ReportProblemPage(app: app, help: help)
        case .subscription:
            if let purchases { SubscriptionPage(purchases: purchases) }
        case .terms: LegalView(document: .terms)
        case .privacy: LegalView(document: .privacy)
        }
    }

    // MARK: Actions

    /// Turning analytics on asks first (when the app gives a question); turning it off doesn't.
    private func toggleAnalytics(_ on: Bool) {
        if on, analytics?.askFirst != nil { askingAnalytics = true } else { setAnalytics(on) }
    }

    private func setAnalytics(_ on: Bool) {
        analyticsOn = on
        analytics?.setOn(on)
    }

    private func restore() {
        guard let purchases else { return }
        restoring = true
        Task {
            let premium = await purchases.restore()
            restoring = false
            restoreMessage = premium ? ui("Premium is active on this device.") : ui("No active subscription found for this Apple ID.")
        }
    }
}

// MARK: - Pages

/// Contact, report and the app's common questions.
public struct HelpPage: View {
    let app: AppIdentity
    let help: SettingsHelp
    @Environment(\.sliceTheme) private var theme

    public init(app: AppIdentity, help: SettingsHelp) {
        self.app = app
        self.help = help
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GroupedSection(headerText: nil, footerText: Text(ui("We reply within 24 hours, every day."))) {
                    if let mail = URL(string: "mailto:\(app.supportEmail)") {
                        Link(destination: mail) {
                            Row(icon: "envelope.fill", title: Text(ui("Email us")), meta: app.supportEmail) { EmptyView() }
                        }
                        .buttonStyle(.plain)
                    }
                    RowDivider()
                    NavigationLink(value: StandardSettingsPage.report) {
                        Row(icon: "exclamationmark.bubble.fill", iconTint: .success, title: Text(ui("Report a problem")),
                            meta: ui("Sends your message and app version"), showsChevron: true) { EmptyView() }
                    }
                    .buttonStyle(.plain)
                }
                if !help.faqs.isEmpty {
                    GroupedSection(headerText: Text(ui("Common questions"))) {
                        ForEach(Array(help.faqs.enumerated()), id: \.offset) { index, faq in
                            if index > 0 { RowDivider() }
                            DisclosureGroup {
                                Text(faq.answer).font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                            } label: {
                                Text(faq.question).font(theme.font(.callout)).foregroundStyle(theme.ink)
                            }
                            .padding(14)
                            .tint(theme.inkTertiary)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(theme.canvas)
        .navigationTitle(Text(ui("Help and support")))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Opens Mail with the user's message, topic and (optionally) app version and device.
public struct ReportProblemPage: View {
    let app: AppIdentity
    let help: SettingsHelp
    @Environment(\.sliceTheme) private var theme
    @Environment(\.openURL) private var openURL
    @State private var topic = ""
    @State private var message = ""
    @State private var includeDiagnostics = true

    public init(app: AppIdentity, help: SettingsHelp) {
        self.app = app
        self.help = help
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !help.reportTopics.isEmpty {
                    GroupedSection(headerText: Text(ui("What's it about?"))) {
                        Picker(ui("Topic"), selection: $topic) { ForEach(help.reportTopics, id: \.self) { Text($0) } }
                            .pickerStyle(.menu).padding(.horizontal, 8).frame(minHeight: 48)
                    }
                }
                GroupedSection(headerText: Text(ui("What happened?"))) {
                    TextField(ui("Tell us what you tapped and what you expected"), text: $message, axis: .vertical)
                        .lineLimit(5...12).padding(14)
                }
                GroupedSection {
                    Toggle(ui("Include app version and device model"), isOn: $includeDiagnostics).padding(.horizontal, 14).frame(minHeight: 48)
                }
                Button(ui("Send report"), action: send).buttonStyle(.primary).padding(16)
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text(help.reportFooter)
                    .font(theme.font(.caption)).foregroundStyle(theme.inkSecondary).padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(theme.canvas)
        .navigationTitle(Text(ui("Report a problem")))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { if topic.isEmpty { topic = help.reportTopics.first ?? "" } }
    }

    private func send() {
        if let url = Self.mailURL(app: app, topic: topic, message: message, diagnostics: includeDiagnostics ? Self.deviceLine(app: app) : nil) {
            openURL(url)
        }
    }

    static func deviceLine(app: AppIdentity) -> String {
        #if canImport(UIKit)
        "\(app.name) \(app.version) (\(app.build)) · \(UIDevice.current.model) · iOS \(UIDevice.current.systemVersion)"
        #else
        "\(app.name) \(app.version) (\(app.build))"
        #endif
    }

    /// `mailto:` with "App: topic" as subject and the message (plus the device line) as body.
    nonisolated static func mailURL(app: AppIdentity, topic: String, message: String, diagnostics: String?) -> URL? {
        var body = message
        if let diagnostics { body += "\n\n—\n\(diagnostics)" }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = app.supportEmail
        let subject = topic.isEmpty ? app.name : "\(app.name): \(topic)"
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return components.url
    }
}

/// Plan status, restore, manage (Apple handles cancelling).
public struct SubscriptionPage: View {
    let purchases: SettingsPurchases
    @Environment(\.sliceTheme) private var theme
    @State private var managing = false
    @State private var restoring = false
    @State private var restoreMessage: String?

    public init(purchases: SettingsPurchases) { self.purchases = purchases }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if purchases.isPremium() {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ui("Premium")).font(theme.font(.footnote)).opacity(0.72)
                        Text(purchases.premiumText).font(theme.display.font(.title2, weight: .heavy))
                    }
                    .foregroundStyle(.white).padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(purchases.cardBackground ?? theme.accent, in: RoundedRectangle(cornerRadius: 28))
                    Button(ui("Manage subscription")) { managing = true }.buttonStyle(.ghost)
                } else {
                    Button(ui("See Premium plans")) { purchases.upgrade() }.buttonStyle(.primary)
                }
                Button(restoring ? ui("Restoring…") : ui("Restore purchases")) {
                    restoring = true
                    Task {
                        let ok = await purchases.restore()
                        restoring = false
                        restoreMessage = ok ? ui("Premium restored.") : ui("No active subscription found for this Apple ID.")
                    }
                }
                .disabled(restoring)
                .frame(maxWidth: .infinity)
                if let restoreMessage {
                    Text(restoreMessage).font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary).frame(maxWidth: .infinity)
                }
                Text(purchases.plansText)
                    .font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary).padding(.top, 8)
                Group {
                    if let billing = purchases.billingText {
                        Text(billing)
                    } else {
                        Text(ui("Payments are handled by Apple. To cancel, open Settings, tap your name, then Subscriptions. To ask for a refund, go to reportaproblem.apple.com. Deleting the app does not cancel the subscription. If your subscription ends you keep every document."))
                    }
                }
                .font(theme.font(.footnote)).foregroundStyle(theme.inkTertiary)
                #if DEBUG
                if let diagnostics = purchases.diagnostics { DiagnosticsPanel(load: diagnostics) }
                #endif
            }
            .padding(16)
        }
        .background(theme.canvas)
        .navigationTitle(Text(ui("Subscription")))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .manageSubscriptionsSheet(isPresented: $managing)
        #endif
    }
}

/// Debug: what each purchase source reports.
struct DiagnosticsPanel: View {
    let load: @MainActor () async -> [String]
    @State private var lines: [String] = []
    @Environment(\.sliceTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: "Purchase status (debug)").font(.footnote.weight(.semibold))
                Spacer()
                Button(String("Refresh")) { Task { lines = await load() } }.font(.footnote)
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(verbatim: line).font(.caption2.monospaced()).foregroundStyle(theme.inkSecondary).textSelection(.enabled)
            }
        }
        .padding(12)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.top, 12)
        .task { lines = await load() }
    }
}
