import AuthenticationServices
import SliceUI
import SwiftUI

/// Sign in with Apple (optional) and Delete account, for the top of Settings >
/// Account: `StandardSettings(…, account: AnyView(AccountRows()))`.
/// StandardSettings adds Restore purchases and Subscription under it.
public struct AccountRows: View {
    let account: AccountService
    let deleteExplanation: LocalizedStringKey?
    @Environment(\.sliceTheme) private var theme
    @State private var confirmingDelete = false
    @State private var error: String?

    /// - Parameter deleteExplanation: What deleting does, in the app's words (main bundle).
    ///   Nil = SliceAccount's ("…Everything you made stays on this device…").
    public init(account: AccountService = .shared, deleteExplanation: LocalizedStringKey? = nil) {
        self.account = account
        self.deleteExplanation = deleteExplanation
    }

    public var body: some View {
        Group {
            if !account.isAvailable {
                Row(icon: "apple.logo", iconTint: .neutral, title: Text("Sign in with Apple", bundle: .module),
                    meta: String(localized: "Available once the app is fully set up", bundle: .module)) { EmptyView() }
            } else if account.isSignedIn {
                Row(icon: "apple.logo", iconTint: .neutral, title: Text("Signed in with Apple", bundle: .module), meta: account.email) { EmptyView() }
                RowDivider()
                Button { confirmingDelete = true } label: {
                    Row(title: Text("Delete account", bundle: .module), titleColor: theme.danger) { EmptyView() }
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign in to link your account across devices. Optional.", bundle: .module)
                        .font(theme.font(.footnote)).foregroundStyle(theme.inkSecondary)
                    SignInWithAppleButton(.signIn) { account.prepare($0) } onCompletion: { result in
                        Task {
                            do { try await account.complete(result) } catch { self.error = AccountService.report(error, step: "Sign in") }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                }
                .padding(14)
            }
        }
        .sheet(isPresented: $confirmingDelete) {
            DeleteAccountSheet(account: account, explanation: deleteExplanation) { error = $0 }
        }
        .alert(Text("Something went wrong", bundle: .module), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(String("OK"), role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }
}

/// Apple requires a fresh sign-in to revoke the token when deleting.
public struct DeleteAccountSheet: View {
    let account: AccountService
    let explanation: LocalizedStringKey?
    let failed: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sliceTheme) private var theme

    public init(account: AccountService = .shared, explanation: LocalizedStringKey? = nil, failed: @escaping (String) -> Void) {
        self.account = account
        self.explanation = explanation
        self.failed = failed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Delete your account?", bundle: .module)
                .textStyle(SliceTextStyle(size: 24, weight: .black, tracking: -0.03, relativeTo: .title2, display: true))
                .foregroundStyle(theme.ink)
            Group {
                if let explanation {
                    Text(explanation)
                } else {
                    Text("This deletes your sign-in and unlinks your subscription from it. Everything you made stays on this device. To stop paying, cancel the subscription in Settings > [your name] > Subscriptions.", bundle: .module)
                }
            }
            .font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary)
            Text("Confirm with Apple to finish:", bundle: .module).font(theme.font(.subheadline, weight: .semibold))
            SignInWithAppleButton(.continue) { account.prepare($0) } onCompletion: { result in
                Task {
                    do {
                        try await account.deleteAccount(with: result)
                    } catch {
                        if let message = AccountService.report(error, step: "Delete account") { failed(message) }
                    }
                    dismiss()
                }
            }
            .frame(height: 48)
            Button { dismiss() } label: { Text("Cancel", bundle: .module) }.frame(maxWidth: .infinity)
        }
        .padding(24)
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}
