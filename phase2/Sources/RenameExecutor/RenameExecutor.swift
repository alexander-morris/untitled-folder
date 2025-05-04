import Foundation
import FilenameAnalyzer

/// Represents the result of a rename operation
public struct RenameResult {
    public let originalPath: URL
    public let newPath: URL
    public let success: Bool
    public let error: Error?
    
    public init(originalPath: URL, newPath: URL, success: Bool, error: Error? = nil) {
        self.originalPath = originalPath
        self.newPath = newPath
        self.success = success
        self.error = error
    }
}

/// Handles atomic file renaming with rollback support
public class RenameExecutor {
    private let fileManager: FileManager
    private var seenPaths: Set<String> = []
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Executes a batch of rename operations atomically
    /// - Parameter proposals: List of rename proposals to execute
    /// - Returns: Array of rename results
    public func execute(proposals: [RenameProposal]) throws -> [RenameResult] {
        var results: [RenameResult] = []
        var rollbackOperations: [(URL, URL)] = []
        seenPaths.removeAll()
        
        // First, validate all operations
        for proposal in proposals {
            let newURL = proposal.originalPath.deletingLastPathComponent().appendingPathComponent(proposal.newName)
            
            // Check for name collisions with existing files or previous renames
            if fileManager.fileExists(atPath: newURL.path) || seenPaths.contains(newURL.path) {
                throw NSError(domain: "RenameExecutor", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Name collision detected: \(proposal.newName)"
                ])
            }
            
            seenPaths.insert(newURL.path)
        }
        
        // Then execute all operations
        for proposal in proposals {
            do {
                let newURL = proposal.originalPath.deletingLastPathComponent().appendingPathComponent(proposal.newName)
                
                // Perform the rename
                try fileManager.moveItem(at: proposal.originalPath, to: newURL)
                
                // Record for potential rollback
                rollbackOperations.append((newURL, proposal.originalPath))
                
                // Record success
                results.append(RenameResult(
                    originalPath: proposal.originalPath,
                    newPath: newURL,
                    success: true
                ))
            } catch {
                // If any rename fails, rollback all previous operations
                try rollback(operations: rollbackOperations)
                
                // Record failure
                results.append(RenameResult(
                    originalPath: proposal.originalPath,
                    newPath: proposal.originalPath,
                    success: false,
                    error: error
                ))
                
                throw error
            }
        }
        
        return results
    }
    
    /// Rolls back a series of rename operations
    /// - Parameter operations: List of (newPath, originalPath) pairs to rollback
    private func rollback(operations: [(URL, URL)]) throws {
        for (newPath, originalPath) in operations.reversed() {
            try fileManager.moveItem(at: newPath, to: originalPath)
        }
    }
} 