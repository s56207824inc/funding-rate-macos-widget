import Foundation

protocol CryptoFearGreedSource: Sendable {
    func fetchLatestFearGreed() async throws -> CryptoFearGreedSnapshot
}
