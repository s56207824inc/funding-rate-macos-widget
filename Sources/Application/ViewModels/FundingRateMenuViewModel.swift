import Foundation

@MainActor
final class FundingRateMenuViewModel: ObservableObject {
    @Published private(set) var snapshots: [FundingRateSnapshot] = []
    @Published private(set) var bitcoinETFNetFlow: BitcoinETFNetFlowSnapshot?
    @Published private(set) var cryptoFearGreed: CryptoFearGreedSnapshot?
    @Published private(set) var bitcoinRSI: BitcoinRSISnapshot?
    @Published private(set) var bitcoinMVRVZScore: BitcoinMVRVZScoreSnapshot?
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
        self.refreshInterval = refreshInterval
        self.openRefreshThreshold = openRefreshThreshold

        self.snapshots = loadCachedFundingRates.execute(expectedSources: sources)
        self.bitcoinETFNetFlow = refreshBitcoinETFNetFlow.loadCached()
        self.cryptoFearGreed = refreshCryptoFearGreed.loadCached()
        self.bitcoinRSI = refreshBitcoinRSI.loadCached()
        self.bitcoinMVRVZScore = refreshBitcoinMVRVZScore.loadCached()
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
        if bitcoinETFNetFlow == nil || cryptoFearGreed == nil || bitcoinRSI == nil || bitcoinMVRVZScore == nil {
            return true
        }
        guard let lastRefreshAt else { return true }
        return Date().timeIntervalSince(lastRefreshAt) > openRefreshThreshold
    }

    private var shouldRefreshForPanelOpen: Bool {
        guard !isRefreshing else { return false }
        if bitcoinETFNetFlow == nil || cryptoFearGreed == nil || bitcoinRSI == nil || bitcoinMVRVZScore == nil {
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
        snapshots = sources.map { source in
            FundingRateSnapshot.loading(for: source.exchangeID, previous: previous[source.exchangeID])
        }
        .sorted(by: { $0.exchange.sortOrder < $1.exchange.sortOrder })
        bitcoinETFNetFlow = BitcoinETFNetFlowSnapshot.loading(previous: previousETFNetFlow)
        cryptoFearGreed = CryptoFearGreedSnapshot.loading(previous: previousFearGreed)
        bitcoinRSI = BitcoinRSISnapshot.loading(previous: previousRSI)
        bitcoinMVRVZScore = BitcoinMVRVZScoreSnapshot.loading(previous: previousMVRVZScore)

        async let fundingResult = refreshFundingRates.execute(previousSnapshots: previous)
        async let etfResult = refreshBitcoinETFNetFlow.execute(previousSnapshot: previousETFNetFlow)
        async let fearGreedResult = refreshCryptoFearGreed.execute(previousSnapshot: previousFearGreed)
        async let rsiResult = refreshBitcoinRSI.execute(previousSnapshot: previousRSI)
        async let mvrvZScoreResult = refreshBitcoinMVRVZScore.execute(previousSnapshot: previousMVRVZScore)

        let result = await fundingResult
        let etfSnapshot = await etfResult
        let fearGreedSnapshot = await fearGreedResult
        let rsiSnapshot = await rsiResult
        let mvrvZScoreSnapshot = await mvrvZScoreResult

        snapshots = result.snapshots
        bitcoinETFNetFlow = etfSnapshot
        cryptoFearGreed = fearGreedSnapshot
        bitcoinRSI = rsiSnapshot
        bitcoinMVRVZScore = mvrvZScoreSnapshot
        lastRefreshAt = [
            result.lastRefreshAt,
            etfSnapshot.fetchedAt == .distantPast ? nil : etfSnapshot.fetchedAt,
            fearGreedSnapshot.fetchedAt == .distantPast ? nil : fearGreedSnapshot.fetchedAt,
            rsiSnapshot.fetchedAt == .distantPast ? nil : rsiSnapshot.fetchedAt,
            mvrvZScoreSnapshot.fetchedAt == .distantPast ? nil : mvrvZScoreSnapshot.fetchedAt
        ]
            .compactMap { $0 }
            .max() ?? lastRefreshAt
        isRefreshing = false
    }
}
