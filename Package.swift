// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatInsights",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ChatInsights",
            targets: ["ChatInsights"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/adamrushy/OpenAISwift.git", from: "1.4.0")
    ],
    targets: [
        .executableTarget(
            name: "ChatInsights",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "OpenAISwift", package: "OpenAISwift")
            ],
            path: "Sources"
        )
    ]
)

