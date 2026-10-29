import Foundation

struct Company: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var initials: String
    var teamLabel: String
    var openRoles: Int
    var isVerified: Bool
    var hiredLastCycle: Int

    init(id: UUID = UUID(), name: String, initials: String, teamLabel: String,
         openRoles: Int, isVerified: Bool = true, hiredLastCycle: Int = 0) {
        self.id = id
        self.name = name
        self.initials = initials
        self.teamLabel = teamLabel
        self.openRoles = openRoles
        self.isVerified = isVerified
        self.hiredLastCycle = hiredLastCycle
    }
}

struct Internship: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var companyID: UUID
    var companyName: String
    var companyInitials: String
    var location: String
    var workMode: WorkMode
    var durationWeeks: Int
    var compensation: String
    var isPaid: Bool
    var easyApply: Bool
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
         companyInitials: String, location: String, workMode: WorkMode, durationWeeks: Int,
         compensation: String, isPaid: Bool, easyApply: Bool, postedDate: Date, closingDate: Date,
         description: String, responsibilities: [String], requiredSkills: [String],
         preferredSkills: [String] = [], careerInterests: [String] = [], applicants: Int = 0,
         teamSize: Int = 0, category: SkillCategory) {
        self.id = id
        self.title = title
        self.companyID = companyID
        self.companyName = companyName
        self.companyInitials = companyInitials
        self.location = location
        self.workMode = workMode
        self.durationWeeks = durationWeeks
        self.compensation = compensation
        self.isPaid = isPaid
        self.easyApply = easyApply
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
