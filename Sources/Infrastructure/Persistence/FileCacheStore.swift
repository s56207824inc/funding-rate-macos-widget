import Foundation

struct FileCacheStore: Sendable {
    let fileName: String

    func load<Cache: Decodable>(_ type: Cache.Type) -> Cache? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: cacheURL())
            return try decoder.decode(type, from: data)
        } catch {
            return nil
        }
    }

    func save<Cache: Encodable>(_ cache: Cache, errorContext: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(cache)
            let url = try cacheURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save \(errorContext) cache: \(error.localizedDescription)")
        }
    }

    private func cacheURL() throws -> URL {
        try applicationSupportRoot()
            .appendingPathComponent(fileName)
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
