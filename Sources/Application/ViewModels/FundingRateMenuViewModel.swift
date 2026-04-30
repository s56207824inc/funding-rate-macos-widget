import Foundation

@MainActor
final class FundingRateMenuViewModel: ObservableObject {
    @Published private(set) var snapshots: [FundingRateSnapshot] = []
    @Published private(set) var bitcoinETFNetFlow: BitcoinETFNetFlowSnapshot?
    @Published private(set) var cryptoFearGreed: CryptoFearGreedSnapshot?
    @Published private(set) var bitcoinRSI: BitcoinRSISnapshot?
    @Published private(set) var bitcoinMVRVZScore: BitcoinMVRVZScoreSnapshot?
    @Published private(set) var bitcoinSpotPrice: BitcoinSpotPriceSnapshot?
    @Published private(set) var stablecoinSupply: StablecoinSupplySnapshot?
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshAt: Date?

    private let refreshInterval: TimeInterval
    private let openRefreshThreshold: TimeInterval
    private let sources: [FundingRateSource]
    private let loadCachedFundingRates: LoadCachedFundingRatesUseCase
    private let refreshFundingRates: RefreshFundingRatesUseCase
    private let refreshBitcoinETFNetFlow: RefreshBitcoinETFNetFlowUseCase
    private let refreshCryptoFearGreed: RefreshCryptoFearGreedUseCase
    private let refreshBitcoinRSI: RefreshBitcoinRSIUseCase
    private let refreshBitcoinMVRVZScore: RefreshBitcoinMVRVZScoreUseCase
    private let refreshBitcoinSpotPrice: RefreshBitcoinSpotPriceUseCase
    private let refreshStablecoinSupply: RefreshStablecoinSupplyUseCase
    private var refreshTask: Task<Void, Never>?
    private var periodicTask: Task<Void, Never>?

    init(
        sources: [FundingRateSource],
        loadCachedFundingRates: LoadCachedFundingRatesUseCase,
        refreshFundingRates: RefreshFundingRatesUseCase,
        refreshBitcoinETFNetFlow: RefreshBitcoinETFNetFlowUseCase,
        refreshCryptoFearGreed: RefreshCryptoFearGreedUseCase,
        refreshBitcoinRSI: RefreshBitcoinRSIUseCase,
        refreshBitcoinMVRVZScore: RefreshBitcoinMVRVZScoreUseCase,
        refreshBitcoinSpotPrice: RefreshBitcoinSpotPriceUseCase,
        refreshStablecoinSupply: RefreshStablecoinSupplyUseCase,
        refreshInterval: TimeInterval = 600,
        openRefreshThreshold: TimeInterval = 60
    ) {
        self.sources = sources
        self.loadCachedFundingRates = loadCachedFundingRates
        self.refreshFundingRates = refreshFundingRates
        self.refreshBitcoinETFNetFlow = refreshBitcoinETFNetFlow
        self.refreshCryptoFearGreed = refreshCryptoFearGreed
        self.refreshBitcoinRSI = refreshBitcoinRSI
        self.refreshBitcoinMVRVZScore = refreshBitcoinMVRVZScore
        self.refreshBitcoinSpotPrice = refreshBitcoinSpotPrice
        self.refreshStablecoinSupply = refreshStablecoinSupply
        self.refreshInterval = refreshInterval
        self.openRefreshThreshold = openRefreshThreshold

        self.snapshots = loadCachedFundingRates.execute(expectedSources: sources)
        self.bitcoinETFNetFlow = refreshBitcoinETFNetFlow.loadCached()
        self.cryptoFearGreed = refreshCryptoFearGreed.loadCached()
        self.bitcoinRSI = refreshBitcoinRSI.loadCached()
        self.bitcoinMVRVZScore = refreshBitcoinMVRVZScore.loadCached()
        self.bitcoinSpotPrice = refreshBitcoinSpotPrice.loadCached()
        self.stablecoinSupply = refreshStablecoinSupply.loadCached()
        self.lastRefreshAt = snapshots.map(\.fetchedAt).max()

        startPeriodicRefreshLoop()
        if shouldRefreshOnLaunch {
            refresh(force: true)
        }
    }

    deinit {
        refreshTask?.cancel()
        periodicTask?.cancel()
    }

    var footerText: String {
        formatUpdatedAt(lastRefreshAt)
    }

    func snapshot(for exchange: ExchangeID) -> FundingRateSnapshot? {
        snapshots.first(where: { $0.exchange == exchange })
    }

    var accumulationScore: AccumulationScore {
        AccumulationScore(
            spotPrice: bitcoinSpotPrice,
            mvrvZScore: bitcoinMVRVZScore,
            fearGreed: cryptoFearGreed,
            rsi: bitcoinRSI,
            etfNetFlow: bitcoinETFNetFlow,
            fundingRates: snapshots
        )
    }

    func refreshIfNeededForPanelOpen() {
        guard shouldRefreshForPanelOpen else { return }
        refresh(force: true)
    }

