import Foundation

struct BitcoinSpotPriceSnapshot: Codable, Sendable {
    let priceUSD: Double?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension BitcoinSpotPriceSnapshot {
    static func loading(previous: BitcoinSpotPriceSnapshot?) -> BitcoinSpotPriceSnapshot {
        BitcoinSpotPriceSnapshot(
            priceUSD: previous?.priceUSD,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "Binance",
            errorMessage: nil
        )
    }

    static func failed(previous: BitcoinSpotPriceSnapshot?, message: String) -> BitcoinSpotPriceSnapshot {
        BitcoinSpotPriceSnapshot(
            priceUSD: previous?.priceUSD,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "Binance",
            errorMessage: message
        )
    }
}
