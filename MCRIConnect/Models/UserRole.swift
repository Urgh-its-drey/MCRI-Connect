import Foundation

/// The three workspaces. Raw values are the `public.user_role` labels in Supabase, so a
/// role read from the database decodes straight into this without a mapping table.
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case employer
    case programManager = "program_manager"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Student"
        case .employer: return "Employer"
        case .programManager: return "Program manager"
        }
    }

    /// The label shown wherever a person picks or sees their own role.
    var welcomeTitle: String {
        switch self {
        case .student: return "Student"
        case .employer: return "Employer"
        case .programManager: return "Manager"
        }
    }

    var glyph: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .employer: return "building.2.fill"
        case .programManager: return "chart.bar.xaxis"
        }
    }

    var blurb: String {
        switch self {
        case .student: return "Find and apply to internships"
        case .employer: return "Hire from the cohort as a company"
        case .programManager: return "Run placements across the programme"
        }
    }

    /// Only students self-onboard into a profile. Employers create a company, managers
    /// arrive from an institution domain.
    var requiresOnboarding: Bool { self == .student }

    var tabTitles: [String] {
        switch self {
        case .student: return ["Home", "Explore", "Applications", "Messages", "Profile"]
        case .employer: return ["Dashboard", "Roles", "Candidates", "Messages", "Company"]
        case .programManager: return ["Overview", "Students", "Employers", "Placements", "Reports"]
        }
    }

    var tabSymbols: [String] {
        switch self {
        case .student: return ["house.fill", "magnifyingglass", "briefcase.fill", "bubble.left.fill", "person.fill"]
        case .employer: return ["square.grid.2x2.fill", "briefcase.fill", "person.2.fill", "bubble.left.fill", "building.2.fill"]
        case .programManager: return ["chart.bar.fill", "person.2.fill", "building.2.fill", "arrow.triangle.branch", "doc.text.fill"]
        }
    }
}

/// The signed-in person, as the server described them. `id` is the auth uid, which is also
/// `students.id` / `profiles.id`, so every record the app owns is keyed off it.
struct Session: Codable, Hashable {
    var id: UUID?
    var role: UserRole
    var displayName: String
    var initials: String
    var email: String?
    var companyID: UUID?
    var avatarPath: String?
    var isAuthenticated: Bool

    static let signedOut = Session(id: nil, role: .student, displayName: "", initials: "",
                                   email: nil, companyID: nil, avatarPath: nil,
                                   isAuthenticated: false)
}
