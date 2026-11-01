# SliceQR

Crisp QR code images for any text: payment links, URLs, Wi‑Fi details,
contact cards. Edges stay sharp when printed or drawn into a PDF (each module
is scaled up with nearest-neighbour sampling).

Generation only. Scanning with the camera lives in the app for now.

## Use

```swift
import SliceQR

// UIKit / SwiftUI (iOS)
let image = SliceQR.image(for: "https://buy.stripe.com/abc")           // UIImage?
Image(uiImage: image!).interpolation(.none).resizable().scaledToFit()

// Core Graphics (PDF drawing, macOS, tests)
let cg = SliceQR.cgImage(for: "https://slice-of-life.uk", scale: 8, correction: .high)
```

## API

| Call | Returns |
|---|---|
| `SliceQR.cgImage(for:scale:correction:)` | `CGImage?` |
| `SliceQR.image(for:scale:correction:)` (iOS) | `UIImage?` |
| `SliceQR.CorrectionLevel` | `.low`, `.medium` (default), `.quartile`, `.high` |

- `scale`: pixels per QR module, default 12.
- Returns nil for empty text, a scale of 0 or less, or text too long for a QR
  code (about 2,900 bytes at `.low`).
- In SwiftUI, draw it with `.interpolation(.none)` so it stays sharp when resized.

Used by: Duly (payment QR code on invoices).
