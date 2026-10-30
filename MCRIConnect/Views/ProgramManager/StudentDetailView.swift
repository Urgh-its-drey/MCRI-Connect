import SwiftUI

/// One student, as the programme office reads them: how ready they are, what is missing,
/// everywhere they have applied, and the coach who owns the next step.
struct StudentDetailView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ManagerViewModel()

    var student: Student

    private var applications: [Application] {
        store.applications
            .filter { $0.studentID == student.id }
            .sorted { $0.lastUpdateDate > $1.lastUpdateDate }
    }

    private var placement: Placement? {
        store.placements.first { $0.studentID == student.id }
    }

    private var band: ReadinessBand { student.readiness }

    var body: some View {
        MCRIPage {
            header
            readinessCard
            actionsCard

            if !applications.isEmpty {
                MCRISectionHeader(title: "Applications",
                                  subtitle: "\(applications.filter { !$0.isClosed }.count) live · \(applications.filter(\.isClosed).count) closed")
                ForEach(applications) { application in
                    MCRIApplicationRow(application: application, showsStepper: false)
                }
            }

            MCRISectionHeader(title: "Profile")
            skillsCard
            projectsCard
            termsCard
        }
        .mcriScreen(title: student.firstName, hidesTitle: false)
        .background(MCRITheme.background.ignoresSafeArea())
        .refreshable { await store.load() }
    }

    private var header: some View {
        MCRIScreenHero {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: student.initials, size: 56,
                             imageURL: mcriAvatarURL(student.avatarPath), isCircle: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.fullName)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(student.programme) · \(student.year) · \(student.city)")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        MCRIStatusBadge(band.label, tone: band == .readyToApply ? .positive : .attention)
                        MCRIStatusBadge(student.availability.rawValue, tone: .neutral)
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }

            Text(student.bio)
                .font(.mcriCaption)
                .foregroundStyle(MCRITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var readinessCard: some View {
        MCRICard(edge: band == .readyToApply ? .blue : (band == .notStarted ? .red : .none)) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(spacing: MCRITheme.Spacing.s4) {
                    MCRIMatchRing(score: student.profileStrength, size: 74, lineWidth: 7, caption: "ready")

                    VStack(alignment: .leading, spacing: 3) {
                        Text(band.label)
                            .font(.mcriSection)
                            .foregroundStyle(MCRITheme.tint(for: student.profileStrength))
                        Text(student.advisor.map { "Advisor · \($0)" } ?? "No advisor assigned yet")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                        if let placement {
                            Text("Pipeline · \(placement.stage.label)")
                                .font(.mcriCaption2)
                                .foregroundStyle(MCRITheme.textTertiary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if student.missingSections.isEmpty {
                    Label("Nothing blocks their matches.", systemImage: "checkmark.circle.fill")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.positive)
                } else {
                    Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        Text("Outstanding").mcriLabelStyle()
                        ForEach(student.missingSections, id: \.self) { gap in
                            HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                                Image(systemName: "circle.dashed")
                                    .font(.caption2)
                                    .foregroundStyle(MCRITheme.primaryAction)
                                    .padding(.top, 2)
                                Text(gap)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Next step",
                                  subtitle: "The student sees every message in their inbox")

                if let placement {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        MCRISecondaryButton(title: "Message", symbol: "bubble.left",
                                            fullWidth: false, compact: true) {
                            viewModel.message(student, from: auth.session.displayName)
                        }
                        if let next = viewModel.stageAfter(placement.stage) {
                            MCRIButton(title: "Move to \(next.label)", symbol: "arrow.right",
                                       fullWidth: false) {
                                viewModel.advance(placement)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        MCRISecondaryButton(title: "Message", symbol: "bubble.left",
                                            fullWidth: false, compact: true) {
                            viewModel.message(student, from: auth.session.displayName)
                        }
                        Spacer(minLength: 0)
                        Text("Not in the pipeline yet")
                            .font(.mcriCaption2)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                }
            }
        }
    }

    private var skillsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Skills",
                                  subtitle: "\(student.skills.count) listed · \(student.cvFileName == nil ? "no CV" : "CV on file")")

                if student.skills.isEmpty {
                    Text("No skills evidenced yet, so their fit score cannot rise.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                } else {
                    ForEach(student.skills) { skill in
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                            Image(systemName: skill.category.symbol)
                                .font(.caption2)
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(skill.name)
                                    .font(.mcriCaption.weight(.semibold))
                                    .foregroundStyle(MCRITheme.textPrimary)
                                if let evidence = skill.evidence {
                                    Text(evidence)
                                        .font(.mcriFootnote)
                                        .foregroundStyle(MCRITheme.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                            Text(skill.proficiency.label)
                                .font(.mcriCaption2)
                                .foregroundStyle(MCRITheme.textTertiary)
                        }
                        if skill.id != student.skills.last?.id {
                            Rectangle().fill(MCRITheme.divider).frame(height: 1)
                        }
                    }
                }

                if !student.interests.isEmpty {
                    Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    FlowingChips {
                        ForEach(student.interests, id: \.self) { interest in
                            MCRISkillChip(name: interest, tint: MCRITheme.primaryAction)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var projectsCard: some View {
        if !student.projects.isEmpty {
            MCRISectionHeader(title: "Projects")
            ForEach(student.projects) { project in
                MCRICard {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(project.title)
                                .font(.mcriCardTitle)
                                .foregroundStyle(MCRITheme.textPrimary)
                            Spacer()
                            Text(String(project.year))
                                .font(.mcriCaption2)
                                .foregroundStyle(MCRITheme.textTertiary)
                        }
                        Text(project.summary)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let outcome = project.outcome {
                            Label(outcome, systemImage: "chart.line.uptrend.xyaxis")
                                .font(.mcriCaption.weight(.medium))
                                .foregroundStyle(MCRITheme.primaryAction)
                        }
                    }
                }
            }
        }
    }

    private var termsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Working terms")
                infoRow(symbol: "mappin.and.ellipse", label: "Based in", value: student.city)
                infoRow(symbol: student.workMode.symbol, label: "Mode", value: student.workMode.label)
                infoRow(symbol: "calendar", label: "Available", value: student.availability.rawValue)
                infoRow(symbol: "doc.fill", label: "CV", value: student.cvFileName ?? "Not attached")
                if let placement {
                    infoRow(symbol: "briefcase", label: "Placed into",
                            value: placement.internshipTitle ?? "Awaiting a role")
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
                .foregroundStyle(value == "Not attached" ? MCRITheme.blocked : MCRITheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
        .accessibilityElement(children: .combine)
    }
}

private struct StudentDetailViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .programManager) { StudentDetailView(student: SampleData.alex) }
}
}
