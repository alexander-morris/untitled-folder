import Foundation

class MockFileManager: FileManager {
    var mockFileExists = false
    var moveItemError: ((URL) -> Error?)? = nil
    var movedItems: [(from: URL, to: URL)] = []
    
    override func fileExists(atPath path: String) -> Bool {
        return mockFileExists
    }
    
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        if let errorHandler = moveItemError, let error = errorHandler(dstURL) {
            throw error
        }
        movedItems.append((from: srcURL, to: dstURL))
    }
    
    func reset() {
        mockFileExists = false
        moveItemError = nil
        movedItems.removeAll()
    }
} 