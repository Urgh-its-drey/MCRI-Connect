
import SwiftUI


private enum ExploreTheme {
    static let background = Color(hex: 0x153A55)
    static let card = Color(hex: 0x1D4865)
    static let savedSearch = Color(hex: 0x159BE8).opacity(0.16)
    static let text = Color(hex: 0xF7F9FA)
    static let muted = Color(hex: 0x546F83)
    static let red = Color(hex: 0xC4432A)
    static let charcoal = Color(hex: 0x55595C)
    static let orange = Color(hex: 0xFF6825)
    static let blue = Color(hex: 0x159BE8)
    static let border = Color(hex: 0x159BE8).opacity(0.38)
    static let secondary = Color(hex: 0x7B909F)
    static let placeholder = Color(hex: 0x89929A)
    static let tabBar = Color(hex: 0x2A536E)
    static let avatar = Color(hex: 0x102D42)
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255,
                  blue: Double(hex & 255) / 255, opacity: 1)
    }
}

private struct Internship: Identifiable, Hashable {
    let id: Int
    let title: String
    let company: String
    let location: String
    let weeks: Int
    let skills: String
    let match: Int
    let design: Bool
    var remote: Bool { location == "Remote" }
    var distanceKM: Int { remote ? 0 : (location.contains("Cape Town") ? 12 : 25) }
    
    static let examples: [Internship] = [
        .init(id: 0, title: "Product Design Intern", company: "Orbit Labs",
              location: "Remote", weeks: 12, skills: "Figma · User research · Prototyping",
              match: 94, design: true),
        .init(id: 1, title: "Mobile Developer Intern", company: "Northstar Labs",
              location: "Hybrid · Cape Town", weeks: 10, skills: "SwiftUI · Git · Accessibility",
              match: 88, design: false),
        .init(id: 2, title: "Data Analyst Intern", company: "MCRI Analytics",
              location: "On-site · Durban", weeks: 16, skills: "SQL · Python · Dashboards",
              match: 81, design: false)
    ]
    
    static let demo: [Internship] = examples + (3..<48).map { index in
        let example = examples[index % 3]
        return Internship(id: index, title: example.title,
                          company: "Demo Studio \(index + 1)",
                          location: example.location, weeks: example.weeks,
                          skills: example.skills, match: max(52, 80 - index / 2),
                          design: example.design)
    }
}

struct ExploreView: View {
    var onTabSelected: ((String) -> Void)? = nil
    @State private var search = ""
    @State private var remoteFirst = true
    @State private var designOnly = false
    @State private var internshipSelected = true
    @State private var paidSelected = true
    @State private var bookmarks: Set<Int> = [0]
    @State private var visibleCount = 3
    @State private var sortByMatch = true
    @State private var selectedTab = "Explore"
    @State private var showFilters = false
    @State private var selectedJob: Internship?
    @FocusState private var searchFocused: Bool
    
