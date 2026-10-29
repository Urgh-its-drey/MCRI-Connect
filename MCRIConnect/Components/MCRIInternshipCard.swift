import SwiftUI

/// Company monogram tile: every employer mark in the app is drawn the same way.
struct MCRILogoTile: View {
    var initials: String
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MCRITheme.Radius.mark, style: .continuous)
                .fill(MCRITheme.raised)
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(MCRITheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.mark, style: .continuous)
            .strokeBorder(MCRITheme.hairline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// A search-result row: identity, logistics, one fit number, and a save control.
struct MCRIInternshipCard: View {
    var role: MatchedRole
    var isSaved: Bool
    var showsApply: Bool = false
    var onSelect: () -> Void
    var onSave: () -> Void

    private var internship: Internship { role.internship }

    var body: some View {
        MCRICard(edge: role.score >= 90 ? .orange : .none, padding: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                    MCRILogoTile(initials: internship.companyInitials)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(internship.title)
                            .font(.mcriCardTitle)
                            .foregroundStyle(MCRITheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .accessibilityAddTraits(.isButton)
                        Text(internship.companyName)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                    }

                    Spacer(minLength: MCRITheme.Spacing.s2)

                    MCRIMatchRing(score: role.score, size: 40, lineWidth: 4)
                }

                MetaRow(items: [
                    (icon: "mappin", text: internship.location),
                    (icon: internship.workMode.symbol, text: internship.durationLabel),
                    (icon: "banknote", text: internship.compensation),
                ])

                HStack(spacing: MCRITheme.Spacing.s2) {
                    if internship.easyApply {
                        MCRIStatusBadge("Easy Apply", symbol: "bolt.fill", tone: .attention)
                    }
                    if internship.isClosingSoon {
                        MCRIStatusBadge("Closes in \(internship.daysUntilDeadline)d",
                                        symbol: "alarm.fill", tone: .blocked)
                    }
                    Spacer(minLength: MCRITheme.Spacing.s2)
                    Button(action: onSave) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSaved ? MCRITheme.primaryAction : MCRITheme.textTertiary)
                            .frame(width: MCRITheme.Metrics.minTapTarget,
                                   height: MCRITheme.Metrics.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSaved ? "Remove saved role" : "Save this role")

                    if showsApply {
                        MCRIButton(title: "Apply", symbol: "paperplane.fill",
                                   fullWidth: false, action: onSelect)
                    }
                }
            }
        }
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(internship.title) at \(internship.companyName), \(role.score) percent match")
    }
}

/// A compact meta line used across cards: icon + text pairs.
struct MetaRow: View {
    struct Item {
        var icon: String
        var text: String
    }

    var items: [Item]

    init(items: [(icon: String, text: String)]) {
        self.items = items.map { Item(icon: $0.icon, text: $0.text) }
    }

    var body: some View {
        FlowingChips(spacing: MCRITheme.Spacing.s3, lineSpacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Image(systemName: item.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MCRITheme.secondaryAction)
                    Text(item.text)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .fixedSize()
                }
                .accessibilityLabel(item.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MCRIInternshipCardPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIInternshipCard") {
        MCRIInternshipCard(role: MCRIPreview.flagship, isSaved: false,
                           onSelect: { }, onSave: { })
        MCRIInternshipCard(role: MCRIPreview.flagship, isSaved: true, showsApply: true,
                           onSelect: { }, onSave: { })
        MCRIInternshipCard(role: MCRIPreview.stretch, isSaved: false,
                           onSelect: { }, onSave: { })
    }
}
}

private struct MCRIInternshipCardPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Narrowest iPhone", width: MCRIPhoneWidth.small) {
        MCRIInternshipCard(role: MCRIPreview.flagship, isSaved: false, showsApply: true,
                           onSelect: { }, onSave: { })
        MCRICard {
            MetaRow(items: [
                (icon: "mappin", text: "Cape Town · Hybrid"),
                (icon: "clock", text: "12 weeks"),
                (icon: "banknote", text: "R18 000 / month"),
            ])
        }
    }
}
}

private struct MCRIInternshipCardPreview3: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRILogoTile") {
        HStack(spacing: MCRITheme.Spacing.s4) {
            MCRILogoTile(initials: "OL")
            MCRILogoTile(initials: "NS", size: 32)
            MCRILogoTile(initials: "MCRI", size: 56)
        }
    }
}
}
