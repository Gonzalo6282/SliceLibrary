import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Crisp QR code images. Each module of the code is scaled up with
/// nearest-neighbour sampling, so the edges stay sharp when printed or drawn
/// into a PDF.
public enum SliceQR {
    /// How much of the code can be damaged and still scan. Higher levels make
    /// a denser code for the same text.
    public enum CorrectionLevel: String, Sendable, CaseIterable {
        /// About 7% can be lost.
        case low = "L"
        /// About 15% can be lost. The default, and a good fit for print and PDFs.
        case medium = "M"
        /// About 25% can be lost.
        case quartile = "Q"
        /// About 30% can be lost. Use it when a logo sits on top of the code.
        case high = "H"
    }

    /// The QR code for `payload` as a CGImage, or nil if it can't be made
    /// (for example, text too long for a QR code).
    ///
    /// - Parameters:
    ///   - payload: The text to encode (a URL, a payment link, any string). Encoded as UTF-8.
    ///   - scale: Pixels per QR module. 12 gives a sharp code at PDF sizes.
    ///   - correction: The error-correction level.
    public static func cgImage(
        for payload: String, scale: CGFloat = 12, correction: CorrectionLevel = .medium
    ) -> CGImage? {
        guard !payload.isEmpty, scale > 0 else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = correction.rawValue
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: scale, y: scale)) else {
            return nil
        }
        return CIContext().createCGImage(output, from: output.extent)
    }

    #if canImport(UIKit)
    /// The QR code for `payload` as a UIImage, or nil if it can't be made.
    /// Same parameters as ``cgImage(for:scale:correction:)``.
    public static func image(
        for payload: String, scale: CGFloat = 12, correction: CorrectionLevel = .medium
    ) -> UIImage? {
        cgImage(for: payload, scale: scale, correction: correction).map { UIImage(cgImage: $0) }
    }
    #endif
}
