import Foundation

enum ExchangeID: String, CaseIterable, Codable, Identifiable, Sendable {
    case bybit
    case binance
    case okx
    case hyperliquid
    case bitget

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bybit: "Bybit"
        case .binance: "Binance"
        case .okx: "OKX"
        case .hyperliquid: "Hyperliquid"
        case .bitget: "Bitget"
        }
    }

    var sortOrder: Int {
        switch self {
        case .bybit: 0
        case .binance: 1
        case .okx: 2
        case .hyperliquid: 3
        case .bitget: 4
        }
    }
}

enum SourceStatus: String, Codable, Sendable {
    case ok
    case stale
    case error
    case loading
}

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

struct CryptoFearGreedSnapshot: Codable, Sendable {
    let value: Int?
    let classification: String?
    let reportDate: Date?
    let fetchedAt: Date
    let sourceStatus: SourceStatus
    let sourceName: String
    let errorMessage: String?
}

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
