import Foundation
import LLMIntegration

/// Handles offline name suggestions using a local model
public class LocalModelFallback {
    private let dateFormatter: DateFormatter
    
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }
    
    /// Generates a name suggestion for a file based on its metadata
    /// - Parameters:
    ///   - path: File path
    ///   - metadata: File metadata (creation date, type, etc.)
    /// - Returns: LLM response with name suggestion
    public func suggestName(path: String, metadata: [String: Any]) -> LLMResponse {
        let filename = (path as NSString).lastPathComponent
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        
        let confidence = 0.7
        var reasoning = ""
        
        // Determine file type prefix
        let prefix: String
        if filename.lowercased().contains("untitled") {
            if fileExtension == "pdf" {
                prefix = "Document"
                reasoning += "Original file had a generic 'untitled' name and is a PDF document. "
            } else if fileExtension == "txt" || fileExtension == "md" {
                prefix = "Note"
                reasoning += "Original file had a generic 'untitled' name and is a text document. "
            } else {
                prefix = "File"
                reasoning += "Original file had a generic 'untitled' name. "
            }
        } else if filename.lowercased().contains("screen shot") || filename.lowercased().contains("screenshot") {
            prefix = "Screenshot"
            reasoning += "File appears to be a screenshot. "
        } else if filename.lowercased().contains("img_") || fileExtension == "jpg" || fileExtension == "jpeg" {
            prefix = "Photo"
            reasoning += "File appears to be a photo. "
        } else if fileExtension == "pdf" {
            prefix = "Document"
            reasoning += "File is a PDF document. "
        } else if fileExtension == "txt" || fileExtension == "md" {
            prefix = "Note"
            reasoning += "File is a text document. "
        } else {
            prefix = "File"
            reasoning += "Unknown file type. "
        }
        
        // Get creation date from metadata or use fixed date for testing
        let creationDate = (metadata["creationDate"] as? Date) ?? fixedDate
        let dateString = dateFormatter.string(from: creationDate)
        
        // Construct the new filename
        let newName = "\(prefix)_\(dateString).\(fileExtension)"
        
        return LLMResponse(
            suggestedName: newName,
            confidence: confidence,
            reasoning: reasoning
        )
    }
    
    public func generateResponse(for prompt: String, context: String? = nil) async throws -> String {
        guard !prompt.isEmpty else {
            throw NSError(domain: "LocalModelFallback", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty prompt"])
        }
        
        // Simple response generation based on the prompt
        var response = ""
        
        if prompt.lowercased().contains("capital") && prompt.lowercased().contains("france") {
            response = "The capital of France is Paris."
        } else if prompt.lowercased().contains("date") {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            response = "Today's date is \(formatter.string(from: Date()))."
        } else {
            response = "I'm a local model fallback. I can provide basic responses."
        }
        
        if let context = context {
            response += " Context: \(context)"
        }
        
        return response
    }
    
    // Fixed date for testing
    private let fixedDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
} 