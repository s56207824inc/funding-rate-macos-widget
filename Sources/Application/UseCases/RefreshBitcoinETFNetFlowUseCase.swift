import Foundation

struct RefreshBitcoinETFNetFlowUseCase {
    private let source: BitcoinETFNetFlowSource
    private let cache: BitcoinETFNetFlowCache
    private let staleThreshold: TimeInterval
    private let timeoutInterval: TimeInterval

    init(
        source: BitcoinETFNetFlowSource,
        cache: BitcoinETFNetFlowCache,
        staleThreshold: TimeInterval,
        timeoutInterval: TimeInterval = 8
    ) {
        self.source = source
        self.cache = cache
        self.staleThreshold = staleThreshold
        self.timeoutInterval = timeoutInterval
    }

    func loadCached() -> BitcoinETFNetFlowSnapshot? {
        cache.load().map(normalize)
    }

    func execute(previousSnapshot: BitcoinETFNetFlowSnapshot?) async -> BitcoinETFNetFlowSnapshot {
        if let previousSnapshot, shouldUseCachedSnapshotForMarketClosure(previousSnapshot) {
            return normalize(previousSnapshot)
        }

        do {
            let snapshot = try await withThrowingTimeout(seconds: timeoutInterval) {
                try await source.fetchLatestNetFlow()
            }
            let normalized = normalize(snapshot)
            cache.save(normalized)
            return normalized
        } catch {
            return BitcoinETFNetFlowSnapshot.failed(
                previous: previousSnapshot,
                message: error.localizedDescription
            )
        }
    }

    private func normalize(_ snapshot: BitcoinETFNetFlowSnapshot) -> BitcoinETFNetFlowSnapshot {
        guard snapshot.sourceStatus == .ok else { return snapshot }

        let status: SourceStatus = Date().timeIntervalSince(snapshot.fetchedAt) > staleThreshold ? .stale : .ok

        return BitcoinETFNetFlowSnapshot(
            reportDate: snapshot.reportDate,
            totalNetFlowMillionsUSD: snapshot.totalNetFlowMillionsUSD,
            entries: snapshot.entries,
            fetchedAt: snapshot.fetchedAt,
            sourceStatus: status,
            sourceName: snapshot.sourceName,
            errorMessage: snapshot.errorMessage
        )
    }

    private func shouldUseCachedSnapshotForMarketClosure(_ snapshot: BitcoinETFNetFlowSnapshot) -> Bool {
        guard isUSMarketWeekend(now: Date()) else { return false }
        guard let reportDate = snapshot.reportDate else { return false }
        return isLatestWeekendTradingDate(reportDate, relativeTo: Date())
    }
}

private func isUSMarketWeekend(now: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
    let weekday = calendar.component(.weekday, from: now)
    return weekday == 1 || weekday == 7
}

private func isLatestWeekendTradingDate(_ reportDate: Date, relativeTo now: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current

    let weekday = calendar.component(.weekday, from: now)
    let expectedOffsetDays: Int?

    switch weekday {
    case 7:
        expectedOffsetDays = 1
    case 1:
        expectedOffsetDays = 2
    default:
        expectedOffsetDays = nil
    }

    guard let expectedOffsetDays,
          let expectedDate = calendar.date(byAdding: .day, value: -expectedOffsetDays, to: now) else {
        return false
    }

    return calendar.isDate(reportDate, inSameDayAs: expectedDate)
}
