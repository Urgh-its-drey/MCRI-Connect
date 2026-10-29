import SwiftUI

/// Horizontal distribution bars for cohort readiness.
struct MCRIHorizontalBars: View {
    struct Entry {
        var label: String
        var value: Int
        var color: Color
    }

    var entries: [Entry]
    var total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.label)
                            .font(.mcriCaption2.weight(.semibold))
                            .foregroundStyle(MCRITheme.textSecondary)
                        Spacer()
                        Text("\(entry.value)")
                            .font(.mcriCaption.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text("\(percent(of: entry.value))%")
                            .font(.mcriCaption2)
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.textTertiary)
                            .frame(width: 34, alignment: .trailing)
                    }
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(MCRITheme.surfaceHi)
                            Capsule()
                                .fill(entry.color)
                                .frame(width: max(6, proxy.size.width * CGFloat(entry.value)
                                    / CGFloat(max(total, 1))))
                        }
                    }
                    .frame(height: 7)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(entry.label): \(entry.value) students, \(percent(of: entry.value)) percent")
            }
        }
    }

    private func percent(of value: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(value) / Double(total) * 100).rounded())
    }
}

/// Stage funnel: one segment per pipeline stage, width proportional to volume.
struct MCRIFunnel: View {
    struct Segment {
        var label: String
        var value: Int
        var color: Color
    }

    var segments: [Segment]

    var body: some View {
        let total = segments.reduce(0) { $0 + $1.value }
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s3) {
            HStack(spacing: 3) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(segment.color)
                        .frame(maxWidth: .infinity,
                               minHeight: 8,
                               maxHeight: 8)
                        .opacity(total == 0 ? 0.25 : 1)
                }
            }

            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                HStack(spacing: MCRITheme.Spacing.s2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.color)
                        .frame(width: 8, height: 8)
                    Text(segment.label)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                    Spacer()
                    Text("\(segment.value)")
                        .font(.mcriCaption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(MCRITheme.textPrimary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(segments.map { "\($0.label) \($0.value)" }.joined(separator: ", "))
    }
}

/// Compact column chart for a weekly series (applications sent per week).
struct MCRIVolumeChart: View {
    var values: [Int]
    var caption: String

    private var peak: Int { max(values.max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s2) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(index == values.count - 1 ? MCRITheme.primaryAction : MCRITheme.secondaryAction)
                            .frame(height: max(6, CGFloat(value) / CGFloat(peak) * 54))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 58)
            .accessibilityHidden(true)

            Text(caption)
                .font(.mcriCaption2)
                .foregroundStyle(MCRITheme.textTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption). Highest week \(peak), latest week \(values.last ?? 0)")
    }
}

private struct MCRIChartsPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Charts") {
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRISectionHeader(title: "Cohort readiness")
                MCRIHorizontalBars(
                    entries: [
                        .init(label: "Ready to apply", value: 96, color: MCRIStatusTone.positive.label),
                        .init(label: "Nearly ready", value: 74, color: MCRIStatusTone.attention.label),
                        .init(label: "Needs support", value: 37, color: MCRIStatusTone.blocked.label),
                        .init(label: "Not started", value: 41, color: MCRIStatusTone.neutral.label),
                    ],
                    total: 248
                )
            }
        }
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRISectionHeader(title: "Application funnel")
                MCRIFunnel(segments: [
                    .init(label: "Submitted", value: 412, color: MCRIStatusTone.information.label),
                    .init(label: "Shortlisted", value: 168, color: MCRIStatusTone.neutral.label),
                    .init(label: "Interviewing", value: 74, color: MCRIStatusTone.attention.label),
                    .init(label: "Placed", value: 39, color: MCRIStatusTone.positive.label),
                ])
            }
        }
        MCRICard {
            VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
                MCRISectionHeader(title: "Weekly applications")
                MCRIVolumeChart(values: [26, 31, 44, 38, 57, 63, 71],
                                caption: "Last 7 weeks · up 27%")
            }
        }
    }
}
}
