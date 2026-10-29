import SwiftUI

/// The five tones the design system allows for status colour. Green is not one of
/// them, so positive states ride on blue and only real failures use red.
enum MCRIStatusTone {
    case positive, neutral, attention, information, blocked

    var fill: Color {
        switch self {
        case .positive: return MCRITheme.blueTint
        case .neutral: return MCRITheme.grayTint
        case .attention: return MCRITheme.orangeTint
        case .information: return MCRITheme.surfaceHi
        case .blocked: return MCRITheme.redTint
        }
    }

    var stroke: Color {
        switch self {
        case .positive: return MCRITheme.secondaryAction.opacity(0.5)
        case .neutral: return MCRITheme.placeholder.opacity(0.5)
        case .attention: return MCRITheme.primaryAction.opacity(0.5)
        case .information: return MCRITheme.hairline
        case .blocked: return MCRITheme.blocked.opacity(0.55)
        }
    }

    var label: Color {
        switch self {
        case .positive: return MCRITheme.secondaryAction
        case .neutral: return MCRITheme.textTertiary
        case .attention: return MCRITheme.primaryAction
        case .information: return MCRITheme.textSecondary
        case .blocked: return MCRITheme.blocked
        }
    }
}

extension ApplicationStage {
    var tone: MCRIStatusTone {
        switch self {
        case .submitted: return .positive
        case .underReview: return .neutral
        case .shortlisted, .interviewScheduled: return .attention
        case .offered: return .positive
        case .declined: return .blocked
        }
    }
}

extension PlacementStage {
    var tone: MCRIStatusTone {
        switch self {
        case .preparing: return .neutral
        case .applying: return .positive
        case .shortlisted, .interviewing: return .attention
        case .placed: return .positive
        }
    }
}

struct MCRIStatusBadge: View {
    var title: String
    var symbol: String?
    var tone: MCRIStatusTone

    init(_ title: String, symbol: String? = nil, tone: MCRIStatusTone) {
        self.title = title
        self.symbol = symbol
        self.tone = tone
    }

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 9, weight: .bold))
            } else {
                Circle().fill(tone.label).frame(width: 6, height: 6)
            }
            Text(title).font(.mcriCaption2.weight(.semibold))
        }
        .foregroundStyle(tone.label)
        .padding(.horizontal, MCRITheme.Spacing.s2 + 2)
        .frame(height: 24)
        .background(tone.fill, in: Capsule())
        .overlay(Capsule().strokeBorder(tone.stroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// A skill with its proficiency and, in the profile editor, a delete affordance.
struct MCRISkillChip: View {
    var name: String
    var dots: Int = 0
    var tint: Color = MCRITheme.secondaryAction
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 5) {
            if dots > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<dots, id: \.self) { _ in
                        Circle().fill(tint).frame(width: 4, height: 4)
                    }
                }
            }
            Text(name).font(.mcriCaption2.weight(.semibold)).lineLimit(1)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(name)")
            }
        }
        .foregroundStyle(MCRITheme.textSecondary)
        .padding(.horizontal, MCRITheme.Spacing.s2 + 2)
        .frame(height: 26)
        .background(MCRITheme.surfaceHi, in: Capsule())
        .overlay(Capsule().strokeBorder(MCRITheme.hairline, lineWidth: 1))
    }
}

/// Wrapping row for chips. Uses the Layout protocol so chip heights and Dynamic
/// Type text both decide the line breaks.
struct FlowingChips: Layout {
    var spacing: CGFloat = MCRITheme.Spacing.s2
    var lineSpacing: CGFloat = MCRITheme.Spacing.s2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var widestLine: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0, lineWidth + spacing + size.width > maxWidth {
                height += lineHeight + lineSpacing
                widestLine = max(widestLine, lineWidth)
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += (lineWidth > 0 ? spacing : 0) + size.width
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: max(widestLine, lineWidth), height: height + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let width = min(size.width, maxWidth)
            if x > bounds.minX, x + width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: width, height: size.height))
            x += width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
/// A live filter in the explore bar; selected chips carry the orange active state.
struct MCRIFilterChip: View {
    var title: String
    var symbol: String? = nil
    var isSelected: Bool
    var trailingCount: Int? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark" : (symbol ?? "plus"))
                    .font(.system(size: 10, weight: .bold))
                Text(title).font(.mcriCaption.weight(.semibold))
                if let trailingCount {
                    Text("\(trailingCount)")
                        .font(.mcriCaption2.weight(.bold))
                        .foregroundStyle(isSelected ? MCRITheme.textOnAccent : MCRITheme.textTertiary)
                }
            }
            .foregroundStyle(isSelected ? MCRITheme.textOnAccent : MCRITheme.textSecondary)
            .fixedSize()
            .padding(.horizontal, MCRITheme.Spacing.s3)
            .frame(height: MCRITheme.Metrics.minTapTarget)
            .background(isSelected ? MCRITheme.primaryAction : MCRITheme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? MCRITheme.primaryAction : MCRITheme.border,
                                           lineWidth: 1))
        }
        .buttonStyle(MCRIPressStyle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct MCRIChipsPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIStatusBadge") {
        FlowingChips {
            MCRIStatusBadge("Placed", symbol: "checkmark.seal.fill", tone: .positive)
            MCRIStatusBadge("Draft", tone: .neutral)
            MCRIStatusBadge("Closing soon", symbol: "alarm.fill", tone: .attention)
            MCRIStatusBadge("Under review", symbol: "eye.fill", tone: .information)
            MCRIStatusBadge("Declined", symbol: "xmark.circle.fill", tone: .blocked)
        }
    }
}
}

private struct MCRIChipsPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRISkillChip") {
        FlowingChips {
            MCRISkillChip(name: "Design systems")
            MCRISkillChip(name: "Figma", dots: 3)
            MCRISkillChip(name: "User research", dots: 5)
            MCRISkillChip(name: "Prototyping", dots: 2, onRemove: { })
            MCRISkillChip(name: "A very long skill name that has to survive 320pt", dots: 4)
        }
    }
}
}

private struct MCRIChipsPreview3: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIFilterChip / FlowingChips") {
        FlowingChips {
            MCRIFilterChip(title: "All roles", isSelected: true) { }
            MCRIFilterChip(title: "Remote", symbol: "globe", isSelected: false) { }
            MCRIFilterChip(title: "Paid", symbol: "banknote", isSelected: false, trailingCount: 12) { }
            MCRIFilterChip(title: "Filters", symbol: "line.3.horizontal.decrease.circle",
                           isSelected: false, trailingCount: 2) { }
        }
        MCRICard {
            FlowingChips(spacing: MCRITheme.Spacing.s2, lineSpacing: MCRITheme.Spacing.s2) {
                ForEach(["Figma", "Prototyping", "Design systems", "Accessibility",
                         "User research", "Motion"], id: \.self) { name in
                    MCRISkillChip(name: name, dots: 3)
                }
            }
        }
    }
}
}

private struct MCRIChipsPreview4: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Wrapping at the narrowest width",
                     width: MCRIPhoneWidth.small) {
        FlowingChips {
            ForEach(["Design systems", "User research", "Accessibility audit",
                     "Prototyping", "Motion design"], id: \.self) { name in
                MCRIFilterChip(title: name, isSelected: true) { }
            }
        }
    }
}
}
