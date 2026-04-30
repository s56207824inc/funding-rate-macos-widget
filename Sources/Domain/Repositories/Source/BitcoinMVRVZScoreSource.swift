import Foundation

protocol BitcoinMVRVZScoreSource: Sendable {
    func fetchLatestMVRVZScore() async throws -> BitcoinMVRVZScoreSnapshot
}
