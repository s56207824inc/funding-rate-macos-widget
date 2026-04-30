import Foundation

protocol FundingRateCache: Sendable {
    func load() -> [FundingRateSnapshot]
    func save(_ snapshots: [FundingRateSnapshot])
}
