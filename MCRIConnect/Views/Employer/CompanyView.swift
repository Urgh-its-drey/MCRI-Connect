import SwiftUI

/// The employer's own record: the company students see on every role card, the logo and
/// details behind it, and the account controls. Switching workspaces is not one of them —
/// the role is set by the programme, so leaving means signing out.
struct CompanyView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    @State private var isEditing = false

    var body: some View {
        Group {
            if let company = viewModel.company {
                content(company)
            } else {
                MCRIEmptyState(symbol: "building.2",
                               title: "No company on this account",
                               message: "Employers post through a company record. Sign out and create the "
                                   + "account again with your company name, or ask your programme manager to "
                                   + "link this address to a company.",
                               actionTitle: "Sign out") {
                    auth.signOut()
                }
                .mcriScreen()
            }
        }
    }

    private func content(_ company: Company) -> some View {
        MCRIPage {
            brandCard(company)

            MCRISectionHeader(title: "What students see")
            MCRISecondaryButton(title: isEditing ? "Done editing" : "Edit company details",
                                symbol: isEditing ? "checkmark" : "square.and.pencil",
                                fullWidth: false) {
                isEditing.toggle()
            }

            if isEditing {
                CompanyEditor(company: company, onSave: { updated in
                    store.saveCompany(updated)
                    isEditing = false
                })
            } else {
                previewCard(company)
            }

            MCRISectionHeader(title: "How this cycle is going")
            statsGrid

            MCRISectionHeader(title: "Roles")
            roleSummary

            MCRISectionHeader(title: "Account")
            accountCard
        }
        .mcriScreen(title: "Company", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private func brandCard(_ company: Company) -> some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: company.initials, size: 54,
                             imageURL: mcriLogoURL(company.logoPath))

                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(company.teamLabel)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    MCRIStatusBadge(company.verificationLabel,
                                    symbol: company.isVerified ? "checkmark.seal.fill" : "hourglass",
                                    tone: company.isVerified ? .positive : .attention)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }

            if !company.isVerified {
                Text("A programme manager verifies new companies. Until then your roles stay hidden from students.")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Signed in as \(auth.session.displayName) · \(auth.session.role.title)")
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
    }

    private var statsGrid: some View {
        let columns = MCRITheme.Grid.statCards()
        return LazyVGrid(columns: columns, spacing: MCRITheme.Spacing.s3) {
            MCRIStatCard(label: "Hired last cycle",
                         value: "\(viewModel.company?.hiredLastCycle ?? 0)",
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

    private func previewCard(_ company: Company) -> some View {
        MCRICard(edge: .blue) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRIAvatarPicker(title: "Company logo",
                                 initials: company.initials,
                                 bucket: .logos,
                                 currentPath: company.logoPath,
                                 maxExtent: 512) { data, extent in
                    store.setCompanyLogo(data, extent: extent)
                }

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                if let role = viewModel.livePostings.first {
                    HStack(spacing: MCRITheme.Spacing.s3) {
                        MCRILogoTile(initials: company.initials, size: 42,
                                     imageURL: mcriLogoURL(company.logoPath))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.title)
                                .font(.mcriCardTitle)
                                .foregroundStyle(MCRITheme.textPrimary)
                            Text("\(company.name) · \(role.location)")
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    FlowingChips {
                        ForEach(role.requiredSkills, id: \.self) { skill in
                            MCRISkillChip(name: skill)
                        }
                    }

                    Text(role.description)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                } else {
                    Text("Publish a role to show students what they would own in their first twelve weeks.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    MCRIButton(title: "Post a role", symbol: "plus", fullWidth: false) {
                        router.go(.createInternship)
                    }
                }
            }
        }
    }

    private var roleSummary: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                if viewModel.postings.isEmpty {
                    Text("Nothing published yet. Roles you post appear here with their applicant count.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(viewModel.postings) { role in
                    Button {
                        router.go(.editInternship(role.id))
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
                            Text(role.isClosed ? role.status.label
                                 : "\(role.daysUntilDeadline)d left")
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
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                MCRIAccountRow(symbol: "lock.person.crop.circle",
                               title: "Account and privacy",
                               detail: "Password reset, your data, delete this account") {
                    router.go(.account)
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

/// Company details the hiring team owns. Verification and `is_verified` stay out of this
/// form — the server revoked an employer's right to set them.
private struct CompanyEditor: View {
    var company: Company
    var onSave: (Company) -> Void

    @State private var name: String
    @State private var teamLabel: String
    @State private var tagline: String
    @State private var website: String
    @State private var location: String
    @State private var registrationNumber: String

    init(company: Company, onSave: @escaping (Company) -> Void) {
        self.company = company
        self.onSave = onSave
        _name = State(initialValue: company.name)
        _teamLabel = State(initialValue: company.teamLabel)
        _tagline = State(initialValue: company.tagline ?? "")
        _website = State(initialValue: company.website ?? "")
        _location = State(initialValue: company.location ?? "")
        _registrationNumber = State(initialValue: company.registrationNumber ?? "")
    }

    var body: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRIField(label: "Company name", placeholder: "Orbit Labs (Pty) Ltd",
                          text: $name, autocapitalization: .words)
                MCRIField(label: "Team label", placeholder: "Product guild · 2 open roles",
                          text: $teamLabel)
                MCRIField(label: "Registration number", placeholder: "2016/442187/07",
                          text: $registrationNumber, keyboard: .numbersAndPunctuation)
                MCRIField(label: "Website", placeholder: "https://orbitlabs.co.za",
                          text: $website, keyboard: .URL)
                MCRIField(label: "Where you hire from", placeholder: "Cape Town",
                          text: $location, autocapitalization: .words)
                MCRITextArea(label: "One line students read on every role",
                             placeholder: "Product studio building clinic software.",
                             text: $tagline, minLines: 2, counter: 90)

                MCRIButton(title: "Save company details", symbol: "checkmark",
                           isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2) {
                    var updated = company
                    updated.name = name.trimmed
                    updated.initials = NameParts.initials(updated.name)
                    updated.teamLabel = teamLabel.trimmed
                    updated.tagline = tagline.trimmed.isEmpty ? nil : tagline.trimmed
                    updated.website = website.trimmed.isEmpty ? nil : website.trimmed
                    updated.location = location.trimmed.isEmpty ? nil : location.trimmed
                    updated.registrationNumber = registrationNumber.trimmed.isEmpty
                        ? nil : registrationNumber.trimmed
                    onSave(updated)
                }
            }
        }
    }
}

struct MCRIAccountRow: View {
    var symbol: String
    var title: String
    var detail: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCRITheme.Spacing.s3) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCRITheme.secondaryAction)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.mcriCaption.weight(.semibold))
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text(detail).font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: MCRITheme.Spacing.s2)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MCRITheme.textTertiary)
            }
            .frame(minHeight: MCRITheme.Metrics.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

private struct CompanyViewPreview1: PreviewProvider {
    static var previews: some View {
        MCRIPreviewScreen(signedInAs: .employer) { CompanyView() }
    }
}
