import Foundation

struct BybitFundingRateSource: FundingRateSource {
    let exchangeID: ExchangeID = .bybit
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchBTCFundingRate() async throws -> FundingRateSnapshot {
        guard let url = URL(string: "https://api.bybit.com/v5/market/tickers?category=linear&symbol=BTCUSDT") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(BybitResponse.self, from: URLRequest(url: url))
        guard let row = response.result.list.first else {
            throw ProviderError.missingData("Bybit 無資料")
        }

        return FundingRateSnapshot(
            exchange: exchangeID,
            symbol: "BTC",
            fundingRate: Double(row.fundingRate),
            nextFundingTime: row.nextFundingTime.flatMap(parseMilliseconds),
            fetchedAt: Date(),
            sourceStatus: .ok,
            errorMessage: nil
        )
    }
}

struct BinanceFundingRateSource: FundingRateSource {
    let exchangeID: ExchangeID = .binance
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchBTCFundingRate() async throws -> FundingRateSnapshot {
        guard let url = URL(string: "https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(BinanceResponse.self, from: URLRequest(url: url))
        return FundingRateSnapshot(
            exchange: exchangeID,
            symbol: "BTC",
            fundingRate: Double(response.lastFundingRate),
            nextFundingTime: Date(timeIntervalSince1970: TimeInterval(response.nextFundingTime) / 1000),
            fetchedAt: Date(),
            sourceStatus: .ok,
            errorMessage: nil
        )
    }
}

struct OKXFundingRateSource: FundingRateSource {
    let exchangeID: ExchangeID = .okx
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchBTCFundingRate() async throws -> FundingRateSnapshot {
        guard let url = URL(string: "https://www.okx.com/api/v5/public/funding-rate?instId=BTC-USDT-SWAP") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(OKXResponse.self, from: URLRequest(url: url))
        guard let row = response.data.first else {
            throw ProviderError.missingData("OKX 無資料")
        }

        return FundingRateSnapshot(
            exchange: exchangeID,
            symbol: "BTC",
            fundingRate: Double(row.fundingRate),
            nextFundingTime: row.nextFundingTime.flatMap(parseMilliseconds),
            fetchedAt: Date(),
            sourceStatus: .ok,
            errorMessage: nil
        )
    }
}

struct HyperliquidFundingRateSource: FundingRateSource {
    let exchangeID: ExchangeID = .hyperliquid
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchBTCFundingRate() async throws -> FundingRateSnapshot {
        guard let url = URL(string: "https://api.hyperliquid.xyz/info") else {
            throw ProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["type": "metaAndAssetCtxs"])

        let response = try await httpClient.decode(HyperliquidResponse.self, from: request)
        guard let index = response.universe.firstIndex(where: { $0.name == "BTC" }),
              response.assetContexts.indices.contains(index) else {
            throw ProviderError.missingData("Hyperliquid BTC 無資料")
        }

        let context = response.assetContexts[index]
        return FundingRateSnapshot(
            exchange: exchangeID,
            symbol: "BTC",
            fundingRate: Double(context.funding),
            nextFundingTime: nil,
            fetchedAt: Date(),
            sourceStatus: .ok,
            errorMessage: nil
        )
    }
}

struct BitgetFundingRateSource: FundingRateSource {
    let exchangeID: ExchangeID = .bitget
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchBTCFundingRate() async throws -> FundingRateSnapshot {
        guard let url = URL(string: "https://api.bitget.com/api/v2/mix/market/current-fund-rate?symbol=BTCUSDT&productType=USDT-FUTURES") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(BitgetResponse.self, from: URLRequest(url: url))
        guard let row = response.data.first else {
            throw ProviderError.missingData("Bitget 無資料")
        }

        return FundingRateSnapshot(
            exchange: exchangeID,
            symbol: "BTC",
            fundingRate: Double(row.fundingRate),
            nextFundingTime: row.nextUpdate.flatMap(parseMilliseconds),
            fetchedAt: Date(),
            sourceStatus: .ok,
            errorMessage: nil
        )
    }
}

struct FarsideBitcoinETFNetFlowSource: BitcoinETFNetFlowSource {
    private let httpClient: HTTPClient
    private let sourceName = "Farside"
    private let tickers = ["IBIT", "FBTC", "BITB", "ARKB", "BTCO", "EZBC", "BRRR", "HODL", "BTCW", "MSBT", "GBTC", "BTC"]

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatestNetFlow() async throws -> BitcoinETFNetFlowSnapshot {
        guard let url = URL(string: "https://farside.co.uk/bitcoin-etf-flow-all-data/") else {
            throw ProviderError.invalidURL
        }

        let data = try await httpClient.data(from: URLRequest(url: url))
        guard let html = String(data: data, encoding: .utf8) else {
            throw ProviderError.missingData("ETF 頁面內容無法解析")
        }

        let rows = parseRows(from: html)
        guard let latest = rows.sorted(by: { $0.date < $1.date }).last else {
            throw ProviderError.missingData("ETF 淨流入資料暫時不可用")
        }

        let entries = zip(tickers, latest.values.dropLast()).map { ticker, value in
            BitcoinETFNetFlowEntry(ticker: ticker, netFlowMillionsUSD: parseFlowValue(value))
        }

        return BitcoinETFNetFlowSnapshot(
            reportDate: latest.date,
            totalNetFlowMillionsUSD: parseFlowValue(latest.values.last ?? ""),
            entries: entries,
            fetchedAt: Date(),
            sourceStatus: .ok,
            sourceName: sourceName,
            errorMessage: nil
        )
    }

