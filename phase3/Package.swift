// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "phase3",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LLMIntegration",
            targets: ["LLMIntegration"]
        ),
        .library(
            name: "LocalModelFallback",
            targets: ["LocalModelFallback"]
        ),
        .library(
            name: "GoogleAuth",
            targets: ["GoogleAuth"]
        ),
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [
        .package(path: "../phase1"),
        .package(path: "../phase2")
    ],
    targets: [
        .target(
            name: "GoogleAuth",
            dependencies: []
        ),
        .target(
            name: "Networking",
            dependencies: []
        ),
        .target(
            name: "LLMIntegration",
            dependencies: [
                .product(name: "FilenameAnalyzer", package: "phase1"),
                "GoogleAuth",
                "Networking"
            ]
        ),
        .target(
            name: "LocalModelFallback",
            dependencies: [
                "LLMIntegration",
                .product(name: "FilenameAnalyzer", package: "phase1")
            ]
        ),
        .testTarget(
            name: "GoogleAuthTests",
            dependencies: ["GoogleAuth"]
        ),
        .testTarget(
            name: "LLMIntegrationTests",
            dependencies: ["LLMIntegration"]
        ),
        .testTarget(
            name: "LocalModelFallbackTests",
            dependencies: ["LocalModelFallback"]
        )
    ]
) 