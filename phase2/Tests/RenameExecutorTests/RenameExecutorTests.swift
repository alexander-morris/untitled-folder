import XCTest
import FilenameAnalyzer
@testable import RenameExecutor

final class RenameExecutorTests: XCTestCase {
    var mockFileManager: MockFileManager!
    var tempDirectory: URL!
    var executor: RenameExecutor!
    
    override func setUpWithError() throws {
        mockFileManager = MockFileManager()
        tempDirectory = URL(fileURLWithPath: "/test")
        executor = RenameExecutor(fileManager: mockFileManager)
    }
    
    override func setUp() {
        mockFileManager.reset()
    }
    
    func testSuccessfulRename() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        
        // Create test file path
        let originalFile = tempDirectory.appendingPathComponent("test.txt")
        
        // Create rename proposal
        let proposal = RenameProposal(
            originalPath: originalFile,
            newName: "renamed.txt",
            confidence: 1.0
        )
        
        // Execute rename
        let results = try executor.execute(proposals: [proposal])
        
        // Verify results
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].success)
        XCTAssertEqual(mockFileManager.movedItems.count, 1)
        XCTAssertEqual(mockFileManager.movedItems[0].from, originalFile)
        XCTAssertEqual(mockFileManager.movedItems[0].to.lastPathComponent, "renamed.txt")
    }
    
    func testNameCollision() throws {
        // Set up mock
        mockFileManager.mockFileExists = true
        
        // Create test file path
        let originalFile = tempDirectory.appendingPathComponent("test.txt")
        
        // Create rename proposal
        let proposal = RenameProposal(
            originalPath: originalFile,
            newName: "existing.txt",
            confidence: 1.0
        )
        
        // Execute rename and expect failure
        XCTAssertThrowsError(try executor.execute(proposals: [proposal])) { error in
            XCTAssertTrue(error.localizedDescription.contains("Name collision"))
        }
        
        // Verify no files were moved
        XCTAssertEqual(mockFileManager.movedItems.count, 0)
    }
    
    func testBatchRenameWithRollback() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        
        // Create test file paths
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        let file3 = tempDirectory.appendingPathComponent("file3.txt")
        
        // Create rename proposals
        let proposals = [
            RenameProposal(originalPath: file1, newName: "renamed1.txt", confidence: 1.0),
            RenameProposal(originalPath: file2, newName: "renamed2.txt", confidence: 1.0),
            RenameProposal(originalPath: file3, newName: "renamed1.txt", confidence: 1.0) // This will cause a collision
        ]
        
        // Execute batch rename and expect failure due to name collision
        XCTAssertThrowsError(try executor.execute(proposals: proposals)) { error in
            XCTAssertTrue(error.localizedDescription.contains("Name collision"))
        }
        
        // Verify no files were moved since validation failed
        XCTAssertEqual(mockFileManager.movedItems.count, 0)
    }
    
    func testBatchRenameWithMoveFailure() throws {
        // Set up mock
        mockFileManager.mockFileExists = false
        
        // Create test file paths
        let file1 = tempDirectory.appendingPathComponent("file1.txt")
        let file2 = tempDirectory.appendingPathComponent("file2.txt")
        
        // Create rename proposals
        let proposals = [
            RenameProposal(originalPath: file1, newName: "renamed1.txt", confidence: 1.0),
            RenameProposal(originalPath: file2, newName: "renamed2.txt", confidence: 1.0)
        ]
        
        // Set up mock to fail on the second move
        var moveCount = 0
        mockFileManager.moveItemError = { url in
            moveCount += 1
            if moveCount == 2 {
                return NSError(domain: "Test", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Move failed"
                ])
            }
            return nil
        }
        
        // Execute batch rename and expect failure
        XCTAssertThrowsError(try executor.execute(proposals: proposals)) { error in
            XCTAssertTrue(error.localizedDescription.contains("Move failed"))
        }
        
        // Verify rollback occurred
        XCTAssertEqual(mockFileManager.movedItems.count, 2) // 1 original move + 1 rollback
        
        // Verify the sequence of operations
        XCTAssertEqual(mockFileManager.movedItems[0].from.lastPathComponent, "file1.txt")
        XCTAssertEqual(mockFileManager.movedItems[0].to.lastPathComponent, "renamed1.txt")
        
        XCTAssertEqual(mockFileManager.movedItems[1].from.lastPathComponent, "renamed1.txt")
        XCTAssertEqual(mockFileManager.movedItems[1].to.lastPathComponent, "file1.txt")
    }
} 