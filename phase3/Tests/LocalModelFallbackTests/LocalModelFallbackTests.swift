import XCTest
@testable import LocalModelFallback

final class LocalModelFallbackTests: XCTestCase {
    var fallback: LocalModelFallback!
    let fixedDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
    
    override func setUp() {
        super.setUp()
        fallback = LocalModelFallback()
    }
    
    override func tearDown() {
        fallback = nil
        super.tearDown()
    }
    
    func testScreenshotNaming() {
        let metadata: [String: Any] = [
            "creationDate": fixedDate,
            "fileType": "png"
        ]
        let response = fallback.suggestName(path: "Screenshot 2023.png", metadata: metadata)
        
        XCTAssertEqual(response.suggestedName, "Screenshot_2022-01-01_00-00.png")
        XCTAssertTrue(response.confidence > 0.5)
        XCTAssertTrue(response.reasoning.contains("screenshot"))
    }
    
    func testDocumentNaming() {
        let metadata: [String: Any] = [
            "creationDate": fixedDate,
            "fileType": "pdf"
        ]
        let response = fallback.suggestName(path: "Untitled.pdf", metadata: metadata)
        
        XCTAssertEqual(response.suggestedName, "Document_2022-01-01_00-00.pdf")
        XCTAssertTrue(response.confidence > 0.5)
        XCTAssertTrue(response.reasoning.contains("PDF document"))
    }
    
    func testPhotoNaming() {
        let metadata: [String: Any] = [
            "creationDate": fixedDate,
            "fileType": "jpg"
        ]
        let response = fallback.suggestName(path: "IMG_1234.jpg", metadata: metadata)
        
        XCTAssertEqual(response.suggestedName, "Photo_2022-01-01_00-00.jpg")
        XCTAssertTrue(response.confidence > 0.5)
        XCTAssertTrue(response.reasoning.contains("photo"))
    }
    
    func testNoteNaming() {
        let metadata: [String: Any] = [
            "creationDate": fixedDate,
            "fileType": "txt"
        ]
        let response = fallback.suggestName(path: "Untitled.txt", metadata: metadata)
        
        XCTAssertEqual(response.suggestedName, "Note_2022-01-01_00-00.txt")
        XCTAssertTrue(response.confidence > 0.5)
        XCTAssertTrue(response.reasoning.contains("text document"))
    }
    
    func testUnknownFileTypeNaming() {
        let metadata: [String: Any] = [:]
        let response = fallback.suggestName(path: "test.xyz", metadata: metadata)
        
        XCTAssertEqual(response.suggestedName, "File_2022-01-01_00-00.xyz")
        XCTAssertTrue(response.confidence > 0.5)
        XCTAssertTrue(response.reasoning.contains("Unknown file type"))
    }
    
    func testGenerateResponse() async throws {
        let response = try await fallback.generateResponse(for: "What is the capital of France?")
        XCTAssertTrue(response.contains("Paris"))
    }
    
    func testGenerateResponseWithContext() async throws {
        let response = try await fallback.generateResponse(
            for: "What is the capital of France?",
            context: "France is a country in Europe."
        )
        XCTAssertTrue(response.contains("Paris"))
        XCTAssertTrue(response.contains("Context"))
    }
    
    func testGenerateResponseWithEmptyPrompt() async throws {
        do {
            _ = try await fallback.generateResponse(for: "")
            XCTFail("Expected error for empty prompt")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Empty prompt"))
        }
    }
    
    func testGenerateResponseWithDate() async throws {
        let prompt = "What is today's date?"
        let response = try await fallback.generateResponse(for: prompt)
        
        XCTAssertFalse(response.isEmpty)
        
        // Get current date in the expected format
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let expectedDate = formatter.string(from: Date())
        
        XCTAssertTrue(response.contains(expectedDate))
    }
} 