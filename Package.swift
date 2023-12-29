// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift_coco",
    // dependencies: [
    //     .package(url: "https://github.com/google/flatbuffers.git", from: "23.5.26"),
    // ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/pvieito/PythonKit.git", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swift_coco",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PythonKit", package: "PythonKit"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "MyTests",
            dependencies: ["swift_coco"]
            // sources: [
            //     "Tests/MyTests", // Add the path to your test files here
            // ]
        ),
    ]
)