    private func parseRows(from html: String) -> [(date: Date, values: [String])] {
        let sanitized = html
            .replacingOccurrences(of: "(?is)<script.*?</script>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "(?is)<style.*?</style>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")

        let tokens = sanitized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var rows: [(Date, [String])] = []
        var index = 0

        while index < tokens.count {
            let token = tokens[index]
            guard let date = parseETFDate(token) else {
                index += 1
                continue
            }

            let endIndex = min(index + 14, tokens.count)
            let values = Array(tokens[(index + 1)..<endIndex])
            if values.count == 13 {
                rows.append((date, values))
            }
            index = endIndex
        }

        return rows
    }
}

struct AlternativeCryptoFearGreedSource: CryptoFearGreedSource {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatestFearGreed() async throws -> CryptoFearGreedSnapshot {
        guard let url = URL(string: "https://api.alternative.me/fng/?limit=1") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(AlternativeFearGreedResponse.self, from: URLRequest(url: url))
        guard let item = response.data.first else {
            throw ProviderError.missingData("恐懼貪婪指數無資料")
        }

        return CryptoFearGreedSnapshot(
            value: Int(item.value),
            classification: item.valueClassification,
            reportDate: TimeInterval(item.timestamp).map(Date.init(timeIntervalSince1970:)),
            fetchedAt: Date(),
            sourceStatus: .ok,
            sourceName: "Alternative.me",
            errorMessage: nil
        )
    }
}

struct BinanceBitcoinRSISource: BitcoinRSISource {
    private let httpClient: HTTPClient
    private let symbol: String
    private let interval: String
    private let period: Int
    private let sourceName = "Binance"

    init(
        httpClient: HTTPClient,
        symbol: String = "BTCUSDT",
        interval: String = "1d",
        period: Int = 14
    ) {
        self.httpClient = httpClient
        self.symbol = symbol
        self.interval = interval
        self.period = period
    }

