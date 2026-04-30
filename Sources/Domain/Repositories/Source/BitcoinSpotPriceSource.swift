import Foundation

protocol BitcoinSpotPriceSource: Sendable {
    func fetchLatestSpotPrice() async throws -> BitcoinSpotPriceSnapshot
}
