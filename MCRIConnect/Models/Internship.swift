import Foundation

/// Where a posted role is in its own life cycle. `open` is all students ever see.
enum RoleStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case paused
    case closed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .open: return "Open"
        case .paused: return "Paused"
        case .closed: return "Closed"
        }
    }

    var symbol: String {
        switch self {
        case .open: return "paperplane.fill"
        case .paused: return "pause.circle.fill"
        case .closed: return "checkmark.seal.fill"
        }
    }
}

/// A hiring company. Employers in this app are organisations, never individual people —
/// a role is posted against a company and one or more accounts manage it.
struct Company: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var logoPath: String?
    var tagline: String?
    var website: String?
    var location: String?
    var registrationNumber: String?
    var teamLabel: String
    var openRoles: Int
    var isVerified: Bool
    var hiredLastCycle: Int

    init(id: UUID = UUID(), name: String, initials: String, logoPath: String? = nil,
         tagline: String? = nil, website: String? = nil, location: String? = nil,
         registrationNumber: String? = nil, teamLabel: String,
         openRoles: Int, isVerified: Bool = false, hiredLastCycle: Int = 0) {
        self.id = id
        self.name = name
        self.initials = initials
        self.logoPath = logoPath
        self.tagline = tagline
        self.website = website
        self.location = location
        self.registrationNumber = registrationNumber
        self.teamLabel = teamLabel
        self.openRoles = openRoles
        self.isVerified = isVerified
        self.hiredLastCycle = hiredLastCycle
    }

    var verificationLabel: String { isVerified ? "Verified" : "Pending review" }
}

struct Internship: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var companyID: UUID
    var companyName: String
    var companyInitials: String
    var companyLogoPath: String?
    var companyIsVerified: Bool
    var location: String
    var workMode: WorkMode
    var durationWeeks: Int
    var compensation: String
    var isPaid: Bool
    var easyApply: Bool
    var status: RoleStatus
    var postedDate: Date
    var closingDate: Date
    var description: String
    var responsibilities: [String]
    var requiredSkills: [String]
    var preferredSkills: [String]
    var careerInterests: [String]
    var applicants: Int
    var teamSize: Int
    var category: SkillCategory

    init(id: UUID = UUID(), title: String, companyID: UUID, companyName: String,
         companyInitials: String, companyLogoPath: String? = nil, companyIsVerified: Bool = true,
         location: String, workMode: WorkMode, durationWeeks: Int,
         compensation: String, isPaid: Bool, easyApply: Bool, status: RoleStatus = .open,
         postedDate: Date, closingDate: Date,
         description: String, responsibilities: [String], requiredSkills: [String],
         preferredSkills: [String] = [], careerInterests: [String] = [], applicants: Int = 0,
         teamSize: Int = 0, category: SkillCategory) {
        self.id = id
        self.title = title
        self.companyID = companyID
        self.companyName = companyName
        self.companyInitials = companyInitials
        self.companyLogoPath = companyLogoPath
        self.companyIsVerified = companyIsVerified
        self.location = location
        self.workMode = workMode
        self.durationWeeks = durationWeeks
        self.compensation = compensation
        self.isPaid = isPaid
        self.easyApply = easyApply
        self.status = status
        self.postedDate = postedDate
        self.closingDate = closingDate
        self.description = description
        self.responsibilities = responsibilities
        self.requiredSkills = requiredSkills
        self.preferredSkills = preferredSkills
        self.careerInterests = careerInterests
        self.applicants = applicants
        self.teamSize = teamSize
        self.category = category
    }

    var allSkills: [String] { requiredSkills + preferredSkills }

    var deadlineLabel: String {
        closingDate.formatted(date: .abbreviated, time: .omitted)
    }

    var durationLabel: String { "\(durationWeeks) weeks" }

    var daysUntilDeadline: Int {
        let seconds = closingDate.timeIntervalSinceNow
        return Int(ceil(seconds / 86_400))
    }

    var isClosingSoon: Bool { daysUntilDeadline > 0 && daysUntilDeadline <= 5 }

    /// Past its closing date, or deliberately shut by the hiring company.
    var isClosed: Bool { status != .open || daysUntilDeadline <= 0 }
}

struct SavedSearch: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var filters: [String]
    var alertsEnabled: Bool

    init(id: UUID = UUID(), label: String, filters: [String], alertsEnabled: Bool = false) {
        self.id = id
        self.label = label
        self.filters = filters
        self.alertsEnabled = alertsEnabled
    }
}

enum InternshipSort: String, CaseIterable, Identifiable {
    case mostRelevant = "Most relevant"
    case newest = "Newest"
    case closingSoon = "Closing soon"

    var id: String { rawValue }
}
