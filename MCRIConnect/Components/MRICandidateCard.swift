import SwiftUI

/// A student as the hiring team sees them: fit score, the evidence behind it, and
/// the one action that moves them to the next stage.
struct MCRICandidateCard: View {
    var candidate: Candidate
    var internshipTitle: String? = nil
    var onSelect: () -> Void
    var onAdvance: (() -> Void)? = nil
    var onMessage: (() -> Void)? = nil

    var body: some View {
        MCRICard(edge: candidate.isTopPick ? .orange : .none, padding: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: candidate.initials, size: 42,
                           imageURL: mcriAvatarURL(candidate.student.avatarPath), isCircle: true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(candidate.name)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                            .accessibilityAddTraits(.isButton)
                        Text(internshipTitle ?? "\(candidate.student.programme) · \(candidate.student.year)")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    VStack(alignment: .trailing, spacing: 4) {
                        MCRIMatchRing(score: candidate.match, size: 38, lineWidth: 4)
                        MCRIStatusBadge(candidate.status.label, symbol: candidate.status.symbol,
                                        tone: candidate.status.tone)
                    }
                }

                Text(candidate.evidence)
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: MCRITheme.Spacing.s2) {
                    ForEach(candidate.topSkills, id: \.self) { skill in
                        MCRISkillChip(name: skill)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: MCRITheme.Spacing.s2) {
                    if let onMessage {
                        MCRISecondaryButton(title: "Message", symbol: "bubble.left",
                                            fullWidth: false, compact: true, action: onMessage)
                    }
                    Spacer(minLength: 0)
                    if let onAdvance {
                        MCRIButton(title: nextStageTitle, symbol: "arrow.right.circle.fill",
                                   fullWidth: false, action: onAdvance)
                    }
                }
            }
        }
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(candidate.name), \(candidate.match) percent match, \(candidate.status.label)")
    }

    private var nextStage: ApplicationStage? {
        switch candidate.status {
        case .submitted: return .underReview
        case .underReview: return .shortlisted
        case .shortlisted: return .interviewScheduled
        case .interviewScheduled: return .offered
        case .offered, .declined: return nil
        }
    }

    private var nextStageTitle: String {
        switch nextStage {
        case .shortlisted: return "Shortlist"
        case .interviewScheduled: return "Interview"
        case .offered: return "Offer"
        default: return "Review"
        }
    }
}

private struct MRICandidateCardPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRICandidateCard") {
        MCRICandidateCard(candidate: SampleData.candidate(SampleData.alex,
                                                          internship: SampleData.productDesignIntern,
                                                          status: .interviewScheduled),
                          onSelect: { }, onAdvance: { }, onMessage: { })
        MCRICandidateCard(candidate: MCRIPreview.candidate, onSelect: { })
        MCRICandidateCard(candidate: SampleData.candidate(SampleData.maya,
                                                          internship: SampleData.dataAnalystIntern,
                                                          status: .shortlisted),
                          internshipTitle: "Data Analyst Intern",
                          onSelect: { }, onAdvance: { })
    }
}
}

private struct MRICandidateCardPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Narrowest iPhone", width: MCRIPhoneWidth.small) {
        MCRICandidateCard(candidate: MCRIPreview.candidate,
                          onSelect: { }, onAdvance: { }, onMessage: { })
    }
}
}
