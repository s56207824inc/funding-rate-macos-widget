import Foundation

struct RefreshBitcoinSpotPriceUseCase {
    private let source: BitcoinSpotPriceSource
    private let cache: BitcoinSpotPriceCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: BitcoinSpotPriceSource,
        cache: BitcoinSpotPriceCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 5
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> BitcoinSpotPriceSnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: BitcoinSpotPriceSnapshot?) async -> BitcoinSpotPriceSnapshot {
        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestSpotPrice()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return BitcoinSpotPriceSnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: BitcoinSpotPriceSnapshot) -> BitcoinSpotPriceSnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return BitcoinSpotPriceSnapshot(
            priceUSD: snapshot.priceUSD,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }
}
