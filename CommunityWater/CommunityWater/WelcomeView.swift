import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var path: [Destination] = []
    @State private var settings = false
    enum Destination: Hashable { case signIn, signUp }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        Label("COMMUNITY WATER", systemImage: "drop.fill")
                            .font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(WaterTheme.teal)
                        Spacer()
                        Button { settings = true } label: { Image(systemName: "gearshape") }
                            .accessibilityLabel("Community settings")
                    }
                    VStack(alignment: .leading, spacing: 22) {
                        ZStack {
                            Circle().fill(.white.opacity(0.08)).frame(width: 170, height: 170)
                            Circle().stroke(.white.opacity(0.15), lineWidth: 1).frame(width: 130, height: 130)
                            Image(systemName: "drop.fill").font(.system(size: 64)).foregroundStyle(.white)
                            Image(systemName: "person.2.circle.fill").font(.system(size: 40))
                                .foregroundStyle(Color(red: 0.77, green: 0.92, blue: 0.75)).offset(x: 54, y: 46)
                        }.frame(maxWidth: .infinity)
                        Text("Every drop.\nEvery neighbour.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("Find water you can use. Share what you know. Help your community stay connected.")
                            .font(.body).foregroundStyle(.white.opacity(0.85))
                    }.padding(26).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                        .background(WaterTheme.teal.gradient, in: RoundedRectangle(cornerRadius: 28))
                    HStack(alignment: .top, spacing: 14) {
                        feature("Find water", symbol: "map")
                        feature("Share updates", symbol: "bubble.left.and.bubble.right")
                        feature("Track repairs", symbol: "wrench.adjustable")
                    }
                    VStack(spacing: 14) {
                        AuthPrimaryButton(title: "Create an account") { auth.clearFeedback(); path.append(.signUp) }
                        Button { auth.clearFeedback(); path.append(.signIn) } label: {
                            Text("I already have an account").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 11)
                        }.buttonStyle(.bordered).buttonBorderShape(.roundedRectangle(radius: 16))
                        Button("Explore as a guest") { auth.exploreAsGuest() }.font(.subheadline.weight(.semibold)).padding(5)
                    }
                    Text("A little local knowledge can make a big difference.").font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                }.padding(24)
            }.background(WaterTheme.paper).toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .signIn: SignInView { auth.clearFeedback(); path = [.signUp] }
                    case .signUp: SignUpView { auth.clearFeedback(); path = [.signIn] }
                    }
                }
                .sheet(isPresented: $settings) { SettingsView() }
        }
    }

    private func feature(_ title: String, symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title3).foregroundStyle(WaterTheme.teal)
            Text(title).font(.caption.weight(.medium)).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity)
    }
}
