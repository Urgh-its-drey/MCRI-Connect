import SwiftUI

/// Orange fill with a navy label: the one primary action per view.
struct MCRIButton: View {
    var title: String
    var symbol: String? = nil
    var fullWidth: Bool = true
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCRITheme.Spacing.s2) {
                if isLoading {
                    ProgressView()
                        .tint(MCRITheme.textOnAccent)
                        .accessibilityLabel("Working")
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.footnote.weight(.bold))
                }
                Text(title)
            }
            .font(.mcriCardTitle)
            .foregroundStyle(MCRITheme.textOnAccent)
            .lineLimit(1)
            .fixedSize(horizontal: !fullWidth, vertical: false)
            .padding(.horizontal, fullWidth ? 0 : MCRITheme.Spacing.s4)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: MCRITheme.Metrics.controlHeight)
            .background(MCRITheme.primaryAction, in: shape)
            .overlay(shape.strokeBorder(MCRITheme.textOnAccent.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(MCRIPressStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

/// Blue outline on navy. Used for every secondary action beside a primary one.
struct MCRISecondaryButton: View {
    var title: String
    var symbol: String? = nil
    var fullWidth: Bool = true
    var compact: Bool = false
    var isDestructive: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCRITheme.Spacing.s2) {
                if let symbol {
                    Image(systemName: symbol).font(.footnote.weight(.semibold))
                }
                Text(title).font(compact ? .mcriCaption : .mcriCardTitle)
            }
            .lineLimit(1)
            .fixedSize(horizontal: !fullWidth, vertical: false)
            .foregroundStyle(isDestructive ? MCRITheme.blocked : MCRITheme.secondaryAction)
            .padding(.horizontal, compact ? MCRITheme.Spacing.s3 : MCRITheme.Spacing.s4)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: compact ? MCRITheme.Metrics.minTapTarget : MCRITheme.Metrics.controlHeight)
            .background(isDestructive ? MCRITheme.redTint : MCRITheme.blueTint, in: shape)
            .overlay(shape.strokeBorder(isDestructive ? MCRITheme.blocked.opacity(0.55) : MCRITheme.border,
                                       lineWidth: 1))
        }
        .buttonStyle(MCRIPressStyle())
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: compact ? MCRITheme.Radius.chip : MCRITheme.Radius.control,
                         style: .continuous)
    }
}

/// A text-only blue action for inline affordances such as "View details".
struct MCRILinkButton: View {
    var title: String
    var symbol: String = "chevron.right"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title).font(.mcriCaption)
                Image(systemName: symbol).font(.caption2.weight(.bold))
            }
            .foregroundStyle(MCRITheme.secondaryAction)
            .mcriTapTarget()
            .contentShape(Rectangle())
        }
        .buttonStyle(MCRIPressStyle())
    }
}

struct MCRIPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct MCRIButtonPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIButton") {
        MCRIButton(title: "Continue") { }
        MCRIButton(title: "Apply now", symbol: "paperplane.fill") { }
        MCRIButton(title: "Sending", isLoading: true) { }
        MCRIButton(title: "Unavailable", isDisabled: true) { }
        MCRIButton(title: "Save", fullWidth: false) { }
    }
}
}

private struct MCRIButtonPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRISecondaryButton / MCRILinkButton") {
        MCRISecondaryButton(title: "Edit profile", symbol: "pencil") { }
        MCRISecondaryButton(title: "View all", compact: true) { }
        MCRISecondaryButton(title: "Withdraw application", isDestructive: true) { }
        MCRILinkButton(title: "Open saved searches") { }
    }
}
}
