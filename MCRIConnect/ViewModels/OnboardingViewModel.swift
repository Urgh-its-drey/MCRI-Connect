import Foundation
import Combine
import SwiftUI

/// Collects the five answers the match engine needs before it can explain a score.
/// Nothing is saved to the store until the final step, so leaving halfway is safe.
@MainActor
final class OnboardingViewModel: ObservableObject {
    static let steps = ["Programme", "Skills", "Interests", "How you work", "Review"]

    @Published var step = 0
    @Published var fullName = ""
    @Published var programme = ""
    @Published var city = ""
    @Published var year: StudyYear = .second
    @Published var chosenSkills: Set<String> = []
    @Published var chosenInterests: Set<String> = []
    @Published var workMode: WorkMode = .hybrid
    @Published var availability: Availability = .juneWindow
    @Published var cvUploaded = false

    enum StudyYear: String, CaseIterable, Identifiable {
        case first = "1st year"
        case second = "2nd year"
        case third = "3rd year"
        case honours = "Honours"

        var id: String { rawValue }
    }

    static let interestCatalogue = ["Product Design", "UX Research", "Front-end", "Mobile",
                             "Data Analysis", "Machine Learning", "Growth", "Public Health"]

    var interestCatalogue: [String] { Self.interestCatalogue }

    var canAdvance: Bool {
        switch step {
        case 0: return fullName.count >= 2 && programme.count >= 2 && city.count >= 2
        case 1: return chosenSkills.count >= 3
        case 2: return chosenInterests.count >= 1
        default: return true
        }
    }

    var isLastStep: Bool { step == Self.steps.count - 1 }

    var skillOptions: [Skill] { SampleData.skillCatalogue }

    var profileStrength: Int {
        var score = 22
        score += min(chosenSkills.count, 8) * 6
        score += min(chosenInterests.count, 4) * 4
        score += availability == .undecided ? 0 : 8
        score += cvUploaded ? 10 : 0
        return min(score, 100)
    }

    /// Scored against the roles that are live on the server right now, so the preview
    /// a student sees on the last step is the same list they land on after finishing.
    func previewMatches(in store: AppStore) -> [MatchedRole] {
        let student = draftStudent
        return store.publishedRoles
            .map { MatchedRole(internship: $0, result: MatchEngine.shared.result(for: student, on: $0)) }
            .sorted { $0.score > $1.score }
            .prefix(2)
            .map { $0 }
    }

    var draftStudent: Student {
        Student(fullName: fullName.isEmpty ? "New student" : fullName,
                initials: initials,
                programme: programme.isEmpty ? "Unassigned programme" : programme,
                year: year.rawValue,
                city: city.isEmpty ? "Not set" : city,
                workMode: workMode,
                availability: availability,
                bio: "Building a profile through MCRI onboarding.",
                skills: Array(chosenSkills).sorted().map { name in
                    StudentSkill(name: name,
                                 category: SampleData.skillCatalogue.first { $0.name == name }?.category ?? .business,
                                 proficiency: .intermediate,
                                 evidence: "Coursework")
                },
                interests: Array(chosenInterests).sorted(),
                cvFileName: cvUploaded ? "cv.pdf" : nil,
                profileStrength: profileStrength)
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "NS" : String(letters).uppercased()
    }

    func next() {
        guard canAdvance else { return }
        withAnimation(.easeOut(duration: 0.22)) { step = min(step + 1, Self.steps.count - 1) }
    }

    func back() {
        withAnimation(.easeOut(duration: 0.22)) { step = max(step - 1, 0) }
    }

    func toggleSkill(_ name: String) {
        if chosenSkills.contains(name) {
            chosenSkills.remove(name)
        } else {
            chosenSkills.insert(name)
        }
    }

    func toggleInterest(_ name: String) {
        if chosenInterests.contains(name) {
            chosenInterests.remove(name)
        } else {
            chosenInterests.insert(name)
        }
    }

    func finish(store: AppStore, auth: AuthService) {
        guard let index = store.students.firstIndex(where: { $0.id == store.currentStudentID }) else {
            auth.completeOnboarding()
            return
        }
        var student = store.students[index]
        student.fullName = draftStudent.fullName
        student.initials = draftStudent.initials
        student.programme = draftStudent.programme
        student.year = draftStudent.year
        student.city = draftStudent.city
        student.workMode = workMode
        student.availability = availability
        student.interests = draftStudent.interests
        student.skills = student.skills + draftStudent.skills.filter { new in
            !student.skillNames.contains(new.name)
        }
        student.cvFileName = student.cvFileName ?? draftStudent.cvFileName
        student.profileStrength = max(student.profileStrength, profileStrength)
        store.updateStudent(student)
        auth.completeOnboarding()
        store.toast = Toast.success("Profile ready", "Your matches are now explained by your own answers.")
    }
}
