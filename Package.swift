// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnotherCombineCache",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "AnotherCombineCache",
            targets: ["AnotherCombineCache"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/rexcosta/AnotherSwiftCommonLib.git",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "AnotherCombineCache",
            dependencies: ["AnotherSwiftCommonLib"]
        ),
        .testTarget(
            name: "AnotherCombineCacheTests",
            dependencies: ["AnotherCombineCache"]
        ),
    ]
)
