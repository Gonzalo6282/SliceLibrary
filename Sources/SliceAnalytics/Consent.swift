import Foundation

/// When to ask before collecting anything.
public enum ConsentPolicy: Sendable, Hashable {
    /// Everyone is asked; nothing is collected until they tap Allow.
    case askEveryone
    /// Only people in the EEA, the UK and Switzerland are asked (GDPR, UK GDPR,
    /// Swiss FADP). Elsewhere analytics is on until they turn it off in Settings.
    /// An unknown country counts as one that needs asking.
    case askInEuropeOnly
}

public enum ConsentRegion {
    /// EU 27 + Iceland, Liechtenstein, Norway (EEA) + the UK + Switzerland, as
    /// ISO 3166 alpha-2 codes (Locale) and alpha-3 codes (App Store storefront).
    static let alpha2: Set<String> = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU",
        "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH",
        // Territories that follow EU or UK rules on the App Store.
        "GF", "GP", "MQ", "RE", "YT", "AX", "GI",
    ]
    static let alpha3: Set<String> = [
        "AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA", "DEU", "GRC", "HUN", "IRL", "ITA", "LVA",
        "LTU", "LUX", "MLT", "NLD", "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE", "ISL", "LIE", "NOR", "GBR", "CHE",
        "GUF", "GLP", "MTQ", "REU", "MYT", "ALA", "GIB",
    ]

    /// True when `countryCode` (alpha-2 or alpha-3, any case) is in the EEA, the UK or
    /// Switzerland, or is unknown (nil or empty).
    public static func requiresConsent(countryCode: String?) -> Bool {
        guard let code = countryCode?.trimmingCharacters(in: .whitespaces).uppercased(), !code.isEmpty else { return true }
        return code.count == 3 ? alpha3.contains(code) : alpha2.contains(code)
    }
}

/// The stored answer and what it means, given a policy and a country.
struct ConsentState: Equatable {
    var policy: ConsentPolicy
    /// The user's answer (switch or question); nil = never decided.
    var stored: Bool?
    /// The App Store country (alpha-3) or the device region (alpha-2), if known.
    var countryCode: String?

    var requiresConsent: Bool {
        switch policy {
        case .askEveryone: true
        case .askInEuropeOnly: ConsentRegion.requiresConsent(countryCode: countryCode)
        }
    }

    /// Collecting now: the answer, or (no answer yet) on only where no question is needed.
    var isEnabled: Bool { stored ?? !requiresConsent }

    /// Ask once, until the user answers, only where it's required.
    var needsPrompt: Bool { stored == nil && requiresConsent }
}
