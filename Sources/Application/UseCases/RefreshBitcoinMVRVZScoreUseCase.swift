import Foundation

struct RefreshBitcoinMVRVZScoreUseCase {
    private let source: BitcoinMVRVZScoreSource
    private let cache: BitcoinMVRVZScoreCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: BitcoinMVRVZScoreSource,
        cache: BitcoinMVRVZScoreCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 8
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> BitcoinMVRVZScoreSnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: BitcoinMVRVZScoreSnapshot?) async -> BitcoinMVRVZScoreSnapshot {
        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestMVRVZScore()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return BitcoinMVRVZScoreSnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: BitcoinMVRVZScoreSnapshot) -> BitcoinMVRVZScoreSnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return BitcoinMVRVZScoreSnapshot(
            value: snapshot.value,
            realizedPriceUSD: snapshot.realizedPriceUSD,
            shortTermHolderRealizedPriceUSD: snapshot.shortTermHolderRealizedPriceUSD,
            reportDate: snapshot.reportDate,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }
}
