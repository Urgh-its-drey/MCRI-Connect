import SwiftUI

/// Shown whenever a list has nothing to display, with the action that would fill it.
struct MCRIEmptyState: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MCRITheme.Spacing.s4) {
            ZStack {
                Circle().fill(MCRITheme.surfaceHi).frame(width: 84, height: 84)
                Image(systemName: symbol)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(MCRITheme.secondaryAction)
            }

            VStack(spacing: MCRITheme.Spacing.s2) {
                Text(title)
                    .font(.mcriSection)
                    .foregroundStyle(MCRITheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.mcriBody)
                    .foregroundStyle(MCRITheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                MCRISecondaryButton(title: actionTitle, symbol: "arrow.right",
                                    fullWidth: false, compact: true, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MCRITheme.Spacing.s8)
        .accessibilityElement(children: .combine)
    }
}

/// The transient confirmation strip. One at a time, dismissed automatically.
struct MCRIToastMessage: View {
    var toast: Toast

    private var tone: MCRIStatusTone {
        switch toast.kind {
        case .success: return .positive
        case .info: return .information
        case .warning: return .attention
        case .danger: return .blocked
        }
    }

    var body: some View {
        HStack(spacing: MCRITheme.Spacing.s3) {
            Image(systemName: toast.kind.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tone.label)
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title)
                    .font(.mcriCaption.weight(.bold))
                    .foregroundStyle(MCRITheme.textPrimary)
                if let detail = toast.detail {
                    Text(detail)
                        .font(.mcriFootnote)
                        .foregroundStyle(MCRITheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: MCRITheme.Spacing.s2)
        }
        .padding(.horizontal, MCRITheme.Spacing.s4)
        .frame(minHeight: MCRITheme.Metrics.minTapTarget)
        .background(MCRITheme.raised, in: RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
            .strokeBorder(tone.stroke, lineWidth: 1))
        .mcriCardShadow()
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Pins the current toast above the tab bar and removes it after a few seconds.
    func mcriToast(_ toast: Binding<Toast?>) -> some View {
        overlay(alignment: .bottom) {
            if let current = toast.wrappedValue {
                MCRIToastMessage(toast: current)
                    .padding(.horizontal, MCRITheme.Spacing.screenMargin)
                    .padding(.bottom, MCRITheme.Spacing.s8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: current.id) {
                        try? await Task.sleep(nanoseconds: 3_200_000_000)
                        toast.wrappedValue = nil
                    }
            }
        }
        .animation(.spring(duration: 0.32), value: toast.wrappedValue?.id)
    }
}

/// 52pt search field with the action button attached to its trailing edge.
struct MCRISearchBar: View {
    var placeholder: String = "Search roles, skills, employers"
    @Binding var text: String
    var onSubmit: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: MCRITheme.Spacing.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MCRITheme.placeholder)
                TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundColor(MCRITheme.placeholder))
                    .font(.mcriBody)
                    .foregroundStyle(Color.mcriNavy)
                    .tint(MCRITheme.primaryAction)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { onSubmit?() }
                if !text.isEmpty {
                    Button {
                        text = ""
                        onClear?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(MCRITheme.placeholder)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, MCRITheme.Spacing.s3)
            .frame(maxWidth: .infinity)
            .frame(height: MCRITheme.Metrics.controlHeight)
            .background(Color.white, in: fieldShape)

            Button {
                onSubmit?()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MCRITheme.textOnAccent)
                    .frame(width: 52, height: MCRITheme.Metrics.controlHeight)
                    .background(MCRITheme.primaryAction, in: fieldShape)
            }
            .padding(.leading, 4)
            .accessibilityLabel("Search")
        }
    }

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MCRITheme.Radius.control, style: .continuous)
    }
}

private struct MCRIStatesPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIEmptyState") {
        MCRIEmptyState(symbol: "moon.phase.fill", title: "Nothing due today",
                       message: "Applications are moving. We will tell you when an employer replies.")
        MCRIEmptyState(symbol: "magnifyingglass", title: "No roles match those filters",
                       message: "Try widening the location or clearing the work-mode filter.",
                       actionTitle: "Clear filters") { }
    }
}
}

private struct MCRIStatesPreview2: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "MCRIToastMessage") {
        MCRIToastMessage(toast: Toast(title: "Application sent",
                                      detail: "Orbit Labs · Product Design Intern", kind: .success))
        MCRIToastMessage(toast: Toast(title: "Saved to your list", kind: .info))
        MCRIToastMessage(toast: Toast(title: "Deadline is in 2 days",
                                      detail: "Finish the application before Friday.", kind: .warning))
        MCRIToastMessage(toast: Toast(title: "Could not withdraw",
                                      detail: "The employer already replied.", kind: .danger))
    }
}
}

private struct MCRISearchBarPreviewHost: View {
    @State private var filled = "design intern"

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            MCRISearchBar(text: .constant(""))
            MCRISearchBar(placeholder: "Search name, programme or skill", text: $filled,
                          onSubmit: { }, onClear: { filled = "" })
        }
        .padding(MCRITheme.Spacing.s4)
        .mcriPinned(to: MCRIPhoneWidth.small)
    }
}

private struct MCRIStatesPreview3: PreviewProvider {
    static var previews: some View {
    MCRISearchBarPreviewHost()
}
}
