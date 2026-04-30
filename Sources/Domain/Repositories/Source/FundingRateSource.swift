import Foundation

protocol FundingRateSource: Sendable {
    var exchangeID: ExchangeID { get }
    func fetchBTCFundingRate() async throws -> FundingRateSnapshot
}
