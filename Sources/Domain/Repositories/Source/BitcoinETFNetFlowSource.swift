import Foundation

protocol BitcoinETFNetFlowSource: Sendable {
    func fetchLatestNetFlow() async throws -> BitcoinETFNetFlowSnapshot
}
