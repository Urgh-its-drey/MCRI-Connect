import SwiftUI

/// A progress block: label, the number first, the bar, then what to do about it.
struct MCRIProgressCard: View {
    var title: String
    var value: Int
    var caption: String
    var symbol: String
    var gaps: [String] = []
    var action: (() -> Void)? = nil
    var actionTitle: String = "Fix this"

    private var tone: MCRIStatusTone {
        switch value {
        case 80...: return .positive
        case 60..<80: return .attention
        default: return .blocked
        }
    }

    var body: some View {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).mcriLabelStyle()
                        Text(caption)
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(value)")
                            .font(.mcriNumeric)
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("%")
                            .font(.mcriCaption.weight(.bold))
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MCRITheme.surfaceHi)
                        Capsule()
                            .fill(tone.label)
                            .frame(width: max(8, proxy.size.width * CGFloat(min(max(value, 0), 100)) / 100))
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)

                if !gaps.isEmpty {
                    VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
                        ForEach(gaps.prefix(3), id: \.self) { gap in
                            HStack(alignment: .top, spacing: MCRITheme.Spacing.s2) {
                                Image(systemName: symbol)
                                    .font(.caption2)
                                    .foregroundStyle(tone.label)
                                    .padding(.top, 2)
                                Text(gap)
                                    .font(.mcriFootnote)
                                    .foregroundStyle(MCRITheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    if let action {
                        MCRISecondaryButton(title: actionTitle, symbol: "arrow.right",
                                            fullWidth: false, compact: true, action: action)
                            .padding(.top, MCRITheme.Spacing.s1)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) \(value) percent. \(caption)")
    }
}

/// KPI tile for the employer and manager dashboards: number, label, trend.
struct MCRIStatCard: View {
    var label: String
    var value: String
    var detail: String? = nil
    var symbol: String
    var tone: MCRIStatusTone = .information
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { card }
                .buttonStyle(MCRIPressStyle())
        } else {
            card
        }
    }

    @ViewBuilder private var card: some View {
        MCRICard(edge: tone == .attention ? .orange : .none, padding: MCRITheme.Spacing.s4) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tone.label)
                    Text(label).mcriLabelStyle()
                }
                Text(value)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(MCRITheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let detail {
                    Text(detail)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// A ring paired with a headline number, used on the profile and manager overview.
struct MCRIStrengthRing: View {
    var value: Int
    var caption: String
    var size: CGFloat = 84

    var body: some View {
        MCRIMatchRing(score: value, size: size, lineWidth: size * 0.1, caption: caption)
            .accessibilityLabel("\(caption) \(value) percent")
    }
}

private struct MCRIProgressCardPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIProgressCard / MCRIStatCard") {
        MCRIProgressCard(title: "Profile strength", value: 62,
                         caption: "3 fixes lift your matches",
                         symbol: "person.crop.circle.badge.checkmark",
                         gaps: ["Add a CV", "Two more skills with evidence", "Set your availability"],
                         action: { }, actionTitle: "Finish profile")
        MCRIProgressCard(title: "Applications sent", value: 100,
                         caption: "4 open, 1 interview booked",
                         symbol: "paperplane.fill")
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: MCRITheme.Spacing.s3)],
                  spacing: MCRITheme.Spacing.s3) {
            MCRIStatCard(label: "Open roles", value: "2", symbol: "briefcase.fill")
            MCRIStatCard(label: "Applicants", value: "37", detail: "this week",
                         symbol: "person.2.fill", tone: .attention, action: { })
            MCRIStatCard(label: "Offers out", value: "1", detail: "awaiting reply",
                         symbol: "hand.thumbsup.fill", tone: .positive)
        }
    }
}
}

private struct MCRIProgressCardPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIStrengthRing") {
        HStack(spacing: MCRITheme.Spacing.s6) {
            MCRIStrengthRing(value: 84, caption: "Ready")
            MCRIStrengthRing(value: 41, caption: "Building")
            MCRIStrengthRing(value: 12, caption: "Start here", size: 60)
        }
    }
}
}
