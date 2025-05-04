import Foundation
import ImageIO
import PDFKit
import FileScanner

/// Represents a proposal for renaming a file
public struct RenameProposal {
    public let originalPath: URL
    public let newName: String
    public let confidence: Double
    
    public init(originalPath: URL, newName: String, confidence: Double) {
        self.originalPath = originalPath
        self.newName = newName
        self.confidence = confidence
    }
}

/// Analyzes file metadata to generate meaningful names
public class FilenameAnalyzer {
    private let dateFormatter: DateFormatter
    
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
    }
    
    /// Analyzes a file and generates a rename proposal
    /// - Parameter metadata: The file metadata to analyze
    /// - Returns: A rename proposal with the suggested new name
    public func analyze(metadata: FileMetadata) throws -> RenameProposal {
        let fileExtension = metadata.path.pathExtension.lowercased()
        let baseName = try generateBaseName(from: metadata)
        let timestamp = dateFormatter.string(from: metadata.modificationDate)
        
        let newName: String
        let confidence: Double
        
        if metadata.isDirectory {
            newName = "\(baseName)_\(timestamp)"
            confidence = 0.8
        } else {
            switch fileExtension {
            case "jpg", "jpeg", "png", "heic":
                if let imageName = try? analyzeImage(metadata: metadata) {
                    newName = "\(imageName)_\(timestamp).\(fileExtension)"
                    confidence = 0.9
                } else {
                    newName = "\(baseName)_\(timestamp).\(fileExtension)"
                    confidence = 0.7
                }
            case "pdf":
                if let pdfName = try? analyzePDF(metadata: metadata) {
                    newName = "\(pdfName)_\(timestamp).pdf"
                    confidence = 0.85
                } else {
                    newName = "\(baseName)_\(timestamp).pdf"
                    confidence = 0.7
                }
            default:
                newName = "\(baseName)_\(timestamp).\(fileExtension)"
                confidence = 0.7
            }
        }
        
        return RenameProposal(
            originalPath: metadata.path,
            newName: newName,
            confidence: confidence
        )
    }
    
    private func generateBaseName(from metadata: FileMetadata) throws -> String {
        let originalName = metadata.path.deletingPathExtension().lastPathComponent.lowercased()
        
        // Map common untitled patterns to more descriptive names
        let nameMapping: [String: String] = [
            "untitled": "Document",
            "new folder": "Folder",
            "new file": "File",
            "screenshot": "Screenshot",
            "image": "Image",
            "document": "Document"
        ]
        
        for (pattern, replacement) in nameMapping {
            if originalName.contains(pattern) {
                return replacement
            }
        }
        
        return "Document"
    }
    
    private func analyzeImage(metadata: FileMetadata) throws -> String? {
        guard let imageSource = CGImageSourceCreateWithURL(metadata.path as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }
        
        // Try to get EXIF data
        if let exif = imageProperties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            return "Photo_\(dateTimeOriginal.replacingOccurrences(of: ":", with: "-"))"
        }
        
        return nil
    }
    
    private func analyzePDF(metadata: FileMetadata) throws -> String? {
        guard let pdfDocument = PDFDocument(url: metadata.path) else {
            return nil
        }
        
        // Try to get title from PDF metadata
        if let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
           !title.isEmpty {
            return title
        }
        
        // Try to get first line of text as title
        if let firstPage = pdfDocument.page(at: 0),
           let text = firstPage.string,
           let firstLine = text.components(separatedBy: CharacterSet.newlines).first,
           !firstLine.isEmpty {
            return firstLine
        }
        
        return nil
    }
} 