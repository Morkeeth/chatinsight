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
            targets: ["ChatInsights"]),
        .executable(
            name: "chatinsights-server",
            targets: ["ChatInsightsCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/adamrushy/OpenAISwift.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // Main App
        .executableTarget(
            name: "ChatInsights",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "OpenAISwift", package: "OpenAISwift"),
                "MCPCore"
            ],
            path: "Sources",
            exclude: ["CLI", "MCPCore"]
        ),
        // CLI Server
        .executableTarget(
            name: "ChatInsightsCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "MCPCore"
            ],
            path: "Sources/CLI"
        ),
        // Shared MCP Core
        .target(
            name: "MCPCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/MCPCore"
        )
    ]
)

