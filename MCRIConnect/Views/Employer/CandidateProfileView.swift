import SwiftUI

/// What the hiring team reads before deciding: the fit score with the evidence
/// behind every axis, the profile that produced it, and the stage controls.
struct CandidateProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = EmployerViewModel()

    var candidate: Candidate

    private var student: Student { candidate.student }

    private var role: Internship? {
        store.internship(for: candidate.internshipID)
    }

    private var fit: MatchResult? {
        guard let role else { return nil }
        return MatchEngine.shared.result(for: student, on: role)
    }

    var body: some View {
        MCRIPage {
            header
            fitCard

            MCRISectionHeader(title: "Evidence behind the score")
            signalsCard
            skillCard

            if !student.projects.isEmpty {
                MCRISectionHeader(title: "Projects")
                ForEach(student.projects) { project in
                    projectCard(project)
                }
            }

            logisticsCard
            decisionCard
        }
        .mcriScreen(title: student.firstName)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
    }

    private var header: some View {
        MCRICard(edge: candidate.isTopPick ? .orange : .blue) {
            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                MCRILogoTile(initials: student.initials, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.fullName)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("\(student.programme) · \(student.year)")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        MCRIStatusBadge(candidate.status.label, symbol: candidate.status.symbol,
                                        tone: candidate.status.tone)
                        MCRIStatusBadge(student.availability.rawValue, tone: .neutral)
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: MCRITheme.Spacing.s2)
                MCRIMatchRing(score: candidate.match, size: 62, lineWidth: 5, caption: "fit")
            }
        }
    }

    @ViewBuilder private var fitCard: some View {
        if let fit {
            MCRICard {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                    MCRISectionHeader(title: "Fit",
                                      subtitle: "Skills 40% · Logistics 25% · Interests 20% · Profile 15%")
                    MCRIMatchScoreView(result: fit)
                }
            }
        }
    }

    @ViewBuilder private var signalsCard: some View {
        if let fit, !fit.signals.isEmpty {
            MCRICard {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    ForEach(fit.signals) { signal in
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                            Image(systemName: signal.symbol)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(signal.title)
                                    .font(.mcriCaption.weight(.semibold))
                                    .foregroundStyle(MCRITheme.textPrimary)
                                Text(signal.detail)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    if !fit.missingSkills.isEmpty {
                        Rectangle().fill(MCRITheme.divider).frame(height: 1)
                        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                            Text("Not yet evidenced")
                                .mcriLabelStyle()
                            FlowingChips {
                                ForEach(fit.missingSkills, id: \.self) { skill in
                                    MCRISkillChip(name: skill, tint: MCRITheme.blocked)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var skillCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Skills",
                                  subtitle: "\(student.skills.count) listed · \(student.cvFileName == nil ? "no CV" : "CV on file")")
                ForEach(student.skills) { skill in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: MCRITheme.Spacing.s2) {
                            Image(systemName: skill.category.symbol)
                                .font(.caption2)
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .frame(width: 16)
                            Text(skill.name)
                                .font(.mcriCaption.weight(.semibold))
                                .foregroundStyle(MCRITheme.textPrimary)
                            Spacer(minLength: MCRITheme.Spacing.s2)
                            HStack(spacing: 3) {
                                ForEach(0..<skill.proficiency.dots, id: \.self) { _ in
                                    Circle().fill(MCRITheme.secondaryAction).frame(width: 4, height: 4)
                                }
                            }
                            .accessibilityLabel(skill.proficiency.label)
                        }
                        if let evidence = skill.evidence {
                            Text(evidence)
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textTertiary)
                                .padding(.leading, 22)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, skill.id == student.skills.last?.id ? 0 : MCRITheme.Spacing.s3)

                    if skill.id != student.skills.last?.id {
                        Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    }
                }
            }
        }
    }

    private func projectCard(_ project: Project) -> some View {
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
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(MCRITheme.positive)
                        Text(outcome)
                            .font(.mcriCaption.weight(.medium))
                            .foregroundStyle(MCRITheme.textPrimary)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private var logisticsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Working terms")
                infoRow(symbol: "mappin.and.ellipse", label: "Location", value: student.city)
                infoRow(symbol: student.workMode.symbol, label: "Preferred mode", value: student.workMode.label)
                infoRow(symbol: "calendar", label: "Available", value: student.availability.rawValue)
                if let role {
                    infoRow(symbol: "briefcase", label: "Applied to",
                            value: "\(role.title) · \(role.durationLabel)")
                }
                if let advisor = student.advisor {
                    infoRow(symbol: "person.crop.circle.badge.checkmark", label: "Advisor", value: advisor)
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
        .frame(minHeight: MCRITheme.Spacing.s5)
        .accessibilityElement(children: .combine)
    }

    private var decisionCard: some View {
        MCRICard(edge: .none) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Your call",
                                  subtitle: "The student sees every change here in their tracker")
                Text(candidate.evidence)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                MCRIApplicationTimeline(events: timeline)
            }
        }
    }

    private var timeline: [TimelineEvent] {
        var events = [TimelineEvent(title: "Applied", detail: role?.title, date: SampleData.days(-6))]
        if candidate.status != .submitted {
            events.append(TimelineEvent(title: candidate.status.label, date: SampleData.hours(-18)))
        }
        return events
    }

    private var actionBar: some View {
        HStack(spacing: MCRITheme.Spacing.s2) {
            MCRISecondaryButton(title: "Message", symbol: "bubble.left", fullWidth: false) {
                router.go(.thread(viewModel.message(candidate)))
            }

            Menu {
                ForEach(ApplicationStage.pipelineStages) { stage in
                    Button(stage.label) { viewModel.move(candidate, to: stage) }
                }
                Divider()
                Button("Decline", role: .destructive) { viewModel.move(candidate, to: .declined) }
            } label: {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    Text(candidate.status.nextStageTitle)
                    Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.bold))
                }
                .font(.mcriCardTitle)
                .foregroundStyle(MCRITheme.textOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: MCRITheme.Metrics.controlHeight)
                .background(MCRITheme.primaryAction, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control,
                                                                         style: .continuous))
            }
            .accessibilityLabel("Change stage")
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.vertical, MCRITheme.Spacing.s3)
        .background(MCRITheme.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(MCRITheme.hairline).frame(height: 1) }
    }
}

private extension ApplicationStage {
    var nextStageTitle: String {
        switch self {
        case .submitted: return "Move to review"
        case .underReview: return "Shortlist"
        case .shortlisted: return "Schedule interview"
        case .interviewScheduled: return "Make offer"
        case .offered: return "Offer sent"
        case .declined: return "Reopen"
        }
    }
}

private struct CandidateProfileViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) {
        CandidateProfileView(candidate: SampleData.candidate(SampleData.alex,
                                                            internship: SampleData.productDesignIntern,
                                                            status: .interviewScheduled))
    }
}
}
