// swift-tools-version: 6.0
import PackageDescription

// Slice of Life shared library. Each module moved in from a shipped app is
// its own target and product, so an app imports only what it needs
// (see LIBRARY.md).
let package = Package(
    name: "SliceLibrary",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SliceKit", targets: ["SliceKit"]),
        .library(name: "SliceUI", targets: ["SliceUI"]),
        .library(name: "SliceQR", targets: ["SliceQR"]),
        .library(name: "SliceRating", targets: ["SliceRating"]),
        .library(name: "SlicePurchases", targets: ["SlicePurchases"]),
        .library(name: "SliceAnalytics", targets: ["SliceAnalytics"]),
    ],
    dependencies: [
        // Same ranges as Duly, so apps resolve one version of each.
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.96.0"),
        .package(url: "https://github.com/superwall/Superwall-iOS", .upToNextMinor(from: "4.18.0")),
        // 12.19.x only: newer Firebase needs a newer Xcode than 26.1.1.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMinor(from: "12.19.2")),
    ],
    targets: [
        .target(name: "SliceKit"),
        .target(name: "SliceUI", exclude: ["README.md"], resources: [.process("Resources")]),
        .target(name: "SliceQR", exclude: ["README.md"]),
        .target(name: "SliceRating", exclude: ["README.md"]),
        .target(
            name: "SlicePurchases",
            dependencies: [
                "SliceUI",
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
                // Superwall is iOS-only; on macOS (package tests) the native paywall path is used.
                .product(name: "SuperwallKit", package: "Superwall-iOS", condition: .when(platforms: [.iOS])),
            ],
            exclude: ["README.md"]
        ),
        .target(
            name: "SliceAnalytics",
            dependencies: [
                // iOS only here; on macOS (package tests) the consent and event logic runs without Firebase.
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
            ],
            exclude: ["README.md"]
        ),
        .testTarget(name: "SliceKitTests", dependencies: ["SliceKit"]),
        .testTarget(name: "SliceUITests", dependencies: ["SliceUI"]),
        .testTarget(name: "SliceQRTests", dependencies: ["SliceQR"]),
        .testTarget(name: "SliceRatingTests", dependencies: ["SliceRating"]),
        .testTarget(name: "SlicePurchasesTests", dependencies: ["SlicePurchases", "SliceUI"]),
        .testTarget(name: "SliceAnalyticsTests", dependencies: ["SliceAnalytics"]),
    ]
)
