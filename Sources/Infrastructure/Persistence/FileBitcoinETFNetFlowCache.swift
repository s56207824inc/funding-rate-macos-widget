import Foundation

struct FileBitcoinETFNetFlowCache: BitcoinETFNetFlowCache {
    private let store = FileCacheStore(fileName: "bitcoin-etf-net-flow-cache.json")

    func load() -> BitcoinETFNetFlowSnapshot? {
        store.load(PersistedBitcoinETFNetFlowCache.self)?.snapshot
    }

    func save(_ snapshot: BitcoinETFNetFlowSnapshot) {
        let cache = PersistedBitcoinETFNetFlowCache(savedAt: Date(), snapshot: snapshot)
        store.save(cache, errorContext: "ETF net flow")
    }
}

private struct PersistedBitcoinETFNetFlowCache: Codable, Sendable {
    let savedAt: Date
    let snapshot: BitcoinETFNetFlowSnapshot
}
