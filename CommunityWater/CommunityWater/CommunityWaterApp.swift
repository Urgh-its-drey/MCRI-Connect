import SwiftUI
import UIKit

@main
struct CommunityWaterApp: App {
    @StateObject private var store = WaterStore()
    @StateObject private var auth = AuthStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.canExplore { ExploreView() }
                else { WelcomeView() }
            }.environmentObject(store).environmentObject(auth).tint(WaterTheme.teal)
                .onChange(of: store.configuration) { _, _ in auth.signOut() }
                .task {
                    store.startMonitoring()
                    await store.sync()
                    while !Task.isCancelled {
                        do { try await Task.sleep(for: .seconds(60)) } catch { break }
                        if phase == .active { await store.sync() }
                    }
                }
                .onChange(of: phase) { _, value in
                    if value == .active { Task { await store.sync() } }
                }
        }
    }
}

enum WaterTheme {
    static let teal = Color(red: 0.04, green: 0.39, blue: 0.38)
    static let paper = Color(uiColor: .systemGroupedBackground)
}

extension Condition {
    var color: Color {
        switch self {
        case .working: WaterTheme.teal
        case .broken: .red
        case .dry: .orange
        case .unknown: .secondary
        }
    }
}

struct StatusBadge: View {
    let condition: Condition
    var body: some View {
        Label(condition.title, systemImage: condition.symbol)
            .font(.caption.weight(.semibold)).foregroundStyle(condition.color)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(condition.color.opacity(0.10), in: Capsule())
    }
}
