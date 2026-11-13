import Foundation

protocol CommunityService: Sendable {
    func loadPoints() async throws -> [WaterPoint]
    func upload(_ report: WaterReport) async throws
}

struct CommunityAPI: CommunityService {
    let configuration: BackendConfiguration

    private func request(table: String, query: [URLQueryItem] = [], method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let base = configuration.endpoint, configuration.isValid else { throw URLError(.badURL) }
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 25
        request.setValue(configuration.key, forHTTPHeaderField: "apikey")
        // Both modern publishable keys and legacy anon JWTs are supported.
        if !configuration.key.hasPrefix("sb_publishable_") {
            request.setValue("Bearer \(configuration.key)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=ignore-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func rows<T: Decodable>(_ table: String, order: String) async throws -> [T] {
        var result: [T] = []
        var offset = 0
        // Small pages work with the default PostgREST row limit.
        while true {
            let data = try await request(table: table, query: [
                .init(name: "select", value: "*"), .init(name: "order", value: order),
                .init(name: "limit", value: "100"), .init(name: "offset", value: String(offset))
            ])
            let page = try JSONDecoder().decode([T].self, from: data)
            result.append(contentsOf: page)
            if page.count < 100 { return result }
            offset += page.count
        }
    }

    func loadPoints() async throws -> [WaterPoint] {
        let points: [RemotePoint] = try await rows("water_points", order: "id.asc")
        let reports: [RemoteReport] = try await rows("water_reports", order: "id.asc")
        let grouped = Dictionary(grouping: try reports.map { try $0.local() }, by: \.pointID)
        return points.map {
            WaterPoint(id: $0.id, name: $0.name, type: $0.type, area: $0.area,
                       latitude: $0.latitude, longitude: $0.longitude, reports: grouped[$0.id] ?? [])
        }
    }

    func upload(_ report: WaterReport) async throws {
        let body = try JSONEncoder().encode(RemoteReport(report))
        _ = try await request(table: "water_reports", query: [.init(name: "on_conflict", value: "id")], method: "POST", body: body)
    }
}

private struct RemotePoint: Decodable {
    var id: String
    var name: String
    var type: SourceType
    var area: String
    var latitude: Double
    var longitude: Double
}

private struct RemoteReport: Codable {
    var id: UUID
    var point_id: String
    var condition: Condition
    var crowding: Crowding
    var repaired: Bool
    var note: String
    var observed_at: String

    init(_ report: WaterReport) {
        id = report.id; point_id = report.pointID; condition = report.condition
        crowding = report.crowding; repaired = report.repaired; note = report.note
        observed_at = ISO8601DateFormatter().string(from: report.observedAt)
    }

    func local() throws -> WaterReport {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: observed_at) ?? ISO8601DateFormatter().date(from: observed_at) else {
            throw URLError(.cannotParseResponse)
        }
        return WaterReport(id: id, pointID: point_id, condition: condition, crowding: crowding,
                           repaired: repaired, note: note, observedAt: date, delivery: .uploaded)
    }
}
