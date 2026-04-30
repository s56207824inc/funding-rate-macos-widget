import Foundation

struct BitcoinETFNetFlowEntry: Codable, Identifiable, Sendable {
    var id: String { ticker }
    let ticker: String
    let netFlowMillionsUSD: Double?
}

struct BitcoinETFNetFlowSnapshot: Codable, Sendable {
    let reportDate: Date?
    let totalNetFlowMillionsUSD: Double?
    let entries: [BitcoinETFNetFlowEntry]
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

extension BitcoinETFNetFlowSnapshot {
    static func loading(previous: BitcoinETFNetFlowSnapshot?) -> BitcoinETFNetFlowSnapshot {
        BitcoinETFNetFlowSnapshot(
            reportDate: previous?.reportDate,
            totalNetFlowMillionsUSD: previous?.totalNetFlowMillionsUSD,
            entries: previous?.entries ?? [],
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: .loading,
            sourceName: previous?.sourceName ?? "Farside",
            errorMessage: nil
        )
    }

    static func failed(previous: BitcoinETFNetFlowSnapshot?, message: String) -> BitcoinETFNetFlowSnapshot {
        BitcoinETFNetFlowSnapshot(
            reportDate: previous?.reportDate,
            totalNetFlowMillionsUSD: previous?.totalNetFlowMillionsUSD,
            entries: previous?.entries ?? [],
            fetchedAt: previous?.fetchedAt ?? .distantPast,
            sourceStatus: previous == nil ? .error : .stale,
            sourceName: previous?.sourceName ?? "Farside",
            errorMessage: message
        )
    }
}
