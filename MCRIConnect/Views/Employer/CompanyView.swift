import SwiftUI

/// The employer's own record: what students see on a role card, the team behind it,
/// and the account controls that move between roles.
struct CompanyView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    var body: some View {
        MCRIPage {
            brandCard

            MCRISectionHeader(title: "How this cycle is going")
            statsGrid

            MCRISectionHeader(title: "Students see this on every role")
            previewCard

            MCRISectionHeader(title: "Roles")
            roleSummary

            MCRISectionHeader(title: "Account")
            accountCard
        }
        .mcriScreen(title: "Company", hidesTitle: false)
    }

    private var brandCard: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: viewModel.company.initials, size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.company.name)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(viewModel.company.teamLabel)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    if viewModel.company.isVerified {
                        MCRIStatusBadge("Verified partner", symbol: "checkmark.seal.fill", tone: .positive)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }

            Text("Signed in as \(auth.session.displayName) · \(auth.session.role.title)")
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
    }

    private var statsGrid: some View {
        let columns = MCRITheme.Grid.statCards()
        return LazyVGrid(columns: columns, spacing: MCRITheme.Spacing.s3) {
            MCRIStatCard(label: "Hired last cycle", value: "\(viewModel.company.hiredLastCycle)",
                         detail: "From this programme", symbol: "checkmark.seal.fill")
            MCRIStatCard(label: "Live roles", value: "\(viewModel.livePostings.count)",
                         detail: "\(viewModel.closedPostings.count) closed", symbol: "briefcase.fill") {
                router.go(.internships)
            }
            MCRIStatCard(label: "Average fit", value: "\(viewModel.averageMatch)%",
                         detail: "Across \(viewModel.pipeline.count) applicants", symbol: "target")
            MCRIStatCard(label: "Awaiting you", value: "\(viewModel.awaitingReview)",
                         detail: "Applications not yet reviewed", symbol: "hourglass", tone: .attention)
        }
    }

    private var previewCard: some View {
        MCRICard(edge: .blue) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: viewModel.company.initials, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.livePostings.first?.title ?? "Product Design Intern")
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("\(viewModel.company.name) · \(viewModel.livePostings.first?.location ?? "South Africa")")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                FlowingChips {
                    ForEach(viewModel.livePostings.first?.requiredSkills ?? [], id: \.self) { skill in
                        MCRISkillChip(name: skill)
                    }
                }

                Text(viewModel.livePostings.first?.description ?? "Publish a role to show students what they "
                     + "would own in their first twelve weeks.")
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
    }

    private var roleSummary: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                ForEach(viewModel.postings) { role in
                    Button {
                        viewModel.select(role: role)
                        router.select(tab: 2)
                    } label: {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(role.title)
                                    .font(.mcriCaption.weight(.semibold))
                                    .foregroundStyle(MCRITheme.textPrimary)
                                Text("\(role.durationLabel) · \(role.compensation)")
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textTertiary)
                            }
                            Spacer(minLength: MCRITheme.Spacing.s2)
                            Text(role.daysUntilDeadline > 0 ? "\(role.daysUntilDeadline)d left" : "Closed")
                                .font(.mcriCaption2.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(role.isClosingSoon ? MCRITheme.blocked : MCRITheme.textTertiary)
                        }
                        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if role.id != viewModel.postings.last?.id {
                        Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    }
                }
            }
        }
    }

    private var accountCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Switch workspace",
                                  subtitle: "Same data, different role view")
                ForEach(UserRole.allCases) { role in
                    Button {
                        auth.switchRole(role)
                    } label: {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            Image(systemName: role.glyph)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(role == auth.session.role
                                                 ? MCRITheme.primaryAction : MCRITheme.textTertiary)
                                .frame(width: 24)
                            Text(role.title)
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.textPrimary)
                            Spacer()
                            if role == auth.session.role {
                                MCRIStatusBadge("Current", tone: .attention)
                            }
                        }
                        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Switch to \(role.title) workspace")
                }

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                MCRISecondaryButton(title: "Sign out", symbol: "rectangle.portrait.and.arrow.right",
                                    isDestructive: true) {
                    auth.signOut()
                }
            }
        }
    }
}

private struct CompanyViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) { CompanyView() }
}
}
