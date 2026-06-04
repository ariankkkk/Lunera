import Foundation

struct SupabaseRESTClient {
    var configuration: LuneraSupabaseConfiguration? = LuneraSupabaseConfiguration.fromBundle()
    var authRepository: AuthRepository = .shared
    var urlSession: URLSession = .shared

    func get<Response: Decodable>(
        table: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await request(table: table, method: "GET", queryItems: queryItems, body: Optional<EmptyRequestBody>.none)
    }

    func post<Response: Decodable, Body: Encodable>(
        table: String,
        queryItems: [URLQueryItem] = [],
        prefer: String = "return=representation",
        body: Body
    ) async throws -> Response {
        try await request(table: table, method: "POST", queryItems: queryItems, prefer: prefer, body: body)
    }

    func patch<Response: Decodable, Body: Encodable>(
        table: String,
        queryItems: [URLQueryItem] = [],
        prefer: String = "return=representation",
        body: Body
    ) async throws -> Response {
        try await request(table: table, method: "PATCH", queryItems: queryItems, prefer: prefer, body: body)
    }

    func delete<Response: Decodable>(
        table: String,
        queryItems: [URLQueryItem] = [],
        prefer: String = "return=minimal"
    ) async throws -> Response {
        try await request(table: table, method: "DELETE", queryItems: queryItems, prefer: prefer, body: Optional<EmptyRequestBody>.none)
    }

    private func request<Response: Decodable, Body: Encodable>(
        table: String,
        method: String,
        queryItems: [URLQueryItem],
        prefer: String = "return=representation",
        body: Body?
    ) async throws -> Response {
        guard let configuration else {
            throw RepositoryError.missingConfiguration
        }

        guard let accessToken = await authRepository.validAccessToken() else {
            throw RepositoryError.notAuthenticated
        }

        var components = URLComponents(url: configuration.url.appending(path: "rest/v1/\(table)"), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else {
            throw RepositoryError.missingConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(prefer, forHTTPHeaderField: "Prefer")

        if let body {
            request.httpBody = try JSONEncoder.luneraSupabase.encode(body)
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.networkFailure
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RepositoryError.server(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        }

        if data.isEmpty, Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        return try JSONDecoder.luneraSupabase.decode(Response.self, from: data)
    }
}

enum RepositoryError: Error, Equatable {
    case missingConfiguration
    case notAuthenticated
    case networkFailure
    case server(statusCode: Int, message: String?)
}

private struct EmptyRequestBody: Encodable {}

struct EmptyResponse: Decodable, Equatable {
    init() {}
}
