import Foundation

// Shared by Auth, AuthView, RootView, and the rest of the app.
enum UserRole: String, CaseIterable, Identifiable, Codable, Hashable {
    case student = "Student"
    case employer = "Employer"
    case programManager = "Program manager"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .student:
            return "graduationcap"
        case .employer:
            return "building.2"
        case .programManager:
            return "person.2"
        }
    }
}

