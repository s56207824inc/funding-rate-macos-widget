import Foundation

enum SourceStatus: String, Codable, Sendable {
    case ok
    case stale
    case error
    case loading
}
