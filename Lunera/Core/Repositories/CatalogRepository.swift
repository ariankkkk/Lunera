import Foundation

final class CatalogRepository {
    private let restClient: SupabaseRESTClient

    init(restClient: SupabaseRESTClient = SupabaseRESTClient()) {
        self.restClient = restClient
    }

    func fetchGarments(limit: Int = 40) async throws -> [Garment] {
        try await restClient.get(
            table: "garments",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
    }

    func fetchStores() async throws -> [Store] {
        try await restClient.get(
            table: "stores",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "name.asc")
            ]
        )
    }

    func fetchStockSnapshots(garmentId: UUID, size: String? = nil) async throws -> [StockSnapshot] {
        var queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "garment_id", value: "eq.\(garmentId.uuidString)"),
            URLQueryItem(name: "order", value: "observed_at.desc")
        ]

        if let size {
            queryItems.append(URLQueryItem(name: "size", value: "eq.\(size)"))
        }

        return try await restClient.get(table: "stock_snapshots", queryItems: queryItems)
    }
}
