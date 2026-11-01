import SwiftUI

/// A number field that saves on every keystroke. (SwiftUI's
/// `TextField(value:format:)` only commits on return or focus loss, so tapping
/// "Done" in a sheet could lose what was typed.) Zero shows as empty.
/// Accepts the user's decimal and grouping separators; never negative.
public struct DecimalField: View {
    let placeholder: LocalizedStringKey
    @Binding var value: Decimal
    var allowsFraction: Bool

    @State private var text = ""
    @FocusState private var focused: Bool

    public init(_ placeholder: LocalizedStringKey, value: Binding<Decimal>, allowsFraction: Bool = true) {
        self.placeholder = placeholder
        _value = value
        self.allowsFraction = allowsFraction
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            #if os(iOS)
            .keyboardType(allowsFraction ? .decimalPad : .numberPad)
            #endif
            .focused($focused)
            .onAppear { text = Self.display(value) }
            .onChange(of: text) {
                if let parsed = Self.parse(text) { value = parsed }
            }
            .onChange(of: value) {
                // Outside changes (e.g. a different line) refresh the text when not editing.
                if !focused, Self.parse(text) != value { text = Self.display(value) }
            }
            .onChange(of: focused) {
                if !focused { text = Self.display(value) }
            }
    }

    /// "12.5", "12,5" (comma locales), "1,234.50"; empty = 0; nonsense = nil (keep the last value).
    nonisolated public static func parse(_ text: String, locale: Locale = .current) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        let decimalSep = locale.decimalSeparator ?? "."
        let groupSep = locale.groupingSeparator ?? ","
        var cleaned = trimmed.replacingOccurrences(of: groupSep == decimalSep ? "" : groupSep, with: "")
        if decimalSep != "." { cleaned = cleaned.replacingOccurrences(of: decimalSep, with: ".") }
        cleaned = cleaned.filter { "0123456789.-".contains($0) }
        guard !cleaned.isEmpty, cleaned.filter({ $0 == "." }).count <= 1,
            let d = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
        else { return nil }
        return max(d, 0)
    }

    /// The text shown for a value: "" for zero, no grouping.
    nonisolated public static func display(_ value: Decimal) -> String {
        value == 0 ? "" : value.formatted(.number.grouping(.never))
    }
}

/// Whole numbers (a next number, a count of days).
public struct IntField: View {
    let placeholder: LocalizedStringKey
    @Binding var value: Int

    public init(_ placeholder: LocalizedStringKey, value: Binding<Int>) {
        self.placeholder = placeholder
        _value = value
    }

    public var body: some View {
        DecimalField(
            placeholder,
            value: Binding(get: { Decimal(value) }, set: { value = Self.rounded($0) }),
            allowsFraction: false)
    }

    nonisolated static func rounded(_ value: Decimal) -> Int {
        var v = value, r = Decimal()
        NSDecimalRound(&r, &v, 0, .plain)
        return NSDecimalNumber(decimal: r).intValue
    }
}

extension Binding where Value == Decimal {
    /// Shows 0 as an empty field (so the placeholder appears and typing
    /// doesn't land next to a "0"); clearing the field stores 0.
    public var zeroAsEmpty: Binding<Decimal?> {
        Binding<Decimal?>(
            get: { wrappedValue == 0 ? nil : wrappedValue },
            set: { wrappedValue = $0 ?? 0 })
    }
}
