import Foundation

protocol StablecoinSupplyCache: Sendable {
    func load() -> StablecoinSupplySnapshot?
    func save(_ snapshot: StablecoinSupplySnapshot)
}
