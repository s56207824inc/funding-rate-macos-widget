import Foundation

struct FundingRateSnapshot: Codable, Identifiable, Sendable {
    var id: ExchangeID { exchange }
    let exchange: ExchangeID
    let symbol: String
    let fundingRate: Double?
    let nextFundingTime: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let errorMessage: String?
}

extension FundingRateSnapshot {
    static func loading(for exchange: ExchangeID, previous: FundingRateSnapshot?) -> FundingRateSnapshot {
        FundingRateSnapshot(
            exchange: exchange,
            symbol: "BTC",
            fundingRate: previous?.fundingRate,
            nextFundingTime: previous?.nextFundingTime,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            errorMessage: nil
        )
    }

    static func failed(for exchange: ExchangeID, previous: FundingRateSnapshot?, message: String) -> FundingRateSnapshot {
        FundingRateSnapshot(
            exchange: exchange,
            symbol: "BTC",
            fundingRate: previous?.fundingRate,
            nextFundingTime: previous?.nextFundingTime,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            errorMessage: message
        )
    }
}
