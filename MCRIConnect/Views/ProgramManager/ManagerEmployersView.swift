import SwiftUI

/// Every hiring company on the programme. Verification happens here: an unverified
/// company's roles stay invisible to students until a manager approves the organisation.
struct ManagerEmployersView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controls

            ScrollView {
                LazyVStack(spacing: MCRITheme.Spacing.s3) {
                    if store.isLoading && store.companies.isEmpty {
                        MCRICardSkeleton(rows: 3).padding(.top, MCRITheme.Spacing.s2)
                    } else if viewModel.visibleCompanies.isEmpty {
                        MCRIEmptyState(symbol: "building.2",
                                       title: viewModel.hasCompanyFilters ? "No company in this slice" : "No employers yet",
                                       message: viewModel.hasCompanyFilters
                                           ? "Clear the filters to see every company on the programme."
                                           : "Companies appear here as employers create their accounts.",
                                       actionTitle: viewModel.hasCompanyFilters ? "Clear filters" : nil) {
                            viewModel.clearCompanyFilters()
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        if !viewModel.pendingCompanies.isEmpty && viewModel.verificationFilter == nil {
                            pendingBanner
                        }

                        ForEach(viewModel.visibleCompanies) { company in
                            companyCard(company)
                        }
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Employers", hidesTitle: false)
        .refreshable { await store.load() }
    }

    private var controls: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISearchBar(placeholder: "Search company, city or role", text: $viewModel.companyQuery)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRIFilterChip(title: "All", isSelected: viewModel.verificationFilter == nil,
                                   trailingCount: store.companies.count) {
                        viewModel.verificationFilter = nil
                    }
                    MCRIFilterChip(title: "Verified", symbol: "checkmark.seal.fill",
                                   isSelected: viewModel.verificationFilter == true,
                                   trailingCount: viewModel.verifiedCompanies.count) {
                        viewModel.verificationFilter = true
                    }
                    MCRIFilterChip(title: "Awaiting review", symbol: "hourglass",
                                   isSelected: viewModel.verificationFilter == false,
                                   trailingCount: viewModel.pendingCompanies.count) {
                        viewModel.verificationFilter = false
                    }
                    if viewModel.hasCompanyFilters {
                        Button("Clear") { viewModel.clearCompanyFilters() }
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

    private var pendingBanner: some View {
        MCRICard(edge: .orange) {
            HStack(spacing: MCRITheme.Spacing.s3) {
                Image(systemName: "hourglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCRITheme.primaryAction)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(viewModel.pendingCompanies.count) companies awaiting verification")
                        .font(.mcriCaption.weight(.semibold))
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("Their roles stay hidden from students until you approve them.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                }
                Spacer(minLength: 0)
                MCRILinkButton(title: "Review") { viewModel.verificationFilter = false }
            }
        }
    }

    private func companyCard(_ company: Company) -> some View {
        let roles = viewModel.roles(of: company)
        let open = viewModel.openRoles(of: company)

        return MCRICard(edge: company.isVerified ? .none : .orange) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                Button {
                    router.go(.company(company.id))
                } label: {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                            MCRILogoTile(initials: company.initials, size: 44,
                                         imageURL: mcriLogoURL(company.logoPath))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(company.name)
                                    .font(.mcriCardTitle)
                                    .foregroundStyle(MCRITheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Text(company.location ?? "South Africa")
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: MCRITheme.Spacing.s2)

                            MCRIStatusBadge(company.verificationLabel,
                                            symbol: company.isVerified ? "checkmark.seal.fill" : "hourglass",
                                            tone: company.isVerified ? .positive : .attention)
                        }

                        HStack(spacing: MCRITheme.Spacing.s3) {
                            stat("Roles", "\(roles.count)")
                            stat("Open", "\(open.count)")
                            stat("Applications", "\(viewModel.applications(of: company))")
                            stat("Placed", "\(viewModel.placedStudents(of: company).count)")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(company.name), \(company.verificationLabel), "
                                    + "\(roles.count) roles, \(viewModel.applications(of: company)) applications")

                if let waiting = optionalWaiting(company) {
                    Text("\(waiting) applications at this company have not been reviewed yet")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.primaryAction)
                }

                verificationRow(company)
            }
        }
    }

    private func optionalWaiting(_ company: Company) -> Int? {
        let waiting = viewModel.awaitingReview(of: company)
        return waiting > 0 ? waiting : nil
    }

    private func verificationRow(_ company: Company) -> some View {
        HStack(spacing: MCRITheme.Spacing.s2) {
            if company.isVerified {
                MCRISecondaryButton(title: "Withdraw verification", symbol: "xmark.seal",
                                    fullWidth: false, compact: true, isDestructive: true) {
                    viewModel.setVerified(company, verified: false)
                }
            } else {
                MCRIButton(title: "Verify company", symbol: "checkmark.seal.fill",
                           fullWidth: false, isDisabled: false) {
                    viewModel.setVerified(company, verified: true)
                }
            }

            Spacer(minLength: 0)

            Text(company.registrationNumber.map { "Reg · \($0)" } ?? "No registration number on file")
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
                .lineLimit(1)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.mcriNumeric)
                .monospacedDigit()
                .foregroundStyle(MCRITheme.textPrimary)
            Text(label)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ManagerEmployersViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { ManagerEmployersView() }
}
}