    func refresh(force: Bool = false) {
        guard refreshTask == nil || force else { return }
        refreshTask = Task {
            await runRefresh()
            refreshTask = nil
        }
    }

    private var shouldRefreshOnLaunch: Bool {
        if bitcoinETFNetFlow == nil || cryptoFearGreed == nil || bitcoinRSI == nil || bitcoinMVRVZScore == nil || bitcoinSpotPrice == nil || stablecoinSupply == nil {
            return true
        }
        guard let lastRefreshAt else { return true }
        return Date().timeIntervalSince(lastRefreshAt) > openRefreshThreshold
    }

    private var shouldRefreshForPanelOpen: Bool {
        guard !isRefreshing else { return false }
        if bitcoinETFNetFlow == nil || cryptoFearGreed == nil || bitcoinRSI == nil || bitcoinMVRVZScore == nil || bitcoinSpotPrice == nil || stablecoinSupply == nil {
            return true
        }
        guard let lastRefreshAt else { return true }
        return Date().timeIntervalSince(lastRefreshAt) > openRefreshThreshold
    }

    private func startPeriodicRefreshLoop() {
        periodicTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(refreshInterval))
                if Task.isCancelled { return }
                await runRefresh()
            }
        }
    }

    private func runRefresh() async {
        if isRefreshing { return }
        isRefreshing = true

        let previous = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.exchange, $0) })
        let previousETFNetFlow = bitcoinETFNetFlow
        let previousFearGreed = cryptoFearGreed
        let previousRSI = bitcoinRSI
        let previousMVRVZScore = bitcoinMVRVZScore
        let previousSpotPrice = bitcoinSpotPrice
        let previousStablecoinSupply = stablecoinSupply
        snapshots = sources.map { source in
            FundingRateSnapshot.loading(for: source.exchangeID, previous: previous[source.exchangeID])
        }
        .sorted(by: { $0.exchange.sortOrder < $1.exchange.sortOrder })
        bitcoinETFNetFlow = BitcoinETFNetFlowSnapshot.loading(previous: previousETFNetFlow)
        cryptoFearGreed = CryptoFearGreedSnapshot.loading(previous: previousFearGreed)
        bitcoinRSI = BitcoinRSISnapshot.loading(previous: previousRSI)
        bitcoinMVRVZScore = BitcoinMVRVZScoreSnapshot.loading(previous: previousMVRVZScore)
        bitcoinSpotPrice = BitcoinSpotPriceSnapshot.loading(previous: previousSpotPrice)
        stablecoinSupply = StablecoinSupplySnapshot.loading(previous: previousStablecoinSupply)

        async let fundingResult = refreshFundingRates.execute(previousSnapshots: previous)
        async let etfResult = refreshBitcoinETFNetFlow.execute(previousSnapshot: previousETFNetFlow)
        async let fearGreedResult = refreshCryptoFearGreed.execute(previousSnapshot: previousFearGreed)
        async let rsiResult = refreshBitcoinRSI.execute(previousSnapshot: previousRSI)
        async let mvrvZScoreResult = refreshBitcoinMVRVZScore.execute(previousSnapshot: previousMVRVZScore)
        async let spotPriceResult = refreshBitcoinSpotPrice.execute(previousSnapshot: previousSpotPrice)
        async let stablecoinSupplyResult = refreshStablecoinSupply.execute(previousSnapshot: previousStablecoinSupply)

        let result = await fundingResult
        let etfSnapshot = await etfResult
        let fearGreedSnapshot = await fearGreedResult
        let rsiSnapshot = await rsiResult
        let mvrvZScoreSnapshot = await mvrvZScoreResult
        let spotPriceSnapshot = await spotPriceResult
        let stablecoinSupplySnapshot = await stablecoinSupplyResult

        snapshots = result.snapshots
        bitcoinETFNetFlow = etfSnapshot
        cryptoFearGreed = fearGreedSnapshot
        bitcoinRSI = rsiSnapshot
        bitcoinMVRVZScore = mvrvZScoreSnapshot
        bitcoinSpotPrice = spotPriceSnapshot
        stablecoinSupply = stablecoinSupplySnapshot
        lastRefreshAt = [
            result.lastRefreshAt,
            etfSnapshot.fetchedAt == .distantPast ? nil : etfSnapshot.fetchedAt,
            fearGreedSnapshot.fetchedAt == .distantPast ? nil : fearGreedSnapshot.fetchedAt,
            rsiSnapshot.fetchedAt == .distantPast ? nil : rsiSnapshot.fetchedAt,
            mvrvZScoreSnapshot.fetchedAt == .distantPast ? nil : mvrvZScoreSnapshot.fetchedAt,
            spotPriceSnapshot.fetchedAt == .distantPast ? nil : spotPriceSnapshot.fetchedAt,
            stablecoinSupplySnapshot.fetchedAt == .distantPast ? nil : stablecoinSupplySnapshot.fetchedAt
        ]
            .compactMap { $0 }
            .max() ?? lastRefreshAt
        isRefreshing = false
    }
}

