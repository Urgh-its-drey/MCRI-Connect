import SwiftUI

/// The live caseload: each student at the stage they are actually at, with the
/// move that advances them and the paperwork that blocks them.
struct PlacementPipelineView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls

            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s4) {
                    if store.isLoading && store.placements.isEmpty {
                        MCRICardSkeleton(rows: 3).padding(.top, MCRITheme.Spacing.s2)
                    } else if viewModel.visiblePlacements.isEmpty {
                        MCRIEmptyState(symbol: "arrow.triangle.branch",
                                       title: viewModel.hasFilters ? "Nobody in this view" : "No placements yet",
                                       message: viewModel.hasFilters
                                           ? "Clear the filters to see the whole pipeline."
                                           : "Students enter the pipeline once they start applying.",
                                       actionTitle: viewModel.hasFilters ? "Clear filters" : nil) {
                            viewModel.clearFilters()
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        ForEach(PlacementStage.allCases) { stage in
                            let items = viewModel.visiblePlacements.filter { $0.stage == stage }
                            if !items.isEmpty {
                                stageSection(stage, items)
                            }
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Placements", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var controls: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISearchBar(placeholder: "Search student, skill or advisor", text: $viewModel.query)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRIFilterChip(title: "All stages", isSelected: viewModel.stageFilter == nil,
                                   trailingCount: viewModel.placements.count) {
                        viewModel.stageFilter = nil
                    }
                    ForEach(PlacementStage.allCases) { stage in
                        MCRIFilterChip(title: stage.label, symbol: stage.symbol,
                                       isSelected: viewModel.stageFilter == stage,
                                       trailingCount: store.placements(in: stage).count) {
                            viewModel.stageFilter = stage
                        }
                    }
                    ForEach(viewModel.advisors, id: \.self) { advisor in
                        MCRIFilterChip(title: advisor, isSelected: viewModel.advisorFilter == advisor) {
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

    private func stageSection(_ stage: PlacementStage, _ items: [Placement]) -> some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            HStack(alignment: .firstTextBaseline, spacing: MCRITheme.Spacing.s2) {
                Image(systemName: stage.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(stage.tone.label)
                Text(stage.label).mcriLabelStyle()
                Text("\(items.count)")
                    .font(.mcriCaption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(MCRITheme.textTertiary)
                Spacer()
                if stage == .interviewing {
                    MCRILinkButton(title: "Reports") { router.go(.reports) }
                }
            }

            ForEach(items) { placement in
                placementCard(placement, stage: stage)
            }
        }
    }

    private func placementCard(_ placement: Placement, stage: PlacementStage) -> some View {
        let next = viewModel.stageAfter(stage)

        return MCRICard(edge: placement.readiness < 60 ? .red : (stage == .placed ? .blue : .none)) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: placement.initials, size: 42)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(placement.studentName)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text(placement.internshipTitle ?? "No role attached yet")
                            .font(.mcriFootnote)
                            .foregroundStyle(placement.internshipTitle == nil
                                             ? MCRITheme.primaryAction : MCRITheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(placement.readiness)%")
                            .font(.mcriNumeric)
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.tint(for: placement.readiness))
                        Text("readiness")
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MCRITheme.surfaceHi)
                        Capsule()
                            .fill(MCRITheme.tint(for: placement.readiness))
                            .frame(width: max(6, proxy.size.width * CGFloat(placement.readiness) / 100))
                    }
                }
                .frame(height: 5)
                .accessibilityHidden(true)

                FlowingChips {
                    ForEach(placement.topSkills.prefix(3), id: \.self) { skill in
                        MCRISkillChip(name: skill)
                    }
                }

                HStack(spacing: MCRITheme.Spacing.s2) {
                    Menu {
                        ForEach(PlacementStage.allCases) { stage in
                            Button(stage.label) { viewModel.move(placement, to: stage) }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.left.arrow.right").font(.caption2.weight(.bold))
                            Text("Stage").font(.mcriCaption.weight(.semibold))
                        }
                        .foregroundStyle(MCRITheme.secondaryAction)
                        .padding(.horizontal, MCRITheme.Spacing.s3)
                        .frame(height: MCRITheme.Metrics.minTapTarget)
                        .background(MCRITheme.blueTint, in: Capsule())
                        .overlay(Capsule().strokeBorder(MCRITheme.border, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Set stage for \(placement.studentName)")

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    MCRISecondaryButton(title: "Message", symbol: "bubble.left",
                                        fullWidth: false, compact: true) {
                        router.go(.thread(viewModel.message(placement, from: auth.session.displayName)))
                    }

                    if let next {
                        MCRIButton(title: next.shortTitle, symbol: "arrow.right.circle.fill",
                                   fullWidth: false, isDisabled: next == .placed && placement.internshipTitle == nil) {
                            viewModel.advance(placement)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(placement.studentName), \(stage.label), \(placement.readiness) percent ready")
    }
}

private extension PlacementStage {
    var shortTitle: String {
        switch self {
        case .preparing: return "Start"
        case .applying: return "Apply"
        case .shortlisted: return "Shortlist"
        case .interviewing: return "Interview"
        case .placed: return "Place"
        }
    }
}

private struct PlacementPipelineViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { PlacementPipelineView() }
}
}
