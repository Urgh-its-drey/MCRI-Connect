import Foundation

// Row shapes for the views the schema exposes, and column shapes for writes. Both spell
// keys the way Postgres does, because the PostgREST coder does not convert between cases.

// Older read views return null initials for a single-word name. Treat the monogram as
// optional presentation data so it cannot prevent an otherwise valid workspace loading.
private func resolvedInitials(_ value: String?, name: String) -> String {
    guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return NameParts.initials(name)
    }
    return value
}

// MARK: - Identity

struct ProfileDTO: Decodable {
    let id: String
    let role: String
    let full_name: String
    let email: String?
    let company_id: String?
    let avatar_path: String?
    let status: String

    var domain: ProfileRecord {
        ProfileRecord(id: UUID(uuidString: id) ?? UUID(),
                      role: UserRole(rawValue: role) ?? .student,
                      fullName: full_name,
                      email: email,
                      companyID: company_id.flatMap(UUID.init),
                      avatarPath: avatar_path,
                      status: status)
    }
}

// MARK: - Students

struct StudentRecordDTO: Decodable {
    let id: String
    let full_name: String
    let initials: String?
    let programme: String
    let year: String
    let city: String
    let work_mode: String
    let availability: String
    let bio: String
    let profile_strength: Int
    let advisor: String?
    let cv_name: String?
    let avatar_path: String?
    let skills: [SkillDTO]
    let interests: [String]
    let projects: [ProjectDTO]
    let certificates: [CertificateDTO]

    var domain: Student {
        Student(id: UUID(uuidString: id) ?? UUID(),
                fullName: full_name,
                initials: resolvedInitials(initials, name: full_name),
                programme: programme,
                year: year,
                city: city,
                workMode: WorkMode(rawValue: work_mode) ?? .hybrid,
                availability: Availability(rawValue: availability) ?? .undecided,
                bio: bio,
                skills: skills.map(\.domain),
                interests: interests,
                projects: projects.map(\.domain),
                certificates: certificates.map(\.domain),
                cvFileName: cv_name,
                profileStrength: profile_strength,
                advisor: advisor,
                avatarPath: avatar_path)
    }
}

struct SkillDTO: Decodable {
    let id: String
    let name: String
    let category: String
    let proficiency: Int
    let evidence: String?

    var domain: StudentSkill {
        StudentSkill(id: UUID(uuidString: id) ?? UUID(),
                     name: name,
                     category: SkillCategory(rawValue: category) ?? .technology,
                     proficiency: Proficiency(rawValue: proficiency) ?? .intermediate,
                     evidence: evidence)
    }
}

struct ProjectDTO: Decodable {
    let id: String
    let title: String
    let summary: String
    let outcome: String?
    let year: Int

    var domain: Project {
        Project(id: UUID(uuidString: id) ?? UUID(), title: title, summary: summary,
                outcome: outcome, year: year)
    }
}

struct CertificateDTO: Decodable {
    let id: String
    let name: String
    let issuer: String
    let year: Int

    var domain: Certificate {
        Certificate(id: UUID(uuidString: id) ?? UUID(), name: name, issuer: issuer, year: year)
    }
}

// MARK: - Companies and roles

struct CompanyRecordDTO: Decodable {
    let id: String
    let name: String
    let initials: String
    let logo_path: String?
    let tagline: String?
    let website: String?
    let location: String?
    let registration_number: String?
    let team_label: String?
    let is_verified: Bool
    let hired_last_cycle: Int
    let open_roles: Int

    var domain: Company {
        Company(id: UUID(uuidString: id) ?? UUID(),
                name: name,
                initials: initials,
                logoPath: logo_path,
                tagline: tagline,
                website: website,
                location: location,
                registrationNumber: registration_number,
                teamLabel: team_label ?? "\(open_roles) open roles",
                openRoles: open_roles,
                isVerified: is_verified,
                hiredLastCycle: hired_last_cycle)
    }
}

struct RoleRecordDTO: Decodable {
    let id: String
    let company_id: String
    let title: String
    let location: String
    let work_mode: String
    let duration_weeks: Int
    let compensation: String
    let is_paid: Bool
    let easy_apply: Bool
    let status: String
    let description: String
    let responsibilities: [String]
    let required_skills: [String]
    let preferred_skills: [String]
    let career_interests: [String]
    let category: String
    let team_size: Int
    let posted_date: Date
    let closing_date: Date
    let company_name: String
    let company_initials: String
    let company_logo_path: String?
    let company_is_verified: Bool
    let applicants: Int

