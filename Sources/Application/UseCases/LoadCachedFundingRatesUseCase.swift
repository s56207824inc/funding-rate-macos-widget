import Foundation

struct LoadCachedFundingRatesUseCase {
    private let cache: FundingRateCache

    init(cache: FundingRateCache) {
        self.cache = cache
    }

    func execute(expectedSources: [FundingRateSource]) -> [FundingRateSnapshot] {
        let cachedSnapshots = cache.load()
        return expectedSources.compactMap { source in
            cachedSnapshots.first(where: { $0.exchange == source.exchangeID })
        }
        .sorted(by: snapshotSort)
    }

    private func snapshotSort(_ lhs: FundingRateSnapshot, _ rhs: FundingRateSnapshot) -> Bool {
        lhs.exchange.sortOrder < rhs.exchange.sortOrder
    }
}
