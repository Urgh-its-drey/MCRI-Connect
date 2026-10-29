import Foundation

enum ApplicationStage: String, Codable, CaseIterable, Identifiable {
    case submitted
    case underReview
    case shortlisted
    case interviewScheduled
    case offered
    case declined

    var id: String { rawValue }

    var label: String {
        switch self {
        case .submitted: return "Submitted"
        case .underReview: return "Under review"
        case .shortlisted: return "Shortlisted"
        case .interviewScheduled: return "Interview scheduled"
        case .offered: return "Offered"
        case .declined: return "Declined"
        }
    }

    var symbol: String {
        switch self {
        case .submitted: return "checkmark.circle.fill"
        case .underReview: return "eye.fill"
        case .shortlisted: return "star.fill"
        case .interviewScheduled: return "calendar.fill"
        case .offered: return "hand.thumbsup.fill"
        case .declined: return "xmark.circle.fill"
        }
    }

    /// The four stages drawn on the tracker stepper.
    static let trackerStages: [ApplicationStage] = [.submitted, .underReview, .shortlisted, .offered]

    var trackerIndex: Int? { Self.trackerStages.firstIndex(of: self) }

    /// The columns the employer's pipeline board is built from.
    static let pipelineStages: [ApplicationStage] = [.submitted, .underReview, .shortlisted, .interviewScheduled, .offered]
}

struct TimelineEvent: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var detail: String?
    var date: Date
    var isDone: Bool

    init(id: UUID = UUID(), title: String, detail: String? = nil, date: Date, isDone: Bool = true) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
        self.isDone = isDone
    }
}

struct Application: Identifiable, Codable, Hashable {
    let id: UUID
    var internshipID: UUID
    var studentID: UUID
    var stage: ApplicationStage
    var submittedDate: Date
    var lastUpdateDate: Date
    var interviewDate: Date?
    var employerNote: String?
    var nextAction: String?
    var timeline: [TimelineEvent]

    init(id: UUID = UUID(), internshipID: UUID, studentID: UUID, stage: ApplicationStage,
         submittedDate: Date, lastUpdateDate: Date, interviewDate: Date? = nil,
         employerNote: String? = nil, nextAction: String? = nil, timeline: [TimelineEvent] = []) {
        self.id = id
        self.internshipID = internshipID
        self.studentID = studentID
        self.stage = stage
        self.submittedDate = submittedDate
        self.lastUpdateDate = lastUpdateDate
        self.interviewDate = interviewDate
        self.employerNote = employerNote
        self.nextAction = nextAction
        self.timeline = timeline
    }

    var isClosed: Bool { stage == .declined }

    var stageProgress: Double {
        guard let index = stage.trackerIndex else { return 0 }
        return Double(index) / Double(max(ApplicationStage.trackerStages.count - 1, 1))
    }
}
