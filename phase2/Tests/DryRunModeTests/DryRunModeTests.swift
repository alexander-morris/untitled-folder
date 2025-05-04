import XCTest
import FilenameAnalyzer
@testable import DryRunMode

final class DryRunModeTests: XCTestCase {
    var mockFileManager: MockFileManager!
    var tempDirectory: URL!
    var dryRun: DryRunMode!
    
    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        tempDirectory = URL(fileURLWithPath: "/test")
        dryRun = DryRunMode(fileManager: mockFileManager)
    }
    
    func testSuccessfulSimulation() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        mockFileManager.mockIsWritable = true
        
        // Create test file path
        let originalFile = tempDirectory.appendingPathComponent("test.txt")
        
        // Create rename proposal
        let proposal = RenameProposal(
            originalPath: originalFile,
            newName: "renamed.txt",
            confidence: 1.0
        )
        
        // Simulate rename
        let results = dryRun.simulate(proposals: [proposal])
        
        // Verify results
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].wouldSucceed)
        XCTAssertNil(results[0].error)
    }
    
    func testNameCollisionSimulation() throws {
        // Set up mock
        mockFileManager.mockFileExists = true
        mockFileManager.mockIsWritable = true
        
        // Create test file path
        let originalFile = tempDirectory.appendingPathComponent("test.txt")
        
        // Create rename proposal
        let proposal = RenameProposal(
            originalPath: originalFile,
            newName: "existing.txt",
            confidence: 1.0
        )
        
        // Simulate rename
        let results = dryRun.simulate(proposals: [proposal])
        
        // Verify results
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].wouldSucceed)
        XCTAssertNotNil(results[0].error)
        XCTAssertTrue(results[0].error?.localizedDescription.contains("Name collision") ?? false)
    }
    
    func testPermissionSimulation() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        mockFileManager.mockIsWritable = false
        
        // Create test file path
        let originalFile = tempDirectory.appendingPathComponent("test.txt")
        
        // Create rename proposal
        let proposal = RenameProposal(
            originalPath: originalFile,
            newName: "renamed.txt",
            confidence: 1.0
        )
        
        // Simulate rename
        let results = dryRun.simulate(proposals: [proposal])
        
        // Verify results
        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].wouldSucceed)
        XCTAssertNotNil(results[0].error)
        XCTAssertTrue(results[0].error?.localizedDescription.contains("Insufficient permissions") ?? false)
    }
    
    func testReportGeneration() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        mockFileManager.mockIsWritable = true
        
        // Create test file paths
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        
        // Create rename proposals
        let proposals = [
            RenameProposal(originalPath: file1, newName: "renamed1.txt", confidence: 1.0),
            RenameProposal(originalPath: file2, newName: "renamed1.txt", confidence: 1.0)
        ]
        
        // First file should succeed, second should fail due to collision
        mockFileManager.mockFileExists = false
        let results = dryRun.simulate(proposals: proposals)
        
        // Generate report
        let report = dryRun.generateReport(results: results)
        
        // Verify report content
        XCTAssertTrue(report.contains("Total operations: 2"))
        XCTAssertTrue(report.contains("Would succeed: 1"))
        XCTAssertTrue(report.contains("Would fail: 1"))
        XCTAssertTrue(report.contains("file1.txt → renamed1.txt"))
        XCTAssertTrue(report.contains("file2.txt → renamed1.txt"))
        XCTAssertTrue(report.contains("Name collision"))
    }
} 