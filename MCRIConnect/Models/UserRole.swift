import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case employer
    case programManager

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Student"
        case .employer: return "Employer"
        case .programManager: return "Program manager"
        }
    }

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
        case .employer: return "briefcase.fill"
        case .programManager: return "chart.bar.xaxis"
        }
    }

    var tabTitles: [String] {
        switch self {
        case .student: return ["Home", "Explore", "Applications", "Messages", "Profile"]
        case .employer: return ["Dashboard", "Internships", "Candidates", "Messages", "Company"]
        case .programManager: return ["Overview", "Students", "Placements", "Reports", "Settings"]
        }
    }

    var tabSymbols: [String] {
        switch self {
        case .student: return ["house.fill", "magnifyingglass", "briefcase.fill", "bubble.left.fill", "person.fill"]
        case .employer: return ["square.grid.2x2.fill", "briefcase.fill", "person.2.fill", "bubble.left.fill", "building.2.fill"]
        case .programManager: return ["chart.bar.fill", "person.2.fill", "arrow.triangle.branch", "doc.text.fill", "gearshape.fill"]
        }
    }
}

struct Session: Codable, Hashable {
    var role: UserRole
    var displayName: String
    var initials: String
    var isAuthenticated: Bool

    static let signedOut = Session(role: .student, displayName: "", initials: "", isAuthenticated: false)
}
