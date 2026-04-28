import Foundation

protocol FundingRateCache: Sendable {
    func load() -> [FundingRateSnapshot]
    func save(_ snapshots: [FundingRateSnapshot])
}

protocol BitcoinETFNetFlowCache: Sendable {
    func load() -> BitcoinETFNetFlowSnapshot?
    func save(_ snapshot: BitcoinETFNetFlowSnapshot)
}

protocol CryptoFearGreedCache: Sendable {
    func load() -> CryptoFearGreedSnapshot?
    func save(_ snapshot: CryptoFearGreedSnapshot)
}

protocol BitcoinRSICache: Sendable {
    func load() -> BitcoinRSISnapshot?
    func save(_ snapshot: BitcoinRSISnapshot)
}

protocol BitcoinMVRVZScoreCache: Sendable {
    func load() -> BitcoinMVRVZScoreSnapshot?
    func save(_ snapshot: BitcoinMVRVZScoreSnapshot)
}

struct PersistedCache: Codable, Sendable {
    let savedAt: Date
    let snapshots: [FundingRateSnapshot]
}

struct PersistedBitcoinETFNetFlowCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinETFNetFlowSnapshot
}

struct PersistedCryptoFearGreedCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: CryptoFearGreedSnapshot
}

struct PersistedBitcoinRSICache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinRSISnapshot
}

struct PersistedBitcoinMVRVZScoreCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinMVRVZScoreSnapshot
}
