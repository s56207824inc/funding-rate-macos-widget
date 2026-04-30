import Foundation

protocol StablecoinSupplySource: Sendable {
    func fetchLatestSupply() async throws -> StablecoinSupplySnapshot
}
