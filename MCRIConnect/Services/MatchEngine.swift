import Foundation

/// Scores a student against an internship on four independent axes so every
/// percentage on screen can be traced back to the profile it came from.
struct MatchEngine {
    static let shared = MatchEngine()

    struct Outcome {
        var breakdown: MatchBreakdown
        var signals: [MatchSignal]
        var gaps: [MatchGap]
        var matchedSkills: [String]
        var missingSkills: [String]
    }

    func evaluate(_ student: Student, on internship: Internship) -> Outcome {
        let owned = Set(student.skills.map { $0.name.lowercased() })
        let required = internship.requiredSkills
        let preferred = internship.preferredSkills

        let matched = required.filter { owned.contains($0.lowercased()) }
        let missing = required.filter { !owned.contains($0.lowercased()) }
        let preferredHits = preferred.filter { owned.contains($0.lowercased()) }

        var skills: Int
        if required.isEmpty {
            skills = 70
        } else {
            let coverage = Double(matched.count) / Double(required.count)
            let bonus = preferred.isEmpty ? 0 : Double(preferredHits.count) / Double(preferred.count) * 0.15
            skills = Int(min(1.0, coverage + bonus) * 100)
        }

        let interestHits = internship.careerInterests.filter { need in
            student.interests.contains { $0.caseInsensitiveCompare(need) == .orderedSame }
        }
        let interests: Int
        if internship.careerInterests.isEmpty {
            interests = 70
        } else {
            interests = Int(Double(interestHits.count) / Double(internship.careerInterests.count) * 100)
        }

        var logistics = 50
        if student.workMode == internship.workMode {
            logistics += 25
        } else if internship.workMode == .remote || student.workMode == .remote {
            logistics += 15
        }
        if internship.isPaid { logistics += 12 }
        if internship.daysUntilDeadline > 4 { logistics += 8 }
        if student.availability != .undecided { logistics += 5 }
        logistics = min(logistics, 100)

        let breakdown = MatchBreakdown(skills: skills, interests: interests,
                                       logistics: logistics, profile: student.profileStrength)

        var signals: [MatchSignal] = []
        if !matched.isEmpty {
            signals.append(MatchSignal(title: "\(matched.count) skills match this role",
                                       detail: matched.joined(separator: " · "),
                                       symbol: "checkmark.seal.fill"))
        }
        if let project = student.projects.first(where: { project in
            internship.allSkills.contains { skill in project.summary.localizedCaseInsensitiveContains(skill) }
        }) ?? student.projects.first {
            signals.append(MatchSignal(title: project.title + " is relevant",
                                       detail: project.outcome ?? project.summary,
                                       symbol: "hammer.fill"))
        }
        if !interestHits.isEmpty {
            signals.append(MatchSignal(title: "Matches your career interests",
                                       detail: interestHits.joined(separator: " · "),
                                       symbol: "target"))
        }
        if student.workMode == internship.workMode {
            signals.append(MatchSignal(title: "\(internship.workMode.label) work matches you",
                                       detail: "You prefer \(internship.workMode.label.lowercased()) placements",
                                       symbol: internship.workMode.symbol))
        }
        if internship.daysUntilDeadline > 4 {
            signals.append(MatchSignal(title: "Timeline works",
                                       detail: "Available before the \(internship.deadlineLabel) deadline",
                                       symbol: "calendar"))
        }

        var gaps: [MatchGap] = []
        if let hole = missing.first {
            gaps.append(MatchGap(action: "Add \(hole) to your skills with one example", lift: 6))
        }
        if student.projects.isEmpty {
            gaps.append(MatchGap(action: "Add one case study to your portfolio", lift: 7))
        }
        if student.cvFileName == nil {
            gaps.append(MatchGap(action: "Upload your CV so employers can open it", lift: 4))
        }
        if student.profileStrength < 80 {
            gaps.append(MatchGap(action: "Finish your profile to lift every match", lift: 5))
        }

        return Outcome(breakdown: breakdown, signals: signals, gaps: gaps,
                       matchedSkills: matched, missingSkills: missing)
    }

    func result(for student: Student, on internship: Internship) -> MatchResult {
        let outcome = evaluate(student, on: internship)
        return MatchResult(breakdown: outcome.breakdown,
                           signals: outcome.signals,
                           gaps: outcome.gaps,
                           percentile: percentile(for: outcome.breakdown.overall),
                           matchedSkills: outcome.matchedSkills,
                           missingSkills: outcome.missingSkills)
    }

    func score(for student: Student, on internship: Internship) -> Int {
        evaluate(student, on: internship).breakdown.overall
    }

    func percentile(for score: Int) -> Int {
        switch score {
        case 90...100: return 6
        case 85..<90: return 11
        case 80..<85: return 18
        case 70..<80: return 31
        default: return 54
        }
    }
}
