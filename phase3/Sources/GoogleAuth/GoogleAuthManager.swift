import Foundation
import AuthenticationServices

/// Errors that can occur during Google authentication
public enum GoogleAuthError: Error, Equatable {
    case userCancelled
    case invalidRedirectURI
    case noAccessToken
    case invalidResponse
    case networkError(String)
    case unknownError(String)
    
    public static func == (lhs: GoogleAuthError, rhs: GoogleAuthError) -> Bool {
        switch (lhs, rhs) {
        case (.userCancelled, .userCancelled),
             (.invalidRedirectURI, .invalidRedirectURI),
             (.noAccessToken, .noAccessToken),
             (.invalidResponse, .invalidResponse):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)),
             (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Manages Google Sign-In authentication
public class GoogleAuthManager: NSObject {
    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String
    var webAuthSession: ASWebAuthenticationSession?
    private var accessToken: String?
    
    public init(clientId: String, clientSecret: String, redirectURI: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        super.init()
    }
    
    /// Signs in with Google and returns an access token
    /// - Returns: Access token if successful
    public func signIn() async throws -> String {
        guard let redirectURL = URL(string: redirectURI) else {
            throw GoogleAuthError.invalidRedirectURI
        }
        
        let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/generative-language")
        ]
        
        guard let finalURL = components.url else {
            throw GoogleAuthError.invalidRedirectURI
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.webAuthSession = ASWebAuthenticationSession(
                    url: finalURL,
                    callbackURLScheme: redirectURL.scheme
                ) { callbackURL, error in
                    if let error = error {
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            continuation.resume(throwing: GoogleAuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: GoogleAuthError.networkError(error.localizedDescription))
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL,
                          let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                        continuation.resume(throwing: GoogleAuthError.invalidResponse)
                        return
                    }
                    
                    Task {
                        do {
                            let token = try await self.exchangeCodeForToken(code)
                            self.accessToken = token
                            continuation.resume(returning: token)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                self.webAuthSession?.start()
            }
        }
    }
    
    /// Exchanges the authorization code for an access token
    /// - Parameter code: Authorization code from Google
    /// - Returns: Access token
    private func exchangeCodeForToken(_ code: String) async throws -> String {
        guard let tokenURL = URL(string: "https://oauth2.googleapis.com/token") else {
            throw GoogleAuthError.invalidRedirectURI
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GoogleAuthError.invalidResponse
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw GoogleAuthError.noAccessToken
        }
        
        return accessToken
    }
}

extension GoogleAuthManager: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Ensure we're on the main thread when accessing UI elements
        if Thread.isMainThread {
            return NSApplication.shared.windows.first ?? NSWindow()
        } else {
            var window: NSWindow?
            DispatchQueue.main.sync {
                window = NSApplication.shared.windows.first ?? NSWindow()
            }
            return window!
        }
    }
} 