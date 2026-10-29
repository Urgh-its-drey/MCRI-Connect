import SwiftUI

/// Everything the employer has published: live roles with their applicant load,
/// and the closed ones kept visible so nothing disappears mid-cycle.
struct EmployerInternshipsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s3) {
                    if store.isLoading && store.internships.isEmpty {
                        MCRICardSkeleton(rows: 2).padding(.top, MCRITheme.Spacing.s2)
                    } else if viewModel.postings.isEmpty {
                        MCRIEmptyState(symbol: "briefcase",
                                       title: "No roles published",
                                       message: "Post your first internship and eligible students are "
                                           + "matched to it the same day.",
                                       actionTitle: "Post a role") {
                            router.go(.createInternship)
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        sectionTitle("Live · \(viewModel.livePostings.count)")
                        ForEach(viewModel.livePostings) { role in
                            roleRow(role, live: true)
                        }

                        if !viewModel.closedPostings.isEmpty {
                            sectionTitle("Closed")
                            ForEach(viewModel.closedPostings) { role in
                                roleRow(role, live: false)
                            }
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Internships", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var header: some View {
        HStack(spacing: MCRITheme.Spacing.s2) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Published by \(viewModel.company.name)")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
                Text("\(viewModel.pipeline.count) applicants in total")
                    .font(.mcriSection)
                    .foregroundStyle(MCRITheme.textPrimary)
            }
            Spacer(minLength: MCRITheme.Spacing.s3)
            MCRIButton(title: "New", symbol: "plus", fullWidth: false) {
                router.go(.createInternship)
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.vertical, MCRITheme.Spacing.s3)
        .background(MCRITheme.background)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .mcriLabelStyle()
            .padding(.top, MCRITheme.Spacing.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func roleRow(_ role: Internship, live: Bool) -> some View {
        let applicants = store.candidates(for: role.id)
        return MCRICard(edge: live && role.isClosingSoon ? .orange : .none) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(role.title)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                            .accessibilityAddTraits(.isButton)
                        MetaRow(items: [
                            (icon: "mappin", text: role.location),
                            (icon: role.workMode.symbol, text: role.durationLabel),
                        ])
                    }
                    Spacer(minLength: MCRITheme.Spacing.s2)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(applicants.count)")
                            .font(.mcriNumeric)
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("applicants")
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                }

                FlowingChips {
                    ForEach(role.requiredSkills.prefix(4), id: \.self) { skill in
                        MCRISkillChip(name: skill)
                    }
                }

                HStack(spacing: MCRITheme.Spacing.s2) {
                    if live {
                        MCRIStatusBadge(role.easyApply ? "Easy Apply" : "CV required",
                                        symbol: role.easyApply ? "bolt.fill" : "doc.text",
                                        tone: role.easyApply ? .attention : .neutral)
                        if role.isClosingSoon {
                            MCRIStatusBadge("Closes in \(role.daysUntilDeadline)d",
                                            symbol: "alarm.fill", tone: .blocked)
                        }
                    } else {
                        MCRIStatusBadge("Closed", symbol: "archivebox", tone: .neutral)
                    }
                    Spacer(minLength: MCRITheme.Spacing.s2)
                    if live {
                        MCRISecondaryButton(title: "Review", symbol: "person.2.fill",
                                            fullWidth: false, compact: true) {
                            viewModel.select(role: role)
                            router.select(tab: 2)
                        }
                    } else {
                        MCRISecondaryButton(title: "Reopen", symbol: "arrow.counterclockwise",
                                            fullWidth: false, compact: true) {
                            reopen(role)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            guard live else { return }
            router.go(.internship(role.id))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(role.title), \(applicants.count) applicants, \(live ? "live" : "closed")")
    }

    private func reopen(_ role: Internship) {
        var updated = role
        updated.closingDate = SampleData.days(21)
        store.update(updated)
        store.toast = .success("Role reopened", "\(updated.title) is live again.")
    }
}

private struct EmployerInternshipsViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) { EmployerInternshipsView() }
}
}
