import SwiftUI

/// The explainable-match screen: the score first, then the evidence behind it,
/// then the honest gap and the sticky apply bar.
struct InternshipDetailView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: InternshipDetailViewModel

    init(role: Internship) {
        _viewModel = StateObject(wrappedValue: InternshipDetailViewModel(role))
    }

    private var internship: Internship { viewModel.internship }

    private var isSaved: Bool { store.savedInternshipIDs.contains(internship.id) }

    private var applicantLine: String {
        if viewModel.applicantsAhead > 0 {
            return "\(internship.applicants) applicants · you are in the top \(viewModel.result?.percentile ?? 0)%"
        }
        return "\(internship.applicants) applicants · be the first to apply"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                header
                matchCard
                signalsCard
                gapCard
                detailCard
                responsibilitiesCard
                skillsCard
                similarCard
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .padding(.top, MCRITheme.Spacing.s3)
            .padding(.bottom, MCRITheme.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .mcriScreen(title: internship.companyName)
        .safeAreaInset(edge: .bottom) { applyBar }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
            MCRILogoTile(initials: internship.companyInitials, size: 52,
                       imageURL: mcriLogoURL(internship.companyLogoPath))

            VStack(alignment: .leading, spacing: 3) {
                Text(internship.title)
                    .font(.mcriTitle)
                    .foregroundStyle(MCRITheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(internship.companyName) · \(internship.location)")
                    .font(.mcriCaption)
                    .foregroundStyle(MCRITheme.textSecondary)
            }

            Spacer(minLength: MCRITheme.Spacing.s2)

            Button {
                viewModel.toggleSave()
            } label: {
                Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.isSaved ? MCRITheme.primaryAction : MCRITheme.textTertiary)
                    .frame(width: MCRITheme.Metrics.minTapTarget,
                           height: MCRITheme.Metrics.minTapTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(viewModel.isSaved ? "Remove saved role" : "Save this role")
        }
    }

    private var matchCard: some View {
        MCRICard(isHighlighted: viewModel.score >= 90) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                if let result = viewModel.result {
                    MCRIMatchScoreView(result: result)
                }

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                HStack(spacing: MCRITheme.Spacing.s3) {
                    fact(symbol: "clock.fill", value: internship.durationLabel, label: "duration")
                    fact(symbol: "banknote", value: internship.compensation, label: "stipend")
                    fact(symbol: "person.2.fill", value: "\(internship.applicants)", label: "applicants")
                }
            }
        }
    }

    private func fact(symbol: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MCRITheme.secondaryAction)
                Text(value)
                    .font(.mcriCaption.weight(.bold))
                    .foregroundStyle(MCRITheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var signalsCard: some View {
        Group {
            if !viewModel.signals.isEmpty {
                MCRICard {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                        MCRISectionHeader(title: "Why this scores \(viewModel.score)%")
                        ForEach(viewModel.signals) { signal in
                            HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                                Image(systemName: signal.symbol)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(MCRITheme.secondaryAction)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(signal.title)
                                        .font(.mcriCaption.weight(.semibold))
                                        .foregroundStyle(MCRITheme.textPrimary)
                                    Text(signal.detail)
                                        .font(.mcriFootnote)
                                        .foregroundStyle(MCRITheme.textTertiary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var gapCard: some View {
        if let gap = viewModel.gaps.first {
            MCRICard(edge: .orange, padding: MCRITheme.Spacing.s4) {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(MCRITheme.primaryAction)
                        Text("The honest gap")
                            .font(.mcriCaption2.weight(.bold))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .foregroundStyle(MCRITheme.primaryAction)
                    }

                    Text(gap.action)
                        .font(.mcriBody)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.missingSkills.isEmpty {
                        Text("Nothing in this role is missing from your profile — the gap is evidence, "
                             + "not skills.")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textTertiary)
                    } else {
                        FlowingChips {
                            ForEach(viewModel.missingSkills, id: \.self) { skill in
                                MCRISkillChip(name: skill, tint: MCRITheme.primaryAction)
                            }
                        }
                    }

                    MCRISecondaryButton(title: "Close this gap (+\(gap.lift)%)", symbol: "arrow.up.right",
                                        fullWidth: false, compact: true) {
                        router.go(.skillPicker)
                    }
                }
            }
        }
    }

    private var detailCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "The role")
                Text(internship.description)
                    .font(.mcriBody)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                MetaRow(items: [
                    (icon: internship.workMode.symbol, text: internship.workMode.label),
                    (icon: "calendar", text: "Closes \(internship.deadlineLabel)"),
                ])
            }
        }
    }

    private var responsibilitiesCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "What you will own")
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                    ForEach(internship.responsibilities, id: \.self) { item in
                        HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                            Image(systemName: "circlebadge.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(MCRITheme.secondaryAction)
                                .padding(.top, 6)
                            Text(item)
                                .font(.mcriCaption)
                                .foregroundStyle(MCRITheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Rectangle().fill(MCRITheme.divider).frame(height: 1)

                MetaRow(items: [(icon: "building.2.fill", text: "Team of \(internship.teamSize)")])
            }
        }
    }

    private var skillsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Skills this role asks for",
                                  subtitle: "Blue means your profile already proves it")
                FlowingChips {
                    ForEach(internship.requiredSkills, id: \.self) { skill in
                        let matched = viewModel.matchedSkills.contains(skill)
                        MCRISkillChip(name: skill,
                                      dots: matched ? 3 : 0,
                                      tint: matched ? MCRITheme.secondaryAction : MCRITheme.placeholder)
                            .foregroundStyle(matched ? MCRITheme.textPrimary : MCRITheme.textTertiary)
                    }
                }
                if !internship.preferredSkills.isEmpty {
                    Text("Nice to have: \(internship.preferredSkills.joined(separator: ", "))")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder private var similarCard: some View {
        if !viewModel.similarRoles.isEmpty {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Also worth applying to")
                ForEach(viewModel.similarRoles) { role in
                    MCRIInternshipCard(role: role,
                                       isSaved: store.savedInternshipIDs.contains(role.id),
                                       showsApply: false) {
                        router.go(.internship(role.id))
                    } onSave: {
                        store.toggleSave(role.internship)
                    }
                }
            }
        }
    }

    private var applyBar: some View {
        VStack(spacing: MCRITheme.Spacing.s2) {
            if viewModel.hasApplied, let application = viewModel.application {
                MCRISecondaryButton(title: "Open your application", symbol: application.stage.symbol) {
                    router.go(.application(application.id))
                }
                Text("You applied \(application.submittedDate.formatted(.relative(presentation: .named)))")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
            } else {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    MCRISecondaryButton(title: isSaved ? "Saved" : "Save",
                                        symbol: isSaved ? "bookmark.fill" : "bookmark",
                                        fullWidth: false) {
                        store.toggleSave(internship)
                    }
                    .fixedSize()

                    MCRIButton(title: internship.easyApply ? "Easy Apply" : "Apply with CV",
                               symbol: "paperplane.fill") {
                        viewModel.apply()
                    }
                }
                Text(applicantLine)
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.top, MCRITheme.Spacing.s3)
        .padding(.bottom, MCRITheme.Spacing.s2)
        .background(MCRITheme.sunken.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(MCRITheme.hairline).frame(height: 1) }
    }
}

private struct InternshipDetailViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { InternshipDetailView(role: SampleData.productDesignIntern) }
}
}
