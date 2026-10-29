import SwiftUI

/// First frame on launch: brandmark, promise, and the loading tell.
struct SplashView: View {
    @State private var ringProgress = 0.0
    @State private var contentVisible = false

    var body: some View {
        ZStack {
            MCRITheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(MCRITheme.primaryAction,
                                style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 108, height: 108)

                    MCRIBrandMark(size: 74, filled: false)
                }

                VStack(spacing: MCRITheme.Spacing.s3) {
                    Text("MCRI Connect")
                        .font(.system(size: 29, weight: .bold))
                        .kerning(-0.4)
                        .foregroundStyle(MCRITheme.textPrimary)
                        .padding(.top, MCRITheme.Spacing.s6)

                    Text("Internship matching")
                        .font(.mcriCaption2.weight(.bold))
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(MCRITheme.primaryAction)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(MCRITheme.accent)
                        .frame(width: 32, height: 3)
                        .padding(.top, MCRITheme.Spacing.s1)

                    VStack(spacing: 3) {
                        Text("Every match you see is explained,")
                        Text("not just ranked.")
                    }
                    .font(.mcriFootnote)
                    .foregroundStyle(MCRITheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, MCRITheme.Spacing.s2)
                }
                .opacity(contentVisible ? 1 : 0)

                Spacer()

                VStack(spacing: MCRITheme.Spacing.s4) {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            SplashDot(delay: Double(index) * 0.16)
                        }
                    }

                    Text("Cohort 2026 · 248 students · 38 employers")
                        .font(.mcriCaption2)
                        .foregroundStyle(MCRITheme.textTertiary.opacity(0.7))
                }
                .padding(.bottom, MCRITheme.Spacing.s8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { ringProgress = 0.94 }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { contentVisible = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("MCRI Connect, internship matching")
    }
}

private struct SplashDot: View {
    var delay: Double
    @State private var raised = false

    var body: some View {
        Circle()
            .fill(MCRITheme.placeholder)
            .frame(width: 6, height: 6)
            .opacity(raised ? 1 : 0.3)
            .offset(y: raised ? -2 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                    .delay(delay)) { raised = true }
            }
            .accessibilityHidden(true)
    }
}

private struct SplashViewPreview1: PreviewProvider {
    static var previews: some View {
    SplashView()
}
}
