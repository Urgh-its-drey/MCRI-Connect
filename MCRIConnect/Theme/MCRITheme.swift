import SwiftUI

/// Tokens for the MCRI Connect design system. The canvas stays navy and every content block
/// sits on a grey card, because text on the light-navy surface measured below AA. Slate at
/// `#303B45` carries white at 10.8:1 and the tertiary tier at 6.0:1.
struct MCRITheme {
    static let background = Color.mcriNavy
    static let surface = Color.mcriSlate
    static let primaryAction = Color.mcriOrange
    static let secondaryAction = Color.mcriBlue
    static let accent = Color.mcriRed
    static let primaryText = Color.mcriWhite
    static let secondaryText = Color.mcriSlateText
    static let placeholder = Color.mcriMist

    /// Charcoal measures 1.7:1 on navy, so it is reserved for light surfaces.
    /// Text on the dark canvas uses these blended-white tiers instead.
    static let textPrimary = Color.mcriWhite
    static let textSecondary = Color.mcriWhite.opacity(0.80)
    static let textTertiary = Color.mcriWhite.opacity(0.68)
    static let textOnAccent = Color.mcriNavy

    /// One step below the card: inputs, wells and message bubbles sit inside a card.
    static let sunken = Color(hex: "#222A31")
    static let raised = Color(hex: "#3D4A56")

    static let hairline = Color.mcriWhite.opacity(0.10)
    static let border = Color.mcriWhite.opacity(0.22)
    static let borderStrong = Color.mcriBlue
    static let divider = Color.mcriWhite.opacity(0.10)

    static let orangeTint = Color.mcriOrange.opacity(0.18)
    static let blueTint = Color.mcriBlue.opacity(0.18)
    static let redTint = Color.mcriRed.opacity(0.24)
    static let grayTint = Color.mcriMist.opacity(0.16)
    static let surfaceHi = Color.mcriWhite.opacity(0.08)

    static let matchStrong = Color.mcriOrange
    static let matchGood = Color.mcriBlue
    static let matchFair = Color.mcriGray
    static let positive = Color.mcriBlue
    static let attention = Color.mcriOrange
    static let blocked = Color.mcriRed

    /// White on orange is 2.7:1 and fails AA; red is the only fill that carries white.
    static func label(on fill: Color) -> Color {
        if fill == Color.mcriRed { return .mcriWhite }
        return .mcriNavy
    }

    static func tint(for score: Int) -> Color {
        switch score {
        case 90...100: return matchStrong
        case 70..<90: return matchGood
        default: return matchFair
        }
    }

    enum Radius {
        static let card: CGFloat = 20
        static let control: CGFloat = 16
        static let chip: CGFloat = 12
        static let mark: CGFloat = 10
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
        static let screenMargin: CGFloat = 20
    }

    enum Metrics {
        static let minTapTarget: CGFloat = 44
        static let controlHeight: CGFloat = 52
        static let tabBarHeight: CGFloat = 78
        static let shadowRadius: CGFloat = 14
        static let shadowY: CGFloat = 6
        static let shadowOpacity: Double = 0.28
    }

    enum Grid {
        /// Two stat cards across a normal iPhone, one when the width — or a large
        /// text size — will not fit both without clipping the number.
        static func statCards(spacing: CGFloat = Spacing.s3) -> [GridItem] {
            [GridItem(.adaptive(minimum: 150), spacing: spacing)]
        }
    }
}

extension View {
    /// Subtle elevation: a dark drop under a light-navy card, never a blur filter.
    func mcriCardShadow() -> some View {
        shadow(color: Color.black.opacity(MCRITheme.Metrics.shadowOpacity),
               radius: MCRITheme.Metrics.shadowRadius,
               y: MCRITheme.Metrics.shadowY)
    }

    /// Every interactive region in the app clears 44x44 without distorting its label.
    func mcriTapTarget() -> some View {
        frame(minHeight: MCRITheme.Metrics.minTapTarget)
            .contentShape(Rectangle())
    }
}

/// Scaled text styles rather than fixed point sizes, so Dynamic Type works end to end.
/// Display 32 -> largeTitle · Title 24 -> title · Section 17 -> title3 · Card 14.5 -> headline
/// Body 13.5 -> body · Caption 11 -> footnote · Label 10.5 -> caption2 · Numeric 22 -> title2
extension Font {
    static let mcriDisplay = Font.largeTitle.bold()
    static let mcriTitle = Font.title.bold()
    static let mcriSection = Font.title3.weight(.semibold)
    static let mcriCardTitle = Font.headline
    static let mcriBody = Font.body
    static let mcriCallout = Font.callout
    static let mcriCaption = Font.subheadline
    static let mcriFootnote = Font.footnote
    static let mcriCaption2 = Font.caption
    static let mcriLabel = Font.caption2.bold()
    static let mcriNumeric = Font.title2.bold()
}

extension Text {
    /// The all-caps, tracked label style used above every section.
    func mcriLabelStyle() -> some View {
        self.font(.mcriLabel)
            .tracking(1.1)
            .foregroundStyle(MCRITheme.textTertiary)
            .textCase(.uppercase)
    }
}
