import Foundation

struct BitcoinRSISnapshot: Codable, Sendable {
    let value: Double?
    let intervalLabel: String
    let period: Int
    let reportDate: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension BitcoinRSISnapshot {
    static func loading(previous: BitcoinRSISnapshot?) -> BitcoinRSISnapshot {
        BitcoinRSISnapshot(
            value: previous?.value,
            intervalLabel: previous?.intervalLabel ?? "1D",
            period: previous?.period ?? 14,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "Binance",
            errorMessage: nil
        )
    }

    static func failed(previous: BitcoinRSISnapshot?, message: String) -> BitcoinRSISnapshot {
        BitcoinRSISnapshot(
            value: previous?.value,
            intervalLabel: previous?.intervalLabel ?? "1D",
            period: previous?.period ?? 14,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "Binance",
            errorMessage: message
        )
    }
}
