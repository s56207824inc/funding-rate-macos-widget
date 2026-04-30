import Foundation

struct FileStablecoinSupplyCache: StablecoinSupplyCache {
    private let store = FileCacheStore(fileName: "stablecoin-supply-cache.json")

    func load() -> StablecoinSupplySnapshot? {
        store.load(PersistedStablecoinSupplyCache.self)?.snapshot
    }

    func save(_ snapshot: StablecoinSupplySnapshot) {
        let cache = PersistedStablecoinSupplyCache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "stablecoin supply")
    }
}

private struct PersistedStablecoinSupplyCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: StablecoinSupplySnapshot
}
