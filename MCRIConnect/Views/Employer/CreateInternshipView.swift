import SwiftUI

/// Posting a role is the only place an employer writes to the matching engine, so
/// the form demands the same evidence the students are asked for.
struct CreateInternshipView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: CreateInternshipViewModel

    @State private var blocker: String?

    init(role: Internship? = nil) {
        _viewModel = StateObject(wrappedValue: CreateInternshipViewModel(editing: role))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: MCRITheme.Spacing.s4) {
                    companyStrip

                    stepContent
                }
                .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                .padding(.top, MCRITheme.Spacing.s3)
                .padding(.bottom, MCRITheme.Spacing.s6)
            }
            .scrollIndicators(.hidden)

            footer
        }
        .mcriScreen(title: viewModel.isEditing ? "Edit role" : "Post a role", hidesTitle: false)
        .background(MCRITheme.background.ignoresSafeArea())
    }

    /// The publishing account, shown so the employer never mistakes a role for a personal post.
    private var companyStrip: some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            MCRILogoTile(initials: store.currentCompany?.initials ?? "?", size: 34,
                         imageURL: mcriLogoURL(store.currentCompany?.logoPath))
            VStack(alignment: .leading, spacing: 1) {
                Text(store.currentCompany?.name ?? "No company on this account")
                    .font(.mcriCaption.weight(.semibold))
                    .foregroundStyle(MCRITheme.textPrimary)
                Text(store.currentCompany.map { $0.isVerified ? "Verified employer" : "Awaiting verification" }
                     ?? "Add your company on the Company tab")
                    .font(.mcriCaption2)
                    .foregroundStyle(store.currentCompany?.isVerified == true
                                     ? MCRITheme.positive : MCRITheme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(MCRITheme.Spacing.s3)
        .background(MCRITheme.sunken, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control,
                                                            style: .continuous))
    }

    private var header: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            MCRIStepIndicator(steps: viewModel.steps, index: viewModel.step)
            MCRIProgressSummary(value: viewModel.progress, caption: "Detail students will match against")
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.top, MCRITheme.Spacing.s2)
        .padding(.bottom, MCRITheme.Spacing.s3)
        .background(MCRITheme.background)
    }

    @ViewBuilder private var stepContent: some View {
        switch viewModel.step {
        case 0: roleStep
        case 1: workStep
        case 2: termsStep
        default: reviewStep
        }
    }

    private var roleStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            MCRIField(label: "Role title", placeholder: "Product Design Intern",
                      text: $viewModel.title, autocapitalization: .sentences)
            MCRIField(label: "Location", placeholder: "Cape Town or Remote · South Africa",
                      text: $viewModel.location, autocapitalization: .sentences)

            MCRISegmentPicker(title: "Work mode", options: WorkMode.allCases,
                              selection: $viewModel.workMode, label: { $0.label })

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Text("Practice area").mcriLabelStyle()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCRITheme.Spacing.s2) {
                        ForEach(SkillCategory.allCases) { category in
                            MCRIFilterChip(title: category.label, symbol: category.symbol,
                                           isSelected: viewModel.category == category) {
                                if viewModel.category != category {
                                    viewModel.category = category
                                    viewModel.requiredSkills = []
                                }
                            }
                        }
                    }
                }
                .frame(height: MCRITheme.Metrics.minTapTarget)
            }
        }
    }

    private var workStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            MCRITextArea(label: "What the intern actually does",
                         placeholder: "Own one surface end to end with a senior reviewer…",
                         text: $viewModel.summary, minLines: 4, counter: 400)

            MCRITextArea(label: "Responsibilities (one per line)",
                         placeholder: "Run two user interviews a week\nMaintain the shared component library",
                         text: $viewModel.responsibilitiesText, minLines: 3)

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Text("Required skills · \(viewModel.requiredSkills.count)/6").mcriLabelStyle()
                FlowingChips {
                    ForEach(viewModel.skillCandidates, id: \.self) { skill in
                        MCRIFilterChip(title: skill,
                                       isSelected: viewModel.contains(skill)) {
                            viewModel.toggle(skill)
                        }
                    }
                }
                Text("Only skills a student can evidence. The match score reads this list.")
                    .font(.mcriCaption2)
                    .foregroundStyle(MCRITheme.textTertiary)
            }

            MCRIField(label: "Career interests (comma separated)", placeholder: "Product Design, UX Research",
                      text: $viewModel.interestsText, autocapitalization: .sentences)
        }
    }

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            durationRow

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Toggle(isOn: $viewModel.isPaid) {
                    Text("Paid placement").font(.mcriCaption).foregroundStyle(MCRITheme.textPrimary)
                }
                .tint(MCRITheme.primaryAction)
                .frame(minHeight: MCRITheme.Metrics.minTapTarget)

                if viewModel.isPaid {
                    MCRIField(label: "Stipend", placeholder: "R15 000 / month", text: $viewModel.compensation)
                } else {
                    Text("Unpaid roles are flagged to programme managers before they go live.")
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                Toggle(isOn: $viewModel.easyApply) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Easy Apply").font(.mcriCaption).foregroundStyle(MCRITheme.textPrimary)
                        Text("Students send their profile without re-uploading a CV")
                            .font(.mcriCaption2).foregroundStyle(MCRITheme.textTertiary)
                    }
                }
                .tint(MCRITheme.primaryAction)
                .frame(minHeight: MCRITheme.Metrics.minTapTarget)
            }
        }
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
            Text("Duration").mcriLabelStyle()
            HStack(spacing: MCRITheme.Spacing.s3) {
                stepButton(symbol: "minus", action: { viewModel.durationWeeks = max(4, viewModel.durationWeeks - 2) })
                VStack(spacing: 1) {
                    Text("\(viewModel.durationWeeks)")
                        .font(.mcriNumeric)
                        .monospacedDigit()
                        .foregroundStyle(MCRITheme.textPrimary)
                    Text("weeks")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                stepButton(symbol: "plus", action: { viewModel.durationWeeks = min(26, viewModel.durationWeeks + 2) })
            }
            .padding(MCRITheme.Spacing.s2)
            .background(MCRITheme.sunken, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control,
                                                              style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Duration \(viewModel.durationWeeks) weeks")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: viewModel.durationWeeks = min(26, viewModel.durationWeeks + 2)
            case .decrement: viewModel.durationWeeks = max(4, viewModel.durationWeeks - 2)
            @unknown default: break
            }
        }
    }

    private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MCRITheme.secondaryAction)
                .frame(width: MCRITheme.Metrics.minTapTarget, height: MCRITheme.Metrics.minTapTarget)
                .background(MCRITheme.blueTint, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.chip,
                                                                     style: .continuous))
        }
        .buttonStyle(MCRIPressStyle())
        .accessibilityLabel(symbol == "plus" ? "Add two weeks" : "Remove two weeks")
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            MCRISectionHeader(title: "Review",
                              subtitle: "This is exactly what students see")
            MCRICard(edge: .orange) {
                VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                    HStack(spacing: MCRITheme.Spacing.s3) {
                        MCRILogoTile(initials: store.currentCompany?.initials ?? "?", size: 44,
                                     imageURL: mcriLogoURL(store.currentCompany?.logoPath))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.title.isEmpty ? "Untitled role" : viewModel.title)
                                .font(.mcriCardTitle)
                                .foregroundStyle(MCRITheme.textPrimary)
                            Text("\(store.currentCompany?.name ?? "Your company") · \(viewModel.location.isEmpty ? "Location needed" : viewModel.location)")
                                .font(.mcriFootnote)
                                .foregroundStyle(MCRITheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    MetaRow(items: [
                        (icon: viewModel.workMode.symbol, text: viewModel.workMode.label),
                        (icon: "clock", text: "\(viewModel.durationWeeks) weeks"),
                        (icon: "banknote", text: viewModel.isPaid ? viewModel.compensation : "Unpaid"),
                    ])

                    Text(viewModel.summary.isEmpty ? "Add a description on step 2." : viewModel.summary)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowingChips {
                        ForEach(viewModel.requiredSkills, id: \.self) { skill in
                            MCRISkillChip(name: skill)
                        }
                    }

                    HStack(spacing: MCRITheme.Spacing.s2) {
                        if viewModel.easyApply {
                            MCRIStatusBadge("Easy Apply", symbol: "bolt.fill", tone: .attention)
                        }
                        MCRIStatusBadge(viewModel.isEditing
                                        ? "Closes \(viewModel.closingDate.formatted(date: .abbreviated, time: .omitted))"
                                        : "Closes in \(viewModel.closesInDays) days",
                                        symbol: "calendar", tone: .neutral)
                        Spacer(minLength: 0)
                    }
                }
            }

            MCRIProgressCard(title: "Profile detail", value: viewModel.progress,
                             caption: "Roles under 70% get fewer matched students",
                             symbol: "exclamationmark.circle.fill",
                             gaps: reviewGaps)
        }
    }

    private var reviewGaps: [String] {
        var gaps: [String] = []
        if viewModel.summary.count < 120 { gaps.append("Description is short — students skip thin roles") }
        if viewModel.requiredSkills.count < 3 { gaps.append("Add a third required skill for fairer matching") }
        if viewModel.careerInterests.isEmpty { gaps.append("No career interests: interest score stays neutral") }
        if viewModel.responsibilities.count < 3 { gaps.append("List a third responsibility") }
        return gaps
    }

    private var footer: some View {
        VStack(spacing: MCRITheme.Spacing.s2) {
            if let blocker {
                HStack(spacing: MCRITheme.Spacing.s2) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                    Text(blocker).font(.mcriCaption2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(MCRITheme.blocked)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: MCRITheme.Spacing.s2) {
                if viewModel.step > 0 {
                    MCRISecondaryButton(title: "Back", symbol: "chevron.left", fullWidth: false) {
                        blocker = nil
                        viewModel.back()
                    }
                }
                Spacer(minLength: 0)
                MCRIButton(title: viewModel.isLastStep
                                ? (viewModel.isEditing ? "Save changes" : "Publish role")
                                : "Continue",
                           symbol: viewModel.isLastStep
                                ? (viewModel.isEditing ? "checkmark" : "paperplane.fill")
                                : "arrow.right",
                           fullWidth: false) {
                    submit()
                }
            }
        }
        .padding(.horizontal, MCRITheme.Spacing.screenMargin)
        .padding(.vertical, MCRITheme.Spacing.s3)
        .background(MCRITheme.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(MCRITheme.hairline).frame(height: 1) }
    }

    private func submit() {
        switch viewModel.submit(store: store) {
        case .advanced:
            blocker = nil
        case .blocked(let message):
            blocker = message
        case .published(let role):
            router.popToRoot()
            router.select(tab: 1)
            store.toast = .success("Role live", "\(role.title) is visible to matched students.")
        case .updated(let role):
            router.pop()
            store.toast = .success("Role updated", "\(role.title) now carries the new detail.")
        }
    }
}

/// The thin progress bar above the form: same geometry as the score bars, but
/// reading out completion rather than fit.
private struct MCRIProgressSummary: View {
    var value: Int
    var caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(caption).mcriLabelStyle()
                Spacer()
                Text("\(value)%")
                    .font(.mcriCaption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(MCRITheme.tint(for: value))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MCRITheme.surfaceHi)
                    Capsule()
                        .fill(MCRITheme.tint(for: value))
                        .frame(width: max(6, proxy.size.width * CGFloat(value) / 100))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) \(value) percent complete")
    }
}

private struct CreateInternshipViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewScreen(signedInAs: .employer) { CreateInternshipView() }
}
}
