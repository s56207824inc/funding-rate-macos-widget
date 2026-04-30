import Foundation

protocol BitcoinMVRVZScoreCache: Sendable {
    func load() -> BitcoinMVRVZScoreSnapshot?
    func save(_ snapshot: BitcoinMVRVZScoreSnapshot)
}