    func fetchLatestRSI() async throws -> BitcoinRSISnapshot {
        guard let url = URL(string: "https://api.binance.com/api/v3/klines?symbol=\(symbol)&interval=\(interval)&limit=100") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode([[BinanceKlineField]].self, from: URLRequest(url: url))
        let closes = response.compactMap { row -> Double? in
            guard row.count > 4 else { return nil }
            if case let .string(value) = row[4] {
                return Double(value)
            }
            return nil
        }

        guard closes.count > period else {
            throw ProviderError.missingData("RSI K 線資料不足")
        }

        guard let value = calculateRSI(closes: closes, period: period) else {
            throw ProviderError.missingData("RSI 計算失敗")
        }

        let reportDate = response.last.flatMap { row -> Date? in
            guard row.count > 6, case let .int64(closeTime) = row[6] else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(closeTime) / 1000)
        }

        return BitcoinRSISnapshot(
            value: value,
            intervalLabel: interval.uppercased(),
            period: period,
            reportDate: reportDate,
            fetchedAt: Date(),
            sourceStatus: .ok,
            sourceName: sourceName,
            errorMessage: nil
        )
    }
}

struct BitboBitcoinMVRVZScoreSource: BitcoinMVRVZScoreSource {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatestMVRVZScore() async throws -> BitcoinMVRVZScoreSnapshot {
        guard let url = URL(string: "https://charts.bitbo.io/api/v1/mvrv-z/?latest=true") else {
            throw ProviderError.invalidURL
        }

        let response = try await httpClient.decode(BitboMVRVZScoreResponse.self, from: URLRequest(url: url))
        guard let latest = response.data.last else {
            throw ProviderError.missingData("MVRV Z-Score 無資料")
        }

        return BitcoinMVRVZScoreSnapshot(
            value: Double(latest.mvrvZScore),
            realizedPriceUSD: nil,
            shortTermHolderRealizedPriceUSD: nil,
            reportDate: parseISODate(latest.date),
            fetchedAt: Date(),
            sourceStatus: .ok,
            sourceName: "Bitbo",
            errorMessage: nil
        )
    }
}

struct NewhedgeBitcoinMVRVZScoreSource: BitcoinMVRVZScoreSource {
    private let httpClient: HTTPClient
    private let sourceName = "Newhedge"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatestMVRVZScore() async throws -> BitcoinMVRVZScoreSnapshot {
        let pages = [
            "https://newhedge.io/bitcoin/mvrv-z-score",
            "https://newhedge.io/bitcoin"
        ]

        for page in pages {
            guard let url = URL(string: page) else { continue }
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

            do {
                let data = try await httpClient.data(from: request)
                guard let html = String(data: data, encoding: .utf8) else {
                    continue
                }

                guard let latestValue = parseLatestMVRVZScore(from: html) else {
                    continue
                }

                return BitcoinMVRVZScoreSnapshot(
                    value: latestValue,
                    realizedPriceUSD: nil,
                    shortTermHolderRealizedPriceUSD: nil,
                    reportDate: nil,
                    fetchedAt: Date(),
                    sourceStatus: .ok,
                    sourceName: sourceName,
                    errorMessage: nil
                )
            } catch {
                continue
            }
        }

        throw ProviderError.missingData("MVRV Z-Score 最新快照無資料")
    }

    private func parseLatestMVRVZScore(from html: String) -> Double? {
        let tokens = tokenizeHTML(html)
        let normalizedTokens = tokens.map(normalizeToken)

        if let pageValue = parseFromDedicatedPage(tokens: tokens, normalizedTokens: normalizedTokens) {
            return pageValue
        }

        return parseFromDashboard(tokens: tokens, normalizedTokens: normalizedTokens)
    }

