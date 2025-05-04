import Foundation

class MockFileManager: FileManager {
    var mockFileExists = false
    var mockIsWritable = true
    
    override func fileExists(atPath path: String) -> Bool {
        return mockFileExists
    }
    
    override func isWritableFile(atPath path: String) -> Bool {
        return mockIsWritable
    }
} 