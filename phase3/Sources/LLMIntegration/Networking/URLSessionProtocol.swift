import Foundation

/// Protocol for URLSession functionality
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {} 