    private func tokenizeHTML(_ html: String) -> [String] {
        let sanitized = html
            .replacingOccurrences(of: "(?is)<script.*?</script>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "(?is)<style.*?</style>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")

        return sanitized
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseFromDedicatedPage(tokens: [String], normalizedTokens: [String]) -> Double? {
        guard let latestIndex = normalizedTokens.firstIndex(of: "latest mvrv z score snapshot") else {
            return nil
        }

        let searchWindow = Array(tokens.suffix(from: latestIndex).prefix(20))
        let normalizedWindow = searchWindow.map(normalizeToken)
        guard let metricIndex = normalizedWindow.firstIndex(of: "mvrv z score") else {
            return nil
        }

        for token in searchWindow.dropFirst(metricIndex + 1) {
            let candidate = numericCandidate(from: token)
            if let value = Double(candidate) {
                return value
            }
        }

        return nil
    }

    private func parseFromDashboard(tokens: [String], normalizedTokens: [String]) -> Double? {
        guard let metricIndex = normalizedTokens.firstIndex(of: "mvrv z-score")
            ?? normalizedTokens.firstIndex(of: "mvrv z score") else {
            return nil
        }

        let searchWindow = Array(tokens.suffix(from: metricIndex).prefix(10))
        for token in searchWindow.dropFirst() {
            let candidate = numericCandidate(from: token)
            if let value = Double(candidate) {
                return value
            }
        }

        return nil
    }

    private func normalizeToken(_ token: String) -> String {
        token
            .lowercased()
            .replacingOccurrences(of: "####", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func numericCandidate(from token: String) -> String {
        token
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "+-0123456789.").inverted)
    }
}

struct BGeometricsBitcoinMVRVZScoreSource: BitcoinMVRVZScoreSource {
    private let httpClient: HTTPClient
    private let sourceName = "BGeometrics"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLatestMVRVZScore() async throws -> BitcoinMVRVZScoreSnapshot {
        guard let url = URL(string: "https://charts.bgeometrics.com/graphics/mvrv.html") else {
            throw ProviderError.invalidURL
        }

        async let htmlData = httpClient.data(from: URLRequest(url: url))
        async let realizedPriceData = fetchRealizedPriceData()
        async let sthRealizedPriceData = fetchShortTermHolderRealizedPriceData()

        let data = try await htmlData
        guard let html = String(data: data, encoding: .utf8) else {
            throw ProviderError.missingData("MVRV Z-Score 圖表內容無法解析")
        }

        guard let snapshot = parseSnapshot(from: html) else {
            throw ProviderError.missingData("MVRV Z-Score 圖表資料無法解析")
        }

        let realizedPrice = try await realizedPriceData
        let sthRealizedPrice = try await sthRealizedPriceData

        return BitcoinMVRVZScoreSnapshot(
            value: snapshot.value,
            realizedPriceUSD: realizedPrice,
            shortTermHolderRealizedPriceUSD: sthRealizedPrice,
            reportDate: snapshot.reportDate,
            fetchedAt: Date(),
            sourceStatus: .ok,
            sourceName: sourceName,
            errorMessage: nil
        )
    }

    private func parseSnapshot(from html: String) -> (value: Double, reportDate: Date)? {
        let pattern = #"const\s+data_mvrv\s*=\s*(\[\[.*?\]\]);"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let dataRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let arrayText = String(html[dataRange])
        guard let data = arrayText.data(using: .utf8),
              let rows = try? JSONDecoder().decode([[Double]].self, from: data),
              let last = rows.last,
              last.count >= 2 else {
            return nil
        }

        let reportDate = Date(timeIntervalSince1970: last[0] / 1000)
        return (value: last[1], reportDate: reportDate)
    }

    private func fetchRealizedPriceData() async throws -> Double? {
        guard let url = URL(string: "https://charts.bgeometrics.com/files/realized_price.json") else {
            throw ProviderError.invalidURL
        }

        let rows = try await httpClient.decode([[Double]].self, from: URLRequest(url: url))
        guard let last = rows.last, last.count >= 2 else {
            return nil
        }

        return last[1]
    }

    private func fetchShortTermHolderRealizedPriceData() async throws -> Double? {
        guard let url = URL(string: "https://charts.bgeometrics.com/files/sth_realized_price.json") else {
            throw ProviderError.invalidURL
        }

        let rows = try await httpClient.decode([[Double]].self, from: URLRequest(url: url))
        guard let last = rows.last, last.count >= 2 else {
            return nil
        }

        return last[1]
    }
}

private func parseMilliseconds(_ value: String) -> Date? {
    guard let milliseconds = Double(value) else { return nil }
    return Date(timeIntervalSince1970: milliseconds / 1000)
}

private func parseETFDate(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "dd MMM yyyy"
    return formatter.date(from: value)
}

private func parseFlowValue(_ value: String) -> Double? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed != "-" else { return nil }

    if trimmed.hasPrefix("("), trimmed.hasSuffix(")") {
        let numeric = String(trimmed.dropFirst().dropLast())
        return Double(numeric).map { -$0 }
    }

    return Double(trimmed)
}

private func parseISODate(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: value)
}

private struct BybitResponse: Decodable {
    struct ResultPayload: Decodable {
        struct Row: Decodable {
            let fundingRate: String
            let nextFundingTime: String?
        }

