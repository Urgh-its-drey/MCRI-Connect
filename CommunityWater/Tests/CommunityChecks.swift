import Foundation

actor TestCommunity: CommunityService {
    var points: [WaterPoint]
    var failing = false
    var loseResponse = false
    var uploads: [UUID] = []
    init(points: [WaterPoint]) { self.points = points }
    func setFailing(_ value: Bool) { failing = value }
    func loseNextResponse() { loseResponse = true }
    func loadPoints() async throws -> [WaterPoint] { points }
    func upload(_ report: WaterReport) async throws {
        if failing { throw URLError(.notConnectedToInternet) }
        uploads.append(report.id)
        guard let index = points.firstIndex(where: { $0.id == report.pointID }) else { throw URLError(.badURL) }
        if !points[index].reports.contains(where: { $0.id == report.id }) {
            var shared = report
            shared.delivery = .uploaded; shared.isMine = false
            points[index].reports.append(shared)
        }
        if loseResponse {
            loseResponse = false
            throw URLError(.networkConnectionLost)
        }
    }
    func uploadCount() -> Int { uploads.count }
}

@main
struct CommunityChecks {
    @MainActor static func main() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "CommunityChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suite)
        }
        let store = WaterStore(directory: directory, defaults: defaults)
        let point = store.points[0]
        store.toggleSaved(point.id)
        precondition(store.report(pointID: point.id, condition: .working, crowding: .crowded, repaired: true, note: "  Pump fixed  "))
        let reloaded = WaterStore(directory: directory, defaults: defaults)
        precondition(reloaded.saved.contains(point.id))
        precondition(reloaded.points[0].latest?.note == "Pump fixed")
        precondition(reloaded.points[0].latest?.crowding == .crowded)
        precondition(reloaded.points[0].latest?.repaired == true)
        precondition(reloaded.points[0].latest?.delivery == .local)
        precondition(reloaded.points[0].latest?.isMine == true)
        precondition(store.pending.isEmpty)
        precondition(!store.report(pointID: "missing", condition: .dry, crowding: .unknown, repaired: false, note: ""))
        precondition(!store.report(pointID: point.id, condition: .dry, crowding: .unknown, repaired: false, note: String(repeating: "x", count: 501)))
        precondition(!store.report(pointID: point.id, condition: .dry, crowding: .unknown, repaired: false, note: "", observedAt: Date().addingTimeInterval(500)))
        let blank = WaterPoint(id: "verified", name: "Verified borehole", type: .borehole, area: "Community", latitude: -17.8, longitude: 31)
        precondition(blank.condition == .unknown && blank.latest == nil)

        let config = BackendConfiguration(url: "https://community-test.supabase.co", key: "sb_publishable_test")
        precondition(config.isValid)
        precondition(!BackendConfiguration(url: "http://community-test.supabase.co", key: "test").isValid)
        precondition(!BackendConfiguration(url: "https://example.com", key: "test").isValid)
        precondition(!BackendConfiguration(url: config.url, key: "sb_secret_example").isValid)
        let rolePayload = Data("{\"role\":\"service_role\"}".utf8).base64EncodedString()
        precondition(!BackendConfiguration(url: config.url, key: "header.\(rolePayload).signature").isValid)
        precondition(store.configure(config))
        precondition(store.points.isEmpty) // Demo reports never enter a real community.
        let service = TestCommunity(points: [blank])
        await store.sync(using: service)
        precondition(store.points.count == 1)
        precondition(store.report(pointID: blank.id, condition: .working, crowding: .quiet, repaired: true, note: "Latest"))
        let newest = store.points[0].latest!
        precondition(store.report(pointID: blank.id, condition: .broken, crowding: .unknown, repaired: false, note: "Earlier observation", observedAt: Date().addingTimeInterval(-3600)))
        precondition(store.points[0].condition == .working) // Late uploads cannot replace newer observations.
        await service.setFailing(true)
        await store.sync(using: service)
        precondition(store.pending.count == 2)
        let offlineReload = WaterStore(directory: directory, defaults: defaults)
        precondition(offlineReload.pending.count == 2 && offlineReload.pending.contains { $0.id == newest.id })
        await service.setFailing(false)
        await store.sync(using: service)
        precondition(store.pending.isEmpty)
        await store.sync(using: service)
        let uploads = await service.uploadCount()
        precondition(uploads == 2 && store.points[0].reports.count == 2)
        precondition(store.points[0].reports.allSatisfy { $0.isMine && $0.delivery == .uploaded })
        precondition(store.report(pointID: blank.id, condition: .dry, crowding: .unknown, repaired: false, note: "Lost response"))
        await service.loseNextResponse()
        await store.sync(using: service)
        precondition(store.pending.count == 1)
        await store.sync(using: service)
        precondition(store.pending.isEmpty && store.points[0].reports.count == 3)
        let totalUploads = await service.uploadCount()
        precondition(totalUploads == 3) // Server confirmation resolves an interrupted acknowledgement.
        precondition(store.configure(nil))
        precondition(store.points[0].latest?.note == "Pump fixed")
        precondition(store.configure(config))
        precondition(store.points[0].reports.count == 3)

        let blocker = directory.appendingPathComponent("blocker")
        try Data("file".utf8).write(to: blocker)
        let failing = WaterStore(directory: blocker, defaults: defaults)
        precondition(!failing.report(pointID: blank.id, condition: .dry, crowding: .unknown, repaired: false, note: ""))
        _ = failing.configure(nil)
        let before = failing.points
        precondition(!failing.report(pointID: before[0].id, condition: .dry, crowding: .unknown, repaired: false, note: ""))
        precondition(failing.points == before && failing.error != nil)

        let corruptDir = directory.appendingPathComponent("corrupt")
        try FileManager.default.createDirectory(at: corruptDir, withIntermediateDirectories: true)
        let corruptURL = corruptDir.appendingPathComponent("demo.json")
        try Data("invalid".utf8).write(to: corruptURL)
        let corrupt = WaterStore(directory: corruptDir, defaults: defaults)
        precondition(corrupt.recoveryRequired)
        precondition(!corrupt.report(pointID: corrupt.points[0].id, condition: .dry, crowding: .unknown, repaired: false, note: ""))
        let original = try String(contentsOf: corruptURL, encoding: .utf8)
        precondition(original == "invalid")
        corrupt.recoverStorage()
        precondition(!corrupt.recoveryRequired)
        let backups = try FileManager.default.contentsOfDirectory(at: corruptDir, includingPropertiesForKeys: nil)
        precondition(backups.contains { $0.pathExtension == "backup" })
        print("PASS: offline persistence, independent status fields, history ordering, upload retry, deduplication, ownership, separate caches, failed-save rollback and corruption recovery")
    }
}
