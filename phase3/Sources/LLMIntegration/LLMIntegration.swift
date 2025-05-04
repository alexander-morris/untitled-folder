import Foundation
import Networking

/// Configuration for the LLM API
public struct LLMConfig {
    public let apiKey: String
    public let model: String
    public let maxTokens: Int
    public let temperature: Double
    
    public init(apiKey: String, model: String, maxTokens: Int = 100, temperature: Double = 0.7) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

/// Response from the LLM API
public struct LLMResponse: Equatable {
    public let suggestedName: String
    public let confidence: Double
    public let reasoning: String
    
    public init(suggestedName: String, confidence: Double, reasoning: String) {
        self.suggestedName = suggestedName
        self.confidence = confidence
        self.reasoning = reasoning
    }
}

/// Errors that can occur during LLM operations
public enum LLMError: Error, Equatable {
    case invalidRequest
    case networkError(Error)
    case invalidResponse
    case tokenLimitExceeded
    case apiError(String)
    
    public static func == (lhs: LLMError, rhs: LLMError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidRequest, .invalidRequest),
             (.invalidResponse, .invalidResponse),
             (.tokenLimitExceeded, .tokenLimitExceeded):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.apiError(let lhsMessage), .apiError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// Protocol for URL session to enable testing
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Handles communication with LLM APIs for name suggestions
public class LLMIntegration {
    private let config: LLMConfig
    private let session: URLSessionProtocol
    private let jsonDecoder = JSONDecoder()
    
    public init(config: LLMConfig, session: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.session = session
    }
    
    /// Suggests a name for a file based on its metadata and optional context
    /// - Parameters:
    ///   - fileName: Current file name
    ///   - fileType: File type
    ///   - fileContent: Optional file content preview
    ///   - context: Optional context about the file
    /// - Returns: LLM response with name suggestion
    public func suggestName(
        for fileName: String,
        fileType: String,
        fileContent: String? = nil,
        context: [String]? = nil
    ) async throws -> LLMResponse {
        do {
            // Format prompt
            let prompt = formatPrompt(fileName: fileName, fileType: fileType, fileContent: fileContent, context: context)
            
            // Check token limit
            if prompt.count > config.maxTokens {
                throw LLMError.tokenLimitExceeded
            }
            
            // Create request
            let request = try createRequest(with: prompt)
            
            // Send request
            let (data, response) = try await session.data(for: request)
            
            // Handle response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseResponse(data: data)
            default:
                throw LLMError.apiError("HTTP \(httpResponse.statusCode)")
            }
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.networkError(error)
        }
    }
    
    /// Formats the prompt for the LLM API
    private func formatPrompt(
        fileName: String,
        fileType: String,
        fileContent: String?,
        context: [String]?
    ) -> String {
        var prompt = """
        Suggest a descriptive filename for a file with the following characteristics:
        
        Current name: \(fileName)
        File type: \(fileType)
        """
        
        if let content = fileContent {
            prompt += "\n\nFile content preview:\n\(content)"
        }
        
        if let context = context {
            prompt += "\n\nContext files:\n"
            context.forEach { prompt += "- \($0)\n" }
        }
        
        prompt += """
        
        Please provide your response in the following format:
        <filename>
        Confidence: <0.0-1.0>
        <reasoning>
        """
        
        return prompt
    }
    
    /// Creates an URLRequest for the LLM API
    private func createRequest(with prompt: String) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
            throw LLMError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": config.model,
            "prompt": prompt,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    /// Parses the response from the LLM API
    private func parseResponse(data: Data) throws -> LLMResponse {
        struct Response: Codable {
            struct Choice: Codable {
                let text: String
            }
            let choices: [Choice]
        }
        
        do {
            let response = try jsonDecoder.decode(Response.self, from: data)
            guard let text = response.choices.first?.text else {
                throw LLMError.invalidResponse
            }
            
            // Parse the response text to extract the suggested name, confidence, and reasoning
            let lines = text.split(separator: "\n")
            guard lines.count >= 3,
                  let confidence = Double(lines[1].split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) else {
                throw LLMError.invalidResponse
            }
            
            return LLMResponse(
                suggestedName: String(lines[0]),
                confidence: confidence,
                reasoning: String(lines[2...].joined(separator: "\n"))
            )
        } catch {
            throw LLMError.invalidResponse
        }
    }
} 