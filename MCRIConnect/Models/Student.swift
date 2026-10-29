import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var summary: String
    var outcome: String?
    var year: Int

    init(id: UUID = UUID(), title: String, summary: String, outcome: String? = nil, year: Int) {
        self.id = id
        self.title = title
        self.summary = summary
        self.outcome = outcome
        self.year = year
    }
}

struct Certificate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var issuer: String
    var year: Int

    init(id: UUID = UUID(), name: String, issuer: String, year: Int) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.year = year
    }
}

enum ReadinessBand: String, Codable, CaseIterable, Identifiable {
    case readyToApply
    case nearlyReady
    case needsSupport
    case notStarted

    var id: String { rawValue }

    var label: String {
        switch self {
        case .readyToApply: return "Ready to apply"
        case .nearlyReady: return "Nearly ready"
        case .needsSupport: return "Needs support"
        case .notStarted: return "Not started"
        }
    }

    static func band(for strength: Int) -> ReadinessBand {
        switch strength {
        case 80...100: return .readyToApply
        case 60..<80: return .nearlyReady
        case 30..<60: return .needsSupport
        default: return .notStarted
        }
    }
}

struct Student: Identifiable, Codable, Hashable {
    let id: UUID
    var fullName: String
    var initials: String
    var programme: String
    var year: String
    var city: String
    var workMode: WorkMode
    var availability: Availability
    var bio: String
    var skills: [StudentSkill]
    var interests: [String]
    var projects: [Project]
    var certificates: [Certificate]
    var cvFileName: String?
    var profileStrength: Int
    var advisor: String?

    init(id: UUID = UUID(), fullName: String, initials: String, programme: String, year: String,
         city: String, workMode: WorkMode, availability: Availability, bio: String,
         skills: [StudentSkill], interests: [String], projects: [Project] = [],
         certificates: [Certificate] = [], cvFileName: String? = nil,
         profileStrength: Int, advisor: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.initials = initials
        self.programme = programme
        self.year = year
        self.city = city
        self.workMode = workMode
        self.availability = availability
        self.bio = bio
        self.skills = skills
        self.interests = interests
        self.projects = projects
        self.certificates = certificates
        self.cvFileName = cvFileName
        self.profileStrength = profileStrength
        self.advisor = advisor
    }

    var firstName: String { fullName.split(separator: " ").first.map(String.init) ?? fullName }

    var skillNames: [String] { skills.map(\.name) }

    var readiness: ReadinessBand { ReadinessBand.band(for: profileStrength) }

    /// Sections still missing content, used by the profile-completion checklist.
    var missingSections: [String] {
        var missing: [String] = []
        if skills.count < 5 { missing.append("Add at least 5 evidenced skills") }
        if projects.isEmpty { missing.append("Add a project with a measured outcome") }
        if cvFileName == nil { missing.append("Upload your CV") }
        if interests.isEmpty { missing.append("Pick your career interests") }
        if availability == .undecided { missing.append("Confirm your availability") }
        return missing
    }
}
