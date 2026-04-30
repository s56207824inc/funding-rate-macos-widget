import Foundation

struct RefreshStablecoinSupplyUseCase {
    private let source: StablecoinSupplySource
    private let cache: StablecoinSupplyCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: StablecoinSupplySource,
        cache: StablecoinSupplyCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 8
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> StablecoinSupplySnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: StablecoinSupplySnapshot?) async -> StablecoinSupplySnapshot {
        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestSupply()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return StablecoinSupplySnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: StablecoinSupplySnapshot) -> StablecoinSupplySnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return StablecoinSupplySnapshot(
            totalMarketCapUSD: snapshot.totalMarketCapUSD,
            change7DUSD: snapshot.change7DUSD,
            change7DPercent: snapshot.change7DPercent,
            change30DUSD: snapshot.change30DUSD,
            change30DPercent: snapshot.change30DPercent,
            reportDate: snapshot.reportDate,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }
}
