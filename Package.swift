// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "whisperkit",
    platforms: [
        .iOS(.v16),
        .macOS("13.3"),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "WhisperKit",
            targets: ["WhisperKit"]
        ),
    ] + (isMLXEnabled() ? [
        .executable(
            name: "whisperkit-cli",
            targets: ["WhisperKitCLI"]
        ),
        .library(
            name: "WhisperKitMLX",
            targets: ["WhisperKitMLX"]
        ),
    ] : []),
    dependencies: [
        .package(url: "https://github.com/huggingface/swift-transformers.git", exact: "0.1.7"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.3.0"),
    ] + (isMLXEnabled() ? [
        .package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.16.2"),
    ] : []),
    targets: [
        .target(
            name: "WhisperKit",
            dependencies: [
                .product(name: "Transformers", package: "swift-transformers"),
            ],
            path: "Sources/WhisperKit/Core"
        ),
        .testTarget(
            name: "WhisperKitTests",
            dependencies: [
                "WhisperKit",
                "WhisperKitTestsUtils",
                .product(name: "Transformers", package: "swift-transformers"),
            ]
        ),
        .target(
            name: "WhisperKitTestsUtils",
            dependencies: [
                "WhisperKit",
                .product(name: "Transformers", package: "swift-transformers"),
            ],
            path: ".",
            exclude: [
                "Examples",
                "Sources/WhisperKit",
                "Sources/WhisperKitCLI",
                "Tests",
                "Makefile",
                "README.md",
                "LICENSE",
                "CONTRIBUTING.md",
            ],
            resources: [
                .copy("Models/whisperkit-coreml"),
                .copy("Models/whisperkit-mlx"),
                .process("Sources/WhisperKitTestsUtils/Resources")
            ]
        ),
    ] + (isMLXEnabled() ? [
        .target(
            name: "WhisperKitMLX",
            dependencies: [
                "WhisperKit",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXFFT", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
            ],
            path: "Sources/WhisperKit/MLX",
            resources: [
                .copy("Resources/mel_filters_80.npy"),
                .copy("Resources/mel_filters_128.npy"),
            ]
        ),
        .testTarget(
            name: "WhisperKitMLXTests",
            dependencies: [
                "WhisperKit",
                "WhisperKitMLX",
                "WhisperKitTestsUtils",
                .product(name: "Transformers", package: "swift-transformers"),
            ]
        ),
        .executableTarget(
            name: "WhisperKitCLI",
            dependencies: [
                "WhisperKit",
                "WhisperKitMLX",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ] : [])
)

// NOTE: `MLX` doesn't support `watchOS` yet, that's why we control the build using the `MLX_DISABLED` environment variable.
// To manualy build for `watchOS` use:
// MLX_DISABLED=1 xcodebuild clean build-for-testing -scheme whisperkit -sdk watchos -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm)' -skipPackagePluginValidation
// or with swift build:
// MLX_DISABLED=1 swift build -c release

func isMLXEnabled() -> Bool {
    if let disabledValue = ProcessInfo.processInfo.environment["MLX_DISABLED"] {
        return disabledValue.lowercased() == "true" || disabledValue == "1"
    }

    // Default enabled
    return true
}
