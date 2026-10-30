import SwiftUI

/// The cohort at a glance: how many students are ready, where the funnel leaks,
/// and which advisors are carrying the most risk.
struct ManagerOverviewView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()

    private let columns = MCRITheme.Grid.statCards()

    var body: some View {
        Group {
            if store.isLoading && store.placements.isEmpty {
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
                MCRIStatCard(label: "Students", value: "\(viewModel.metrics.totalStudents)",
                             detail: "Enrolled this cycle", symbol: "person.2.fill") {
                    router.go(.students)
                }
                MCRIStatCard(label: "Ready", value: "\(viewModel.metrics.readyForPlacement)",
                             detail: "\(viewModel.readyShare)% of the cohort", symbol: "checkmark.seal.fill")
                MCRIStatCard(label: "Applications", value: "\(viewModel.metrics.activeApplications)",
                             detail: "Live across \(store.internships.count) roles", symbol: "paperplane.fill")
                MCRIStatCard(label: "Unmatched", value: "\(viewModel.metrics.unmatchedStudents)",
                             detail: "No application in 14 days", symbol: "tray.full.fill", tone: .attention) {
                    router.go(.reports)
                }
            }

            MCRISectionHeader(title: "Cohort readiness",
                              subtitle: "Band comes from profile strength, not attendance") {
                MCRILinkButton(title: "Students") { router.select(tab: 1) }
            }
            readinessCard

            MCRISectionHeader(title: "Placement funnel",
                              subtitle: "Your active caseload, stage by stage") {
                MCRILinkButton(title: "Pipeline") { router.select(tab: 3) }
            }
            funnelCard

            MCRISectionHeader(title: "Hiring companies",
                              subtitle: "\(viewModel.verifiedCompanies.count) verified · \(viewModel.pendingCompanies.count) awaiting review") {
                MCRILinkButton(title: "All employers") { router.go(.companies) }
            }
            companiesCard

            MCRISectionHeader(title: "Advisor load")
            advisorCard

            MCRISectionHeader(title: "Applications per week",
                              subtitle: "Latest week is live")
            volumeCard

            if !viewModel.alerts.isEmpty {
                MCRISectionHeader(title: "Today's priorities",
                                  subtitle: "\(viewModel.alerts.count) items need a decision") {
                    MCRILinkButton(title: "All reports") { router.go(.reports) }
                }
                ForEach(viewModel.alerts.prefix(2)) { alert in
                    AlertRow(alert: alert) { viewModel.nudge(alert) }
                }
            }
        }
    }

    private var hero: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.session.displayName.isEmpty ? "Programme office" : auth.session.displayName)
                        .font(.mcriCaption2.weight(.bold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(MCRITheme.primaryAction)
                    Text("Placement cycle")
                        .font(.mcriDisplay)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("\(viewModel.placedCount) placed · \(viewModel.activeCaseload.count) still in progress")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                }
                Spacer()
                MCRIStrengthRing(value: viewModel.readyShare, caption: "ready", size: 74)
            }

            if !viewModel.atRisk.isEmpty {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRIStatusBadge("\(viewModel.atRisk.count) below 60%", symbol: "exclamationmark.triangle.fill",
                                    tone: .attention)
                    MCRIStatusBadge("\(viewModel.placementRate)% placed", symbol: "checkmark", tone: .positive)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var readinessCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRIHorizontalBars(entries: viewModel.readinessBars, total: viewModel.cohortTotal)
                Text("\(viewModel.cohortTotal) of \(viewModel.metrics.totalStudents) students have started a profile")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var funnelCard: some View {
        MCRICard {
            MCRIFunnel(segments: viewModel.funnel)
        }
    }

    private var companiesCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                if viewModel.companies.isEmpty {
                    Text("Companies appear here as employers create their accounts.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                } else {
                    ForEach(viewModel.companies.prefix(4)) { company in
                        Button {
                            router.go(.company(company.id))
                        } label: {
                            HStack(spacing: MCRITheme.Spacing.s3) {
                                MCRILogoTile(initials: company.initials, size: 34,
                                             imageURL: mcriLogoURL(company.logoPath))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(company.name)
                                        .font(.mcriCaption.weight(.semibold))
                                        .foregroundStyle(MCRITheme.textPrimary)
                                    Text("\(viewModel.openRoles(of: company).count) open · "
                                         + "\(viewModel.applications(of: company)) applications")
                                        .font(.mcriFootnote)
                                        .foregroundStyle(MCRITheme.textTertiary)
                                }
                                Spacer(minLength: MCRITheme.Spacing.s2)
                                if company.isVerified {
                                    MCRIStatusBadge("Verified", tone: .positive)
                                } else {
                                    MCRIStatusBadge("Review", tone: .attention)
                                }
                            }
                            .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if company.id != viewModel.companies.prefix(4).last?.id {
                            Rectangle().fill(MCRITheme.divider).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private var advisorCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                ForEach(viewModel.advisorLoads) { load in
                    HStack(spacing: MCRITheme.Spacing.s3) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(load.advisor)
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.textPrimary)
                            Text("\(load.students) students · \(load.placed) placed")
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textTertiary)
                        }
                        Spacer(minLength: MCRITheme.Spacing.s2)
                        if load.atRisk > 0 {
                            MCRIStatusBadge("\(load.atRisk) at risk", tone: .attention)
                        } else {
                            MCRIStatusBadge("On track", tone: .positive)
                        }
                    }
                    .frame(minHeight: MCRITheme.Spacing.s6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.advisorFilter = load.advisor
                        router.select(tab: 1)
                    }
                    .accessibilityLabel("\(load.advisor): \(load.students) students, \(load.atRisk) at risk")

                    if load.id != viewModel.advisorLoads.last?.id {
                        Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    }
                }
            }
        }
    }

    private var volumeCard: some View {
        MCRICard {
            if viewModel.weeklyApplications.isEmpty {
                Text("Weekly activity appears once the first applications land.")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
            } else {
                MCRIVolumeChart(values: viewModel.weeklyApplications,
                                caption: "7 weeks · \(viewModel.weeklyApplications.last ?? 0) applications in the latest week")
            }
        }
    }
}

private struct ManagerOverviewViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { ManagerOverviewView() }
}
}
