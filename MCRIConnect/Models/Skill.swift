import Foundation

enum SkillCategory: String, Codable, CaseIterable, Identifiable {
    case design
    case technology
    case data
    case business
    case communication
    case research

    var id: String { rawValue }

    var label: String {
        switch self {
        case .design: return "Design"
        case .technology: return "Technology"
        case .data: return "Data"
        case .business: return "Business"
        case .communication: return "Communication"
        case .research: return "Research"
        }
    }

    var symbol: String {
        switch self {
        case .design: return "paintbrush.pointed.fill"
        case .technology: return "chevron.left.forwardslash.chevron.right"
        case .data: return "chart.bar.fill"
        case .business: return "briefcase.fill"
        case .communication: return "bubble.left.fill"
        case .research: return "magnifyingglass"
        }
    }
}

struct Skill: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: SkillCategory

    init(id: UUID = UUID(), name: String, category: SkillCategory) {
        self.id = id
        self.name = name
        self.category = category
    }
}

enum Proficiency: Int, Codable, CaseIterable, Identifiable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }

    var dots: Int { rawValue }
}

/// A skill the student claims, plus the evidence that backs it. Employers see the
/// evidence line, which is why skill names alone never satisfy a profile check.
struct StudentSkill: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: SkillCategory
    var proficiency: Proficiency
    var evidence: String?

    init(id: UUID = UUID(), name: String, category: SkillCategory,
         proficiency: Proficiency, evidence: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.proficiency = proficiency
        self.evidence = evidence
    }
}

enum WorkMode: String, Codable, CaseIterable, Identifiable {
    case remote
    case hybrid
    case onSite

    var id: String { rawValue }

    var label: String {
        switch self {
        case .remote: return "Remote"
        case .hybrid: return "Hybrid"
        case .onSite: return "On-site"
        }
    }

    var symbol: String {
        switch self {
        case .remote: return "house.lodge.fill"
        case .hybrid: return "arrow.triangle.2.circlepath"
        case .onSite: return "building.2.fill"
        }
    }
}

enum Availability: String, Codable, CaseIterable, Identifiable {
    case juneWindow = "June – August 2026"
    case fullYear = "Full academic year"
    case immediate = "Available immediately"
    case undecided = "Not sure yet"

    var id: String { rawValue }
}
