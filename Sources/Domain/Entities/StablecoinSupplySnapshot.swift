import Foundation

struct StablecoinSupplySnapshot: Codable, Sendable {
    let totalMarketCapUSD: Double?
    let change7DUSD: Double?
    let change7DPercent: Double?
    let change30DUSD: Double?
    let change30DPercent: Double?
    let reportDate: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension StablecoinSupplySnapshot {
    static func loading(previous: StablecoinSupplySnapshot?) -> StablecoinSupplySnapshot {
        StablecoinSupplySnapshot(
            totalMarketCapUSD: previous?.totalMarketCapUSD,
            change7DUSD: previous?.change7DUSD,
            change7DPercent: previous?.change7DPercent,
            change30DUSD: previous?.change30DUSD,
            change30DPercent: previous?.change30DPercent,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "DeFiLlama",
            errorMessage: nil
        )
    }

    static func failed(previous: StablecoinSupplySnapshot?, message: String) -> StablecoinSupplySnapshot {
        StablecoinSupplySnapshot(
            totalMarketCapUSD: previous?.totalMarketCapUSD,
            change7DUSD: previous?.change7DUSD,
            change7DPercent: previous?.change7DPercent,
            change30DUSD: previous?.change30DUSD,
            change30DPercent: previous?.change30DPercent,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "DeFiLlama",
            errorMessage: message
        )
    }
}
