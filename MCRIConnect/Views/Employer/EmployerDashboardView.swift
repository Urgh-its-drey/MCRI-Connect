import SwiftUI

/// The employer's morning screen: how much is in the funnel, who is waiting on us,
/// and which of the two live roles needs attention today.
struct EmployerDashboardView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    private let columns = MCRITheme.Grid.statCards()

    var body: some View {
        Group {
            if store.isLoading && store.internships.isEmpty {
                MCRICardSkeleton(rows: 3)
                    .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            } else if let error = store.loadError {
                MCRIErrorState(message: error) { Task { await store.load() } }
            } else {
                content
            }
        }
        .mcriScreen()
        .refreshable { await store.load() }
    }

    private var content: some View {
        MCRIPage {
            hero

            LazyVGrid(columns: columns, spacing: MCRITheme.Spacing.s3) {
                MCRIStatCard(label: "Open roles", value: "\(viewModel.livePostings.count)",
                             detail: "Across \(viewModel.pipeline.count) applicants",
                             symbol: "briefcase.fill") {
                    router.go(.internships)
                }
                MCRIStatCard(label: "Awaiting review", value: "\(viewModel.awaitingReview)",
                             detail: "Oldest waiting 4 days",
                             symbol: "hourglass", tone: .attention) {
                    router.select(tab: 2)
                }
                MCRIStatCard(label: "Interviews", value: "\(viewModel.inInterview)",
                             detail: "Booked this cycle",
                             symbol: "video.fill") {
                    router.select(tab: 2)
                }
                MCRIStatCard(label: "Offers out", value: "\(viewModel.offersOut)",
                             detail: "Awaiting a student reply",
                             symbol: "hand.thumbsup.fill")
            }

            if let candidate = viewModel.firstToAction {
                reviewCard(candidate)
            }

            MCRISectionHeader(title: "Your funnel",
                              subtitle: "Every candidate against your roles, by stage") {
                MCRILinkButton(title: "Pipeline") { router.select(tab: 2) }
            }
            funnelCard

            MCRISectionHeader(title: "Strongest candidates",
                              subtitle: "90%+ fit, ranked on evidence in their profile") {
                MCRILinkButton(title: "See all") { router.select(tab: 2) }
            }
            ForEach(viewModel.topPicks.prefix(3)) { candidate in
                candidateCard(candidate)
            }

            roleLoadCard
        }
    }

    private var hero: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: viewModel.company.initials, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(auth.session.displayName.isEmpty ? "Talent team" : auth.session.displayName)
                        .font(.mcriCaption2.weight(.bold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(MCRITheme.primaryAction)
                    Text(viewModel.company.name)
                        .font(.mcriDisplay)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("\(viewModel.company.teamLabel) · \(viewModel.company.hiredLastCycle) hired last cycle")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                }
                Spacer(minLength: MCRITheme.Spacing.s2)
                MCRIMatchRing(score: viewModel.averageMatch, size: 62, lineWidth: 5, caption: "fit")
            }

            MCRIButton(title: "Post a role", symbol: "plus", fullWidth: false) {
                router.go(.createInternship)
            }
        }
    }

    private func reviewCard(_ candidate: Candidate) -> some View {
        MCRICard(edge: .orange) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "First to action")
                HStack(spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: candidate.initials, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.name)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("\(candidate.match)% fit · \(candidate.student.availability.rawValue)")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }
                    Spacer(minLength: MCRITheme.Spacing.s2)
                    MCRIStatusBadge(candidate.status.label, symbol: candidate.status.symbol,
                                    tone: candidate.status.tone)
                }

                Text(candidate.evidence)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRISecondaryButton(title: "Move to review", fullWidth: false, compact: true) {
                        viewModel.advance(candidate)
                    }
                    Spacer(minLength: 0)
                    MCRIButton(title: "Open profile", symbol: "arrow.right", fullWidth: false) {
                        router.go(.candidate(candidate.id))
                    }
                }
            }
        }
    }

    private var funnelCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                if viewModel.stageBoard.isEmpty {
                    Text("No candidates in the funnel yet. Published roles show applicants here within a day.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                } else {
                    MCRIFunnel(segments: viewModel.stageBoard.map { column in
                        MCRIFunnel.Segment(label: column.stage.label, value: column.items.count,
                                           color: column.stage.tone.label)
                    })
                }
            }
        }
    }

    private func candidateCard(_ candidate: Candidate) -> some View {
        MCRICandidateCard(candidate: candidate,
                          internshipTitle: viewModel.role(for: candidate)?.title) {
            router.go(.candidate(candidate.id))
        } onAdvance: {
            viewModel.advance(candidate)
        } onMessage: {
            router.go(.thread(viewModel.message(candidate)))
        }
    }

    private var roleLoadCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Workload per role",
                                  subtitle: "Where your review time is going")
                ForEach(viewModel.roleLoads) { load in
                    Button {
                        viewModel.select(role: load.role)
                        router.select(tab: 2)
                    } label: {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(load.role.title)
                                    .font(.mcriCaption.weight(.semibold))
                                    .foregroundStyle(MCRITheme.textPrimary)
                                Text("\(load.applicants) applicants · closes \(load.role.deadlineLabel)")
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textTertiary)
                            }
                            Spacer(minLength: MCRITheme.Spacing.s2)
                            if load.awaitingReview > 0 {
                                MCRIStatusBadge("\(load.awaitingReview) to review", tone: .attention)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MCRITheme.border)
                        }
                        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if load.id != viewModel.roleLoads.last?.id {
                        Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    }
                }
            }
        }
    }
}

private struct EmployerDashboardViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) { EmployerDashboardView() }
}
}
