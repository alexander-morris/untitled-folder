import XCTest
@testable import FileScanner
@testable import FilenameAnalyzer

final class IntegrationTests: XCTestCase {
    var fileManager: FileManager!
    var tempDirectory: URL!
    var scanner: FileScanner!
    var analyzer: FilenameAnalyzer!
    
    override func setUpWithError() throws {
        fileManager = FileManager()
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        scanner = FileScanner(fileManager: fileManager)
        analyzer = FilenameAnalyzer()
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempDirectory)
    }
    
    func testEndToEndRenameProcess() throws {
        // Create test files
        let untitledFile = tempDirectory.appendingPathComponent("Untitled.txt")
        let newFolder = tempDirectory.appendingPathComponent("New Folder")
        let screenshot = tempDirectory.appendingPathComponent("Screenshot.png")
        
        try "test".write(to: untitledFile, atomically: true, encoding: .utf8)
        try fileManager.createDirectory(at: newFolder, withIntermediateDirectories: true)
        try "test".write(to: screenshot, atomically: true, encoding: .utf8)
        
        // Scan for untitled files
        let metadataList = try scanner.scanDirectory(at: tempDirectory)
        XCTAssertEqual(metadataList.count, 3)
        
        // Analyze each file
        var proposals: [RenameProposal] = []
        for metadata in metadataList {
            let proposal = try analyzer.analyze(metadata: metadata)
            proposals.append(proposal)
        }
        
        // Verify proposals
        XCTAssertEqual(proposals.count, 3)
        
        // Sort proposals by original path for consistent testing
        let sortedProposals = proposals.sorted { $0.originalPath.path < $1.originalPath.path }
        
        // Create a map of path components to proposals for easier lookup
        let proposalMap = Dictionary(uniqueKeysWithValues: sortedProposals.map { ($0.originalPath.lastPathComponent, $0) })
        
        // Check each file's proposal
        let untitledProposal = proposalMap[untitledFile.lastPathComponent]
        XCTAssertNotNil(untitledProposal)
        XCTAssertTrue(untitledProposal?.newName.hasPrefix("Document_") ?? false)
        XCTAssertTrue(untitledProposal?.newName.hasSuffix(".txt") ?? false)
        
        let folderProposal = proposalMap[newFolder.lastPathComponent]
        XCTAssertNotNil(folderProposal)
        XCTAssertTrue(folderProposal?.newName.hasPrefix("Folder_") ?? false)
        
        let screenshotProposal = proposalMap[screenshot.lastPathComponent]
        XCTAssertNotNil(screenshotProposal)
        XCTAssertTrue(screenshotProposal?.newName.hasPrefix("Screenshot_") ?? false)
        XCTAssertTrue(screenshotProposal?.newName.hasSuffix(".png") ?? false)
    }
    
    func testPerformance() throws {
        // Create a large number of test files
        let fileCount = 100
        for i in 0..<fileCount {
            let fileName = "Untitled_\(i).txt"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            try "test".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        // Measure scanning performance
        measure {
            _ = try? scanner.scanDirectory(at: tempDirectory)
        }
    }
    
    func testAnalysisPerformance() throws {
        // Create test files and get metadata
        let fileCount = 100
        for i in 0..<fileCount {
            let fileName = "Untitled_\(i).txt"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            try "test".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let metadataList = try scanner.scanDirectory(at: tempDirectory)
        
        // Measure analysis performance
        measure {
            for metadata in metadataList {
                _ = try? analyzer.analyze(metadata: metadata)
            }
        }
    }
} 