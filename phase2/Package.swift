// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "UntitledFolderPhase2",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "RenameExecutor",
            targets: ["RenameExecutor"]),
        .library(
            name: "DryRunMode",
            targets: ["DryRunMode"])
    ],
    dependencies: [
        .package(path: "../phase1")
    ],
    targets: [
        .target(
            name: "RenameExecutor",
            dependencies: [
                .product(name: "FilenameAnalyzer", package: "phase1")
            ]),
        .target(
            name: "DryRunMode",
            dependencies: [
                .product(name: "FilenameAnalyzer", package: "phase1")
            ]),
        .testTarget(
            name: "RenameExecutorTests",
            dependencies: ["RenameExecutor"]),
        .testTarget(
            name: "DryRunModeTests",
            dependencies: ["DryRunMode"])
    ]
) 