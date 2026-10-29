import SwiftUI

/// The role's five destinations. Icons always travel with a label so the bar reads
/// at a glance, and the active tab takes the orange momentum colour.
struct MCRITabBar: View {
    @Binding var selection: Int
    var items: [Item]

    struct Item {
        var title: String
        var symbol: String
        var badge: Int = 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                MCRITabBarItem(
                    item: item,
                    isSelected: index == selection,
                    action: {
                        selection = index
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            }
        }
        .padding(.top, MCRITheme.Spacing.s2)
        .background(MCRITheme.sunken.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(MCRITheme.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab bar")
    }
}

private struct MCRITabBarItem: View {
    var item: MCRITabBar.Item
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? MCRITheme.primaryAction : MCRITheme.textTertiary)
                        .frame(height: 22)

                    if item.badge > 0 {
                        Text("\(item.badge)")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(MCRITheme.textOnAccent)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(MCRITheme.primaryAction, in: Capsule())
                            .offset(x: 8, y: -4)
                    }
                }

                Text(item.title)
                    .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? MCRITheme.textPrimary : MCRITheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Rectangle()
                    .fill(isSelected ? MCRITheme.primaryAction : .clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: MCRITheme.Metrics.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Hosts a role's five tabs. Every tab stays mounted so each NavigationStack
/// keeps its own path when the user hops between them.
struct MCRIRootTabView<Content: View>: View {
    @Binding var selection: Int
    var items: [MCRITabBar.Item]
    @ViewBuilder var content: (Int) -> Content

    var body: some View {
        ZStack {
            ForEach(0..<items.count, id: \.self) { index in
                content(index)
                    .opacity(index == selection ? 1 : 0)
                    .allowsHitTesting(index == selection)
                    .accessibilityHidden(index != selection)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MCRITabBar(selection: $selection, items: items)
        }
        .background(MCRITheme.background.ignoresSafeArea())
    }
}

private struct MCRITabBarPreviewHost: View {
    @State private var selection = 2
    var width: CGFloat = MCRIPhoneWidth.compact

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            MCRITabBar(selection: $selection, items: MCRIPreview.studentTabs)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(MCRITheme.background)
    }
}

private struct MCRITabBarPreview1: PreviewProvider {
    static var previews: some View {
    MCRITabBarPreviewHost()
}
}

private struct MCRITabBarPreview2: PreviewProvider {
    static var previews: some View {
    MCRITabBarPreviewHost(width: MCRIPhoneWidth.small)
}
}

private struct MCRITabBarPreview3: PreviewProvider {
    static var previews: some View {
    MCRITabBarPreviewHost(width: MCRIPhoneWidth.wide)
}
}

private struct MCRIRootTabPreviewHost: View {
    @State private var selection = 0

    var body: some View {
        MCRIRootTabView(selection: $selection, items: MCRIPreview.studentTabs) { index in
            NavigationStack {
                MCRIPage {
                    MCRISectionHeader(title: "Tab \(index + 1)",
                                      subtitle: "Each tab keeps its own scroll position.")
                    MCRIInternshipCard(role: MCRIPreview.flagship, isSaved: false,
                                       onSelect: { }, onSave: { })
                }
                .navigationTitle(MCRIPreview.studentTabs[index].title)
                .toolbarBackground(MCRITheme.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }
}

private struct MCRITabBarPreview4: PreviewProvider {
    static var previews: some View {
    MCRIRootTabPreviewHost()
}
}
