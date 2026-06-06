// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tflite_flutter",
    platforms: [
        .macOS("10.11"),
    ],
    products: [
        .library(
            name: "tflite_flutter",
            targets: ["tflite_flutter"]
        ),
        .library(
            name: "tflite-flutter",
            targets: ["tflite_flutter"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "tflite_flutter",
            path: "Sources", 
            resources: []
        ),
    ]
)
