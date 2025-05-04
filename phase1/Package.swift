// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "UntitledFolderCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FileScanner",
            targets: ["FileScanner"]),
        .library(
            name: "FilenameAnalyzer",
            targets: ["FilenameAnalyzer"]),
    ],
    dependencies: [
        // Add dependencies here as needed
    ],
    targets: [
        .target(
            name: "FileScanner",
            dependencies: []),
        .target(
            name: "FilenameAnalyzer",
            dependencies: ["FileScanner"],
            linkerSettings: [
                .linkedFramework("ImageIO"),
                .linkedFramework("PDFKit")
            ]),
        .testTarget(
            name: "FileScannerTests",
            dependencies: ["FileScanner"]),
        .testTarget(
            name: "FilenameAnalyzerTests",
            dependencies: ["FilenameAnalyzer"]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["FileScanner", "FilenameAnalyzer"]),
    ]
) 