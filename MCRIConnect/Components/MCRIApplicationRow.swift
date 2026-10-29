import SwiftUI

/// One application in the tracker: where it stands, and the single next action.
struct MCRIApplicationRow: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    var application: Application
    var showsStepper: Bool = true

    private var role: Internship? { store.internship(for: application.internshipID) }

    var body: some View {
        MCRICard(edge: application.isClosed ? .red : (application.nextAction == nil ? .none : .orange),
                 padding: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: role?.companyInitials ?? "?", size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(role?.title ?? "Role closed")
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                            .accessibilityAddTraits(.isButton)
                        Text(role?.companyName ?? "")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    MCRIStatusBadge(application.stage.label,
                                    symbol: application.stage.symbol,
                                    tone: application.stage.tone)
                }

                if showsStepper, !application.isClosed {
                    MCRIStageStepper(stages: ApplicationStage.trackerStages,
                                     currentIndex: application.stage.trackerIndex ?? 0)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        if let note = application.employerNote {
                            MetaRow(items: [(icon: "eye.fill", text: note)])
                        }
                        Text("Updated \(application.lastUpdateDate.formatted(.relative(presentation: .named)))")
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                    Spacer(minLength: MCRITheme.Spacing.s2)
                    if let next = application.nextAction {
                        MCRISecondaryButton(title: next, fullWidth: false, compact: true, action: open)
                    }
                }
            }
        }
        .onTapGesture(perform: open)
        .accessibilityElement(children: .contain)
    }

    private var open: () -> Void {
        { router.go(.application(application.id)) }
    }
}

private struct MCRIApplicationRowPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .student) {
        MCRIPage {
            MCRISectionHeader(title: "MCRIApplicationRow")
            ForEach(SampleData.applications) { application in
                MCRIApplicationRow(application: application)
            }
            MCRIApplicationRow(application: SampleData.applications[0], showsStepper: false)
        }
        .mcriScreen()
    }
}
}

private struct MCRIApplicationRowPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .student) {
        MCRIPage {
            ForEach(SampleData.applications) { application in
                MCRIApplicationRow(application: application)
            }
        }
        .mcriScreen()
        .mcriPinned(to: MCRIPhoneWidth.small)
    }
}
}
