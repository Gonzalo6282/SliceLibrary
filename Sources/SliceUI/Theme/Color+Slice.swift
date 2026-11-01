import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// A colour from a hex string: `"#7FEE64"`, `"7FEE64"`, or with alpha `"#7FEE6480"`.
    /// Invalid strings give clear.
    public init(hex: String) {
        self = Self.parseHex(hex).map { Color(.sRGB, red: $0.r, green: $0.g, blue: $0.b, opacity: $0.a) } ?? .clear
    }

    /// A colour that follows the system appearance: `light` in light mode, `dark` in dark mode.
    public init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }

    /// Hex in light mode, hex in dark mode.
    public init(light: String, dark: String) {
        self.init(light: Color(hex: light), dark: Color(hex: dark))
    }

    nonisolated static func parseHex(_ hex: String) -> (r: Double, g: Double, b: Double, a: Double)? {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let value = UInt64(s, radix: 16) else { return nil }
        let hasAlpha = s.count == 8
        let r = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? Double(value & 0xFF) / 255 : 1
        return (r, g, b, a)
    }
}
