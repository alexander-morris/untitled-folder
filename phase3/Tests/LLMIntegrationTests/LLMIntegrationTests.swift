import XCTest
@testable import LLMIntegration

// Mock URLSession for testing
class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        guard let data = data, let response = response else {
            throw URLError(.unknown)
        }
        return (data, response)
    }
}

final class LLMIntegrationTests: XCTestCase {
    var mockSession: MockURLSession!
    var llmIntegration: LLMIntegration!
    let fixedDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        let config = LLMConfig(apiKey: "test-key", model: "test-model", maxTokens: 100)
        llmIntegration = LLMIntegration(config: config, session: mockSession)
    }
    
    override func tearDown() {
        mockSession = nil
        llmIntegration = nil
        super.tearDown()
    }
    
    func testSuggestNameSuccess() async throws {
        // Prepare mock response
        let responseJSON = """
        {
            "choices": [
                {
                    "text": "suggested_name\\nConfidence: 0.95\\nThis is a test reasoning"
                }
            ]
        }
        """
        mockSession.data = responseJSON.data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Test
        let response = try await llmIntegration.suggestName(
            for: "test.txt",
            fileType: "text",
            fileContent: "test content",
            context: ["context1", "context2"]
        )
        
        // Verify
        XCTAssertEqual(response.suggestedName, "suggested_name")
        XCTAssertEqual(response.confidence, 0.95)
        XCTAssertEqual(response.reasoning, "This is a test reasoning")
    }
    
    func testSuggestNameNetworkError() async {
        // Prepare mock error
        mockSession.error = URLError(.badServerResponse)
        
        // Test and verify
        do {
            _ = try await llmIntegration.suggestName(
                for: "test.txt",
                fileType: "text"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as LLMError {
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected networkError but got \(error)")
            }
        } catch {
            XCTFail("Expected LLMError but got \(error)")
        }
    }
    
    func testSuggestNameInvalidResponse() async {
        // Prepare invalid response
        let responseJSON = """
        {
            "choices": []
        }
        """
        mockSession.data = responseJSON.data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/completions")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Test and verify
        do {
            _ = try await llmIntegration.suggestName(
                for: "test.txt",
                fileType: "text"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as LLMError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Expected LLMError but got \(error)")
        }
    }
    
    func testSuggestNameTokenLimitExceeded() async {
        // Create LLM with small token limit
        let config = LLMConfig(apiKey: "test-key", model: "test-model", maxTokens: 10)
        llmIntegration = LLMIntegration(config: config, session: mockSession)
        
        // Test and verify
        do {
            _ = try await llmIntegration.suggestName(
                for: "test.txt",
                fileType: "text",
                fileContent: "This is a very long content that should exceed the token limit"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as LLMError {
            XCTAssertEqual(error, .tokenLimitExceeded)
        } catch {
            XCTFail("Expected LLMError but got \(error)")
        }
    }
    
    func testSuggestNameAPIError() async {
        // Prepare error response
        mockSession.data = "{}".data(using: .utf8)
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/completions")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Test and verify
        do {
            _ = try await llmIntegration.suggestName(
                for: "test.txt",
                fileType: "text"
            )
            XCTFail("Expected error to be thrown")
        } catch let error as LLMError {
            if case .apiError(let message) = error {
                XCTAssertEqual(message, "HTTP 401")
            } else {
                XCTFail("Expected apiError but got \(error)")
            }
        } catch {
            XCTFail("Expected LLMError but got \(error)")
        }
    }
} 