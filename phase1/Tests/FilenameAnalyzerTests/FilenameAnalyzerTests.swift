import XCTest
import FileScanner
import PDFKit
import UniformTypeIdentifiers
@testable import FilenameAnalyzer

final class FilenameAnalyzerTests: XCTestCase {
    var analyzer: FilenameAnalyzer!
    var fileManager: FileManager!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        analyzer = FilenameAnalyzer()
        fileManager = FileManager()
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: tempDirectory)
    }
    
    func testAnalyzeUntitledFile() throws {
        let fileURL = tempDirectory.appendingPathComponent("Untitled.txt")
        try "test".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let metadata = FileMetadata(
            path: fileURL,
            modificationDate: Date(),
            size: 4,
            isDirectory: false
        )
        
        let proposal = try analyzer.analyze(metadata: metadata)
        XCTAssertEqual(proposal.originalPath, fileURL)
        XCTAssertTrue(proposal.newName.hasPrefix("Document_"))
        XCTAssertTrue(proposal.newName.hasSuffix(".txt"))
        XCTAssertEqual(proposal.confidence, 0.7)
    }
    
    func testAnalyzeUntitledFolder() throws {
        let folderURL = tempDirectory.appendingPathComponent("New Folder")
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let metadata = FileMetadata(
            path: folderURL,
            modificationDate: Date(),
            size: 0,
            isDirectory: true
        )
        
        let proposal = try analyzer.analyze(metadata: metadata)
        XCTAssertEqual(proposal.originalPath, folderURL)
        XCTAssertTrue(proposal.newName.hasPrefix("Folder_"))
        XCTAssertEqual(proposal.confidence, 0.8)
    }
    
    func testAnalyzeScreenshot() throws {
        let fileURL = tempDirectory.appendingPathComponent("Screenshot.png")
        try "test".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let metadata = FileMetadata(
            path: fileURL,
            modificationDate: Date(),
            size: 4,
            isDirectory: false
        )
        
        let proposal = try analyzer.analyze(metadata: metadata)
        XCTAssertEqual(proposal.originalPath, fileURL)
        XCTAssertTrue(proposal.newName.hasPrefix("Screenshot_"))
        XCTAssertTrue(proposal.newName.hasSuffix(".png"))
        XCTAssertEqual(proposal.confidence, 0.7)
    }
    
    func testAnalyzeImageWithEXIF() throws {
        // Create a test image with EXIF data
        let fileURL = tempDirectory.appendingPathComponent("image.jpg")
        let imageData = try createTestImageWithEXIF()
        try imageData.write(to: fileURL)
        
        let metadata = FileMetadata(
            path: fileURL,
            modificationDate: Date(),
            size: Int64(imageData.count),
            isDirectory: false
        )
        
        let proposal = try analyzer.analyze(metadata: metadata)
        XCTAssertEqual(proposal.originalPath, fileURL)
        XCTAssertTrue(proposal.newName.hasPrefix("Photo_"))
        XCTAssertTrue(proposal.newName.hasSuffix(".jpg"))
        XCTAssertEqual(proposal.confidence, 0.9)
    }
    
    func testAnalyzePDF() throws {
        // Create a test PDF with title
        let fileURL = tempDirectory.appendingPathComponent("test.pdf")
        let pdfData = try createTestPDF()
        try pdfData.write(to: fileURL)
        
        let metadata = FileMetadata(
            path: fileURL,
            modificationDate: Date(),
            size: Int64(pdfData.count),
            isDirectory: false
        )
        
        let proposal = try analyzer.analyze(metadata: metadata)
        XCTAssertEqual(proposal.originalPath, fileURL)
        XCTAssertTrue(proposal.newName.hasPrefix("Test Document_"))
        XCTAssertTrue(proposal.newName.hasSuffix(".pdf"))
        XCTAssertEqual(proposal.confidence, 0.85)
    }
    
    // Helper methods for creating test files
    
    private func createTestImageWithEXIF() throws -> Data {
        let imageData = NSMutableData()
        let destination = CGImageDestinationCreateWithData(imageData as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil)!
        
        // Create a simple image
        let size = CGSize(width: 100, height: 100)
        let renderer = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        renderer.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        renderer.fill(CGRect(origin: .zero, size: size))
        let image = renderer.makeImage()!
        
        // Add EXIF data
        let exifProperties: [CFString: Any] = [
            kCGImagePropertyExifDateTimeOriginal: "2023:01:01 12:00:00"
        ]
        
        let properties: [CFString: Any] = [
            kCGImagePropertyExifDictionary: exifProperties,
            kCGImagePropertyOrientation: 1
        ]
        
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return imageData as Data
    }
    
    private func createTestPDF() throws -> Data {
        let pdfDocument = PDFDocument()
        let page = PDFPage()
        pdfDocument.insert(page, at: 0)
        
        // Set document title
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: "Test Document"
        ]
        
        // Add some text
        let text = "This is a test PDF document."
        let textAnnotation = PDFAnnotation(
            bounds: CGRect(x: 50, y: 50, width: 200, height: 50),
            forType: PDFAnnotationSubtype.text,
            withProperties: nil
        )
        textAnnotation.contents = text
        page.addAnnotation(textAnnotation)
        
        guard let data = pdfDocument.dataRepresentation() else {
            throw NSError(domain: "TestError", code: 2, userInfo: nil)
        }
        
        return data
    }
} 