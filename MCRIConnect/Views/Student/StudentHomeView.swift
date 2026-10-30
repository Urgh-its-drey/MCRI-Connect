import SwiftUI

struct StudentHomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        Group {
            if store.isLoading && store.students.isEmpty {
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

            if !viewModel.needsResponse.isEmpty {
                nextActionCard
            }

            MCRISectionHeader(title: "Best matches for you",
                              subtitle: "Ranked by your profile, not by who posted last") {
                MCRILinkButton(title: "See all") { router.select(tab: 1) }
            }

            ForEach(viewModel.recommended) { role in
                MCRIInternshipCard(role: role,
                                   isSaved: store.savedInternshipIDs.contains(role.id),
                                   showsApply: false) {
                    router.go(.internship(role.id))
                } onSave: {
                    store.toggleSave(role.internship)
                }
            }

            closingRow

            MCRISectionHeader(title: "Your applications",
                              subtitle: "\(viewModel.activeApplications.count) open · \(viewModel.savedCount) saved")
            if viewModel.activeApplications.isEmpty {
                MCRIEmptyState(symbol: "paperplane",
                               title: "No applications yet",
                               message: "Open a match above and Easy Apply sends the profile you just built.",
                               actionTitle: "Browse roles") {
                    router.select(tab: 1)
                }
            } else {
                ForEach(viewModel.activeApplications.prefix(3)) { application in
                    MCRIApplicationRow(application: application)
                }
            }
        }
    }

    @ViewBuilder private var hero: some View {
        MCRIScreenHero {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greeting)
                        .font(.mcriCaption2.weight(.bold))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(MCRITheme.primaryAction)
                    Text(viewModel.firstName)
                        .font(.mcriDisplay)
                        .foregroundStyle(MCRITheme.textPrimary)
                    if let student = viewModel.student {
                        Text("\(student.programme) · \(student.year)")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }
                }
                Spacer()
                MCRIMatchRing(score: viewModel.profileStrength, size: 62, lineWidth: 5,
                              caption: "ready")
            }

            HStack(spacing: MCRITheme.Spacing.s2) {
                heroStat(value: "\(viewModel.recommended.filter { $0.score >= 70 }.count)", label: "strong fits")
                heroStat(value: "\(viewModel.activeApplications.count)", label: "in flight")
                heroStat(value: "\(viewModel.closingSoon.count)", label: "closing soon")
            }
        }
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.mcriNumeric)
                .foregroundStyle(MCRITheme.textPrimary)
            Text(label)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var nextActionCard: some View {
        let application = viewModel.needsResponse[0]
        MCRICard(edge: .orange, padding: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Needs your response")
                if let role = store.internship(for: application.internshipID) {
                    Text(role.title)
                        .font(.mcriCardTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(application.nextAction ?? "Check the tracker")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    if let interview = application.interviewDate {
                        MetaRow(items: [(icon: "calendar",
                                         text: interview.formatted(date: .abbreviated, time: .shortened))])
                    }
                }
                MCRIButton(title: "Open application", symbol: "arrow.right", fullWidth: false) {
                    router.go(.application(application.id))
                }
            }
        }
    }

    @ViewBuilder private var closingRow: some View {
        if !viewModel.closingSoon.isEmpty {
            MCRICard {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    MCRISectionHeader(title: "Deadline watch")
                    ForEach(viewModel.closingSoon) { role in
                        Button {
                            router.go(.internship(role.id))
                        } label: {
                            HStack(spacing: MCRITheme.Spacing.s3) {
                                Image(systemName: "alarm.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(MCRITheme.blocked)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(role.internship.title)
                                        .font(.mcriCaption.weight(.semibold))
                                        .foregroundStyle(MCRITheme.textPrimary)
                                    Text("Closes \(role.internship.deadlineLabel) · \(role.score)% match")
                                        .font(.mcriFootnote)
                                        .foregroundStyle(MCRITheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MCRITheme.border)
                            }
                            .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if role.id != viewModel.closingSoon.last?.id {
                            Rectangle().fill(MCRITheme.divider).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct StudentHomeViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { StudentHomeView() }
}
}
