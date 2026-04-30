import Foundation

struct FileFundingRateCache: FundingRateCache {
    private let store = FileCacheStore(fileName: "funding-rate-cache.json")

    func load() -> [FundingRateSnapshot] {
        store.load(PersistedFundingRateCache.self)?.snapshots ?? []
    }

    func save(_ snapshots: [FundingRateSnapshot]) {
        let cache = PersistedFundingRateCache(savedAt: Date(), snapshots: snapshots)
        store.save(cache, errorContext: "funding rate")
    }
}

private struct PersistedFundingRateCache: Codable, Sendable {
    let savedAt: Date
    let snapshots: [FundingRateSnapshot]
}
