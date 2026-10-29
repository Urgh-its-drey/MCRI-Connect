import SwiftUI

/// Shared chrome for every screen in the app: navy canvas, consistent margins,
/// and a navigation bar that does not bleed the page colour.
extension View {
    func mcriScreen(title: String? = nil, hidesTitle: Bool = true) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MCRITheme.background.ignoresSafeArea())
            .toolbarBackground(MCRITheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(hidesTitle ? .hidden : .automatic, for: .navigationBar)
    }
}

/// Standard page body: 20pt side margins, 4pt-grid section spacing, hidden scroll bars.
struct MCRIPage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: MCRITheme.Spacing.s4) {
                content()
            }
            .padding(.horizontal, MCRITheme.Spacing.screenMargin)
            .padding(.top, MCRITheme.Spacing.s2)
            .padding(.bottom, MCRITheme.Spacing.s6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
    }
}

/// The one gradient in the app: the signed-in banner behind the greeting and the
/// readiness ring. Everything below it returns to flat navy.
struct MCRIScreenHero<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: MCRITheme.Spacing.s4) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MCRITheme.Spacing.s5)
        .background {
            LinearGradient(colors: [Color.mcriNavy, Color.mcriLightNavy],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Rectangle().fill(MCRITheme.primaryAction.opacity(0.10)))
        }
        .clipShape(RoundedRectangle(cornerRadius: MCRITheme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MCRITheme.Radius.card, style: .continuous)
            .strokeBorder(MCRITheme.border, lineWidth: 1))
    }
}
