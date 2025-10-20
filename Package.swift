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
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // Main App
        .executableTarget(
            name: "ChatInsights",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "OpenAISwift", package: "OpenAISwift"),
                .product(name: "ModelContextProtocol", package: "swift-sdk"),
                "MCPCore"
            ],
            path: "Sources",
            exclude: ["CLI"]
        ),
        // CLI Server
        .executableTarget(
            name: "ChatInsightsCLI",
            dependencies: [
                .product(name: "ModelContextProtocol", package: "swift-sdk"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "MCPCore"
            ],
            path: "Sources/CLI"
        ),
        // Shared MCP Core
        .target(
            name: "MCPCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ModelContextProtocol", package: "swift-sdk")
            ],
            path: "Sources/MCPCore"
        )
    ]
)

