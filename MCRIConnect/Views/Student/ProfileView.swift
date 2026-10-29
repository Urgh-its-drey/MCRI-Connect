import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        Group {
            if let student = viewModel.student {
                content(student)
            } else {
                MCRILoadingView(message: "Loading your profile")
            }
        }
        .mcriScreen(title: "Profile")
    }

    private func content(_ student: Student) -> some View {
        MCRIPage {
            identityCard(student)
            readinessCard
            skillsCard(student)
            interestsCard
            logisticsCard(student)
            projectsCard(student)
            documentsCard(student)

            MCRISecondaryButton(title: "Sign out", symbol: "rectangle.portrait.and.arrow.right",
                                isDestructive: true) {
                auth.signOut()
            }
            .padding(.top, MCRITheme.Spacing.s2)
        }
    }

    private func identityCard(_ student: Student) -> some View {
        MCRIScreenHero {
            HStack(spacing: MCRITheme.Spacing.s4) {
                MCRILogoTile(initials: student.initials, size: 62)

                VStack(alignment: .leading, spacing: 3) {
                    Text(student.fullName)
                        .font(.mcriTitle)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(student.programme) · \(student.year)")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    MetaRow(items: [(icon: "mappin", text: student.city)])
                }

                Spacer(minLength: 0)

                Button {
                    viewModel.beginNameEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MCRITheme.textSecondary)
                        .frame(width: MCRITheme.Metrics.minTapTarget,
                               height: MCRITheme.Metrics.minTapTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Edit your name")
            }

            Text(student.bio)
                .font(.mcriCaption)
                .foregroundStyle(MCRITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .alert("Your name", isPresented: $viewModel.editName) {
            TextField("Full name", text: $viewModel.nameDraft)
                .textInputAutocapitalization(.words)
            Button("Save") { viewModel.commitName() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Employers see this on every application you send.")
        }
    }

    private var readinessCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Readiness",
                                  subtitle: "\(viewModel.matchedRolesLifted) role\(viewModel.matchedRolesLifted == 1 ? "" : "s") score 70% or higher for you")

                HStack(spacing: MCRITheme.Spacing.s4) {
                    MCRIMatchRing(score: viewModel.strength, size: 74, lineWidth: 7, caption: "complete")

                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        Text(viewModel.readiness.label)
                            .font(.mcriSection)
                            .foregroundStyle(MCRITheme.tint(for: viewModel.strength))

                        if viewModel.missingSections.isEmpty {
                            Text("Nothing outstanding. Your profile answers everything the "
                                 + "match engine asks.")
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            ForEach(viewModel.missingSections.prefix(2), id: \.self) { gap in
                                HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                                    Image(systemName: "circle.dashed")
                                        .font(.caption2)
                                        .foregroundStyle(MCRITheme.primaryAction)
                                        .padding(.top, 2)
                                    Text(gap)
                                        .font(.mcriFootnote)
                                        .foregroundStyle(MCRITheme.textSecondary)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func skillsCard(_ student: Student) -> some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Skills with evidence") {
                    MCRILinkButton(title: "Add", symbol: "plus") { router.go(.skillPicker) }
                }

                if student.skills.isEmpty {
                    Text("Add the tools you have used on a real project.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                } else {
                    ForEach(student.skills) { skill in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                                MCRISkillChip(name: skill.name, dots: skill.proficiency.dots,
                                              tint: MCRITheme.secondaryAction)
                                Spacer()
                                Text(skill.category.label)
                                    .font(.mcriCaption2)
                                    .foregroundStyle(MCRITheme.textTertiary)
                                Button {
                                    viewModel.remove(skill)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13))
                                        .foregroundStyle(MCRITheme.textTertiary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Remove \(skill.name)")
                            }
                            if let evidence = skill.evidence {
                                Text(evidence)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if skill.id != student.skills.last?.id {
                            Rectangle().fill(MCRITheme.divider).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private var interestsCard: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Career interests")
                FlowingChips {
                    ForEach(OnboardingViewModel.interestCatalogue, id: \.self) { interest in
                        MCRIFilterChip(title: interest,
                                       isSelected: viewModel.interests.contains(interest)) {
                            viewModel.toggleInterest(interest)
                        }
                    }
                }
            }
        }
    }

    private func logisticsCard(_ student: Student) -> some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRICard {
                MCRISegmentPicker(title: "How you want to work", options: WorkMode.allCases,
                                  selection: Binding(get: { student.workMode },
                                                     set: { viewModel.setWorkMode($0) }),
                                  label: { $0.label }, symbol: { $0.symbol })
            }
            MCRICard {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                    Text("Availability").mcriLabelStyle()
                    FlowingChips {
                        ForEach(Availability.allCases) { option in
                            MCRIFilterChip(title: option.rawValue,
                                           symbol: "calendar",
                                           isSelected: student.availability == option) {
                                viewModel.setAvailability(option)
                            }
                        }
                    }
                }
            }
        }
    }

    private func projectsCard(_ student: Student) -> some View {
        Group {
            if !student.projects.isEmpty {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    MCRISectionHeader(title: "Projects")
                    ForEach(student.projects) { project in
                        MCRICard(padding: MCRITheme.Spacing.s4) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(project.title)
                                        .font(.mcriCardTitle)
                                        .foregroundStyle(MCRITheme.textPrimary)
                                    Spacer()
                                    Text("Year \(project.year)")
                                        .font(.mcriCaption2)
                                        .foregroundStyle(MCRITheme.textTertiary)
                                }
                                Text(project.summary)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let outcome = project.outcome {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.caption2)
                                            .foregroundStyle(MCRITheme.primaryAction)
                                            .padding(.top, 2)
                                        Text(outcome)
                                            .font(.mcriCaption.weight(.semibold))
                                            .foregroundStyle(MCRITheme.primaryAction)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func documentsCard(_ student: Student) -> some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                MCRISectionHeader(title: "Documents")

                HStack(spacing: MCRITheme.Spacing.s3) {
                    Image(systemName: student.cvFileName == nil ? "doc.badge.plus" : "doc.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(student.cvFileName == nil
                                         ? MCRITheme.primaryAction : MCRITheme.secondaryAction)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(student.cvFileName ?? "No CV attached")
                            .font(.mcriCaption.weight(.semibold))
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("Employers open it before they shortlist")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                    Spacer()
                    MCRISecondaryButton(title: student.cvFileName == nil ? "Attach" : "Replace",
                                        fullWidth: false, compact: true,
                                        action: viewModel.uploadCV)
                }

                if !student.certificates.isEmpty {
                    Rectangle().fill(MCRITheme.divider).frame(height: 1)
                    FlowingChips {
                        ForEach(student.certificates) { certificate in
                            MCRISkillChip(name: "\(certificate.name) · \(certificate.year)",
                                          tint: MCRITheme.primaryAction)
                        }
                    }
                }
            }
        }
    }
}

/// The gap-closing sheet reached from a match screen: pick a skill, prove it, done.
struct SkillPickerView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router

    @State private var query = ""
    @State private var selected: Skill?
    @State private var evidence = ""

    private var options: [Skill] {
        guard !query.isEmpty else { return SampleData.skillCatalogue }
        return SampleData.skillCatalogue.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            MCRISearchBar(placeholder: "Search the skill catalogue", text: $query)
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.vertical, MCRITheme.Spacing.s3)
                .background(MCRITheme.background)

            ScrollView {
                VStack(spacing: MCRITheme.Spacing.s3) {
                    FlowingChips {
                        ForEach(options) { skill in
                            MCRIFilterChip(title: skill.name,
                                           symbol: skill.category.symbol,
                                           isSelected: selected?.id == skill.id) {
                                selected = skill
                            }
                        }
                    }

                    if let skill = selected {
                        MCRICard(edge: .blue) {
                            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                                MCRISectionHeader(title: "Prove \(skill.name)",
                                                  subtitle: skill.category.label)
                                MCRITextArea(label: "Where have you used it?",
                                             placeholder: "Course project, freelance job, or a club you ran",
                                             text: $evidence, minLines: 3, counter: 120)
                                MCRIButton(title: "Add to profile", symbol: "plus",
                                           isDisabled: evidence.trimmingCharacters(in: .whitespaces).count < 8) {
                                    store.addSkill(skill.name, category: skill.category, evidence: evidence)
                                    router.pop()
                                }
                            }
                        }
                    } else {
                        Text("Pick a skill to attach the evidence employers look for.")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, MCRITheme.Spacing.s6)
                    }
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.bottom, MCRITheme.Spacing.s8)
            }
            .scrollIndicators(.hidden)
        }
        .mcriScreen(title: "Add a skill")
        .background(MCRITheme.background.ignoresSafeArea())
    }
}

private struct ProfileViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { ProfileView() }
}
}

private struct ProfileViewPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen { SkillPickerView() }
}
}
