import Foundation
import Combine
import SwiftUI

/// The programme roll-up: cohort readiness, where students are stuck, and the
/// advisor load behind each number.
@MainActor
final class ManagerViewModel: ObservableObject {
    struct AdvisorLoad: Identifiable {
        var advisor: String
        var students: Int
        var placed: Int
        var atRisk: Int
        var id: String { advisor }
    }

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    @Published var query = ""
    @Published var stageFilter: PlacementStage?
    @Published var bandFilter: ReadinessBand?
    @Published var advisorFilter: String?

    // MARK: Cohort reads

    var metrics: ProgramMetrics { store.metrics }

    var placements: [Placement] { store.placements }

    var alerts: [ReportAlert] { store.alerts }

    var weeklyApplications: [Int] { store.weeklyApplications }

    var cohortTotal: Int { store.readiness.reduce(0) { $0 + $1.count } }

    var readyShare: Int {
        guard metrics.totalStudents > 0 else { return 0 }
        return Int(Double(metrics.readyForPlacement) / Double(metrics.totalStudents) * 100)
    }

    var placementRate: Int {
        guard metrics.totalStudents > 0 else { return 0 }
        return Int(Double(metrics.successfulPlacements) / Double(metrics.totalStudents) * 100)
    }

    var readinessBars: [MCRIHorizontalBars.Entry] {
        store.readiness.map { slice in
            MCRIHorizontalBars.Entry(label: slice.band.label, value: slice.count,
                                     color: Self.color(for: slice.band))
        }
    }

    var funnel: [MCRIFunnel.Segment] {
        PlacementStage.allCases.map { stage in
            MCRIFunnel.Segment(label: stage.label, value: store.placements(in: stage).count,
                               color: stage.tone.label)
        }
    }

    var activeCaseload: [Placement] {
        placements.filter { $0.stage != .placed }.sorted { $0.readiness < $1.readiness }
    }

    var atRisk: [Placement] { placements.filter { $0.readiness < 60 } }

    var placedCount: Int { store.placements(in: .placed).count }

    var advisors: [String] {
        Array(Set(placements.map(\.advisor))).sorted()
    }

    var advisorLoads: [AdvisorLoad] {
        advisors.map { advisor in
            let owned = placements.filter { $0.advisor == advisor }
            return AdvisorLoad(advisor: advisor,
                               students: owned.count,
                               placed: owned.filter { $0.stage == .placed }.count,
                               atRisk: owned.filter { $0.readiness < 60 }.count)
        }
        .sorted { $0.atRisk > $1.atRisk }
    }

    // MARK: Filtering

    var visiblePlacements: [Placement] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return placements.filter { placement in
            if let stageFilter, placement.stage != stageFilter { return false }
            if let bandFilter, ReadinessBand.band(for: placement.readiness) != bandFilter { return false }
            if let advisorFilter, placement.advisor != advisorFilter { return false }
            guard !needle.isEmpty else { return true }
            return placement.studentName.lowercased().contains(needle)
                || placement.topSkills.contains { $0.lowercased().contains(needle) }
                || placement.advisor.lowercased().contains(needle)
        }
        .sorted { $0.readiness > $1.readiness }
    }

    var visibleStudents: [Student] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.students.filter { student in
            if let bandFilter, student.readiness != bandFilter { return false }
            if let advisorFilter, student.advisor != advisorFilter { return false }
            guard !needle.isEmpty else { return true }
            return student.fullName.lowercased().contains(needle)
                || student.programme.lowercased().contains(needle)
                || student.skillNames.contains { $0.lowercased().contains(needle) }
        }
        .sorted { $0.profileStrength > $1.profileStrength }
    }

    var hasFilters: Bool {
        stageFilter != nil || bandFilter != nil || advisorFilter != nil || !query.isEmpty
    }

    func clearFilters() {
        stageFilter = nil
        bandFilter = nil
        advisorFilter = nil
        query = ""
    }

    func student(_ placement: Placement) -> Student? {
        store.student(for: placement.studentID)
    }

    // MARK: Actions

    func move(_ placement: Placement, to stage: PlacementStage) {
        store.move(placement, to: stage)
    }

    func advance(_ placement: Placement) {
        guard let next = stageAfter(placement.stage) else { return }
        store.move(placement, to: next)
    }

    func message(_ placement: Placement, from senderName: String) -> UUID {
        guard let student = student(placement) else { return UUID() }
        return store.openThread(with: student, from: senderName).id
    }

    func nudge(_ alert: ReportAlert) {
        store.nudge(alert)
    }

    func stageAfter(_ stage: PlacementStage) -> PlacementStage? {
        switch stage {
        case .preparing: return .applying
        case .applying: return .shortlisted
        case .shortlisted: return .interviewing
        case .interviewing: return .placed
        case .placed: return nil
        }
    }

    static func color(for band: ReadinessBand) -> Color {
        switch band {
        case .readyToApply: return MCRITheme.secondaryAction
        case .nearlyReady: return MCRITheme.secondaryAction.opacity(0.55)
        case .needsSupport: return MCRITheme.primaryAction
        case .notStarted: return MCRITheme.placeholder
        }
    }

    /// The gap that explains a student's band in one line, straight from their profile.
    func gapSummary(for student: Student) -> String {
        let missing = student.missingSections
        guard !missing.isEmpty else { return "Profile complete — nothing blocks matching" }
        return missing.first ?? ""
    }
}
