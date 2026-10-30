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
    @Published var companyQuery = ""
    /// nil shows every company, true only verified, false only those awaiting review.
    @Published var verificationFilter: Bool?

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

    func message(_ placement: Placement, from senderName: String) {
        guard let student = student(placement) else { return }
        store.openThread(with: student, from: senderName)
    }

    /// Messaging straight from the cohort list or a student's own record.
    func message(_ student: Student, from senderName: String) {
        store.openThread(with: student, from: senderName)
    }

    // MARK: Employers

    /// Every company on the programme, verified first. RLS gives a manager the whole table.
    var companies: [Company] {
        store.companies.sorted {
            if $0.isVerified != $1.isVerified { return $0.isVerified }
            return $0.name < $1.name
        }
    }

    var pendingCompanies: [Company] { store.companies.filter { !$0.isVerified } }
    var verifiedCompanies: [Company] { store.companies.filter { $0.isVerified } }

    /// Roles currently open to students across every verified company.
    var liveRoles: [Internship] { store.publishedRoles }

    func setVerified(_ company: Company, verified: Bool) {
        store.setVerified(company, verified: verified)
    }

    func roles(of company: Company) -> [Internship] {
        store.internships.filter { $0.companyID == company.id }
    }

    func openRoles(of company: Company) -> [Internship] {
        roles(of: company).filter { !$0.isClosed }
    }

    /// The employers list, searched and sliced by verification state.
    var visibleCompanies: [Company] {
        let needle = companyQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return companies.filter { company in
            if let verificationFilter, company.isVerified != verificationFilter { return false }
            guard !needle.isEmpty else { return true }
            return company.name.lowercased().contains(needle)
                || (company.location ?? "").lowercased().contains(needle)
                || roles(of: company).contains { $0.title.lowercased().contains(needle) }
        }
    }

    var hasCompanyFilters: Bool { verificationFilter != nil || !companyQuery.isEmpty }

    func clearCompanyFilters() {
        verificationFilter = nil
        companyQuery = ""
    }

    /// Students placed at this company, matched through the role they were placed into.
    func placedStudents(of company: Company) -> [Placement] {
        let titles = Set(roles(of: company).map(\.title))
        return store.placements.filter { placement in
            placement.stage == .placed && titles.contains(placement.internshipTitle ?? "")
        }
    }

    /// The single number a manager needs on an employer row: how much of the company's
    /// pipeline is waiting on them.
    func awaitingReview(of company: Company) -> Int {
        let roleIDs = Set(roles(of: company).map(\.id))
        return store.applications.filter { roleIDs.contains($0.internshipID) && $0.stage == .submitted }.count
    }

    func applications(of company: Company) -> Int {
        let roleIDs = Set(roles(of: company).map(\.id))
        return store.applications.filter { roleIDs.contains($0.internshipID) }.count
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