struct AccumulationScore {
    private static let negativeFundingThreshold = -0.00005

    let items: [AccumulationScoreItem]
    let earnedPoints: Double
    let maxPoints: Double

    init(
        spotPrice: BitcoinSpotPriceSnapshot?,
        mvrvZScore: BitcoinMVRVZScoreSnapshot?,
        fearGreed: CryptoFearGreedSnapshot?,
        rsi: BitcoinRSISnapshot?,
        etfNetFlow: BitcoinETFNetFlowSnapshot?,
        fundingRates: [FundingRateSnapshot]
    ) {
        let spot = spotPrice?.priceUSD
        let realized = mvrvZScore?.realizedPriceUSD
        let shortTermRealized = mvrvZScore?.shortTermHolderRealizedPriceUSD
        let averageFunding = Self.averageFundingRate(from: fundingRates)

        let rules = [
            AccumulationScoreItem(
                title: "MVRV Z < 1",
                detail: "估值進入偏低區",
                valueText: formatMVRVZScoreValue(mvrvZScore?.value),
                weight: 2,
                isTriggered: (mvrvZScore?.value).map { $0 < 1 } ?? false
            ),
            AccumulationScoreItem(
                title: "低於 STH 成本",
                detail: "短期持有者承壓",
                valueText: Self.spotComparisonText(spot: spot, reference: shortTermRealized),
                weight: 2,
                isTriggered: Self.isBelow(spot: spot, reference: shortTermRealized)
            ),
            AccumulationScoreItem(
                title: "接近 Realized Price",
                detail: "靠近全市場平均成本",
                valueText: Self.spotComparisonText(spot: spot, reference: realized),
                weight: 2,
                isTriggered: Self.isNear(spot: spot, reference: realized, threshold: 0.12)
            ),
            AccumulationScoreItem(
                title: "極度恐懼",
                detail: "市場情緒夠悲觀",
                valueText: formatFearGreedValue(fearGreed?.value),
                weight: 1.5,
                isTriggered: (fearGreed?.value).map { $0 < 25 } ?? false
            ),
            AccumulationScoreItem(
                title: "Funding <= -0.005%",
                detail: "市場偏空夠明顯",
                valueText: formatFundingRate(averageFunding),
                weight: 1,
                isTriggered: averageFunding.map { $0 <= Self.negativeFundingThreshold } ?? false
            ),
            AccumulationScoreItem(
                title: "ETF 不再流出",
                detail: "邊際資金沒有惡化",
                valueText: formatMillionsUSD(etfNetFlow?.totalNetFlowMillionsUSD),
                weight: 1,
                isTriggered: (etfNetFlow?.totalNetFlowMillionsUSD).map { $0 >= 0 } ?? false
            ),
            AccumulationScoreItem(
                title: "RSI 偏弱",
                detail: "技術面接近低檔",
                valueText: formatRSIValue(rsi?.value),
                weight: 0.5,
                isTriggered: (rsi?.value).map { $0 < 35 } ?? false
            )
        ]

        self.items = rules
        self.earnedPoints = rules.reduce(0) { $0 + ($1.isTriggered ? $1.weight : 0) }
        self.maxPoints = rules.reduce(0) { $0 + $1.weight }
    }

    var segmentCount: Int {
        Int(maxPoints)
    }

    var filledSegments: Int {
        min(segmentCount, Int(earnedPoints.rounded(.down)))
    }

    var fillRatio: Double {
        guard maxPoints > 0 else { return 0 }
        return max(0, min(1, earnedPoints / maxPoints))
    }

    var scoreText: String {
        "\(formatPoint(earnedPoints)) / \(formatPoint(maxPoints))"
    }

    var statusText: String {
        let ratio = earnedPoints / maxPoints
        switch ratio {
        case ..<0.25:
            return "觀望"
        case 0.25..<0.45:
            return "冷靜觀察"
        case 0.45..<0.65:
            return "開始分批"
        case 0.65..<0.85:
            return "重點佈局"
        default:
            return "深度恐慌"
        }
    }

    var subtitleText: String {
        let triggered = items.filter(\.isTriggered).count
        return "\(triggered) 個條件達成"
    }

    private static func averageFundingRate(from snapshots: [FundingRateSnapshot]) -> Double? {
        let values = snapshots.compactMap(\.fundingRate)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func isBelow(spot: Double?, reference: Double?) -> Bool {
        guard let spot, let reference else { return false }
        return spot <= reference
    }

    private static func isNear(spot: Double?, reference: Double?, threshold: Double) -> Bool {
        guard let spot, let reference else { return false }
        return spot <= reference * (1 + threshold)
    }

    private static func spotComparisonText(spot: Double?, reference: Double?) -> String {
        guard let spot, let reference else { return "--" }
        let ratio = (spot / reference) - 1
        let sign = ratio > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", ratio * 100))%"
    }

    private func formatPoint(_ value: Double) -> String {
        value == floor(value) ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}

struct AccumulationScoreItem: Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let valueText: String
    let weight: Double
    let isTriggered: Bool
}
