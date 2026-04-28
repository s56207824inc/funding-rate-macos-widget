import Foundation

struct FileFundingRateCache: FundingRateCache {
    func load() -> [FundingRateSnapshot] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try cacheURL()
            let data = try Data(contentsOf: url)
            let cache = try decoder.decode(PersistedCache.self, from: data)
            return cache.snapshots
        } catch {
            return []
        }
    }

    func save(_ snapshots: [FundingRateSnapshot]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let cache = PersistedCache(savedAt: Date(), snapshots: snapshots)
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent("funding-rate-cache.json")
    }
}

struct FileBitcoinETFNetFlowCache: BitcoinETFNetFlowCache {
    func load() -> BitcoinETFNetFlowSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try cacheURL()
            let data = try Data(contentsOf: url)
            let cache = try decoder.decode(PersistedBitcoinETFNetFlowCache.self, from: data)
            return cache.snapshot
        } catch {
            return nil
        }
    }

    func save(_ snapshot: BitcoinETFNetFlowSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let cache = PersistedBitcoinETFNetFlowCache(savedAt: Date(), snapshot: snapshot)
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save ETF cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent("bitcoin-etf-net-flow-cache.json")
    }
}

struct FileCryptoFearGreedCache: CryptoFearGreedCache {
    func load() -> CryptoFearGreedSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try cacheURL()
            let data = try Data(contentsOf: url)
            let cache = try decoder.decode(PersistedCryptoFearGreedCache.self, from: data)
            return cache.snapshot
        } catch {
            return nil
        }
    }

    func save(_ snapshot: CryptoFearGreedSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let cache = PersistedCryptoFearGreedCache(savedAt: Date(), snapshot: snapshot)
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save fear greed cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent("crypto-fear-greed-cache.json")
    }
}

struct FileBitcoinRSICache: BitcoinRSICache {
    func load() -> BitcoinRSISnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try cacheURL()
            let data = try Data(contentsOf: url)
            let cache = try decoder.decode(PersistedBitcoinRSICache.self, from: data)
            return cache.snapshot
        } catch {
            return nil
        }
    }

    func save(_ snapshot: BitcoinRSISnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let cache = PersistedBitcoinRSICache(savedAt: Date(), snapshot: snapshot)
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save RSI cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent("bitcoin-rsi-cache.json")
    }
}

struct FileBitcoinMVRVZScoreCache: BitcoinMVRVZScoreCache {
    func load() -> BitcoinMVRVZScoreSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try cacheURL()
            let data = try Data(contentsOf: url)
            let cache = try decoder.decode(PersistedBitcoinMVRVZScoreCache.self, from: data)
            return cache.snapshot
        } catch {
            return nil
        }
    }

    func save(_ snapshot: BitcoinMVRVZScoreSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let cache = PersistedBitcoinMVRVZScoreCache(savedAt: Date(), snapshot: snapshot)
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save MVRV Z-Score cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent("bitcoin-mvrv-z-score-cache.json")
    }
}

private func applicationSupportRoot() throws -> URL {
    let root = try FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )

    return root
        .appendingPathComponent("FundingRateWidget", isDirectory: true)
}
