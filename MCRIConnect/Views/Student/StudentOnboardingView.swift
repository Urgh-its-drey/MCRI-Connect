import SwiftUI

/// Five short steps that produce the inputs the match engine scores against.
struct StudentOnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s5) {
                    stepCopy
                    stepContent
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.top, MCRITheme.Spacing.s4)
                .padding(.bottom, MCRITheme.Spacing.s8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            footer
        }
        .background(MCRITheme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            if viewModel.step > 0 {
                Button {
                    viewModel.back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MCRITheme.textSecondary)
                        .frame(width: MCRITheme.Metrics.minTapTarget,
                               height: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous step")
            }

            MCRIStepIndicator(steps: OnboardingViewModel.steps, index: viewModel.step)
            Spacer()
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.top, MCRITheme.Spacing.s2)
    }

    @ViewBuilder private var stepCopy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.mcriTitle)
                .foregroundStyle(MCRITheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.mcriBody)
                .foregroundStyle(MCRITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, MCRITheme.Spacing.s2)
    }

    private var title: String {
        switch viewModel.step {
        case 0: return "Who are you?"
        case 1: return "Skills you can prove"
        case 2: return "Where do you want to work?"
        case 3: return "How you work"
        default: return "Your readiness in one look"
        }
    }

    private var subtitle: String {
        switch viewModel.step {
        case 0: return "Employers filter by programme and city first, so this decides what you see."
        case 1: return "Pick what you have actually used on a project. Each one you add lifts your "
            + "skill score on matching roles."
        case 2: return "Interests steer the ranking. They are not a commitment — you can change them anytime."
        case 3: return "Logistics decide whether an offer is even possible for you."
        default: return "This is what the app will show employers. Everything below came from your answers."
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch viewModel.step {
        case 0: identityStep
        case 1: skillsStep
        case 2: interestsStep
        case 3: logisticsStep
        default: reviewStep
        }
    }

    private var identityStep: some View {
        VStack(spacing: MCRITheme.Spacing.s4) {
            MCRIField(label: "Full name", placeholder: "Amahle Dlamini", text: $viewModel.fullName,
                      keyboard: .namePhonePad, autocapitalization: .words)
            MCRIField(label: "Programme", placeholder: "Interaction Design", text: $viewModel.programme,
                      autocapitalization: .words)
            MCRIField(label: "City", placeholder: "Cape Town", text: $viewModel.city,
                      autocapitalization: .words)
            MCRISegmentPicker(title: "Year of study", options: OnboardingViewModel.StudyYear.allCases,
                              selection: $viewModel.year, label: { $0.rawValue })
        }
    }

    private var skillsStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            HStack {
                MCRISectionHeader(title: "Choose at least three")
                Spacer()
                Text("\(viewModel.chosenSkills.count)")
                    .font(.mcriNumeric)
                    .foregroundStyle(viewModel.chosenSkills.count >= 3
                                     ? MCRITheme.primaryAction : MCRITheme.textTertiary)
            }

            ForEach(SkillCategory.allCases) { category in
                let options = viewModel.skillOptions.filter { $0.category == category }
                if !options.isEmpty {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        Text(category.label).mcriLabelStyle()
                        FlowingChips {
                            ForEach(options) { skill in
                                MCRIFilterChip(title: skill.name,
                                               isSelected: viewModel.chosenSkills.contains(skill.name)) {
                                    viewModel.toggleSkill(skill.name)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Text("Career tracks").mcriLabelStyle()
                FlowingChips {
                    ForEach(viewModel.interestCatalogue, id: \.self) { interest in
                        MCRIFilterChip(title: interest,
                                       isSelected: viewModel.chosenInterests.contains(interest)) {
                            viewModel.toggleInterest(interest)
                        }
                    }
                }
            }

            MCRICard {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(MCRITheme.primaryAction)
                    Text("Roles you skip a track for still appear — they just score lower on interests, "
                         + "and the screen tells you why.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var logisticsStep: some View {
        VStack(spacing: MCRITheme.Spacing.s5) {
            MCRISegmentPicker(title: "Preferred work mode", options: WorkMode.allCases,
                              selection: $viewModel.workMode,
                              label: { $0.label }, symbol: { $0.symbol })

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Text("When can you start?").mcriLabelStyle()
                VStack(spacing: MCRITheme.Spacing.s2) {
                    ForEach(Availability.allCases) { option in
                        Button {
                            viewModel.availability = option
                        } label: {
                            HStack(spacing: MCRITheme.Spacing.s3) {
                                Image(systemName: viewModel.availability == option
                                      ? "largecircle.fill.circle" : "circle")
                                    .font(.system(size: 17))
                                    .foregroundStyle(viewModel.availability == option
                                                     ? MCRITheme.primaryAction : MCRITheme.placeholder)
                                Text(option.rawValue)
                                    .font(.mcriBody)
                                    .foregroundStyle(MCRITheme.textPrimary)
                                Spacer()
                            }
                            .frame(minHeight: MCRITheme.Metrics.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.availability == option ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var reviewStep: some View {
        VStack(spacing: MCRITheme.Spacing.s4) {
            MCRICard {
                HStack(spacing: MCRITheme.Spacing.s4) {
                    MCRIMatchRing(score: viewModel.profileStrength, size: 78, lineWidth: 7,
                                  caption: "profile")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile strength")
                            .font(.mcriSection)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text(viewModel.profileStrength >= 80
                             ? "Strong enough that employers can act on it."
                             : "Add a CV and one evidenced project to push past 80.")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }

            Button {
                viewModel.cvUploaded.toggle()
            } label: {
                HStack(spacing: MCRITheme.Spacing.s3) {
                    Image(systemName: viewModel.cvUploaded ? "checkmark.docbase.fill" : "doc.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(viewModel.cvUploaded ? MCRITheme.secondaryAction : MCRITheme.primaryAction)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.cvUploaded ? "cv.pdf attached" : "Attach your CV")
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("Employers open it before shortlisting")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MCRITheme.border)
                }
                .padding(MCRITheme.Spacing.s4)
                .background(MCRITheme.sunken, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control,
                                                                   style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
                    .strokeBorder(MCRITheme.border, lineWidth: 1))
            }
            .buttonStyle(MCRIPressStyle())
            .accessibilityHint("Adds a placeholder CV to your profile")

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                MCRISectionHeader(title: "First matches on this profile")
                ForEach(viewModel.previewMatches(in: store)) { role in
                    MCRICard(padding: MCRITheme.Spacing.s3) {
                        HStack(spacing: MCRITheme.Spacing.s3) {
                            MCRILogoTile(initials: role.internship.companyInitials, size: 36,
                                       imageURL: mcriLogoURL(role.internship.companyLogoPath))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(role.internship.title)
                                    .font(.mcriCaption.weight(.semibold))
                                    .foregroundStyle(MCRITheme.textPrimary)
                                Text(role.internship.companyName)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textTertiary)
                            }
                            Spacer()
                            MCRIMatchRing(score: role.score, size: 34, lineWidth: 3)
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: MCRITheme.Spacing.s2) {
            MCRIButton(title: viewModel.isLastStep ? "Finish setup" : "Continue",
                       symbol: viewModel.isLastStep ? "checkmark" : "arrow.right",
                       isDisabled: !viewModel.canAdvance) {
                if viewModel.isLastStep {
                    viewModel.finish(store: store, auth: auth)
                } else {
                    viewModel.next()
                }
            }
            if viewModel.isLastStep {
                MCRISecondaryButton(title: "Do this later", fullWidth: true, compact: true) {
                    auth.completeOnboarding()
                }
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.bottom, MCRITheme.Spacing.s4)
        .background(MCRITheme.background)
    }
}

private struct StudentOnboardingViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { StudentOnboardingView() }
}
}
