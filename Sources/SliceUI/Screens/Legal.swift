import Foundation
import SwiftUI

/// Terms of Use or Privacy Policy bundled with the app as plain text
/// (`terms.txt`, `privacy.txt`; translations as `terms.fr.txt`, `privacy.de.txt`…).
/// The English file is the fallback (and usually the binding version).
public struct LegalDocument: Hashable, Sendable {
    /// File name without extension.
    public let name: String
    let titleKey: String.LocalizationValue

    public init(name: String, title: String.LocalizationValue) {
        self.name = name
        self.titleKey = title
    }

    public static let terms = LegalDocument(name: "terms", title: "Terms of Use")
    public static let privacy = LegalDocument(name: "privacy", title: "Privacy Policy")

    public var title: String { String(localized: titleKey, bundle: .module) }

    public static func == (a: LegalDocument, b: LegalDocument) -> Bool { a.name == b.name }
    public func hash(into hasher: inout Hasher) { hasher.combine(name) }

    /// The text in the app's current language, split into blocks.
    public var blocks: [LegalBlock] { blocks(language: Bundle.main.preferredLocalizations.first ?? "en") }

    /// `name.<language>.txt` (e.g. `privacy.fr.txt`) if bundled, else `name.txt`.
    /// Looks in the bundle root and in a `Legal` folder.
    public func blocks(language: String, bundle: Bundle = .main) -> [LegalBlock] {
        let code = String(language.prefix(2))
        let names = code == "en" ? [name] : ["\(name).\(code)", name]
        for file in names {
            let url = bundle.url(forResource: file, withExtension: "txt")
                ?? bundle.url(forResource: file, withExtension: "txt", subdirectory: "Legal")
            if let url, let text = try? String(contentsOf: url, encoding: .utf8) { return LegalBlock.parse(text) }
        }
        return []
    }
}

/// "# Title", "## Heading", "### Subheading", "- bullet", plain paragraphs.
public enum LegalBlock: Hashable, Sendable {
    case title(String), heading(String), subheading(String), bullet(String), paragraph(String)

    public static func parse(_ text: String) -> [LegalBlock] {
        text.components(separatedBy: .newlines).compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { return nil }
            if line.hasPrefix("### ") { return .subheading(String(line.dropFirst(4))) }
            if line.hasPrefix("## ") { return .heading(String(line.dropFirst(3))) }
            if line.hasPrefix("# ") { return .title(String(line.dropFirst(2))) }
            if line.hasPrefix("- ") { return .bullet(String(line.dropFirst(2))) }
            return .paragraph(line)
        }
    }
}

/// Shows a ``LegalDocument`` inside the app (push it in a NavigationStack).
public struct LegalView: View {
    let document: LegalDocument
    @Environment(\.sliceTheme) private var theme

    public init(document: LegalDocument) { self.document = document }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(document.blocks.enumerated()), id: \.offset) { _, block in
                    view(for: block)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(theme.canvas)
        .navigationTitle(document.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder private func view(for block: LegalBlock) -> some View {
        switch block {
        case .title:
            EmptyView()  // shown as the navigation title
        case .heading(let text):
            Text(verbatim: text).font(theme.font(.headline)).foregroundStyle(theme.ink).padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
        case .subheading(let text):
            Text(verbatim: text).font(theme.font(.subheadline, weight: .semibold)).foregroundStyle(theme.ink).padding(.top, 4)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: "•").foregroundStyle(theme.inkSecondary)
                Text(verbatim: text).foregroundStyle(theme.inkSecondary)
            }
            .font(theme.font(.subheadline))
        case .paragraph(let text):
            Text(verbatim: text).font(theme.font(.subheadline)).foregroundStyle(theme.inkSecondary)
                .textSelection(.enabled)
        }
    }
}
