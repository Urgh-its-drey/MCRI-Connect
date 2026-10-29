import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ApplicationsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: MCRITheme.Spacing.s4) {
                if store.isLoading && viewModel.all.isEmpty {
                    MCRICardSkeleton(rows: 3)
                        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                        .padding(.top, MCRITheme.Spacing.s6)
                } else {
                    totals
                        .padding(.horizontal, MCRITheme.Spacing.screenMargin)

                    scopePicker

                    if viewModel.visible.isEmpty {
                        MCRIEmptyState(symbol: "tray",
                                       title: emptyTitle,
                                       message: emptyMessage,
                                       actionTitle: "Find roles to apply to") {
                            router.select(tab: 1)
                        }
                        .padding(.top, MCRITheme.Spacing.s6)
                    } else {
                        VStack(spacing: MCRITheme.Spacing.s3) {
                            ForEach(viewModel.visible) { application in
                                MCRIApplicationRow(application: application)
                            }
                        }
                        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                    }
                }
            }
            .padding(.top, MCRITheme.Spacing.s2)
            .padding(.bottom, MCRITheme.Spacing.s6)
        }
        .scrollIndicators(.hidden)
        .mcriScreen(title: "Applications")
        .background(MCRITheme.background.ignoresSafeArea())
    }

    private var totals: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            MCRISectionHeader(title: "Your pipeline",
                              subtitle: viewModel.awaitingResponse > 0
                                ? "\(viewModel.awaitingResponse) waiting on you"
                                : "Nothing waiting on you")
            LazyVGrid(columns: MCRITheme.Grid.statCards(),
                      spacing: MCRITheme.Spacing.s3) {
                ForEach(viewModel.counts, id: \.label) { entry in
                    MCRIStatCard(label: entry.label,
                                 value: "\(entry.value)",
                                 symbol: entry.symbol,
                                 tone: entry.tone)
                }
            }
        }
    }

    private var scopePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCRITheme.Spacing.s2) {
                ForEach(ApplicationsViewModel.Scope.allCases) { scope in
                    MCRIFilterChip(title: scope.rawValue,
                                   isSelected: viewModel.scope == scope,
                                   trailingCount: count(for: scope)) {
                        withAnimation(.easeOut(duration: 0.18)) { viewModel.scope = scope }
                    }
                }
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        }
    }

    private func count(for scope: ApplicationsViewModel.Scope) -> Int {
        viewModel.applications(in: scope).count
    }

    private var emptyTitle: String {
        switch viewModel.scope {
        case .active: return "No open applications"
        case .shortlisted: return "Not shortlisted yet"
        case .closed: return "Nothing closed"
        case .all: return "No applications yet"
        }
    }

    private var emptyMessage: String {
        switch viewModel.scope {
        case .shortlisted:
            return "Shortlists come from employers reviewing your evidenced skills. "
                + "A profile above 80% is reviewed first."
        case .closed:
            return "Withdrawn and declined applications will collect here so you can see what to repeat."
        default:
            return "Open a match in Explore and Easy Apply sends the profile you built during onboarding."
        }
    }
}

struct ApplicationDetailView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    var application: Application

    @State private var confirmWithdraw = false

    private var role: Internship? { store.internship(for: application.internshipID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                stageCard
                nextActionCard
                timelineCard
                if let role { roleCard(role) }
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .padding(.top, MCRITheme.Spacing.s3)
            .padding(.bottom, MCRITheme.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .mcriScreen(title: "Application")
        .confirmationDialog("Withdraw this application?", isPresented: $confirmWithdraw, titleVisibility: .visible) {
            Button("Withdraw", role: .destructive) { store.withdraw(application) }
            Button("Keep it open", role: .cancel) {}
        } message: {
            Text("The employer sees the withdrawal immediately. You can apply again while the role is open.")
        }
    }

    private var stageCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: role?.companyInitials ?? "?", size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(role?.title ?? "Role closed")
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text(role?.companyName ?? "")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }
                    Spacer()
                    MCRIStatusBadge(application.stage.label, symbol: application.stage.symbol,
                                    tone: application.stage.tone)
                }

                if !application.isClosed {
                    MCRIStageStepper(stages: ApplicationStage.trackerStages,
                                     currentIndex: application.stage.trackerIndex ?? 0)
                }

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                MetaRow(items: [
                    (icon: "paperplane.fill", text: "Sent \(application.submittedDate.formatted(.relative(presentation: .named)))"),
                    (icon: "bell.fill", text: "Updated \(application.lastUpdateDate.formatted(.relative(presentation: .named)))"),
                ])
            }
        }
    }

    @ViewBuilder private var nextActionCard: some View {
        if let next = application.nextAction {
            MCRICard(edge: .orange) {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                    Text("Your next move").mcriLabelStyle()
                    Text(next)
                        .font(.mcriSection)
                        .foregroundStyle(MCRITheme.textPrimary)
                    if let interview = application.interviewDate {
                        Text("Booked for \(interview.formatted(date: .complete, time: .shortened))")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }
                    if let note = application.employerNote {
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(MCRITheme.secondaryAction)
                            Text(note)
                                .font(.mcriCaption)
                                .italic()
                                .foregroundStyle(MCRITheme.textSecondary)
                        }
                        .padding(.top, MCRITheme.Spacing.s1)
                    }
                }
            }
        } else {
            MCRICard {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                    Text(application.isClosed ? "Application closed" : "Waiting on the employer")
                        .mcriLabelStyle()
                    Text(application.isClosed
                         ? "Nothing more is required from you. Apply to another role to keep momentum."
                         : "We alert you the moment the hiring team updates this stage.")
                        .font(.mcriBody)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var timelineCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "History")
                MCRIApplicationTimeline(events: application.timeline)
            }
        }
    }

    private func roleCard(_ role: Internship) -> some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRISecondaryButton(title: "Open the role", symbol: "arrow.up.right.square") {
                router.go(.internship(role.id))
            }
            if !application.isClosed {
                MCRISecondaryButton(title: "Withdraw application", symbol: "xmark",
                                    isDestructive: true) {
                    confirmWithdraw = true
                }
            }
        }
    }
}

private struct ApplicationsViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { ApplicationsView() }
}
}

private struct ApplicationsViewPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { ApplicationDetailView(application: SampleData.applications[0]) }
}
}
