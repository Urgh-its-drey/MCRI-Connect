import SwiftUI

/// Fit ring: the score and the colour always travel together, so a glance at the
/// ring tells you which band the match is in.
struct MCRIMatchRing: View {
    var score: Int
    var size: CGFloat = 48
    var lineWidth: CGFloat = 5
    var showsLabel = true
    /// When set, the number sits above this word instead of beside the % glyph.
    var caption: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(MCRITheme.surfaceHi, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(MCRITheme.tint(for: score),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if showsLabel {
                if let caption {
                    VStack(spacing: 1) {
                        Text("\(score)%")
                            .font(.system(size: size * 0.27, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(MCRITheme.textPrimary)
                        Text(caption)
                            .font(.system(size: max(9, size * 0.11), weight: .semibold))
                            .foregroundStyle(MCRITheme.textTertiary)
                    }
                } else {
                    Text("\(score)")
                        .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MCRITheme.textPrimary)
                    + Text("%")
                        .font(.system(size: size * 0.18, weight: .semibold, design: .rounded))
                        .foregroundStyle(MCRITheme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("\(score) percent match")
    }
}

/// One weighted axis of the fit score.
struct MCRIScoreBar: View {
    var name: String
    var score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(name).font(.mcriCaption2.weight(.semibold)).foregroundStyle(MCRITheme.textSecondary)
                Spacer()
                Text("\(score)%")
                    .font(.mcriCaption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(MCRITheme.tint(for: score))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(MCRITheme.surfaceHi)
                    Capsule()
                        .fill(MCRITheme.tint(for: score))
                        .frame(width: max(6, proxy.size.width * CGFloat(score) / 100))
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) \(score) percent")
    }
}

/// The match insights hero: gauge, band label, percentile, then the four axes.
struct MCRIMatchScoreView: View {
    var result: MatchResult
    var compact: Bool = false

    private var bandName: String {
        switch result.score {
        case 90...100: return "Strong match"
        case 70..<90: return "Good match"
        case 50..<70: return "Partial match"
        default: return "Stretch role"
        }
    }

    var body: some View {
        if compact {
            HStack(spacing: MCRITheme.Spacing.s3) {
                MCRIMatchRing(score: result.score, size: 42, lineWidth: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(bandName).font(.mcriCardTitle).foregroundStyle(MCRITheme.textPrimary)
                    Text("Top \(result.percentile)% of applicants for this role")
                        .font(.mcriFootnote).foregroundStyle(MCRITheme.textTertiary)
                }
            }
        } else {
            VStack(spacing: MCRITheme.Spacing.s4) {
                HStack(alignment: .center, spacing: MCRITheme.Spacing.s5) {
                    MCRIMatchRing(score: result.score, size: 92, lineWidth: 9)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bandName)
                            .font(.mcriSection)
                            .foregroundStyle(MCRITheme.tint(for: result.score))
                        Text("You are in the top \(result.percentile)% of students we would show this employer.")
                            .font(.mcriFootnote)
                            .foregroundStyle(MCRITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                VStack(spacing: MCRITheme.Spacing.s3) {
                    ForEach(result.breakdown.components) { component in
                        MCRIScoreBar(name: component.name, score: component.score)
                    }
                }
            }
        }
    }
}

private struct MCRIMatchScoreViewPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIMatchRing / MCRIScoreBar") {
        HStack(spacing: MCRITheme.Spacing.s4) {
            MCRIMatchRing(score: 94)
            MCRIMatchRing(score: 78)
            MCRIMatchRing(score: 52)
            MCRIMatchRing(score: 31, showsLabel: false)
        }
        MCRIMatchRing(score: 88, size: 96, lineWidth: 9, caption: "match")
        VStack(spacing: MCRITheme.Spacing.s2) {
            MCRIScoreBar(name: "Skills", score: 91)
            MCRIScoreBar(name: "Career interests", score: 74)
            MCRIScoreBar(name: "Logistics", score: 58)
            MCRIScoreBar(name: "Profile completeness", score: 33)
        }
    }
}
}

private struct MCRIMatchScoreViewPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIMatchScoreView") {
        MCRIMatchScoreView(result: MCRIPreview.flagship.result)
        MCRIMatchScoreView(result: MCRIPreview.result(skills: 46, interests: 62,
                                                      logistics: 80, profile: 55),
                           compact: true)
    }
}
}

private struct MCRIMatchScoreViewPreview3: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Narrowest iPhone", width: MCRIPhoneWidth.small) {
        MCRIMatchScoreView(result: MCRIPreview.flagship.result)
    }
}
}
