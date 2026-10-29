// swift-tools-version: 6.0
import PackageDescription

// Slice of Life shared library. Two products today; each module moved in
// from an app becomes its own target and product, so an app imports only
// what it needs (Automation Master Plan, Phase 5).
let package = Package(
    name: "SliceLibrary",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SliceKit", targets: ["SliceKit"]),
        .library(name: "SliceUI", targets: ["SliceUI"]),
    ],
    targets: [
        .target(name: "SliceKit"),
        .target(name: "SliceUI"),
        .testTarget(name: "SliceKitTests", dependencies: ["SliceKit"]),
        .testTarget(name: "SliceUITests", dependencies: ["SliceUI"]),
    ]
)
