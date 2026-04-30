import Foundation

protocol CryptoFearGreedCache: Sendable {
    func load() -> CryptoFearGreedSnapshot?
    func save(_ snapshot: CryptoFearGreedSnapshot)
}
