import SwiftUI

/// The hiring board: every candidate against the employer's roles, filterable by
/// stage and by role, with the one action that moves each person forward.
struct CandidatePipelineView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls
            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s4) {
                    if store.isLoading && store.candidates.isEmpty {
                        MCRICardSkeleton(rows: 3).padding(.top, MCRITheme.Spacing.s2)
                    } else if viewModel.visibleCandidates.isEmpty {
                        MCRIEmptyState(symbol: "person.2",
                                       title: viewModel.hasFilters ? "Nobody in this slice" : "No applicants yet",
                                       message: viewModel.hasFilters
                                           ? "Widen the filters to see the rest of your pipeline."
                                           : "Publish a role and matched students land here as they apply.",
                                       actionTitle: viewModel.hasFilters ? "Clear filters" : "Post a role") {
                            if viewModel.hasFilters {
                                viewModel.clearFilters()
                            } else {
                                router.go(.createInternship)
                            }
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        ForEach(viewModel.stageBoard) { column in
                            stageSection(column)
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Candidates", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var controls: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISearchBar(placeholder: "Search name, programme or skill", text: $viewModel.query)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRIFilterChip(title: "All", isSelected: viewModel.stageFilter == nil,
                                   trailingCount: viewModel.pipeline.count) {
                        viewModel.stageFilter = nil
                    }
                    ForEach(ApplicationStage.pipelineStages) { stage in
                        MCRIFilterChip(title: stage.label,
                                       isSelected: viewModel.stageFilter == stage,
                                       trailingCount: viewModel.candidates(in: stage).count) {
                            viewModel.stageFilter = stage
                        }
                    }
                    ForEach(viewModel.postings) { role in
                        MCRIFilterChip(title: role.title, symbol: "line.3.horizontal.decrease.circle",
                                       isSelected: viewModel.roleFilter == role.id) {
                            if viewModel.roleFilter == role.id {
                                viewModel.roleFilter = nil
                            } else {
                                viewModel.select(role: role)
                            }
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

    private func stageSection(_ column: EmployerViewModel.StageColumn) -> some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            HStack(alignment: .firstTextBaseline, spacing: MCRITheme.Spacing.s2) {
                Image(systemName: column.stage.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(column.stage.tone.label)
                Text(column.stage.label)
                    .mcriLabelStyle()
                Text("\(column.items.count)")
                    .font(.mcriCaption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(MCRITheme.textTertiary)
                Spacer()
                if column.stage == .submitted {
                    MCRILinkButton(title: "Review all") {
                        for candidate in column.items.prefix(3) { viewModel.advance(candidate) }
                    }
                }
            }

            ForEach(column.items) { candidate in
                MCRICandidateCard(candidate: candidate,
                                  internshipTitle: viewModel.role(for: candidate)?.title) {
                    router.go(.candidate(candidate.id))
                } onAdvance: {
                    viewModel.advance(candidate)
                } onMessage: {
                    viewModel.message(candidate)
                }
            }
        }
    }
}

private struct CandidatePipelineViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) { CandidatePipelineView() }
}
}
