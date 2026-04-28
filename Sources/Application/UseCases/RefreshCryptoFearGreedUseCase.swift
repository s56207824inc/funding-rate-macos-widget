import Foundation

struct RefreshCryptoFearGreedUseCase {
    private let source: CryptoFearGreedSource
    private let cache: CryptoFearGreedCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: CryptoFearGreedSource,
        cache: CryptoFearGreedCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 6
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> CryptoFearGreedSnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: CryptoFearGreedSnapshot?) async -> CryptoFearGreedSnapshot {
        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestFearGreed()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return CryptoFearGreedSnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: CryptoFearGreedSnapshot) -> CryptoFearGreedSnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return CryptoFearGreedSnapshot(
            value: snapshot.value,
            classification: snapshot.classification,
            reportDate: snapshot.reportDate,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }
}
