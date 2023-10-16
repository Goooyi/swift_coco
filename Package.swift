// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift_coco",
    // dependencies: [
    //     .package(url: "https://github.com/google/flatbuffers.git", from: "23.5.26"),
    // ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swift_coco",
            path: "Sources"),
        .testTarget(
            name: "MyTests",
            dependencies: ["swift_coco"]
            // sources: [
            //     "Tests/MyTests", // Add the path to your test files here
            // ]
        )
    ]
)
