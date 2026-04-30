import Foundation

struct FileBitcoinRSICache: BitcoinRSICache {
    private let store = FileCacheStore(fileName: "bitcoin-rsi-cache.json")

    func load() -> BitcoinRSISnapshot? {
        store.load(PersistedBitcoinRSICache.self)?.snapshot
    }

    func save(_ snapshot: BitcoinRSISnapshot) {
        let cache = PersistedBitcoinRSICache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "RSI")
    }
}

private struct PersistedBitcoinRSICache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinRSISnapshot
}
