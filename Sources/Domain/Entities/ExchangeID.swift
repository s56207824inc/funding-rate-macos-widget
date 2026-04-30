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
