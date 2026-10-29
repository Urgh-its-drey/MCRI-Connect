


import SwiftUI

struct TalentBridgeLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingSplash = true

    
    private let splashDurationNanoseconds: UInt64 = 3_000_000_000

    var body: some View {
        ZStack {
            TBLaunchTheme.background.ignoresSafeArea()
            if showingSplash {
                TBSplashView().transition(.opacity)
            } else {
                TBWelcomeView().transition(.opacity)
            }
        }
        .foregroundStyle(TBLaunchTheme.text)
        .tint(TBLaunchTheme.blue)
        .preferredColorScheme(.dark)
        .task {
            guard showingSplash else { return }
            do {
                try await Task.sleep(nanoseconds: splashDurationNanoseconds)
            } catch {
               
                return
            }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                showingSplash = false
            }
        }
    }
}

private struct TBSplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TBLaunchDecoration()
                VStack(spacing: 0) {
                    Spacer(minLength: 28)
                    brand
                    Spacer(minLength: 32)
                    loading
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }
    
    private var brand: some View {
        VStack(spacing: 17) {
            ZStack {
                Circle().fill(TBLaunchTheme.surface).frame(width: 94, height: 94)
                Circle().stroke(TBLaunchTheme.blue.opacity(0.2), lineWidth: 3)
                Circle().trim(from: 0.04, to: 0.97)
                    .stroke(TBLaunchTheme.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                TBBrandMark(size: 52)
            }.frame(width: 124, height: 124).accessibilityHidden(true)
            Text("MCRI Connect").font(.system(size: 30, weight: .bold))
                .minimumScaleFactor(0.75).lineLimit(1)
            Text("INTERNSHIP MATCHING")
                .font(.system(size: 11, weight: .bold)).tracking(1.2)
                .foregroundStyle(TBLaunchTheme.orange)
            Capsule().fill(TBLaunchTheme.red).frame(width: 32, height: 2)
            Text("Connect your skills to\nreal opportunities.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(TBLaunchTheme.secondary)
        }
    }
    private var loading: some View {
        VStack(spacing: 15) {
            ProgressView().tint(TBLaunchTheme.orange)
            HStack(spacing: 8) {
                Circle().fill(TBLaunchTheme.secondary).frame(width: 5, height: 5)
                Circle().fill(TBLaunchTheme.secondary).frame(width: 5, height: 5)
                Circle().fill(TBLaunchTheme.blue).frame(width: 5, height: 5)
            }.accessibilityHidden(true)
            Text("Loading your experience")
                .font(.caption).foregroundStyle(TBLaunchTheme.secondary)
        }
        .padding(.bottom, 25)
        .accessibilityElement(children: .combine)
    }
    private var footer: some View {
        VStack(spacing: 5) {
            Text("MCRI Analytics · Placement Network")
            Text("v3.0 · Pretoria · Johannesburg · Cape Town")
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(TBLaunchTheme.secondary)
        .multilineTextAlignment(.center)
    }
}

private struct TBWelcomeView: View {
    @State private var role = TBWelcomeRole.student
    @State private var destination: TBWelcomeDestination?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                introduction
                features
                accountActions
                roles
                policies
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(TBLaunchTheme.background.ignoresSafeArea())
        .sheet(item: $destination) { route in
            TBWelcomePlaceholder(destination: route, role: role)
        }
    }
    private var header: some View {
        HStack(spacing: 10) {
            TBBrandMark(size: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text("MCRI Connect").font(.headline)
                Text("Internship matching").font(.system(size: 10)).foregroundStyle(TBLaunchTheme.secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                Text("121 open roles").foregroundStyle(TBLaunchTheme.blue)
                Text("38 employers").foregroundStyle(TBLaunchTheme.secondary)
            }.font(.system(size: 10, weight: .semibold))
        }.padding(.bottom, 10)
    }
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect your skills")
                .font(.system(size: 29, weight: .bold))
            Text("to real opportunities.")
                .font(.system(size: 29, weight: .bold)).foregroundStyle(TBLaunchTheme.orange)
            Text("Answer five questions. See every internship you actually match — and why.")
                .font(.subheadline.weight(.medium)).foregroundStyle(TBLaunchTheme.secondary)
        }
    }
    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            TBWelcomeFeature(icon: "target", accent: TBLaunchTheme.orange,
                             title: "Match scores you can read", detail: "Skills, interests and logistics scored separately")
            Divider().overlay(TBLaunchTheme.blue.opacity(0.2))
            TBWelcomeFeature(icon: "checkmark.shield", accent: TBLaunchTheme.blue,
                             title: "Verified employers only", detail: "38 partner companies, every role confirmed")
            Divider().overlay(TBLaunchTheme.blue.opacity(0.2))
            TBWelcomeFeature(icon: "chart.line.uptrend.xyaxis", accent: TBLaunchTheme.orange,
                             title: "Tracked from apply to offer", detail: "See review stages and response times")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TBLaunchTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(TBLaunchTheme.blue.opacity(0.25), lineWidth: 1))
    }
    private var accountActions: some View {
        VStack(spacing: 12) {
            Button { destination = .createAccount } label: {
                HStack {
                    Spacer()
                    Text("Create account").font(.headline)
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .foregroundStyle(TBLaunchTheme.background)
                .padding(17).background(TBLaunchTheme.orange, in: RoundedRectangle(cornerRadius: 18))
            }
            Button { destination = .login } label: {
                Text("Log in").font(.headline)
                    .frame(maxWidth: .infinity).padding(17)
                    .background(TBLaunchTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(TBLaunchTheme.blue, lineWidth: 1.5))
            }
            Button("Forgot password?") { destination = .resetPassword }
                .font(.caption.weight(.semibold)).foregroundStyle(TBLaunchTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
    }
    private var roles: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTINUE AS").font(.system(size: 10, weight: .bold)).foregroundStyle(TBLaunchTheme.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TBWelcomeRole.allCases) { item in
                        roleButton(item)
                    }
                }.padding(.vertical, 2)
            }
        }
    }
    private func roleButton(_ item: TBWelcomeRole) -> some View {
        let selected: Bool = role == item
        let background: Color = selected ? TBLaunchTheme.orange : TBLaunchTheme.surface
        let foreground: Color = selected ? TBLaunchTheme.background : TBLaunchTheme.blue
        let traits: AccessibilityTraits = selected ? .isSelected : []
        return Button { role = item } label: {
            Label(item.rawValue, systemImage: item.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, 12).frame(minHeight: 44)
                .background(background, in: Capsule())
                .overlay(Capsule().strokeBorder(TBLaunchTheme.blue.opacity(selected ? 0 : 0.3), lineWidth: 1))
        }
        .buttonStyle(.plain).accessibilityAddTraits(traits)
    }
    private var policies: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button("Terms") { destination = .terms }
                Text("")
                Button("Privacy Policy") { destination = .privacy }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(TBLaunchTheme.secondary)
        }
    }
}

