import Foundation

struct RefreshFundingRatesUseCase {
    struct Result: Sendable {
        let snapshots: [FundingRateSnapshot]
        let lastRefreshAt: Date?
    }

    private let sources: [FundingRateSource]
    private let cache: FundingRateCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        sources: [FundingRateSource],
        cache: FundingRateCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 5
    ) {
        self.sources = sources
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func execute(previousSnapshots: [ExchangeID: FundingRateSnapshot]) async -> Result {
        let snapshots = await withTaskGroup(of: FundingRateSnapshot.self) { group in
            for source in sources {
                let previous = previousSnapshots[source.exchangeID]
                group.addTask {
                    do {
                        let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                            try await source.fetchBTCFundingRate()
                        }
                        return normalize(snapshot)
                    } catch {
                        return FundingRateSnapshot.failed(
                            for: source.exchangeID,
                            previous: previous,
                            message: error.localizedDescription
                        )
                    }
                }
            }

            var results: [FundingRateSnapshot] = []
            for await snapshot in group {
                results.append(snapshot)
            }
            return results.sorted(by: snapshotSort)
        }

        cache.save(snapshots)

        let lastRefreshAt = snapshots.compactMap { snapshot in
            snapshot.sourceStatus == .ok ? snapshot.fetchedAt : nil
        }.max()

        return Result(snapshots: snapshots, lastRefreshAt: lastRefreshAt)
    }

    private func normalize(_ snapshot: FundingRateSnapshot) -> FundingRateSnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return FundingRateSnapshot(
            exchange: snapshot.exchange,
            symbol: snapshot.symbol,
            fundingRate: snapshot.fundingRate,
            nextFundingTime: snapshot.nextFundingTime,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            errorMessage: snapshot.errorMessage
        )
    }

    private func snapshotSort(_ lhs: FundingRateSnapshot, _ rhs: FundingRateSnapshot) -> Bool {
        lhs.exchange.sortOrder < rhs.exchange.sortOrder
    }
}
