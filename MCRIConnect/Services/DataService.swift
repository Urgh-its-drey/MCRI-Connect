import Foundation

/// The seam a Supabase client plugs into: every read is async and returns plain
/// models, so swapping `LocalDataService` for a network one touches no views.
protocol DataService {
    func students() async throws -> [Student]
    func internships() async throws -> [Internship]
    func applications(for studentID: UUID) async throws -> [Application]
    func savedSearches() async throws -> [SavedSearch]
    func threads() async throws -> [MessageThread]
    func placements() async throws -> [Placement]
    func metrics() async throws -> ProgramMetrics
    func readiness() async throws -> [ReadinessSlice]
    func weeklyApplications() async throws -> [Int]
    func alerts() async throws -> [ReportAlert]

    func save(application: Application) async throws
    func save(internship: Internship) async throws
    func save(thread: MessageThread) async throws
    func save(search: SavedSearch) async throws
    func save(student: Student) async throws
}

struct LocalDataService: DataService {
    var latency: TimeInterval = 0.35

    private func delay() async throws {
        try? await Task.sleep(nanoseconds: UInt64(latency * 1_000_000_000))
    }

    private func delayed<T>(_ value: T) async throws -> T {
        try await delay()
        return value
    }

    func students() async throws -> [Student] { try await delayed(SampleData.students) }
    func internships() async throws -> [Internship] { try await delayed(SampleData.internships) }

    func applications(for studentID: UUID) async throws -> [Application] {
        try await delayed(SampleData.applications.filter { $0.studentID == studentID })
    }

    func savedSearches() async throws -> [SavedSearch] { try await delayed(SampleData.savedSearches) }
    func threads() async throws -> [MessageThread] { try await delayed(SampleData.threads) }
    func placements() async throws -> [Placement] { try await delayed(SampleData.placements) }
    func metrics() async throws -> ProgramMetrics { try await delayed(SampleData.metrics) }
    func readiness() async throws -> [ReadinessSlice] { try await delayed(SampleData.readiness) }
    func weeklyApplications() async throws -> [Int] { try await delayed(SampleData.weeklyApplications) }
    func alerts() async throws -> [ReportAlert] { try await delayed(SampleData.alerts) }

    func save(application: Application) async throws { try await delay() }
    func save(internship: Internship) async throws { try await delay() }
    func save(thread: MessageThread) async throws { try await delay() }
    func save(search: SavedSearch) async throws { try await delay() }
    func save(student: Student) async throws { try await delay() }
}

enum DataError: LocalizedError {
    case offline
    case notFound

    var errorDescription: String? {
        switch self {
        case .offline: return "You are offline. Connect to load fresh data."
        case .notFound: return "We could not find that record."
        }
    }
}
