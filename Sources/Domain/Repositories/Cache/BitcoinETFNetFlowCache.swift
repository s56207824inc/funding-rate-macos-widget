import Foundation

protocol BitcoinETFNetFlowCache: Sendable {
    func load() -> BitcoinETFNetFlowSnapshot?
    func save(_ snapshot: BitcoinETFNetFlowSnapshot)
}
