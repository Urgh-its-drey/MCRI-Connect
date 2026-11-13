import Foundation

enum Condition: String, Codable, CaseIterable, Identifiable {
    case working, broken, dry, unknown
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .working: "drop.fill"
        case .broken: "wrench.adjustable.fill"
        case .dry: "drop.triangle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}

enum Crowding: String, Codable, CaseIterable, Identifiable {
    case unknown, quiet, crowded
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unknown: "Not reported"
        case .quiet: "Not crowded"
        case .crowded: "Crowded"
        }
    }
}

enum SourceType: String, Codable, CaseIterable, Identifiable {
    case borehole, tap, well, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .borehole: "Borehole"
        case .tap: "Communal tap"
        case .well: "Protected well"
        case .other: "Other"
        }
    }
}

enum Delivery: String, Codable { case sample, local, pending, uploaded }

struct WaterReport: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var pointID: String
    var condition: Condition
    var crowding: Crowding
    var repaired: Bool
    var note: String
    var observedAt: Date
    var delivery: Delivery
    var isMine: Bool = false
}

struct WaterPoint: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var type: SourceType
    var area: String
    var latitude: Double
    var longitude: Double
    var reports: [WaterReport] = []
    var latest: WaterReport? {
        reports.max {
            $0.observedAt == $1.observedAt ? $0.id.uuidString < $1.id.uuidString : $0.observedAt < $1.observedAt
        }
    }
    var condition: Condition { latest?.condition ?? .unknown }
    var history: [WaterReport] { reports.sorted { $0.observedAt > $1.observedAt } }
}

struct Snapshot: Codable {
    var points: [WaterPoint]
    var saved: Set<String>
}

struct BackendConfiguration: Codable, Equatable {
    var url: String
    var key: String
    var endpoint: URL? {
        guard let value = URL(string: url), value.scheme == "https",
              let host = value.host, host.hasSuffix(".supabase.co"),
              value.user == nil, value.password == nil, value.port == nil,
              value.query == nil, value.fragment == nil,
              value.path.isEmpty || value.path == "/" else { return nil }
        return value
    }
    var isValid: Bool {
        guard endpoint != nil else { return false }
        if key.hasPrefix("sb_publishable_") { return key.count > "sb_publishable_".count }
        // Legacy keys are JWTs. Only public anon keys belong in a client app.
        let parts = key.split(separator: ".")
        guard parts.count == 3 else { return false }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return object["role"] as? String == "anon"
    }
}

enum DemoData {
    static let points: [WaterPoint] = {
        let rows: [(String, String, SourceType, String, Double, Double, Condition, Crowding)] = [
            ("demo-budiriro", "Budiriro community borehole", .borehole, "Budiriro", -17.892, 30.948, .working, .quiet),
            ("demo-glenview", "Glen View 3 tap", .tap, "Glen View", -17.904, 30.966, .working, .crowded),
            ("demo-highfield", "Machipisa market borehole", .borehole, "Highfield", -17.889, 30.998, .broken, .unknown),
            ("demo-mufakose", "Mufakose clinic tap", .tap, "Mufakose", -17.876, 30.939, .working, .quiet),
            ("demo-warren", "Warren Park well", .well, "Warren Park", -17.852, 30.985, .dry, .unknown),
            ("demo-kambuzuma", "Kambuzuma Section 5", .borehole, "Kambuzuma", -17.866, 30.966, .unknown, .unknown)
        ]
        let date = ISO8601DateFormatter().date(from: "2026-11-12T07:30:00Z")!
        return rows.enumerated().map { index, row in
            var point = WaterPoint(id: row.0, name: row.1, type: row.2, area: row.3, latitude: row.4, longitude: row.5)
            if row.6 != .unknown {
                point.reports = [
                    WaterReport(pointID: row.0, condition: row.6, crowding: row.7, repaired: index == 3,
                                note: "Illustrative report for demonstration only.", observedAt: date, delivery: .sample),
                    WaterReport(pointID: row.0, condition: .broken, crowding: .unknown, repaired: false,
                                note: "Sample pump problem recorded earlier.", observedAt: date.addingTimeInterval(-172800), delivery: .sample)
                ]
            }
            return point
        }
    }()
}
