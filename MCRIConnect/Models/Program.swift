import Foundation

enum PlacementStage: String, Codable, CaseIterable, Identifiable {
    case preparing
    case applying
    case shortlisted
    case interviewing
    case placed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .preparing: return "Preparing"
        case .applying: return "Applying"
        case .shortlisted: return "Shortlisted"
        case .interviewing: return "Interviewing"
        case .placed: return "Placed"
        }
    }

    var symbol: String {
        switch self {
        case .preparing: return "hammer.fill"
        case .applying: return "paperplane.fill"
        case .shortlisted: return "star.fill"
        case .interviewing: return "video.fill"
        case .placed: return "checkmark.seal.fill"
        }
    }
}

struct Placement: Identifiable, Codable, Hashable {
    let id: UUID
    var studentID: UUID
    var studentName: String
    var initials: String
    var stage: PlacementStage
    var readiness: Int
    var topSkills: [String]
    var advisor: String
    var internshipTitle: String?

    init(id: UUID = UUID(), studentID: UUID, studentName: String, initials: String,
         stage: PlacementStage, readiness: Int, topSkills: [String], advisor: String,
         internshipTitle: String? = nil) {
        self.id = id
        self.studentID = studentID
        self.studentName = studentName
        self.initials = initials
        self.stage = stage
        self.readiness = readiness
        self.topSkills = topSkills
        self.advisor = advisor
        self.internshipTitle = internshipTitle
    }
}

struct ProgramMetrics: Hashable {
    var totalStudents: Int
    var readyForPlacement: Int
    var activeApplications: Int
    var successfulPlacements: Int
    var unmatchedStudents: Int
}

struct ReadinessSlice: Identifiable, Hashable {
    var band: ReadinessBand
    var count: Int
    var id: String { band.rawValue }
}

struct ReportAlert: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case noApplications
        case incompleteProfile
        case deadlineSoon
        case awaitingEmployer
        case missingDocumentation

        var id: String { rawValue }

        var label: String {
            switch self {
            case .noApplications: return "No applications"
            case .incompleteProfile: return "Incomplete profile"
            case .deadlineSoon: return "Deadline soon"
            case .awaitingEmployer: return "Awaiting employer"
            case .missingDocumentation: return "Missing paperwork"
            }
        }

        var symbol: String {
            switch self {
            case .noApplications: return "tray.fill"
            case .incompleteProfile: return "person.crop.circle.badge.questionmark"
            case .deadlineSoon: return "alarm.fill"
            case .awaitingEmployer: return "hourglass"
            case .missingDocumentation: return "doc.badge.ellipsis.fill"
            }
        }
    }

    let id: UUID
    var kind: Kind
    var title: String
    var detail: String
    var action: String
    var studentCount: Int

    init(id: UUID = UUID(), kind: Kind, title: String, detail: String, action: String, studentCount: Int = 1) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.action = action
        self.studentCount = studentCount
    }
}

/// A student as the employer sees them: profile plus the fit score and hiring status.
struct Candidate: Identifiable, Hashable {
    let id: UUID
    var internshipID: UUID
    var student: Student
    var match: Int
    var status: ApplicationStage
    var evidence: String
    var availableFrom: String

    init(id: UUID = UUID(), internshipID: UUID, student: Student, match: Int, status: ApplicationStage,
         evidence: String, availableFrom: String) {
        self.id = id
        self.internshipID = internshipID
        self.student = student
        self.match = match
        self.status = status
        self.evidence = evidence
        self.availableFrom = availableFrom
    }

    var name: String { student.fullName }
    var initials: String { student.initials }
    var topSkills: [String] { Array(student.skillNames.prefix(3)) }
    var profileStrength: Int { student.profileStrength }
    var isTopPick: Bool { match >= 90 }
}
