import SwiftUI

/// Pulsing blocks that match the real card geometry, so the layout does not jump
/// when data lands.
struct MCRISkeleton: View {
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var corner: CGFloat = 8

    @State private var dim = false

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(MCRITheme.surfaceHi)
            .frame(width: width, height: height)
            .opacity(dim ? 0.45 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
            .accessibilityHidden(true)
    }
}

/// A loading stand-in for a list of cards.
struct MCRICardSkeleton: View {
    var rows: Int = 3

    var body: some View {
        VStack(spacing: MCRITheme.Spacing.s3) {
            ForEach(0..<rows, id: \.self) { _ in
                MCRICard {
                    HStack(alignment: .top, spacing: MCRITheme.Spacing.s3) {
                        MCRISkeleton(width: 44, height: 44, corner: MCRITheme.Radius.mark)
                        VStack(alignment: .leading, spacing: 6) {
                            MCRISkeleton(width: 176, height: 14)
                            MCRISkeleton(width: 120, height: 11)
                            MCRISkeleton(width: 220, height: 10)
                        }
                        Spacer()
                        MCRISkeleton(width: 40, height: 40, corner: 20)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

/// The full-bleed loading state used before a screen has any data at all.
struct MCRILoadingView: View {
    var message: String = "Loading your placements"

    var body: some View {
        VStack(spacing: MCRITheme.Spacing.s4) {
            ProgressView().tint(MCRITheme.primaryAction).controlSize(.large)
            Text(message)
                .font(.mcriCaption)
                .foregroundStyle(MCRITheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Error state with the retry that resolves it — never a bare alert.
struct MCRIErrorState: View {
    var message: String
    var retry: () -> Void

    var body: some View {
        MCRIEmptyState(symbol: "wifi.exclamationmark",
                       title: "Nothing loaded yet",
                       message: message,
                       actionTitle: "Try again",
                       action: retry)
    }
}

private struct MCRISkeletonPreview1: PreviewProvider {
    static var previews: some View {
    MCRIPreviewGroup(title: "Skeletons, loading, error") {
        HStack(spacing: MCRITheme.Spacing.s3) {
            MCRISkeleton(width: 44, height: 44, corner: MCRITheme.Radius.chip)
            VStack(alignment: .leading, spacing: 6) {
                MCRISkeleton(width: 168)
                MCRISkeleton(width: 112, height: 10)
            }
        }
        MCRICardSkeleton(rows: 2)
        MCRIErrorState(message: "We could not reach the placement service. Your drafts are safe.") { }
        MCRILoadingView()
        MCRILoadingView(message: "Matching you to 41 open roles")
    }
}
}
