import Foundation

protocol HTTPClient: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T
    func data(from request: URLRequest) async throws -> Data
}

struct URLSessionHTTPClient: HTTPClient {
    func decode<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T {
        let data = try await data(from: request)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    func data(from request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ProviderError.invalidResponse
        }

        return data
    }
}

enum ProviderError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingData(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL 無效"
        case .invalidResponse:
            return "回傳格式異常"
        case .missingData(let message):
            return message
        }
    }
}
