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
        case blocked(String)
    }

    func submit(store: AppStore) -> Outcome {
        guard blocker(for: step) == nil else {
            return .blocked(blocker(for: step) ?? "Check this step.")
        }
        guard !isLastStep else { return .published(publish(store: store)) }
        step += 1
        return .advanced
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

    private func publish(store: AppStore) -> Internship {
        let now = Date()
        let role = Internship(
            title: title.trimmed,
            companyID: SampleData.orbitLabs.id,
            companyName: SampleData.orbitLabs.name,
            companyInitials: SampleData.orbitLabs.initials,
            location: location.trimmed,
            workMode: workMode,
            durationWeeks: durationWeeks,
            compensation: isPaid ? compensation.trimmed : "Unpaid · stipend on review",
            isPaid: isPaid,
            easyApply: easyApply,
            postedDate: now,
            closingDate: SampleData.days(28),
            description: summary.trimmed,
            responsibilities: responsibilities,
            requiredSkills: requiredSkills,
            preferredSkills: [],
            careerInterests: careerInterests.isEmpty ? [category.label] : careerInterests,
            applicants: 0,
            teamSize: 6,
            category: category)
        store.post(role)
        return role
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
