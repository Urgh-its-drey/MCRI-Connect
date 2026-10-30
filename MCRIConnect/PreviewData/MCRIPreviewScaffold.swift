import SwiftUI

/// Gives a screen preview the same environment the app installs at launch: the
/// three shared objects plus the data load every read depends on. Without it a
/// Canvas shows empty states rather than the design.
struct MCRIPreviewScreen<Content: View>: View {
    var signedInAs: UserRole = .student
    /// Tab containers bring their own stack; screens that sit under one need this.
    var inNavigationStack: Bool = true
    @ViewBuilder var content: () -> Content

    @StateObject private var store = AppStore.shared
    @StateObject private var auth = AuthService.shared
    @StateObject private var router = Router()

    var body: some View {
        Group {
            if inNavigationStack {
                NavigationStack { content() }
            } else {
                content()
            }
        }
        .environmentObject(store)
        .environmentObject(auth)
        .environmentObject(router)
        .mcriToast($store.toast)
        .task {
            #if DEBUG
            if !auth.canOpen(signedInAs) { store.previewAsSignedIn(role: signedInAs) }
            #endif
            if store.students.isEmpty { await store.load() }
        }
    }
}

/// The iPhone widths the UI has to survive. `small` is the narrowest device the
/// deployment target still runs on; no simulator ships that small any more, so it
/// has to be checked by pinning a preview rather than by picking a device.
enum MCRIPhoneWidth {
    static let small: CGFloat = 320
    static let compact: CGFloat = 375
    static let wide: CGFloat = 440
}

extension View {
    /// Renders the view at a fixed iPhone width, centred on the app canvas.
    func mcriPinned(to width: CGFloat) -> some View {
        self
            .frame(width: width)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MCRITheme.background)
    }
}

/// A column of component states pinned to a real iPhone width. Components size
/// themselves against the screen, so a Canvas that gives them infinite space
/// proves nothing.
struct MCRIPreviewGroup<Content: View>: View {
    var title: String
    var width: CGFloat = MCRIPhoneWidth.compact
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                Text(title)
                    .font(.mcriCardTitle)
                    .foregroundStyle(MCRITheme.textPrimary)
                content()
            }
            .padding(MCRITheme.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(MCRITheme.background)
    }
}

/// Ready-made data for the component previews. Real sample objects where one
/// exists, synthetic scores where the preview needs to show a specific state.
enum MCRIPreview {
    static func role(_ internship: Internship,
                     _ student: Student = SampleData.alex) -> MatchedRole {
        MatchedRole(internship: internship,
                    result: MatchEngine.shared.result(for: student, on: internship))
    }

    static let flagship = role(SampleData.productDesignIntern)
    static let stretch = role(SampleData.backendIntern, SampleData.reece)

    static func result(skills: Int, interests: Int, logistics: Int, profile: Int) -> MatchResult {
        MatchResult(
            breakdown: MatchBreakdown(skills: skills, interests: interests,
                                      logistics: logistics, profile: profile),
            signals: [MatchSignal(title: "\(skills) skills match this role",
                                  detail: "Two of them come from your portfolio project.",
                                  symbol: "checkmark.circle.fill")],
            gaps: [MatchGap(action: "Add a case study that shows your research process", lift: 7),
                   MatchGap(action: "Upload your CV so employers can open it", lift: 4)],
            percentile: 18,
            matchedSkills: ["Figma", "Design systems", "Prototyping"],
            missingSkills: ["User research", "Accessibility audit"]
        )
    }

    static let stages = ApplicationStage.trackerStages
    static let candidate = SampleData.candidate(SampleData.jordan,
                                                internship: SampleData.mobileDevIntern,
                                                status: .shortlisted)
    static let application = SampleData.applications[0]

    /// Built from the role's own tab metadata so a preview can never drift from the app.
    static func tabs(for role: UserRole, badges: [Int: Int] = [:]) -> [MCRITabBar.Item] {
        zip(role.tabTitles, role.tabSymbols).enumerated().map { index, pair in
            MCRITabBar.Item(title: pair.0, symbol: pair.1, badge: badges[index] ?? 0)
        }
    }

    static var studentTabs: [MCRITabBar.Item] { tabs(for: .student, badges: [2: 3, 3: 1]) }
}
