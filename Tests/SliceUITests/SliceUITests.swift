import Foundation
import SwiftUI
import Testing

@testable import SliceUI

@Test func versionMatchesTheTag() {
    #expect(SliceUI.version == "0.7.1")
}

// MARK: Colours

@Test func hexColours() throws {
    let lime = try #require(Color.parseHex("#7fee64"))
    #expect(lime.r == 0x7F / 255.0 && lime.g == 0xEE / 255.0 && lime.b == 0x64 / 255.0 && lime.a == 1)
    let half = try #require(Color.parseHex("00000080"))
    #expect(abs(half.a - 128 / 255.0) < 0.0001)
    #expect(Color.parseHex("#12345") == nil)
    #expect(Color.parseHex("zzzzzz") == nil)
    #expect(Color(hex: "nope") == .clear)
}

// MARK: Themes

@Test func darkThemeIsAlwaysDark() {
    let lime = Color(hex: "#7fee64")
    let theme = SliceTheme.dark(accent: lime)
    #expect(theme.appearance == .dark)
    #expect(theme.appearance.colorScheme == .dark)
    #expect(theme.accent == lime)
    #expect(theme.onAccent == .black)
    #expect(theme.canvas == .black)
    #expect(theme.ink == .white)
    #expect(theme.success == lime)
}

@Test func systemThemeFollowsTheSystem() {
    let theme = SliceTheme.system(accent: .orange)
    #expect(theme.appearance == .system)
    #expect(theme.appearance.colorScheme == nil)
    #expect(theme.accent == .orange)
    #expect(theme.onAccent == .white)
    #expect(SliceTheme.Appearance.light.colorScheme == .light)
}

@Test func missingColoursComeFromTheAccent() {
    let theme = SliceTheme(
        accent: .purple, canvas: .gray, surface: .white, surfaceAlt: .gray, line: .gray, ink: .black,
        inkSecondary: .gray, inkTertiary: .gray, success: .green, danger: .red, warning: .orange)
    #expect(theme.chipInk == .purple)
    #expect(theme.chipBackground == theme.accentSoft)
    #expect(theme.successText == .green)
    #expect(theme.display == .system)
}

@Test func componentsUseTheAppDefaultWithoutAModifier() {
    #expect(EnvironmentValues().sliceTheme.accent == SliceTheme.appDefault.accent)
    var env = EnvironmentValues()
    env.sliceTheme = .dark(accent: .yellow)
    #expect(env.sliceTheme.accent == .yellow)
}

// MARK: Fonts

@Test func systemFontsMatchSwiftUIStyles() {
    #expect(SliceFontFamily.system.font(.callout) == .callout)
    #expect(SliceFontFamily.system.font(.body, weight: .semibold) == Font.body.weight(.semibold))
    #expect(SliceFontFamily.system.font(fixedSize: 30, weight: .black) == .system(size: 30, weight: .black, design: .default))
    #expect(SliceFontFamily.system(design: .rounded).font(.title) == .system(.title, design: .rounded))
}

@Test func customFontsUseTheirFaces() {
    let inter = SliceFontFamily.custom("Inter-Regular", weights: [.bold: "Inter-Bold"])
    #expect(inter.font(.body) == .custom("Inter-Regular", size: 17, relativeTo: .body))
    #expect(inter.font(.footnote, weight: .bold) == .custom("Inter-Bold", size: 13, relativeTo: .footnote))
    #expect(inter.font(.footnote, weight: .medium) == Font.custom("Inter-Regular", size: 13, relativeTo: .footnote).weight(.medium))
    #expect(inter.font(fixedSize: 20, weight: .bold) == .custom("Inter-Bold", fixedSize: 20))
}

@Test func textStyles() {
    #expect(SliceTextStyle.largeTitle.size == 34 && SliceTextStyle.largeTitle.weight == .heavy)
    #expect(SliceTextStyle.pill.size == 12 && SliceTextStyle.pill.relativeTo == .caption)
    #expect(SliceTextStyle.headline.display)
    #expect(!SliceTextStyle.body.display)
}

// MARK: Component colours

