import Foundation
import Combine

/// Profile is the input side of the match engine: every edit here changes a score
/// somewhere, so the screen shows the consequence next to the control.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var editName = false
    @Published var nameDraft = ""
    @Published var bioDraft = ""
    @Published var showSkillPicker = false

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    var student: Student? { store.currentStudent }

    var strength: Int { store.currentStudent?.profileStrength ?? 0 }

    var readiness: ReadinessBand { store.currentStudent?.readiness ?? .notStarted }

    var missingSections: [String] { store.currentStudent?.missingSections ?? [] }

    var skills: [StudentSkill] { store.currentStudent?.skills ?? [] }

    var projects: [Project] { store.currentStudent?.projects ?? [] }

    var certificates: [Certificate] { store.currentStudent?.certificates ?? [] }

    var interests: [String] { store.currentStudent?.interests ?? [] }

    var matchedRolesLifted: Int {
        guard let student else { return 0 }
        return store.internships.filter { MatchEngine.shared.score(for: student, on: $0) >= 70 }.count
    }

    func beginNameEdit() {
        nameDraft = student?.fullName ?? ""
        editName = true
    }

    func commitName() {
        guard var student, nameDraft.count >= 2 else { return }
        student.fullName = nameDraft
        student.initials = String(nameDraft.split(separator: " ").prefix(2).compactMap { $0.first }).uppercased()
        store.updateStudent(student)
        editName = false
    }

    func commitBio() {
        guard var student, !bioDraft.isEmpty else { return }
        student.bio = bioDraft
        store.updateStudent(student)
        store.toast = Toast.success("Bio saved")
    }

    func remove(_ skill: StudentSkill) {
        store.removeSkill(skill)
    }

    func addSkill(_ name: String, category: SkillCategory, evidence: String) {
        store.addSkill(name, category: category, evidence: evidence)
    }

    func setAvailability(_ availability: Availability) {
        store.setAvailability(availability)
    }

    func setWorkMode(_ mode: WorkMode) {
        guard var student else { return }
        student.workMode = mode
        store.updateStudent(student)
        store.toast = Toast.success("Work mode set", mode.label)
    }

    func uploadCV() {
        guard let name = student?.fullName.split(separator: " ").first else { return }
        store.uploadCV(named: "\(name.lowercased())-cv.pdf")
    }

    func toggleInterest(_ interest: String) {
        guard var student else { return }
        if student.interests.contains(interest) {
            student.interests.removeAll { $0 == interest }
        } else {
            student.interests.append(interest)
        }
        store.updateStudent(student)
    }
}
