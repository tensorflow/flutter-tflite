// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tflite_core",
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "tflite_core",  targets: ["tflite_core"]),
        .library(name: "tflite-flutter",  targets: ["tflite_core"]),
    ],
    targets: [
        .binaryTarget(
            name: "TensorFlowLiteC",
            url: "https://github.com/kewlbear/TensorFlowLiteC/releases/download/0.0.20240626/TensorFlowLiteC.xcframework.zip",
            checksum: "3b527a7be16aa02f0900deb40d1561df839fdce96cf2d1aaa80388b5c28e2ac3"
        ),
        .target(
            name: "tflite_core",
            dependencies: ["TensorFlowLiteC"],
            path: "Sources",
            publicHeadersPath: "."
        ),
    ]
)