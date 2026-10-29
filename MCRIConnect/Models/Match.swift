import Foundation

/// The four axes a fit score is built from. Keeping them separate is what lets the
/// app explain a score instead of asserting it.
struct MatchComponent: Identifiable, Hashable {
    let name: String
    let score: Int

    var id: String { name }
}

struct MatchBreakdown: Codable, Hashable {
    var skills: Int
    var interests: Int
    var logistics: Int
    var profile: Int

    var overall: Int {
        let weighted = Double(skills) * 0.40 + Double(interests) * 0.20
            + Double(logistics) * 0.25 + Double(profile) * 0.15
        return Int(weighted.rounded())
    }

    var components: [MatchComponent] {
        [MatchComponent(name: "Skills", score: skills),
         MatchComponent(name: "Interests", score: interests),
         MatchComponent(name: "Logistics", score: logistics),
         MatchComponent(name: "Profile", score: profile)]
    }

    var weakest: MatchComponent {
        components.min { $0.score < $1.score } ?? MatchComponent(name: "Profile", score: profile)
    }
}

struct MatchSignal: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var symbol: String
}

struct MatchGap: Identifiable, Hashable {
    let id = UUID()
    var action: String
    var lift: Int
}

struct MatchResult: Hashable {
    var breakdown: MatchBreakdown
    var signals: [MatchSignal]
    var gaps: [MatchGap]
    var percentile: Int
    var matchedSkills: [String]
    var missingSkills: [String]

    var score: Int { breakdown.overall }
}

/// An open role paired with the score the current student earned on it.
struct MatchedRole: Identifiable, Hashable {
    let internship: Internship
    let result: MatchResult

    var id: UUID { internship.id }
    var score: Int { result.score }
}
