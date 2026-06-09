// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tflite_flutter",
    platforms: [
        .macOS("10.11"),
    ],
    products: [
        .library(name: "tflite_flutter",  targets: ["tflite_flutter"]),
        .library(name: "tflite-flutter",  targets: ["tflite_flutter"]),
    ],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteC",
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