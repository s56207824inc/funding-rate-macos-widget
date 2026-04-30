import Foundation

struct FileBitcoinMVRVZScoreCache: BitcoinMVRVZScoreCache {
    private let store = FileCacheStore(fileName: "bitcoin-mvrv-z-score-cache.json")

    func load() -> BitcoinMVRVZScoreSnapshot? {
        store.load(PersistedBitcoinMVRVZScoreCache.self)?.snapshot
    }

    func save(_ snapshot: BitcoinMVRVZScoreSnapshot) {
        let cache = PersistedBitcoinMVRVZScoreCache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "MVRV Z-Score")
    }
}

private struct PersistedBitcoinMVRVZScoreCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinMVRVZScoreSnapshot
}