    var domain: Internship {
        Internship(id: UUID(uuidString: id) ?? UUID(),
                   title: title,
                   companyID: UUID(uuidString: company_id) ?? UUID(),
                   companyName: company_name,
                   companyInitials: company_initials,
                   companyLogoPath: company_logo_path,
                   companyIsVerified: company_is_verified,
                   location: location,
                   workMode: WorkMode(rawValue: work_mode) ?? .hybrid,
                   durationWeeks: duration_weeks,
                   compensation: compensation,
                   isPaid: is_paid,
                   easyApply: easy_apply,
                   status: RoleStatus(rawValue: status) ?? .open,
                   postedDate: posted_date,
                   closingDate: closing_date,
                   description: description,
                   responsibilities: responsibilities,
                   requiredSkills: required_skills,
                   preferredSkills: preferred_skills,
                   careerInterests: career_interests,
                   applicants: applicants,
                   teamSize: team_size,
                   category: SkillCategory(rawValue: category) ?? .technology)
    }
}

// MARK: - Applications

struct ApplicationRecordDTO: Decodable {
    let id: String
    let internship_id: String
    let student_id: String
    let stage: String
    let submitted_date: Date
    let last_update_date: Date
    let interview_date: Date?
    let employer_note: String?
    let next_action: String?
    let timeline: [TimelineEvent]

    var domain: Application {
        Application(id: UUID(uuidString: id) ?? UUID(),
                    internshipID: UUID(uuidString: internship_id) ?? UUID(),
                    studentID: UUID(uuidString: student_id) ?? UUID(),
                    stage: ApplicationStage(rawValue: stage) ?? .submitted,
                    submittedDate: submitted_date,
                    lastUpdateDate: last_update_date,
                    interviewDate: interview_date,
                    employerNote: employer_note,
                    nextAction: next_action,
                    timeline: timeline.sorted { $0.date < $1.date })
    }
}

struct CandidateRecordDTO: Decodable {
    let application_id: String
    let internship_id: String
    let student_id: String
    let stage: String
    let full_name: String
    let initials: String?
    let avatar_path: String?
    let programme: String
    let year: String
    let city: String
    let work_mode: String
    let availability: String
    let bio: String
    let profile_strength: Int
    let advisor: String?
    let cv_name: String?
    let interests: [String]
    let skills: [SkillDTO]

    /// The candidate row carries the student inline; `id` is the student's own account id.
    func student(id: UUID) -> Student {
        Student(id: id,
                fullName: full_name,
                initials: resolvedInitials(initials, name: full_name),
                programme: programme,
                year: year,
                city: city,
                workMode: WorkMode(rawValue: work_mode) ?? .hybrid,
                availability: Availability(rawValue: availability) ?? .undecided,
                bio: bio,
                skills: skills.map(\.domain),
                interests: interests,
                cvFileName: cv_name,
                profileStrength: profile_strength,
                advisor: advisor,
                avatarPath: avatar_path)
    }
}

// MARK: - Placements, searches, conversations

struct PlacementRecordDTO: Decodable {
    let id: String
    let student_id: String
    let student_name: String
    let initials: String?
    let avatar_path: String?
    let stage: String
    let readiness: Int
    let top_skills: [String]
    let advisor: String?
    let internship_title: String?

    var domain: Placement {
        Placement(id: UUID(uuidString: id) ?? UUID(),
                  studentID: UUID(uuidString: student_id) ?? UUID(),
                  studentName: student_name,
                  initials: resolvedInitials(initials, name: student_name),
                  avatarPath: avatar_path,
                  stage: PlacementStage(rawValue: stage) ?? .preparing,
                  readiness: readiness,
                  topSkills: top_skills,
                  advisor: advisor ?? "Unassigned",
                  internshipTitle: internship_title)
    }
}

struct SavedSearchDTO: Decodable {
    let id: String
    let label: String
    let filters: [String]
    let alerts_enabled: Bool

    var domain: SavedSearch {
        SavedSearch(id: UUID(uuidString: id) ?? UUID(), label: label, filters: filters,
                    alertsEnabled: alerts_enabled)
    }
}

struct SavedRoleDTO: Decodable {
    let internship_id: String
}

struct ConversationRecordDTO: Decodable {
    let id: String
    let subject: String
    let context: String
    let unread: Int
    let participant_id: String?
    let participant_name: String
    let participant_initials: String?
    let participant_avatar_path: String?
    let messages: [Message]

    var domain: MessageThread {
        MessageThread(id: UUID(uuidString: id) ?? UUID(),
                      participantID: participant_id.flatMap(UUID.init),
                      participantName: participant_name,
                      participantInitials: resolvedInitials(participant_initials, name: participant_name),
                      participantAvatarPath: participant_avatar_path,
                      context: context.isEmpty ? subject : context,
                      messages: messages,
                      unread: unread)
    }
}

struct IDDTO: Decodable {
    let id: String
}

// MARK: - Write payloads

struct StudentColumn: Encodable {
    let id: String
    let programme: String
    let year: String
    let city: String
    let work_mode: String
    let availability: String
    let bio: String
    let profile_strength: Int
    let advisor: String?
    let cv_name: String?

