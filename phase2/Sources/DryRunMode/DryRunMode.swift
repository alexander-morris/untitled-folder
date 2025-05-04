import Foundation
import FilenameAnalyzer

/// Represents a simulated rename operation
public struct SimulatedRename {
    public let originalPath: URL
    public let newPath: URL
    public let wouldSucceed: Bool
    public let error: Error?
    
    public init(originalPath: URL, newPath: URL, wouldSucceed: Bool, error: Error? = nil) {
        self.originalPath = originalPath
        self.newPath = newPath
        self.wouldSucceed = wouldSucceed
        self.error = error
    }
}

/// Simulates rename operations without making actual changes
public class DryRunMode {
    private let fileManager: FileManager
    private var seenPaths: Set<String> = []
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Simulates a batch of rename operations
    /// - Parameter proposals: List of rename proposals to simulate
    /// - Returns: Array of simulated rename results
    public func simulate(proposals: [RenameProposal]) -> [SimulatedRename] {
        var results: [SimulatedRename] = []
        seenPaths.removeAll()
        
        for proposal in proposals {
            let newURL = proposal.originalPath.deletingLastPathComponent().appendingPathComponent(proposal.newName)
            
            // Check for potential name collisions with existing files or previous renames
            if fileManager.fileExists(atPath: newURL.path) || seenPaths.contains(newURL.path) {
                let error = NSError(domain: "DryRunMode", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Name collision would occur: \(proposal.newName)"
                ])
                results.append(SimulatedRename(
                    originalPath: proposal.originalPath,
                    newPath: newURL,
                    wouldSucceed: false,
                    error: error
                ))
                continue
            }
            
            // Check for write permissions
            if !fileManager.isWritableFile(atPath: proposal.originalPath.deletingLastPathComponent().path) {
                let error = NSError(domain: "DryRunMode", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Insufficient permissions to rename: \(proposal.originalPath.lastPathComponent)"
                ])
                results.append(SimulatedRename(
                    originalPath: proposal.originalPath,
                    newPath: newURL,
                    wouldSucceed: false,
                    error: error
                ))
                continue
            }
            
            // If all checks pass, the rename would succeed
            seenPaths.insert(newURL.path)
            results.append(SimulatedRename(
                originalPath: proposal.originalPath,
                newPath: newURL,
                wouldSucceed: true
            ))
        }
        
        return results
    }
    
    /// Generates a human-readable report of the simulation results
    /// - Parameter results: The simulation results to report
    /// - Returns: A formatted string describing the results
    public func generateReport(results: [SimulatedRename]) -> String {
        var report = "Dry Run Report\n"
        report += "=============\n\n"
        
        let successful = results.filter { $0.wouldSucceed }.count
        let failed = results.count - successful
        
        report += "Summary:\n"
        report += "- Total operations: \(results.count)\n"
        report += "- Would succeed: \(successful)\n"
        report += "- Would fail: \(failed)\n\n"
        
        report += "Details:\n"
        for result in results {
            report += "\n\(result.originalPath.lastPathComponent) → \(result.newPath.lastPathComponent)\n"
            if result.wouldSucceed {
                report += "✅ Would succeed\n"
            } else {
                report += "❌ Would fail: \(result.error?.localizedDescription ?? "Unknown error")\n"
            }
        }
        
        return report
    }
} 