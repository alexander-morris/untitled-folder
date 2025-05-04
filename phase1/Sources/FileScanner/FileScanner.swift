import Foundation

/// Represents metadata for a file that needs to be renamed
public struct FileMetadata {
    public let path: URL
    public let modificationDate: Date
    public let size: Int64
    public let isDirectory: Bool
    
    public init(path: URL, modificationDate: Date, size: Int64, isDirectory: Bool) {
        self.path = path
        self.modificationDate = modificationDate
        self.size = size
        self.isDirectory = isDirectory
    }
}

/// Scans directories for untitled files and folders
public class FileScanner {
    private let fileManager: FileManager
    private let untitledPatterns: [String] = [
        "untitled",
        "new folder",
        "new file",
        "screenshot",
        "image",
        "document"
    ]
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Scans a directory and its subdirectories for untitled files and folders
    /// - Parameter rootPath: The path to start scanning from
    /// - Returns: An array of FileMetadata for files that need to be renamed
    public func scanDirectory(at rootPath: URL) throws -> [FileMetadata] {
        var results: [FileMetadata] = []
        
        let enumerator = fileManager.enumerator(
            at: rootPath,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .fileSizeKey,
                .isDirectoryKey
            ],
            options: [.skipsHiddenFiles]
        )
        
        while let url = enumerator?.nextObject() as? URL {
            let resourceValues = try url.resourceValues(forKeys: [
                .contentModificationDateKey,
                .fileSizeKey,
                .isDirectoryKey
            ])
            
            let isUntitled = isUntitledFile(url.lastPathComponent)
            if isUntitled {
                let metadata = FileMetadata(
                    path: url,
                    modificationDate: resourceValues.contentModificationDate ?? Date(),
                    size: Int64(resourceValues.fileSize ?? 0),
                    isDirectory: resourceValues.isDirectory ?? false
                )
                results.append(metadata)
            }
        }
        
        return results
    }
    
    private func isUntitledFile(_ name: String) -> Bool {
        let lowercaseName = name.lowercased()
        return untitledPatterns.contains { pattern in
            lowercaseName.contains(pattern)
        }
    }
} 