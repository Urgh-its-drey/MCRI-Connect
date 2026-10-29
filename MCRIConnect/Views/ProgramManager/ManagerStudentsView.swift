import SwiftUI

/// Every student in the cohort with the reason they are in their band, so a
/// manager can act without opening six screens.
struct ManagerStudentsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls

            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s3) {
                    if store.isLoading && store.students.isEmpty {
                        MCRICardSkeleton(rows: 3).padding(.top, MCRITheme.Spacing.s2)
                    } else if viewModel.visibleStudents.isEmpty {
                        MCRIEmptyState(symbol: "person.2",
                                       title: viewModel.hasFilters ? "No student in this slice" : "No students yet",
                                       message: viewModel.hasFilters
                                           ? "Clear the filters to see the whole cohort."
                                           : "Student profiles appear here as they complete onboarding.",
                                       actionTitle: viewModel.hasFilters ? "Clear filters" : nil) {
                            viewModel.clearFilters()
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        ForEach(viewModel.visibleStudents) { student in
                            studentCard(student)
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Students", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var controls: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISearchBar(placeholder: "Search name, programme or skill", text: $viewModel.query)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRIFilterChip(title: "All", isSelected: viewModel.bandFilter == nil,
                                   trailingCount: store.students.count) {
                        viewModel.bandFilter = nil
                    }
                    ForEach(ReadinessBand.allCases) { band in
                        MCRIFilterChip(title: band.label,
                                       isSelected: viewModel.bandFilter == band) {
                            viewModel.bandFilter = band
                        }
                    }
                    ForEach(viewModel.advisors, id: \.self) { advisor in
                        MCRIFilterChip(title: advisor, symbol: "person.crop.circle",
                                       isSelected: viewModel.advisorFilter == advisor) {
                            viewModel.advisorFilter = viewModel.advisorFilter == advisor ? nil : advisor
                        }
                    }
                    if viewModel.hasFilters {
                        Button("Clear") { viewModel.clearFilters() }
                            .font(.mcriCaption.weight(.semibold))
                            .foregroundStyle(MCRITheme.blocked)
                            .frame(height: MCRITheme.Metrics.minTapTarget)
                            .padding(.horizontal, MCRITheme.Spacing.s3)
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.top, MCRITheme.Spacing.s2)
        .padding(.bottom, MCRITheme.Spacing.s3)
        .background(MCRITheme.background)
    }

    private func studentCard(_ student: Student) -> some View {
        let placement = store.placements.first { $0.studentID == student.id }
        let band = student.readiness

        return MCRICard(edge: band == .readyToApply ? .blue : (band == .notStarted ? .red : .none)) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: student.initials, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.fullName)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("\(student.programme) · \(student.year) · \(student.city)")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    VStack(alignment: .trailing, spacing: 4) {
                        MCRIStrengthRing(value: student.profileStrength, caption: "fit", size: 44)
                        if let placement {
                            MCRIStatusBadge(placement.stage.label, symbol: placement.stage.symbol,
                                            tone: placement.stage.tone)
                        }
                    }
                }

                Text(viewModel.gapSummary(for: student))
                    .font(.mcriFootnote)
                    .foregroundStyle(student.missingSections.isEmpty
                                     ? MCRITheme.positive : MCRITheme.primaryAction)
                    .fixedSize(horizontal: false, vertical: true)

                FlowingChips {
                    ForEach(student.skillNames.prefix(4), id: \.self) { skill in
                        MCRISkillChip(name: skill)
                    }
                }

                HStack(spacing: MCRITheme.Spacing.s2) {
                    Text("Advisor · \(student.advisor ?? "Unassigned")")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .lineLimit(1)
                    Spacer(minLength: MCRITheme.Spacing.s2)
                }

                HStack(spacing: MCRITheme.Spacing.s2) {
                    Spacer(minLength: 0)
                    MCRISecondaryButton(title: "Message", symbol: "bubble.left",
                                        fullWidth: false, compact: true) {
                        if let placement {
                            router.go(.thread(viewModel.message(placement, from: auth.session.displayName)))
                        }
                    }
                    .disabled(placement == nil)
                    .opacity(placement == nil ? 0.45 : 1)

                    MCRIButton(title: "Next stage", symbol: "arrow.right",
                               fullWidth: false, isDisabled: placement == nil
                               || viewModel.stageAfter(placement?.stage ?? .placed) == nil) {
                        if let placement { viewModel.advance(placement) }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(student.fullName), \(student.profileStrength) percent ready, \(band.label)")
    }
}

private struct ManagerStudentsViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { ManagerStudentsView() }
}
}
