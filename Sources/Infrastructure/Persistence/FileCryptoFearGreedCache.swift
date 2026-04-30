import Foundation

struct FileCryptoFearGreedCache: CryptoFearGreedCache {
    private let store = FileCacheStore(fileName: "crypto-fear-greed-cache.json")

    func load() -> CryptoFearGreedSnapshot? {
        store.load(PersistedCryptoFearGreedCache.self)?.snapshot
    }

    func save(_ snapshot: CryptoFearGreedSnapshot) {
        let cache = PersistedCryptoFearGreedCache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "fear greed")
    }
}

private struct PersistedCryptoFearGreedCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: CryptoFearGreedSnapshot
}
