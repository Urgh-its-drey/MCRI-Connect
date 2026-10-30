import Foundation
import Combine

/// Four steps, each one validated before it can be left, so a published role
/// always carries enough detail for the match engine to explain a score.
@MainActor
final class CreateInternshipViewModel: ObservableObject {
    static let stepNames = ["Role", "Work", "Terms", "Review"]

    @Published var step = 0
    @Published var title = ""
    @Published var location = ""
    @Published var workMode: WorkMode = .hybrid
    @Published var category: SkillCategory = .technology
    @Published var durationWeeks = 12
    @Published var compensation = "R15 000 / month"
    @Published var isPaid = true
    @Published var easyApply = true
    @Published var summary = ""
    @Published var responsibilitiesText = ""
    @Published var requiredSkills: [String] = []
    @Published var interestsText = ""

    /// When set, the same four steps edit a role the company already published.
    private let editing: Internship?

    var isEditing: Bool { editing != nil }

    convenience init() {
        self.init(editing: nil)
    }

    init(editing: Internship?) {
        self.editing = editing
        guard let role = editing else { return }
        title = role.title
        location = role.location
        workMode = role.workMode
        category = role.category
        durationWeeks = role.durationWeeks
        compensation = role.compensation
        isPaid = role.isPaid
        easyApply = role.easyApply
        summary = role.description
        responsibilitiesText = role.responsibilities.joined(separator: "\n")
        requiredSkills = role.requiredSkills
        interestsText = role.careerInterests.joined(separator: ", ")
    }

    var steps: [String] { Self.stepNames }

    var responsibilities: [String] {
        responsibilitiesText
            .split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var careerInterests: [String] {
        interestsText
            .split(whereSeparator: { $0 == "," || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var skillCandidates: [String] {
        SampleData.skillCatalogue.filter { $0.category == category }.map(\.name)
    }

    var progress: Int {
        var answered = 0
        if !title.isEmpty { answered += 1 }
        if !location.isEmpty { answered += 1 }
        if summary.count >= 40 { answered += 1 }
        if responsibilities.count >= 2 { answered += 1 }
        if requiredSkills.count >= 2 { answered += 1 }
        if !compensation.isEmpty { answered += 1 }
        return Int(Double(answered) / 6 * 100)
    }

    func toggle(_ skill: String) {
        if let index = requiredSkills.firstIndex(of: skill) {
            requiredSkills.remove(at: index)
        } else if requiredSkills.count < 6 {
            requiredSkills.append(skill)
        }
    }

    func contains(_ skill: String) -> Bool { requiredSkills.contains(skill) }

    enum Outcome {
        case advanced
        case published(Internship)
        case updated(Internship)
        case blocked(String)
    }

    func submit(store: AppStore) -> Outcome {
        guard blocker(for: step) == nil else {
            return .blocked(blocker(for: step) ?? "Check this step.")
        }
        guard !isLastStep else { return publish(store: store) }
        step += 1
        return .advanced
    }

    /// A new role's deadline, or the existing one when editing so a deadline does not move
    /// just because someone fixed a typo.
    var closingDate: Date {
        editing?.closingDate
            ?? Calendar.current.date(byAdding: .day, value: 28, to: Date())
            ?? Date()
    }

    var closesInDays: Int {
        max(0, Int(ceil(closingDate.timeIntervalSinceNow / 86_400)))
    }

    func back() {
        step = max(0, step - 1)
    }

    var isLastStep: Bool { step == Self.stepNames.count - 1 }

    private func validate(_ index: Int) -> Bool {
        switch index {
        case 0:
            return title.trimmed.count >= 4 && location.trimmed.count >= 2
        case 1:
            return summary.trimmed.count >= 40 && responsibilities.count >= 2 && requiredSkills.count >= 2
        case 2:
            return (4...26).contains(durationWeeks) && (isPaid ? !compensation.trimmed.isEmpty : true)
        default:
            return true
        }
    }

    func blocker(for index: Int) -> String? {
        guard !validate(index) else { return nil }
        switch index {
        case 0: return "Give the role a title of at least 4 characters and a location."
        case 1: return "Describe the role in 40+ characters, list 2 responsibilities and 2 required skills."
        case 2: return isPaid ? "Paid roles need a stipend figure students can plan around." : nil
        default: return nil
        }
    }

    private func publish(store: AppStore) -> Outcome {
        guard let company = store.currentCompany else {
            return .blocked("Add your company name on the Company tab before publishing a role.")
        }

        var role = editing ?? Internship(
            title: title.trimmed,
            companyID: company.id,
            companyName: company.name,
            companyInitials: company.initials,
            companyLogoPath: company.logoPath,
            companyIsVerified: company.isVerified,
            location: location.trimmed,
            workMode: workMode,
            durationWeeks: durationWeeks,
            compensation: compensation.trimmed,
            isPaid: isPaid,
            easyApply: easyApply,
            postedDate: Date(),
            closingDate: closingDate,
            description: summary.trimmed,
            responsibilities: responsibilities,
            requiredSkills: requiredSkills,
            careerInterests: careerInterests,
            teamSize: 6,
            category: category)

        role.title = title.trimmed
        role.location = location.trimmed
        role.workMode = workMode
        role.durationWeeks = durationWeeks
        role.compensation = isPaid ? compensation.trimmed : "Unpaid · stipend on review"
        role.isPaid = isPaid
        role.easyApply = easyApply
        role.description = summary.trimmed
        role.responsibilities = responsibilities
        role.requiredSkills = requiredSkills
        role.careerInterests = careerInterests.isEmpty ? [category.label] : careerInterests
        role.category = category

        // The company behind a posting is the account's own record, never form text.
        let stamped = role.stamped(from: company)
        if isEditing {
            store.update(stamped)
            return .updated(stamped)
        }
        store.post(stamped)
        return .published(stamped)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