private struct TBWelcomeFeature: View {
    let icon: String
    let accent: Color
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).foregroundStyle(accent).font(.system(size: 14, weight: .semibold))
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(TBLaunchTheme.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct TBWelcomePlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    let destination: TBWelcomeDestination
    let role: TBWelcomeRole
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                if destination == .createAccount || destination == .login {
                    Text("Continue as \(role.rawValue)").font(.headline)
                }
                Text("This page is not available yet.")
                    .foregroundStyle(TBLaunchTheme.secondary)
                Spacer()
            }
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TBLaunchTheme.background)
            .navigationTitle(destination.rawValue).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .foregroundStyle(TBLaunchTheme.text).tint(TBLaunchTheme.blue).preferredColorScheme(.dark)
    }
}

private enum TBWelcomeRole: String, CaseIterable, Identifiable {
    case student = "Student", employer = "Employer", manager = "Program manager"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .student: return "graduationcap"
        case .employer: return "building.2"
        case .manager: return "person.2"
        }
    }
}

private enum TBWelcomeDestination: String, Identifiable {
    case createAccount = "Create account", login = "Log in", resetPassword = "Reset password"
    case terms = "Terms", privacy = "Privacy Policy"
    var id: String { rawValue }
}

private struct TBBrandMark: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25).fill(TBLaunchTheme.orange)
            TBLetterM()
                .stroke(TBLaunchTheme.background, style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round, lineJoin: .round))
                .padding(size * 0.23)
            Circle().fill(TBLaunchTheme.red).frame(width: size * 0.17, height: size * 0.17)
                .offset(x: -size * 0.22, y: -size * 0.18)
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

private struct TBLetterM: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

private struct TBLaunchDecoration: View {
    var body: some View {
        GeometryReader { geometry in
            Circle().stroke(TBLaunchTheme.blue.opacity(0.08), lineWidth: 26)
                .frame(width: 220, height: 220)
                .position(x: geometry.size.width, y: 25)
            Circle().fill(TBLaunchTheme.orange.opacity(0.06))
                .frame(width: 160, height: 160)
                .position(x: 15, y: geometry.size.height * 0.85)
        }.clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private enum TBLaunchTheme {
    static let background = Color(tbLaunchHex: 0x153A55)
    static let surface = Color(tbLaunchHex: 0x1D4865)
    static let orange = Color(tbLaunchHex: 0xFF6825)
    static let blue = Color(tbLaunchHex: 0x159BE8)
    static let red = Color(tbLaunchHex: 0xC4432A)
    static let text = Color(tbLaunchHex: 0xF7F9FA)
    static let secondary = Color(tbLaunchHex: 0x89929A)
}

private extension Color {
    init(tbLaunchHex: UInt32) {
        self.init(.sRGB, red: Double((tbLaunchHex >> 16) & 255) / 255,
                  green: Double((tbLaunchHex >> 8) & 255) / 255,
                  blue: Double(tbLaunchHex & 255) / 255, opacity: 1)
    }
}

struct TalentBridgeLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TalentBridgeLaunchView().previewDisplayName("Splash → Welcome")
            TBWelcomeView().foregroundStyle(TBLaunchTheme.text).tint(TBLaunchTheme.blue)
                .preferredColorScheme(.dark).previewDisplayName("Welcome")
        }
    }
}
