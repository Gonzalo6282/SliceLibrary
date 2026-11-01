import CoreGraphics
import CoreImage
import SliceQR
import Testing

/// Reads the QR code back with Core Image's detector.
private func decode(_ image: CGImage) -> String? {
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    let features = detector?.features(in: CIImage(cgImage: image)) ?? []
    return (features.first as? CIQRCodeFeature)?.messageString
}

@Test func encodesTheTextAndReadsBack() throws {
    for text in ["https://buy.stripe.com/abc", "Café · 12,50 €", "WIFI:S:Home;T:WPA;P:secret;;"] {
        let image = try #require(SliceQR.cgImage(for: text))
        #expect(decode(image) == text)
    }
}

@Test func everyCorrectionLevelReadsBack() throws {
    for level in SliceQR.CorrectionLevel.allCases {
        let image = try #require(SliceQR.cgImage(for: "https://slice-of-life.uk", correction: level))
        #expect(decode(image) == "https://slice-of-life.uk")
    }
}

@Test func scaleMultipliesTheSize() throws {
    let one = try #require(SliceQR.cgImage(for: "hello", scale: 1))
    let twelve = try #require(SliceQR.cgImage(for: "hello", scale: 12))
    #expect(twelve.width == one.width * 12)
    #expect(twelve.height == one.height * 12)
    #expect(one.width == one.height)
}

@Test func higherCorrectionMakesADenserCode() throws {
    let low = try #require(SliceQR.cgImage(for: "https://slice-of-life.uk/apps", scale: 1, correction: .low))
    let high = try #require(SliceQR.cgImage(for: "https://slice-of-life.uk/apps", scale: 1, correction: .high))
    #expect(high.width > low.width)
}

@Test func emptyTextOrBadScaleGivesNil() {
    #expect(SliceQR.cgImage(for: "") == nil)
    #expect(SliceQR.cgImage(for: "x", scale: 0) == nil)
}

@Test func textTooLongForAQRCodeGivesNil() {
    // A QR code holds at most 2,953 bytes (version 40, level L).
    #expect(SliceQR.cgImage(for: String(repeating: "a", count: 4_000), correction: .low) == nil)
}