    private var results: [Internship] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return Internship.demo.filter { job in
            (!designOnly || job.design) && (query.isEmpty ||
                                            "\(job.title) \(job.company) \(job.location) \(job.skills)"
                .localizedCaseInsensitiveContains(query))
        }.sorted { lhs, rhs in
            if !sortByMatch { return lhs.id > rhs.id }
            // Remote is a ranking preference, so hybrid/on-site matches remain visible.
            let leftScore = lhs.match + (remoteFirst && lhs.remote ? 5 : 0)
            let rightScore = rhs.match + (remoteFirst && rhs.remote ? 5 : 0)
            if leftScore != rightScore { return leftScore > rightScore }
            if lhs.distanceKM != rhs.distanceKM { return lhs.distanceKM < rhs.distanceKM }
            return lhs.id < rhs.id
        }
    }
    
    private var displayedResults: [Internship] { results }
    
    var body: some View {
        NavigationStack {
            exploreContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: Binding(
                    get: { selectedJob != nil },
                    set: { if !$0 { selectedJob = nil } }
                )) {
                    if let job = selectedJob { MatchInsightsPreview(job: job) }
                }
        }
    }
    
    private var exploreContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                ExploreTheme.background.ignoresSafeArea()
                Circle()
                    .stroke(ExploreTheme.blue.opacity(0.10), lineWidth: 22)
                    .frame(width: 148, height: 148)
                    .offset(x: 36, y: -geometry.safeAreaInsets.top - 68)
                    .accessibilityHidden(true)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header.padding(.bottom, 16)
                        searchBar.padding(.bottom, 16)
                        savedSearch.padding(.bottom, 16)
                        filterChips.padding(.bottom, 12)
                        resultsHeader.padding(.bottom, 8)
                        
                        if displayedResults.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass").font(.title)
                                Text("No matches found").font(.headline)
                                Text("Try another role, skill, or company.")
                                    .font(.subheadline).foregroundStyle(ExploreTheme.secondary)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 35)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(displayedResults.prefix(visibleCount)) { job in
                                    jobCard(job)
                                }
                            }
                        }
                        
                        if displayedResults.count > visibleCount {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { visibleCount += 10 }
                            } label: {
                                VStack(spacing: 5) {
                                    Text("\(displayedResults.count - visibleCount) more internships match your filters")
                                        .font(.system(size: 12.5, weight: .bold))
                                    Text(sortByMatch ? "Sorted by fit, then distance" : "Newest listings first")
                                        .font(.system(size: 10.5)).foregroundStyle(ExploreTheme.secondary)
                                }
                                .frame(maxWidth: .infinity).frame(height: 62)
                                .background(ExploreTheme.card, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(ExploreTheme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(0, 50 - geometry.safeAreaInsets.top))
                    .padding(.bottom, 26)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(ExploreTheme.text)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
                    .frame(height: 78, alignment: .top)
                    .padding(.bottom, -geometry.safeAreaInsets.bottom)
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showFilters) { filterSheet }
        }
    }
    
    private var header: some View {
        ZStack(alignment: .topLeading) {
            Text("Explore").font(.system(size: 24, weight: .heavy))
                .tracking(-0.3)
            Text("121 internships · 14 new today")
                .font(.system(size: 11.5)).foregroundStyle(ExploreTheme.muted)
                .offset(y: 30)
            HStack {
                Spacer()
                Button { showFilters = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .frame(width: 36, height: 36)
                        .background(ExploreTheme.card, in: Circle())
                        .overlay(Circle().stroke(ExploreTheme.blue.opacity(0.2)))
                }
                .accessibilityLabel("Search preferences")
            }
        }.frame(height: 42, alignment: .topLeading)
    }
    
    private var searchBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(ExploreTheme.secondary)
                TextField("", text: $search,
                          prompt: Text("Search roles, skills, or companies")
                    .foregroundColor(ExploreTheme.placeholder))
                .font(.system(size: 13))
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { searchFocused = false }
                .accessibilityLabel("Search roles, skills, or companies")
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ExploreTheme.secondary)
                    }
                    .accessibilityLabel("Clear search")
                } else {
                    // Visual microphone affordance from the reference. Selecting
                    // the field opens the system keyboard, which offers dictation.
                    Image(systemName: "mic")
                        .font(.system(size: 12)).foregroundStyle(ExploreTheme.muted)
                        .frame(width: 30, height: 30)
                        .background(ExploreTheme.text.opacity(0.06), in: Circle())
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, 16).padding(.trailing, 5)
            .frame(height: 52)
            .background(ExploreTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ExploreTheme.border))
            
            Button { searchFocused = false } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(ExploreTheme.background)
                    .frame(width: 56, height: 52)
                    .background(ExploreTheme.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityLabel("Search")
        }
    }
    
    private var savedSearch: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(ExploreTheme.background)
                .frame(width: 24, height: 24)
                .background(ExploreTheme.blue, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Saved search").font(.system(size: 9.5, weight: .heavy))
                    .tracking(0.9).foregroundStyle(ExploreTheme.blue)
                Text("Product design · Remote · Paid")
                    .font(.system(size: 12, weight: .semibold))
            }
            Spacer(minLength: 0)
            Button("Edit") { showFilters = true }
                .font(.system(size: 12, weight: .bold)).foregroundStyle(ExploreTheme.blue)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.leading, 12).padding(.trailing, 4)
        .background(ExploreTheme.savedSearch, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(ExploreTheme.border.opacity(0.65)))
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Internship", icon: "briefcase", selected: internshipSelected) {
                    internshipSelected.toggle()
                }
                chip("Remote", icon: "mappin.and.ellipse", selected: remoteFirst) {
                    remoteFirst.toggle()
                }
                chip("Paid", icon: "checkmark", selected: paidSelected) {
                    paidSelected.toggle()
                }
                chip("Design", icon: "folder", selected: designOnly) {
                    designOnly.toggle()
                }
                chip("+6", icon: nil, selected: false) { showFilters = true }
            }
        }
        .frame(height: 32)
    }
    
    private func chip(_ label: String, icon: String?, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 10)) }
                Text(label).font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(selected ? ExploreTheme.background : ExploreTheme.muted)
            .frame(width: chipWidth(label), height: 32)
            .background(selected ? ExploreTheme.orange : ExploreTheme.card,
                        in: Capsule())
            .overlay(Capsule().stroke(selected ? Color.clear : ExploreTheme.border))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
    
    private func chipWidth(_ label: String) -> CGFloat {
        switch label {
        case "Internship": return 96.74
        case "Remote", "Design": return 74.32
        case "Paid": return 61.68
        default: return 34
        }
    }
    
    private var resultsHeader: some View {
        HStack(spacing: 4) {
            Text("\(results.count) matches").font(.system(size: 16, weight: .bold))
            Text("· 12 new").font(.system(size: 12)).foregroundStyle(ExploreTheme.secondary)
            Spacer(minLength: 4)
            Menu {
                Button("Most relevant") { sortByMatch = true }
                Button("Newest first") { sortByMatch = false }
            } label: {
                HStack {
                    Text(sortByMatch ? "Most relevant" : "Newest first")
                        .font(.system(size: 11, weight: .bold))
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down").font(.system(size: 9))
                        .foregroundStyle(ExploreTheme.secondary)
                }
                .padding(.horizontal, 9).frame(width: 128, height: 28)
                .background(ExploreTheme.card, in: Capsule())
                .overlay(Capsule().stroke(ExploreTheme.border))
            }
            .accessibilityLabel("Sort results")
        }.frame(height: 28)
    }
    
    private func jobCard(_ job: Internship) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(job.company.prefix(1)))
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(ExploreTheme.avatar, in: Circle())
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 5) {
                Text(job.title).font(.system(size: 14.5, weight: .semibold))
                    .tracking(-0.3).padding(.trailing, 56)
                Text(job.company).font(.system(size: 12))
                    .foregroundStyle(ExploreTheme.secondary)
                ViewThatFits(in: .horizontal) {
                    metadata(job, vertical: false)
                    metadata(job, vertical: true)
                }
                Text(job.skills).font(.system(size: 11))
                    .foregroundStyle(ExploreTheme.blue)
                    .padding(.trailing, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 20).padding(.trailing, 15).padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 108, alignment: .leading)
        .background(ExploreTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ExploreTheme.blue.opacity(0.2)))
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        .overlay(alignment: .leading) {
            if job.id == 0 {
                Capsule().fill(ExploreTheme.orange).frame(width: 4)
                    .padding(.vertical, 18).padding(.leading, 8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { selectedJob = job }
        .accessibilityAction(named: Text("View internship")) { selectedJob = job }
        .overlay(alignment: .topTrailing) {
            Text("\(job.match)% match").font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(job.id == 0 ? ExploreTheme.background : ExploreTheme.blue)
                .frame(width: 62, height: 26)
                .background(job.id == 0 ? ExploreTheme.orange : ExploreTheme.savedSearch,
                            in: Capsule())
                .padding(.top, 20).padding(.trailing, 20)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                if bookmarks.contains(job.id) { bookmarks.remove(job.id) }
                else { bookmarks.insert(job.id) }
            } label: {
                Image(systemName: bookmarks.contains(job.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 13))
                    .foregroundStyle(bookmarks.contains(job.id) ? ExploreTheme.orange : ExploreTheme.border)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 3).padding(.bottom, 4)
            .accessibilityLabel(bookmarks.contains(job.id) ? "Unsave \(job.title)" : "Save \(job.title)")
        }
    }
    
    private func metadata(_ job: Internship, vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: 3))
        : AnyLayout(HStackLayout(spacing: 6))
        return layout {
            Label(job.location, systemImage: "mappin.and.ellipse")
            Label("\(job.weeks) weeks", systemImage: "clock")
            if job.id == 0 {
                Label("Easy Apply", systemImage: "checkmark")
                    .foregroundStyle(ExploreTheme.blue)
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(ExploreTheme.secondary)
        .padding(.top, 3)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 0) {
            tab("Home", icon: "house")
            tab("Explore", icon: "magnifyingglass")
            tab("Applications", icon: "briefcase")
            tab("Messages", icon: "bubble.left", badge: true)
            tab("Profile", icon: "person")
        }
        .padding(.top, 10).padding(.bottom, 16)
        .background(ExploreTheme.tabBar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.15)).frame(height: 1) }
        .sheet(isPresented: Binding(get: { selectedTab != "Explore" }, set: {
            if !$0 { selectedTab = "Explore" }
        })) {
            NavigationStack {
                VStack(spacing: 12) {
                    Image(systemName: "hammer").font(.largeTitle)
                    Text(selectedTab).font(.title2.bold())
                    Text("Connect this tab to your app’s \(selectedTab.lowercased()) screen.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                .padding(30)
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedTab = "Explore" }
                } }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func tab(_ title: String, icon: String, badge: Bool = false) -> some View {
        Button {
            if let onTabSelected { onTabSelected(title) }
            else { selectedTab = title }
        } label: {
            VStack(spacing: 0) {
                Image(systemName: icon).font(.system(size: 19, weight: .regular))
                    .frame(width: 52, height: 42)
                    .background(title == selectedTab ? ExploreTheme.orange.opacity(0.16) : .clear,
                                in: RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        if badge {
                            Text("2").font(.system(size: 8, weight: .bold))
                                .foregroundStyle(ExploreTheme.text).frame(width: 11, height: 11)
                                .background(ExploreTheme.red, in: Circle())
                                .offset(x: -7, y: 0)
                        }
                    }
                Text(title).font(.system(size: 9.5, weight: .semibold))
            }
            .foregroundStyle(title == selectedTab ? ExploreTheme.orange : ExploreTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 53)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge ? "\(title), 2 unread" : title)
        .accessibilityAddTraits(title == selectedTab ? .isSelected : [])
    }
    
    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Prioritize remote roles", isOn: $remoteFirst)
                    Toggle("Design roles only", isOn: $designOnly)
                    Toggle("Internships", isOn: $internshipSelected)
                    Toggle("Paid", isOn: $paidSelected)
                }
                Section {
                    Text("All demo listings are paid internships. Remote is a ranking preference; hybrid and on-site results are included.")
                    Text("The saved search shown on the Explore screen is an example. Connect it to persistent storage in your app.")
                }.font(.footnote).foregroundStyle(.secondary)
            }
            .tint(ExploreTheme.orange)
            .navigationTitle("Search preferences")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showFilters = false }
            } }
        }
        .presentationDetents([.medium, .large])
    }
    
    
}

