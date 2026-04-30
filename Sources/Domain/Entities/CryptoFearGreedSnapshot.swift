import Foundation

struct CryptoFearGreedSnapshot: Codable, Sendable {
    let value: Int?
    let classification: String?
    let reportDate: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension CryptoFearGreedSnapshot {
    static func loading(previous: CryptoFearGreedSnapshot?) -> CryptoFearGreedSnapshot {
        CryptoFearGreedSnapshot(
            value: previous?.value,
            classification: previous?.classification,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "Alternative.me",
            errorMessage: nil
        )
    }

    static func failed(previous: CryptoFearGreedSnapshot?, message: String) -> CryptoFearGreedSnapshot {
        CryptoFearGreedSnapshot(
            value: previous?.value,
            classification: previous?.classification,
            reportDate: previous?.reportDate,
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "Alternative.me",
            errorMessage: message
        )
    }
}
