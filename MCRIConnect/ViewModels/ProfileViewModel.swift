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
        return store.publishedRoles.filter { MatchEngine.shared.score(for: student, on: $0) >= 70 }.count
    }

    func beginNameEdit() {
        nameDraft = student?.fullName ?? ""
        editName = true
    }

    func commitName() {
        guard var student, nameDraft.count >= 2 else { return }
        student.fullName = nameDraft
        student.initials = NameParts.initials(nameDraft)
        store.updateStudent(student)
        editName = false
        // The account row carries the name the header and the tab bar show, so it follows too.
        Task { await store.updateAccountName(nameDraft) }
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

    func uploadCV(_ data: Data, fileName: String) {
        store.uploadCV(data, named: fileName)
    }

    func setAvatarPhoto(_ data: Data, extent: String) {
        store.setAvatarPhoto(data, extent: extent)
    }

    func toggleInterest(_ interest: String) {
        guard let student else { return }
        var updated = student.interests
        if updated.contains(interest) {
            updated.removeAll { $0 == interest }
        } else {
            updated.append(interest)
        }
        store.setInterests(updated)
    }
}
