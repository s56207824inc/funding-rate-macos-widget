import Foundation

protocol FundingRateSource: Sendable {
    var exchangeID: ExchangeID { get }
    func fetchBTCFundingRate() async throws -> FundingRateSnapshot
}

protocol BitcoinETFNetFlowSource: Sendable {
    func fetchLatestNetFlow() async throws -> BitcoinETFNetFlowSnapshot
}

protocol CryptoFearGreedSource: Sendable {
    func fetchLatestFearGreed() async throws -> CryptoFearGreedSnapshot
}

protocol BitcoinRSISource: Sendable {
    func fetchLatestRSI() async throws -> BitcoinRSISnapshot
}

protocol BitcoinMVRVZScoreSource: Sendable {
    func fetchLatestMVRVZScore() async throws -> BitcoinMVRVZScoreSnapshot
}
