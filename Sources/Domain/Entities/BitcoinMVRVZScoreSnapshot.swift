import Foundation

struct BitcoinMVRVZScoreSnapshot: Codable, Sendable {
    let value: Double?
    let realizedPriceUSD: Double?
    let shortTermHolderRealizedPriceUSD: Double?
    let reportDate: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension BitcoinMVRVZScoreSnapshot {
    static func loading(previous: BitcoinMVRVZScoreSnapshot?) -> BitcoinMVRVZScoreSnapshot {
        BitcoinMVRVZScoreSnapshot(
            value: previous?.value,
            realizedPriceUSD: previous?.realizedPriceUSD,
            shortTermHolderRealizedPriceUSD: previous?.shortTermHolderRealizedPriceUSD,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "BGeometrics",
            errorMessage: nil
        )
    }

    static func failed(previous: BitcoinMVRVZScoreSnapshot?, message: String) -> BitcoinMVRVZScoreSnapshot {
        BitcoinMVRVZScoreSnapshot(
            value: previous?.value,
            realizedPriceUSD: previous?.realizedPriceUSD,
            shortTermHolderRealizedPriceUSD: previous?.shortTermHolderRealizedPriceUSD,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "BGeometrics",
            errorMessage: message
        )
    }
}