private struct MatchInsightsPreview: View {
    let job: Internship
    @Environment(\.dismiss) private var dismiss
    @State private var showApplicationNotice = false
    @State private var showProfileNotice = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(ExploreTheme.text.opacity(0.08), lineWidth: 9)
                        Circle().trim(from: 0, to: CGFloat(job.match) / 100)
                            .stroke(ExploreTheme.orange, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 5) {
                            Text("\(job.match)%").font(.system(size: 25, weight: .bold))
                            Text("YOUR MATCH").font(.system(size: 8, weight: .bold))
                                .tracking(0.8).foregroundStyle(ExploreTheme.secondary)
                        }
                    }.frame(width: 94, height: 94)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(job.title).font(.system(size: 16, weight: .bold))
                        Text("\(job.company) · \(job.location) · \(job.weeks) weeks")
                            .font(.system(size: 11)).foregroundStyle(ExploreTheme.secondary)
                        if job.id == 0 {
                            Label("Top 6% of applicants", systemImage: "sparkles")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(ExploreTheme.orange)
                            Text("A strong fit for your skills, interests and location goals")
                                .font(.system(size: 12)).foregroundStyle(ExploreTheme.secondary)
                        }
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(ExploreTheme.card, in: RoundedRectangle(cornerRadius: 22))
                
                Text("How we score this").font(.system(size: 18, weight: .bold))
                VStack(spacing: 16) {
                    score("Skills", value: job.id == 0 ? 96 : job.match, orange: true)
                    score("Interests", value: job.id == 0 ? 90 : max(0, job.match - 4))
                    score("Logistics", value: job.remote ? 100 : 85)
                    score("Profile", value: 78)
                }
                .padding(16)
                .background(ExploreTheme.card, in: RoundedRectangle(cornerRadius: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why this fits you").font(.system(size: 18, weight: .bold))
                    Text("Example signals from a demo profile")
                        .font(.system(size: 11)).foregroundStyle(ExploreTheme.secondary)
                }
                VStack(alignment: .leading, spacing: 15) {
                    signal("3 skills match this role", detail: job.skills, icon: "checkmark")
                    signal("Your campus app is relevant", detail: "Portfolio evidence aligns with the brief", icon: "folder")
                    signal(job.remote ? "Remote work matches you" : "Location fits your preferences",
                           detail: job.remote ? "Your profile is set to remote-first" : job.location,
                           icon: "mappin.and.ellipse")
                    signal("Timeline works", detail: "Example availability aligns with this internship", icon: "calendar")
                }
                Text("Matched skills").font(.system(size: 18, weight: .bold))
                Text(job.skills).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ExploreTheme.blue)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(ExploreTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                Button { showProfileNotice = true } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Add one case study → +7% match")
                        Spacer()
                        Text("Do it").fontWeight(.bold)
                    }
                    .font(.system(size: 11)).foregroundStyle(ExploreTheme.orange)
                    .padding(16)
                    .background(ExploreTheme.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding(20)
        }
        .background(ExploreTheme.background.ignoresSafeArea())
        .foregroundStyle(ExploreTheme.text)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Easy Apply · 1 tap").font(.system(size: 12, weight: .bold))
                    Text("Demo application preview").font(.system(size: 10))
                        .foregroundStyle(ExploreTheme.secondary)
                }
                Spacer(minLength: 0)
                Button("Apply now") { showApplicationNotice = true }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ExploreTheme.background)
                    .padding(.horizontal, 24).frame(height: 48)
                    .background(ExploreTheme.orange, in: Capsule())
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(ExploreTheme.tabBar.ignoresSafeArea(edges: .bottom))
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(ExploreTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").foregroundStyle(ExploreTheme.text)
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Back to Explore")
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 3) {
                    Text("Match insights").font(.system(size: 16, weight: .bold))
                    Text("Explainable fit · updated today").font(.system(size: 10))
                        .foregroundStyle(ExploreTheme.secondary)
                }
            }
        }
        .alert("Application preview", isPresented: $showApplicationNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect your resume, portfolio, and application service here. No application has been sent.")
        }
        .alert("Profile improvement", isPresented: $showProfileNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Connect your profile editor here. The +7% improvement is an example from the design.")
        }
    }
    
    private func score(_ title: String, value: Int, orange: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.system(size: 12, weight: .semibold)).frame(width: 55, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(ExploreTheme.text.opacity(0.08))
                    Capsule().fill(orange ? ExploreTheme.orange : ExploreTheme.blue)
                        .frame(width: geometry.size.width * CGFloat(value) / 100)
                }
            }.frame(height: 7)
            Text("\(value)").font(.system(size: 12, weight: .bold))
                .frame(width: 28, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value) percent")
    }
    
    private func signal(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundStyle(ExploreTheme.blue)
                .frame(width: 32, height: 32)
                .background(ExploreTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(detail).font(.system(size: 10)).foregroundStyle(ExploreTheme.secondary)
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView().previewDevice("iPhone 14")
    }
}
