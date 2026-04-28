import Foundation

struct RefreshBitcoinRSIUseCase {
    private let source: BitcoinRSISource
    private let cache: BitcoinRSICache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: BitcoinRSISource,
        cache: BitcoinRSICache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 6
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> BitcoinRSISnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: BitcoinRSISnapshot?) async -> BitcoinRSISnapshot {
        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestRSI()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return BitcoinRSISnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: BitcoinRSISnapshot) -> BitcoinRSISnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return BitcoinRSISnapshot(
            value: snapshot.value,
            intervalLabel: snapshot.intervalLabel,
            period: snapshot.period,
            reportDate: snapshot.reportDate,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }
}
