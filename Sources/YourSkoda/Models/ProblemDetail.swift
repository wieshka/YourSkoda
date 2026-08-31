import Foundation

/// RFC 9457 Problem Detail returned by the Škoda B2C API on error responses.
struct ProblemDetail: Codable {
    var type: String?
    var title: String?
    var status: Int?
    var detail: String?
    var instance: String?
    var parameter: String?
    var rejectedValue: String?
    var allowedValues: [String]?
}

enum SkodaAPIError: Error, LocalizedError, Identifiable {
    case unauthorized(ProblemDetail?)
    case forbidden(ProblemDetail?)
    case notFound(ProblemDetail?)
    case unprocessable(ProblemDetail?)
    case rateLimited(retryAfter: Int?, problem: ProblemDetail?)
    case server(Int, ProblemDetail?)
    case network(Error)
    case decoding(Error)
    case missingAPIKey
    case invalidVIN

    var id: String { errorDescription ?? "unknown" }

    var errorDescription: String? {
        switch self {
        case .unauthorized(let p):
            return p?.detail ?? "Unauthorized. Your API key may be invalid or expired."
        case .forbidden(let p):
            return p?.detail ?? "This API key is not authorized for this vehicle or operation."
        case .notFound(let p):
            return p?.detail ?? "No vehicle found for this VIN."
        case .unprocessable(let p):
            return p?.detail ?? "The vehicle cannot perform this operation right now."
        case .rateLimited(let retryAfter, let p):
            if let retryAfter {
                return (p?.detail ?? "Rate limit exceeded.") + " Retry after \(retryAfter)s."
            }
            return p?.detail ?? "Rate limit exceeded."
        case .server(let code, let p):
            return p?.detail ?? "Server error (\(code)). Please try again later."
        case .network(let err):
            return "Network error: \(err.localizedDescription)"
        case .decoding(let err):
            return "Failed to parse response: \(err.localizedDescription)"
        case .missingAPIKey:
            return "No API key configured. Add one in Settings."
        case .invalidVIN:
            return "VIN must be exactly 17 characters."
        }
    }
}
