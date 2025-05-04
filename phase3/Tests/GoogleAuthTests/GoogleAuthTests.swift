import XCTest
import AuthenticationServices
@testable import GoogleAuth

final class GoogleAuthTests: XCTestCase {
    var authManager: GoogleAuthManager!
    fileprivate var mockSession: MockWebAuthSession!
    
    override func setUp() {
        super.setUp()
        authManager = GoogleAuthManager(
            clientId: "test-client-id",
            clientSecret: "test-client-secret",
            redirectURI: "test-redirect-uri"
        )
    }
    
    override func tearDown() {
        authManager = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testSignInURLConstruction() async throws {
        // Create a mock session with a dummy URL
        let dummyURL = URL(string: "https://example.com")!
        mockSession = MockWebAuthSession(
            url: dummyURL,
            callbackURLScheme: "test-redirect-uri",
            completionHandler: { _, _ in }
        )
        
        // Set the mock session
        authManager.webAuthSession = mockSession
        
        // Attempt to sign in
        do {
            _ = try await authManager.signIn()
            XCTFail("Expected error")
        } catch {
            // Verify the URL components
            guard let capturedURL = mockSession.capturedURL else {
                XCTFail("No URL was captured")
                return
            }
            
            XCTAssertEqual(capturedURL.scheme, "https")
            XCTAssertEqual(capturedURL.host, "accounts.google.com")
            XCTAssertEqual(capturedURL.path, "/o/oauth2/v2/auth")
            
            guard let components = URLComponents(url: capturedURL, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                XCTFail("Could not parse URL components")
                return
            }
            
            XCTAssertTrue(queryItems.contains { $0.name == "client_id" && $0.value == "test-client-id" })
            XCTAssertTrue(queryItems.contains { $0.name == "redirect_uri" && $0.value == "test-redirect-uri" })
            XCTAssertTrue(queryItems.contains { $0.name == "response_type" && $0.value == "code" })
            XCTAssertTrue(queryItems.contains { $0.name == "scope" && $0.value?.contains("https://www.googleapis.com/auth/generative-language") == true })
        }
    }
    
    func testSignInCancellation() async throws {
        // Create a mock session that simulates user cancellation
        let dummyURL = URL(string: "https://example.com")!
        mockSession = MockWebAuthSession(
            url: dummyURL,
            callbackURLScheme: "test-redirect-uri",
            completionHandler: { _, _ in }
        )
        mockSession.shouldCancel = true
        
        // Set the mock session
        authManager.webAuthSession = mockSession
        
        // Attempt to sign in
        do {
            _ = try await authManager.signIn()
            XCTFail("Expected error")
        } catch let error as GoogleAuthError {
            if case .networkError(let description) = error {
                XCTAssertTrue(description.contains("canceledLogin"), "Expected cancellation error")
            } else {
                XCTFail("Expected network error with cancellation")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTokenExchange() async throws {
        // Create a mock session that simulates successful authentication
        let dummyURL = URL(string: "https://example.com")!
        mockSession = MockWebAuthSession(
            url: dummyURL,
            callbackURLScheme: "test-redirect-uri",
            completionHandler: { _, _ in }
        )
        mockSession.callbackURL = URL(string: "test-redirect-uri://?code=test-code")!
        
        // Set the mock session
        authManager.webAuthSession = mockSession
        
        // Attempt to sign in
        do {
            _ = try await authManager.signIn()
            XCTFail("Expected error")
        } catch let error as GoogleAuthError {
            if case .networkError(let description) = error {
                XCTAssertTrue(description.contains("noAccessToken"), "Expected no access token error")
            } else {
                XCTFail("Expected network error with no access token")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock Web Auth Session

fileprivate class MockWebAuthSession: ASWebAuthenticationSession {
    var capturedURL: URL?
    var shouldCancel = false
    var callbackURL: URL?
    private var storedCompletionHandler: ((URL?, Error?) -> Void)?
    
    override init(url: URL, callbackURLScheme: String?, completionHandler: @escaping (URL?, Error?) -> Void) {
        super.init(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
        self.capturedURL = url
        self.storedCompletionHandler = completionHandler
    }
    
    override func start() -> Bool {
        if shouldCancel {
            storedCompletionHandler?(nil, NSError(domain: ASWebAuthenticationSessionErrorDomain, code: ASWebAuthenticationSessionError.canceledLogin.rawValue))
        } else if let callbackURL = callbackURL {
            storedCompletionHandler?(callbackURL, nil)
        }
        return true
    }
} 