@Test func iconTintsComeFromTheTheme() {
    let t = SliceTheme.standard
    #expect(IconChip.Tint.accent.tile(in: t) == t.chipBackground)
    #expect(IconChip.Tint.accent.glyph(in: t) == t.chipInk)
    #expect(IconChip.Tint.success.glyph(in: t) == t.successText)
    #expect(IconChip.Tint.danger.tile(in: t) == t.dangerSoft)
    #expect(IconChip.Tint.neutral.glyph(in: t) == t.inkSecondary)
    #expect(IconChip.Tint.custom(tile: .pink, glyph: .brown).glyph(in: t) == .brown)
}

@Test func pillTones() {
    let t = SliceTheme.standard
    #expect(Pill.Tone.neutral.colors(in: t).bordered)
    #expect(Pill.Tone.success.colors(in: t).background == t.success)
    #expect(Pill.Tone.success.colors(in: t).foreground == t.successInk)
    #expect(!Pill.Tone.accent.colors(in: t).bordered)
}

// MARK: Avatar and number fields

@Test(arguments: [
    ("Marlow & Finch Architects", "MF"), ("Ostara Café", "OC"), ("jonas", "J"), ("", "?"), ("  ", "?"),
    ("Ünal Öztürk", "ÜÖ"), ("4 Seasons Ltd", "4S"),
])
func avatarInitials(name: String, expected: String) {
    #expect(Avatar.initials(for: name) == expected)
}

@Test func decimalFieldParsesTyping() {
    let uk = Locale(identifier: "en_GB")
    let de = Locale(identifier: "de_DE")
    #expect(DecimalField.parse("", locale: uk) == 0)
    #expect(DecimalField.parse("5", locale: uk) == 5)
    #expect(DecimalField.parse("12.5", locale: uk) == Decimal(string: "12.5"))
    #expect(DecimalField.parse("1,234.50", locale: uk) == Decimal(string: "1234.5"))
    #expect(DecimalField.parse("12.", locale: uk) == 12)
    #expect(DecimalField.parse("12,5", locale: de) == Decimal(string: "12.5"))
    #expect(DecimalField.parse("1.234,5", locale: de) == Decimal(string: "1234.5"))
    #expect(DecimalField.parse("£40", locale: uk) == 40)
    #expect(DecimalField.parse("1.2.3", locale: uk) == nil)
    #expect(DecimalField.parse("abc", locale: uk) == nil)
    #expect(DecimalField.parse("-5", locale: uk) == 0)
}

@Test func decimalFieldShowsZeroAsEmpty() throws {
    #expect(DecimalField.display(0) == "")
    #expect(!DecimalField.display(try #require(Decimal(string: "87.5"))).isEmpty)
}

@Test func intFieldRoundsHalfAwayFromZero() throws {
    #expect(IntField.rounded(try #require(Decimal(string: "2.5"))) == 3)
    #expect(IntField.rounded(try #require(Decimal(string: "2.4"))) == 2)
}

// MARK: Rendering

@Test @MainActor func componentsRenderInBothThemes() throws {
    for theme in [SliceTheme.system(accent: .indigo), .dark(accent: Color(hex: "#7fee64"))] {
        let view = VStack(spacing: 12) {
            Text("Total").textStyle(.largeTitle)
            GroupedSection(header: "Section", footer: "Footer") {
                Row(icon: "qrcode", title: "Scan", meta: "Today", value: "3", showsChevron: true)
                RowDivider()
                Row(iconTint: .success, verbatim: "Saved") { Pill("New", tone: .accent) }
                FieldRow(label: "Name") { Text("Slice") }
            }
            Banner(tone: .ok, systemImage: "checkmark", text: Text("Saved"))
            HStack {
                ChoiceChip(title: "On", isOn: true) {}
                ChoiceChip(title: "Off", isOn: false) {}
                Avatar(name: "Slice Life")
                IconChip(systemName: "star", tint: .warning)
            }
            Button("Continue") {}.buttonStyle(.primary)
            Button("Later") {}.buttonStyle(.ghost)
            Button("Add") {}.buttonStyle(.small)
        }
        .frame(width: 390)
        .sliceTheme(theme)
        let renderer = ImageRenderer(content: view)
        let image = try #require(renderer.cgImage)
        #expect(image.width >= 390)
    }
}
