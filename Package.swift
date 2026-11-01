// swift-tools-version: 6.0
import PackageDescription

// Slice of Life shared library. Each module moved in from a shipped app is
// its own target and product, so an app imports only what it needs
// (see LIBRARY.md).
let package = Package(
    name: "SliceLibrary",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SliceKit", targets: ["SliceKit"]),
        .library(name: "SliceUI", targets: ["SliceUI"]),
        .library(name: "SliceQR", targets: ["SliceQR"]),
        .library(name: "SliceRating", targets: ["SliceRating"]),
    ],
    targets: [
        .target(name: "SliceKit"),
        .target(name: "SliceUI"),
        .target(name: "SliceQR", exclude: ["README.md"]),
        .target(name: "SliceRating", exclude: ["README.md"]),
        .testTarget(name: "SliceKitTests", dependencies: ["SliceKit"]),
        .testTarget(name: "SliceUITests", dependencies: ["SliceUI"]),
        .testTarget(name: "SliceQRTests", dependencies: ["SliceQR"]),
        .testTarget(name: "SliceRatingTests", dependencies: ["SliceRating"]),
    ]
)
