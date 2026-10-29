import SwiftUI

/// The card every content block sits on: light-navy fill, one hairline border, one soft shadow.
struct MCRICard<Content: View>: View {
    enum Edge {
        case none, blue, orange, red

        var color: Color {
            switch self {
            case .none: return .clear
            case .blue: return MCRITheme.secondaryAction
            case .orange: return MCRITheme.primaryAction
            case .red: return MCRITheme.blocked
            }
        }
    }

    var edge: Edge = .none
    var isHighlighted: Bool = false
    var padding: CGFloat = MCRITheme.Spacing.s4
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MCRITheme.surface, in: shape)
            .overlay(shape.strokeBorder(isHighlighted ? MCRITheme.borderStrong : MCRITheme.hairline,
                                       lineWidth: isHighlighted ? 1.5 : 1))
            .overlay(alignment: .leading) {
                if edge != .none {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(edge.color)
                        .frame(width: 3)
                        .padding(.vertical, padding)
                }
            }
            .mcriCardShadow()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.card, style: .continuous)
    }
}

/// A caption-caps label above a section, with an optional right-aligned action.
struct MCRISectionHeader<Action: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var action: () -> Action

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).mcriLabelStyle()
                if let subtitle {
                    Text(subtitle)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textTertiary)
                }
            }
            Spacer(minLength: MCRITheme.Spacing.s3)
            action()
        }
        .accessibilityElement(children: .contain)
    }
}

extension MCRISectionHeader where Action == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, action: { EmptyView() })
    }
}

/// Two-tone monogram tile used on the splash, welcome header and navigation bar.
struct MCRIBrandMark: View {
    var size: CGFloat = 44
    var filled: Bool = true

    var body: some View {
        ZStack {
            shape.fill(filled ? MCRITheme.primaryAction : MCRITheme.surface)

            Text("M")
                .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                .foregroundStyle(filled ? MCRITheme.textOnAccent : MCRITheme.primaryAction)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(filled ? MCRITheme.accent : MCRITheme.secondaryAction)
                .frame(width: size * 0.16, height: size * 0.16)
                .padding(size * 0.12)
        }
        .overlay {
            if !filled {
                shape.strokeBorder(MCRITheme.border, lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
    }
}

private struct MCRICardPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRICard") {
        MCRICard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Flat card").font(.mcriCardTitle)
                Text("Every content block sits on one of these.").font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textSecondary)
            }
        }
        MCRICard(edge: .orange) { Text("Orange edge").font(.mcriCardTitle) }
        MCRICard(edge: .blue) { Text("Blue edge").font(.mcriCardTitle) }
        MCRICard(edge: .red) { Text("Red edge").font(.mcriCardTitle) }
        MCRICard(isHighlighted: true) { Text("Highlighted").font(.mcriCardTitle) }
    }
}
}

private struct MCRICardPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRISectionHeader / MCRIBrandMark") {
        MCRISectionHeader(title: "Ready to apply", subtitle: "96 of 248 students")
        MCRISectionHeader(title: "Recent activity")
        MCRISectionHeader(title: "Applications") {
            MCRILinkButton(title: "See all") { }
        }
        HStack(spacing: MCRITheme.Spacing.s4) {
            MCRIBrandMark()
            MCRIBrandMark(size: 32, filled: false)
        }
    }
}
}
