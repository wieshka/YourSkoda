import Foundation

/// Thin async/await client for the Škoda Connect B2C Public API (Beta).
/// Reference: https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html
final class SkodaAPIClient {
    static let baseURL = URL(string: "https://public.api.connect.skoda-auto.cz")!

    private let session: URLSession
    /// Latest observed rate limit / key expiry metadata, updated after every request.
    private(set) var lastResponseMeta: ResponseMeta?

    struct ResponseMeta {
        var apiKeyExpiresAt: Date?
        var rateLimitLimit: Int?
        var rateLimitRemaining: Int?
        var rateLimitResetSeconds: Int?
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    private lazy var decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: string) {
                return date
            }
            if let date = ISO8601DateFormatter.standard.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(string)")
        }
        return d
    }()

    private lazy var encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Public operations

    func getVehicle(vin: String, apiKey: String, include: Set<VehiclePart> = []) async throws -> VehicleResponse {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("/api/v1/vehicles/\(vin)"), resolvingAgainstBaseURL: false)!
        if !include.isEmpty {
            let value = include.map(\.rawValue).joined(separator: ",")
            components.queryItems = [URLQueryItem(name: "include", value: value)]
        }
        let request = makeRequest(url: components.url!, method: "GET", apiKey: apiKey)
        return try await send(request, decode: VehicleResponse.self)
    }

    func startCharging(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/charging/start", apiKey: apiKey)
    }

    func stopCharging(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/charging/stop", apiKey: apiKey)
    }

    func startAirConditioning(vin: String, apiKey: String, config: StartAirConditioningConfiguration) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/air-conditioning/start", apiKey: apiKey, body: config)
    }

    func stopAirConditioning(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/air-conditioning/stop", apiKey: apiKey)
    }

    func startAuxiliaryHeating(vin: String, apiKey: String, config: StartAuxiliaryHeatingConfiguration) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/auxiliary-heating/start", apiKey: apiKey, body: config)
    }

    func stopAuxiliaryHeating(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/auxiliary-heating/stop", apiKey: apiKey)
    }

    func startActiveVentilation(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/active-ventilation/start", apiKey: apiKey)
    }

    func stopActiveVentilation(vin: String, apiKey: String) async throws {
        try await sendAction(path: "/api/v1/vehicles/\(vin)/active-ventilation/stop", apiKey: apiKey)
    }

    // MARK: - Plumbing

    private func sendAction<Body: Encodable>(path: String, apiKey: String, body: Body) async throws {
        var request = makeRequest(url: Self.baseURL.appendingPathComponent(path), method: "POST", apiKey: apiKey)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        _ = try await sendNoContent(request)
    }

    private func sendAction(path: String, apiKey: String) async throws {
        let request = makeRequest(url: Self.baseURL.appendingPathComponent(path), method: "POST", apiKey: apiKey)
        _ = try await sendNoContent(request)
    }

    private func makeRequest(url: URL, method: String, apiKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func sendNoContent(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await perform(request)
        try validate(response: response, data: data)
        return data
    }

    private func send<T: Decodable>(_ request: URLRequest, decode: T.Type) async throws -> T {
        let (data, response) = try await perform(request)
        try validate(response: response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SkodaAPIError.decoding(error)
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw SkodaAPIError.network(error)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        captureMeta(from: http)
        guard !(200...299).contains(http.statusCode) else { return }

        let problem = try? JSONDecoder().decode(ProblemDetail.self, from: data)
        switch http.statusCode {
        case 401:
            throw SkodaAPIError.unauthorized(problem)
        case 403:
            throw SkodaAPIError.forbidden(problem)
        case 404:
            throw SkodaAPIError.notFound(problem)
        case 422:
            throw SkodaAPIError.unprocessable(problem)
        case 429:
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw SkodaAPIError.rateLimited(retryAfter: retryAfter, problem: problem)
        default:
            throw SkodaAPIError.server(http.statusCode, problem)
        }
    }

    private func captureMeta(from http: HTTPURLResponse) {
        var meta = ResponseMeta()
        if let expiresString = http.value(forHTTPHeaderField: "X-API-Key-Expires-At") {
            meta.apiKeyExpiresAt = ISO8601DateFormatter.standard.date(from: expiresString)
        }
        meta.rateLimitLimit = http.value(forHTTPHeaderField: "RateLimit-Limit").flatMap(Int.init)
        meta.rateLimitRemaining = http.value(forHTTPHeaderField: "RateLimit-Remaining").flatMap(Int.init)
        meta.rateLimitResetSeconds = http.value(forHTTPHeaderField: "RateLimit-Reset").flatMap(Int.init)
        self.lastResponseMeta = meta
    }
}

extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
