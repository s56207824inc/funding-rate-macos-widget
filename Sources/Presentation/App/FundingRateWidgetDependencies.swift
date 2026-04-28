import Foundation

enum FundingRateWidgetDependencies {
    @MainActor
    static func makeViewModel() -> FundingRateMenuViewModel {
        let httpClient = URLSessionHTTPClient()
        let fundingSources = makeFundingSources(httpClient: httpClient)
        let fundingRateCache = FileFundingRateCache()
        let bitcoinETFNetFlowCache = FileBitcoinETFNetFlowCache()
        let cryptoFearGreedCache = FileCryptoFearGreedCache()
        let bitcoinRSICache = FileBitcoinRSICache()
        let bitcoinMVRVZScoreCache = FileBitcoinMVRVZScoreCache()

        return FundingRateMenuViewModel(
            sources: fundingSources,
            loadCachedFundingRates: LoadCachedFundingRatesUseCase(cache: fundingRateCache),
            refreshFundingRates: RefreshFundingRatesUseCase(
                sources: fundingSources,
                cache: fundingRateCache,
                staleThreshold: 1200
            ),
            refreshBitcoinETFNetFlow: RefreshBitcoinETFNetFlowUseCase(
                source: FarsideBitcoinETFNetFlowSource(httpClient: httpClient),
                cache: bitcoinETFNetFlowCache,
                staleThreshold: 43_200
            ),
            refreshCryptoFearGreed: RefreshCryptoFearGreedUseCase(
                source: AlternativeCryptoFearGreedSource(httpClient: httpClient),
                cache: cryptoFearGreedCache,
                staleThreshold: 43_200
            ),
            refreshBitcoinRSI: RefreshBitcoinRSIUseCase(
                source: BinanceBitcoinRSISource(httpClient: httpClient),
                cache: bitcoinRSICache,
                staleThreshold: 3_600
            ),
            refreshBitcoinMVRVZScore: RefreshBitcoinMVRVZScoreUseCase(
                source: BGeometricsBitcoinMVRVZScoreSource(httpClient: httpClient),
                cache: bitcoinMVRVZScoreCache,
                staleThreshold: 43_200
            )
        )
    }

    private static func makeFundingSources(httpClient: HTTPClient) -> [FundingRateSource] {
        [
            BybitFundingRateSource(httpClient: httpClient),
            BinanceFundingRateSource(httpClient: httpClient),
            OKXFundingRateSource(httpClient: httpClient),
            HyperliquidFundingRateSource(httpClient: httpClient),
            BitgetFundingRateSource(httpClient: httpClient)
        ]
    }
}
