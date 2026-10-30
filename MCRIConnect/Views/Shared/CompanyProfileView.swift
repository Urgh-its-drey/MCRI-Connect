import SwiftUI

/// The company as the programme sees it. Students and managers read the same record:
/// who they are, whether they are verified, and which roles they are hiring into.
struct CompanyProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL

    var company: Company

    private var roles: [Internship] {
        store.internships.filter { $0.companyID == company.id }
    }

    private var openRoles: [Internship] { roles.filter { !$0.isClosed } }

    private var applicationCount: Int {
        let ids = Set(roles.map(\.id))
        return store.applications.filter { ids.contains($0.internshipID) }.count
    }

    var body: some View {
        MCRIPage {
            hero
            factsCard

            MCRISectionHeader(title: "Open roles",
                              subtitle: openRoles.isEmpty ? nil
                                  : "\(openRoles.count) live · \(applicationCount) applications so far") {
                if !openRoles.isEmpty {
                    Text("\(roles.count - openRoles.count) closed")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                }
            }

            if openRoles.isEmpty {
                MCRIEmptyState(symbol: "briefcase",
                               title: "Nothing open right now",
                               message: company.isVerified
                                   ? "This company keeps its profile on the programme and posts when a seat opens."
                                   : "Roles are hidden until a programme manager verifies the company.")
            } else {
                ForEach(openRoles) { role in
                    roleRow(role)
                }
            }

            if !roles.filter(\.isClosed).isEmpty {
                MCRISectionHeader(title: "Closed roles")
                ForEach(roles.filter(\.isClosed)) { role in
                    roleRow(role)
                }
            }
        }
        .mcriScreen(title: company.name, hidesTitle: false)
        .background(MCRITheme.background.ignoresSafeArea())
    }

    private var hero: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: company.initials, size: 54,
                             imageURL: mcriLogoURL(company.logoPath))

                VStack(alignment: .leading, spacing: 4) {
                    Text(company.name)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
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

            if let tagline = company.tagline {
                Text(tagline)
                    .font(.mcriCaption)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var factsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MetaRow(items: [
                    (icon: "mappin.and.ellipse", text: company.location ?? "South Africa"),
                    (icon: "briefcase", text: "\(openRoles.count) open role\(openRoles.count == 1 ? "" : "s")"),
                    (icon: "checkmark.seal", text: "\(company.hiredLastCycle) hired last cycle"),
                ])

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                infoRow(symbol: "hashtag", label: "Registration",
                        value: company.registrationNumber ?? "Not provided")

                if let website = company.website, URL(string: website) != nil {
                    Button {
                        openURL(URL(string: website)!)
                    } label: {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            Image(systemName: "link")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .frame(width: 18)
                            Text("Website")
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textTertiary)
                            Spacer(minLength: MCRITheme.Spacing.s2)
                            Text(website.replacingOccurrences(of: "https://", with: ""))
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .lineLimit(1)
                        }
                        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func infoRow(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MCRITheme.secondaryAction)
                .frame(width: 18)
            Text(label)
                .font(.mcriFootnote)
                .foregroundStyle(MCRITheme.textTertiary)
            Spacer(minLength: MCRITheme.Spacing.s2)
            Text(value)
                .font(.mcriCaption.weight(.semibold))
                .foregroundStyle(MCRITheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func roleRow(_ role: Internship) -> some View {
        Button {
            router.go(.internship(role.id))
        } label: {
            HStack(spacing: MCRITheme.Spacing.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.title)
                        .font(.mcriCaption.weight(.semibold))
                        .foregroundStyle(MCRITheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("\(role.durationLabel) · \(role.compensation) · \(role.workMode.label)")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: MCRITheme.Spacing.s2)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(role.isClosed ? "Closed" : "\(role.applicants) applicants")
                        .font(.mcriCaption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(role.isClosingSoon ? MCRITheme.blocked : MCRITheme.textTertiary)
                    if !role.isClosed {
                        Text("Closes \(role.deadlineLabel)")
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                }
            }
            .padding(MCRITheme.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MCRITheme.surface, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.card,
                                                                style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.card, style: .continuous)
                .strokeBorder(MCRITheme.hairline, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(role.title), \(role.isClosed ? "closed" : "\(role.applicants) applicants")")
    }
}

private struct CompanyProfileViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { CompanyProfileView(company: SampleData.orbitLabs) }
}
}
