import Foundation

struct FileBitcoinSpotPriceCache: BitcoinSpotPriceCache {
    private let store = FileCacheStore(fileName: "bitcoin-spot-price-cache.json")

    func load() -> BitcoinSpotPriceSnapshot? {
        store.load(PersistedBitcoinSpotPriceCache.self)?.snapshot
    }

    func save(_ snapshot: BitcoinSpotPriceSnapshot) {
        let cache = PersistedBitcoinSpotPriceCache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "spot price")
    }
}

private struct PersistedBitcoinSpotPriceCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinSpotPriceSnapshot
}
