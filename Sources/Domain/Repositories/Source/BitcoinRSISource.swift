import Foundation

protocol BitcoinRSISource: Sendable {
    func fetchLatestRSI() async throws -> BitcoinRSISnapshot
}
