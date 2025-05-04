import XCTest
@testable import FileScanner

final class FileScannerTests: XCTestCase {
    var fileManager: FileManager!
    var tempDirectory: URL!
    var scanner: FileScanner!
    
    override func setUpWithError() throws {
        fileManager = FileManager()
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        scanner = FileScanner(fileManager: fileManager)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempDirectory)
    }
    
    func testScanEmptyDirectory() throws {
        let results = try scanner.scanDirectory(at: tempDirectory)
        XCTAssertTrue(results.isEmpty)
    }
    
    func testScanWithUntitledFiles() throws {
        // Create test files
        let untitledFile = tempDirectory.appendingPathComponent("Untitled.txt")
        let newFolder = tempDirectory.appendingPathComponent("New Folder")
        let regularFile = tempDirectory.appendingPathComponent("RegularFile.txt")
        
        try "test".write(to: untitledFile, atomically: true, encoding: .utf8)
        try fileManager.createDirectory(at: newFolder, withIntermediateDirectories: true)
        try "test".write(to: regularFile, atomically: true, encoding: .utf8)
        
        let results = try scanner.scanDirectory(at: tempDirectory)
        XCTAssertEqual(results.count, 2)
        
        let paths = results.map { $0.path.lastPathComponent }.sorted()
        XCTAssertEqual(paths, ["New Folder", "Untitled.txt"])
    }
    
    func testScanWithNestedDirectories() throws {
        // Create nested structure
        let nestedDir = tempDirectory.appendingPathComponent("Nested")
        try fileManager.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        
        let untitledFile = nestedDir.appendingPathComponent("Untitled.txt")
        try "test".write(to: untitledFile, atomically: true, encoding: .utf8)
        
        let results = try scanner.scanDirectory(at: tempDirectory)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].path.lastPathComponent, "Untitled.txt")
    }
    
    func testFileMetadata() throws {
        let untitledFile = tempDirectory.appendingPathComponent("Untitled.txt")
        try "test".write(to: untitledFile, atomically: true, encoding: .utf8)
        
        let results = try scanner.scanDirectory(at: tempDirectory)
        XCTAssertEqual(results.count, 1)
        
        let metadata = results[0]
        XCTAssertEqual(metadata.path.lastPathComponent, untitledFile.lastPathComponent)
        XCTAssertFalse(metadata.isDirectory)
        XCTAssertGreaterThan(metadata.size, 0)
        XCTAssertLessThan(metadata.modificationDate.timeIntervalSinceNow, 1)
    }
} 