        let list: [Row]
    }

    let result: ResultPayload
}

private struct BinanceResponse: Decodable {
    let lastFundingRate: String
    let nextFundingTime: Int64
}

private struct OKXResponse: Decodable {
    struct Row: Decodable {
        let fundingRate: String
        let nextFundingTime: String?
    }

    let data: [Row]
}

private struct HyperliquidResponse: Decodable {
    let universe: [HyperliquidMeta.UniverseItem]
    let assetContexts: [HyperliquidAssetContext]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let meta = try container.decode(HyperliquidMeta.self)
        let assetContexts = try container.decode([HyperliquidAssetContext].self)
        self.universe = meta.universe
        self.assetContexts = assetContexts
    }
}

private struct HyperliquidMeta: Decodable {
    struct UniverseItem: Decodable {
        let name: String
    }

    let universe: [UniverseItem]
}

private struct HyperliquidAssetContext: Decodable {
    let funding: String
}

private struct BitgetResponse: Decodable {
    struct Row: Decodable {
        let fundingRate: String
        let nextUpdate: String?
    }

    let data: [Row]
}

private struct AlternativeFearGreedResponse: Decodable {
    struct Item: Decodable {
        let value: String
        let valueClassification: String
        let timestamp: String

        enum CodingKeys: String, CodingKey {
            case value
            case valueClassification = "value_classification"
            case timestamp
        }
    }

    let data: [Item]
}

private struct BitboMVRVZScoreResponse: Decodable {
    struct Item: Decodable {
        let date: String
        let mvrvZScore: String

        enum CodingKeys: String, CodingKey {
            case date
            case mvrvZScore = "mvrv_z_score"
        }
    }

    let data: [Item]
}

private enum BinanceKlineField: Decodable {
    case int64(Int64)
    case string(String)
    case double(Double)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int64.self) {
            self = .int64(intValue)
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }

        self = .string(try container.decode(String.self))
    }
}

private func calculateRSI(closes: [Double], period: Int) -> Double? {
    guard closes.count > period else { return nil }

    var gains = 0.0
    var losses = 0.0

    for index in 1...period {
        let change = closes[index] - closes[index - 1]
        if change >= 0 {
            gains += change
        } else {
            losses += abs(change)
        }
    }

    var averageGain = gains / Double(period)
    var averageLoss = losses / Double(period)

    if averageLoss == 0 {
        return 100
    }

    if closes.count == period + 1 {
        let rs = averageGain / averageLoss
        return 100 - (100 / (1 + rs))
    }

    for index in (period + 1)..<closes.count {
        let change = closes[index] - closes[index - 1]
        let gain = max(change, 0)
        let loss = max(-change, 0)

        averageGain = ((averageGain * Double(period - 1)) + gain) / Double(period)
        averageLoss = ((averageLoss * Double(period - 1)) + loss) / Double(period)
    }

    if averageLoss == 0 {
        return 100
    }

    let rs = averageGain / averageLoss
    return 100 - (100 / (1 + rs))
}