    init(student: Student) {
        id = student.id.uuidString
        programme = student.programme
        year = student.year
        city = student.city
        work_mode = student.workMode.rawValue
        availability = student.availability.rawValue
        bio = student.bio
        profile_strength = student.profileStrength
        advisor = student.advisor
        cv_name = student.cvFileName
    }
}

struct SkillColumn: Encodable {
    let student_id: String
    let name: String
    let category: String
    let proficiency: Int
    let evidence: String?

    init(skill: StudentSkill, studentID: UUID) {
        student_id = studentID.uuidString
        name = skill.name
        category = skill.category.rawValue
        proficiency = skill.proficiency.rawValue
        evidence = skill.evidence
    }
}

struct ProjectColumn: Encodable {
    let student_id: String
    let title: String
    let summary: String
    let outcome: String?
    let year: Int

    init(project: Project, studentID: UUID) {
        student_id = studentID.uuidString
        title = project.title
        summary = project.summary
        outcome = project.outcome
        year = project.year
    }
}

struct InterestColumn: Encodable {
    let student_id: String
    let interest: String

    init(studentID: UUID, interest: String) {
        student_id = studentID.uuidString
        self.interest = interest
    }
}

struct SavedSearchColumn: Encodable {
    let id: String
    let student_id: String
    let label: String
    let filters: [String]
    let alerts_enabled: Bool

    init(search: SavedSearch, studentID: UUID) {
        id = search.id.uuidString
        student_id = studentID.uuidString
        label = search.label
        filters = search.filters
        alerts_enabled = search.alertsEnabled
    }
}

struct ApplicationColumn: Encodable {
    let internship_id: String
    let student_id: String
    let stage: String
    let submitted_date: Date
    let last_update_date: Date
    let next_action: String?

    init(application: Application) {
        internship_id = application.internshipID.uuidString
        student_id = application.studentID.uuidString
        stage = application.stage.rawValue
        submitted_date = application.submittedDate
        last_update_date = application.lastUpdateDate
        next_action = application.nextAction
    }
}

struct EventColumn: Encodable {
    let application_id: String
    let title: String
    let detail: String?
    let is_done: Bool

    init(applicationID: UUID, event: TimelineEvent) {
        application_id = applicationID.uuidString
        title = event.title
        detail = event.detail
        is_done = event.isDone
    }
}

struct SavedRoleColumn: Encodable {
    let student_id: String
    let internship_id: String

    init(studentID: UUID, internshipID: UUID) {
        student_id = studentID.uuidString
        internship_id = internshipID.uuidString
    }
}

struct InternshipColumn: Encodable {
    let id: String
    let company_id: String
    let title: String
    let location: String
    let work_mode: String
    let duration_weeks: Int
    let compensation: String
    let is_paid: Bool
    let easy_apply: Bool
    let status: String
    let description: String
    let responsibilities: [String]
    let required_skills: [String]
    let preferred_skills: [String]
    let career_interests: [String]
    let category: String
    let team_size: Int
    let posted_date: Date
    let closing_date: Date

    init(internship: Internship, companyID: UUID) {
        id = internship.id.uuidString
        company_id = companyID.uuidString
        title = internship.title
        location = internship.location
        work_mode = internship.workMode.rawValue
        duration_weeks = internship.durationWeeks
        compensation = internship.compensation
        is_paid = internship.isPaid
        easy_apply = internship.easyApply
        status = internship.status.rawValue
        description = internship.description
        responsibilities = internship.responsibilities
        required_skills = internship.requiredSkills
        preferred_skills = internship.preferredSkills
        career_interests = internship.careerInterests
        category = internship.category.rawValue
        team_size = internship.teamSize
        posted_date = internship.postedDate
        closing_date = internship.closingDate
    }
}

struct CompanyColumn: Encodable {
    let id: String
    let name: String
    let initials: String
    let logo_path: String?
    let tagline: String?
    let website: String?
    let location: String?
    let registration_number: String?
    let team_label: String?

    init(company: Company) {
        id = company.id.uuidString
        name = company.name
        initials = company.initials
        logo_path = company.logoPath
        tagline = company.tagline
        website = company.website
        location = company.location
        registration_number = company.registrationNumber
        team_label = company.teamLabel
    }
}

struct PlacementColumn: Encodable {
    let student_id: String
    let stage: String
    let readiness: Int
    let advisor: String?

    init(placement: Placement) {
        student_id = placement.studentID.uuidString
        stage = placement.stage.rawValue
        readiness = placement.readiness
        advisor = placement.advisor
    }
}

struct MessageColumn: Encodable {
    let thread_id: String
    let sender_id: String
    let body: String
    let sent_at: Date

    init(message: Message, senderID: UUID) {
        thread_id = message.threadID.uuidString
        sender_id = senderID.uuidString
        body = message.body
        sent_at = message.sentAt
    }
}
