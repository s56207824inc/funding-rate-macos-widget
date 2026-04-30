import Foundation

protocol BitcoinSpotPriceCache: Sendable {
    func load() -> BitcoinSpotPriceSnapshot?
    func save(_ snapshot: BitcoinSpotPriceSnapshot)
}
