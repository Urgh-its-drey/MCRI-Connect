import Foundation
import Combine

/// Keeps every filter decision in one place so a saved search can replay them and
/// the result list stays a pure function of the current state.
@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var query = ""
    @Published var workModes: Set<WorkMode> = []
    @Published var categories: Set<SkillCategory> = []
    @Published var paidOnly = false
    @Published var easyApplyOnly = false
    @Published var sort: InternshipSort = .mostRelevant
    @Published var filtersOpen = false

    private let store: AppStore

    convenience init() {
        self.init(store: AppStore.shared)
    }

    init(store: AppStore) {
        self.store = store
    }

    var activeFilterCount: Int {
        workModes.count + categories.count + (paidOnly ? 1 : 0) + (easyApplyOnly ? 1 : 0)
    }

    var hasFilters: Bool { activeFilterCount > 0 || !query.isEmpty }

    var results: [MatchedRole] {
        guard let student = store.currentStudent else { return [] }

        let scored = store.publishedRoles.compactMap { role -> MatchedRole? in
            guard matches(role) else { return nil }
            return MatchedRole(internship: role, result: MatchEngine.shared.result(for: student, on: role))
        }

        switch sort {
        case .mostRelevant: return scored.sorted { $0.score > $1.score }
        case .newest: return scored.sorted { $0.internship.postedDate > $1.internship.postedDate }
        case .closingSoon: return scored.sorted { $0.internship.closingDate < $1.internship.closingDate }
        }
    }

    var savedCount: Int { store.savedInternshipIDs.count }

    private func matches(_ role: Internship) -> Bool {
        if paidOnly, !role.isPaid { return false }
        if easyApplyOnly, !role.easyApply { return false }
        if !workModes.isEmpty, !workModes.contains(role.workMode) { return false }
        if !categories.isEmpty, !categories.contains(role.category) { return false }
        guard !query.isEmpty else { return true }

        let haystack = [role.title, role.companyName, role.location]
            + role.requiredSkills + role.preferredSkills + role.careerInterests
        return haystack.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    func toggle(_ mode: WorkMode) {
        if workModes.contains(mode) { workModes.remove(mode) } else { workModes.insert(mode) }
    }

    func toggle(_ category: SkillCategory) {
        if categories.contains(category) { categories.remove(category) } else { categories.insert(category) }
    }

    func reset() {
        query = ""
        workModes = []
        categories = []
        paidOnly = false
        easyApplyOnly = false
        sort = .mostRelevant
    }

    func isSaved(_ id: UUID) -> Bool { store.savedInternshipIDs.contains(id) }

    func toggleSave(_ role: Internship) { store.toggleSave(role) }

    func saveCurrentSearch() {
        guard hasFilters else {
            store.toast = Toast.warning("Nothing to save", "Add a filter or type a search first.")
            return
        }
        store.saveSearch(currentSearch)
    }

    /// Replays a saved search into the live filter state.
    func apply(_ search: SavedSearch) {
        reset()
        for filter in search.filters {
            if let mode = WorkMode.allCases.first(where: { $0.label == filter }) {
                workModes.insert(mode)
            } else if let category = SkillCategory.allCases.first(where: { $0.label == filter }) {
                categories.insert(category)
            } else if filter == "Paid" {
                paidOnly = true
            } else if filter == "Easy Apply" {
                easyApplyOnly = true
            } else {
                query = filter
            }
        }
    }

    /// Snapshot of the live filters, so saving a search stores what is on screen.
    var currentSearch: SavedSearch {
        var labels: [String] = []
        if !query.isEmpty { labels.append(query) }
        labels += workModes.map(\.label)
        labels += categories.map(\.label)
        if paidOnly { labels.append("Paid") }
        if easyApplyOnly { labels.append("Easy Apply") }
        return SavedSearch(label: labels.joined(separator: " · "), filters: labels, alertsEnabled: true)
    }
}
