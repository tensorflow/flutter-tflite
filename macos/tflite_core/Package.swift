// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tflite_flutter",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        .library(name: "tflite_flutter",  targets: ["tflite_flutter"]),
        .library(name: "tflite-flutter",  targets: ["tflite_flutter"]),
    ],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteC",
            // Local macOS xcframework (arm64 + x86_64 fat binary).
            // Built from macos/libtensorflowlite_c-mac.dylib via macos/rebuild_xcframework.sh.
            // Must be ad-hoc signed — run rebuild_xcframework.sh if this directory is missing
            // or if you see a codesign build failure.
            path: "TensorFlowLiteCMac.xcframework"
        ),
        .target(
            name: "tflite_flutter",
            dependencies: ["TensorFlowLiteC"],
            path: "Sources",
            publicHeadersPath: "."
        ),
    ]
)