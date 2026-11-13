import Foundation
import Combine
import Network

@MainActor
final class WaterStore: ObservableObject {
    @Published private(set) var points: [WaterPoint] = []
    @Published private(set) var saved: Set<String> = []
    @Published private(set) var configuration: BackendConfiguration?
    @Published private(set) var syncing = false
    @Published private(set) var connected = true
    @Published private(set) var syncMessage = ""
    @Published private(set) var recoveryRequired = false
    @Published var error: String?
    private let directory: URL
    private let defaults: UserDefaults
    private var monitor: NWPathMonitor?

    var isDemo: Bool { configuration == nil }
    var pending: [WaterReport] { points.flatMap(\.reports).filter { $0.delivery == .pending } }
    var fileURL: URL {
        directory.appendingPathComponent(configuration?.endpoint?.host ?? "demo").appendingPathExtension("json")
    }

    init(directory: URL? = nil, defaults: UserDefaults = .standard) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CommunityWater")
        self.defaults = defaults
        if let data = defaults.data(forKey: "communityBackend"),
           let value = try? JSONDecoder().decode(BackendConfiguration.self, from: data), value.isValid {
            configuration = value
        }
        load()
    }

    func startMonitoring() {
        guard monitor == nil else { return }
        let pathMonitor = NWPathMonitor()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.connected = available
                if available { await self?.sync() }
            }
        }
        monitor = pathMonitor
        pathMonitor.start(queue: DispatchQueue(label: "CommunityWater.network"))
    }

    @discardableResult
    func configure(_ value: BackendConfiguration?) -> Bool {
        guard !syncing, value == nil || value!.isValid else { return false }
        configuration = value
        if let value { defaults.set(try? JSONEncoder().encode(value), forKey: "communityBackend") }
        else { defaults.removeObject(forKey: "communityBackend") }
        error = nil; syncMessage = ""
        load()
        return true
    }

    private func load() {
        points = isDemo ? DemoData.points : []
        saved = []; recoveryRequired = false
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: fileURL))
            guard Set(snapshot.points.map(\.id)).count == snapshot.points.count,
                  snapshot.points.allSatisfy({ point in
                      (-90...90).contains(point.latitude) && (-180...180).contains(point.longitude) &&
                      point.reports.allSatisfy { $0.pointID == point.id } &&
                      Set(point.reports.map(\.id)).count == point.reports.count
                  }) else { throw CocoaError(.fileReadCorruptFile) }
            points = snapshot.points; saved = snapshot.saved
        } catch {
            recoveryRequired = true
            self.error = "Saved data could not be read. The original file is preserved. Recover storage in Settings before saving changes."
        }
    }

    func recoverStorage() {
        do {
            let backup = fileURL.appendingPathExtension("\(UUID().uuidString).backup")
            try FileManager.default.moveItem(at: fileURL, to: backup)
            load()
            error = nil
        } catch { self.error = "The damaged cache could not be backed up. Please check available storage." }
    }

    private func persist(_ updated: [WaterPoint], saved newSaved: Set<String>) -> Bool {
        guard !recoveryRequired else { return false }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(Snapshot(points: updated, saved: newSaved)).write(to: fileURL, options: .atomic)
            points = updated; saved = newSaved
            return true
        } catch {
            self.error = "Changes could not be saved. Check available storage and try again."
            return false
        }
    }

    func toggleSaved(_ id: String) {
        var updated = saved
        if !updated.insert(id).inserted { updated.remove(id) }
        _ = persist(points, saved: updated)
    }

    @discardableResult
    func report(pointID: String, condition: Condition, crowding: Crowding, repaired: Bool, note: String,
                observedAt: Date = Date()) -> Bool {
        guard let index = points.firstIndex(where: { $0.id == pointID }),
              note.count <= 500, observedAt <= Date().addingTimeInterval(60) else { return false }
        var updated = points
        updated[index].reports.append(WaterReport(pointID: pointID, condition: condition, crowding: crowding,
                                                  repaired: repaired, note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                                  observedAt: observedAt, delivery: isDemo ? .local : .pending, isMine: true))
        return persist(updated, saved: saved)
    }

    func sync(using service: (any CommunityService)? = nil) async {
        guard !syncing, !recoveryRequired, connected, let configuration else { return }
        syncing = true
        defer { syncing = false }
        let api = service ?? CommunityAPI(configuration: configuration)
        do {
            let remote = try await api.loadPoints()
            var merged = remote
            // Retain cached reports, including those created during this network request.
            for cached in points {
                if let index = merged.firstIndex(where: { $0.id == cached.id }) {
                    let remoteIDs = Set(merged[index].reports.map(\.id))
                    let ownedIDs = Set(cached.reports.filter(\.isMine).map(\.id))
                    for reportIndex in merged[index].reports.indices {
                        if ownedIDs.contains(merged[index].reports[reportIndex].id) {
                            merged[index].reports[reportIndex].isMine = true
                        }
                    }
                    merged[index].reports.append(contentsOf: cached.reports.filter { !remoteIDs.contains($0.id) })
                } else if cached.reports.contains(where: { $0.delivery == .pending }) {
                    merged.append(cached)
                }
            }
            guard persist(merged, saved: saved) else { return }
            for report in pending {
                try await api.upload(report)
                var updated = points
                for index in updated.indices {
                    if let reportIndex = updated[index].reports.firstIndex(where: { $0.id == report.id }) {
                        updated[index].reports[reportIndex].delivery = .uploaded
                    }
                }
                guard persist(updated, saved: saved) else { return }
            }
            syncMessage = "Updated \(Date().formatted(date: .omitted, time: .shortened))"
        } catch {
            syncMessage = "Could not connect. Saved data is available; pending reports will retry. Check the connection and backend settings."
        }
    }
}
