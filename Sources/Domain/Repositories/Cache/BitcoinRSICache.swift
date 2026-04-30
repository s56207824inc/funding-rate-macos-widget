import Foundation

protocol BitcoinRSICache: Sendable {
    func load() -> BitcoinRSISnapshot?
    func save(_ snapshot: BitcoinRSISnapshot)
}
