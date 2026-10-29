import SwiftUI

struct StudentDashboardView: View {
  @State private var tab = DBTab.home
  @State private var opportunities = DBOpportunity.samples
  @State private var exploreFilter = DBFilter.all
  @State private var search = ""
  @State private var selectedOpportunity: DBOpportunity?
  @State private var showNotifications = false
  @State private var name = "Alex Mensah"
  @State private var course = "BSc Product Design · Year 2"
  @State private var caseStudy = ""
  @State private var reviewConsent = false
  private var savedCount: Int { opportunities.filter { $0.saved }.count }
  private var appliedCount: Int { opportunities.filter { $0.applicationStatus != nil }.count }
  private var newMatches: [DBOpportunity] { opportunities.filter { $0.isNew } }
  private var highNewCount: Int { newMatches.filter { $0.fit > 90 }.count }
  private var initials: String {
    name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
  }
  private var firstName: String {
    guard let first = name.split(separator: " ").first else { return "there" }
    return String(first)
  }
  private var featuredOpportunities: [DBOpportunity] {
    Array(opportunities.prefix(2))
  }
  private var appliedOpportunities: [DBOpportunity] {
    opportunities.filter { $0.applicationStatus != nil }
  }
  private var filtered: [DBOpportunity] {
    opportunities.filter { opportunity in
      let matchesFilter =
        exploreFilter == .all || (exploreFilter == .saved && opportunity.saved)
        || (exploreFilter == .new && opportunity.isNew)
      let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
      let matchesSearch =
        query.isEmpty || opportunity.title.localizedCaseInsensitiveContains(query)
        || opportunity.company.localizedCaseInsensitiveContains(query)
        || opportunity.skills.joined(separator: " ").localizedCaseInsensitiveContains(query)
      return matchesFilter && matchesSearch
    }.sorted { $0.fit > $1.fit }
  }
  var body: some View {
    NavigationStack {
      tabContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DBTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(item: $selectedOpportunity) { opportunity in opportunitySheet(opportunity) }
        .sheet(isPresented: $showNotifications) { notificationsSheet }
    }
    .foregroundStyle(DBTheme.text).tint(DBTheme.blue).preferredColorScheme(.dark)
  }
  @ViewBuilder
  private var tabContent: some View {
    switch tab {
    case .home: home
    case .explore: Explore()
    case .applications: applications
    case .messages: messages
    case .profile: profile
    }
  }
  private var home: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        greeting
        newMatchesBanner
        profileStrength
        statistics
        HStack {
          Text("Best matches for you").font(.headline)
          Spacer()
          Button("See all ›") { openExplore(.all) }.font(.subheadline.bold())
        }
        ForEach(featuredOpportunities) { opportunity in opportunityCard(opportunity) }
        Button {
          openExplore(.all)
        } label: {
          Text("Pull up for \(opportunities.count) open internships")
            .font(.caption.weight(.semibold)).foregroundStyle(DBTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 36).contentShape(Rectangle())
        }
        .simultaneousGesture(
          DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.height < -30 { openExplore(.all) }
          })
      }
      .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
    }
  }
  private var header: some View {
    HStack(spacing: 10) {
      Image(systemName: "m.square.fill").font(.system(size: 32))
        .foregroundStyle(DBTheme.orange)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text("MCRI Connect").font(.headline)
        Text("Internship matching").font(.caption).foregroundStyle(DBTheme.secondary)
      }
      Spacer(minLength: 0)
      Button {
        showNotifications = true
      } label: {
        Image(systemName: "bell").frame(width: 36, height: 36)
          .background(DBTheme.surface, in: Circle())
          .overlay(alignment: .topTrailing) {
            Circle().fill(DBTheme.red).frame(width: 7, height: 7)
          }
      }.accessibilityLabel("Open notifications")
      Button {
        tab = .profile
      } label: {
        Text(initials.isEmpty ? "AM" : initials).font(.caption.bold())
          .foregroundStyle(DBTheme.background).frame(width: 38, height: 38)
          .background(DBTheme.orange, in: Circle())
      }.accessibilityLabel("Open your profile")
    }
  }

  private var greeting: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Hello, \(firstName) 👋")
        .font(.title2.bold())
      Text("Find an internship that fits your skills and interests.")
        .font(.subheadline)
        .foregroundStyle(DBTheme.secondary)
    }
  }

  private var newMatchesBanner: some View {
    Button {
      openExplore(.new)
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "sparkles")
          .font(.title2)
          .foregroundStyle(DBTheme.orange)
        VStack(alignment: .leading, spacing: 5) {
          Text("\(newMatches.count) new matches")
            .font(.headline)
          Text("\(highNewCount) with more than 90% sample alignment")
            .font(.caption)
            .foregroundStyle(DBTheme.secondary)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .foregroundStyle(DBTheme.blue)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .dbCard()
    }
    .buttonStyle(.plain)
  }
  private var profileStrength: some View {
    Button {
      tab = .profile
    } label: {
      HStack(spacing: 16) {
        DBProfileRing(value: 78)
        VStack(alignment: .leading, spacing: 6) {
          Text("Profile strength").font(.headline)
          Text("Add a case study to show what you can do.")
            .font(.caption)
            .foregroundStyle(DBTheme.secondary)
          Text("Complete your profile ›")
            .font(.caption.bold())
            .foregroundStyle(DBTheme.blue)
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .dbCard()
    }
    .buttonStyle(.plain)
  }
  private var statistics: some View {
    HStack(alignment: .top, spacing: 10) {
      DBStatCard(title: "Saved", value: savedCount, symbol: "bookmark.fill", accent: DBTheme.orange)
      {
        openExplore(.saved)
      }
      DBStatCard(
        title: "Applications", value: appliedCount, symbol: "briefcase.fill", accent: DBTheme.blue
      ) {
        tab = .applications
      }
    }
  }
  private var explore: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Explore internships").font(.title2.bold())
        TextField("Search roles, companies or skills", text: $search)
          .textFieldStyle(.plain)
          .autocorrectionDisabled()
          .dbCard(padding: 12)
        exploreFilters
        Text("\(filtered.count) opportunities")
          .font(.caption)
          .foregroundStyle(DBTheme.secondary)
        if filtered.isEmpty {
          Text("No opportunities match your search.")
            .foregroundStyle(DBTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dbCard()
        } else {
          ForEach(filtered) { opportunity in
            opportunityCard(opportunity)
          }
        }
      }
      .padding(20)
      .frame(maxWidth: 600)
      .frame(maxWidth: .infinity)
    }
  }

  private var exploreFilters: some View {
    HStack(spacing: 8) {
      ForEach(DBFilter.allCases) { item in
        exploreFilterButton(item)
      }
    }
  }

  private func exploreFilterButton(_ item: DBFilter) -> some View {
    let isSelected: Bool = exploreFilter == item
    let traits: AccessibilityTraits = isSelected ? .isSelected : []
    return Button(item.rawValue) {
      exploreFilter = item
    }
    .font(.caption.bold())
    .padding(.horizontal, 16)
    .frame(minHeight: 44)
    .foregroundStyle(isSelected ? DBTheme.background : DBTheme.text)
    .background(isSelected ? DBTheme.orange : DBTheme.surface, in: Capsule())
    .buttonStyle(.plain)
    .accessibilityAddTraits(traits)
  }

  private func opportunityCard(_ opportunity: DBOpportunity) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      opportunityCardHeader(opportunity)
      Text("\(opportunity.location) · \(opportunity.duration)")
        .font(.caption)
        .foregroundStyle(DBTheme.secondary)
      Text(opportunity.skills.joined(separator: " · "))
        .font(.caption)
        .foregroundStyle(DBTheme.secondary)
      HStack {
        Label("\(opportunity.fit)% sample alignment", systemImage: "checkmark.seal")
          .font(.caption.bold())
          .foregroundStyle(DBTheme.orange)
        Spacer(minLength: 0)
        Button("View role") { openOpportunity(opportunity) }
          .font(.caption.bold())
          .frame(minHeight: 44)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .dbCard()
  }

  private func opportunityCardHeader(_ opportunity: DBOpportunity) -> some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 5) {
        Text(opportunity.title).font(.headline)
        Text(opportunity.company)
          .font(.subheadline)
          .foregroundStyle(DBTheme.secondary)
        if opportunity.isNew {
          Text("New match")
            .font(.caption2.bold())
            .foregroundStyle(DBTheme.orange)
        }
      }
      Spacer(minLength: 0)
      Button {
        toggleSaved(opportunity)
      } label: {
        Image(systemName: opportunity.saved ? "bookmark.fill" : "bookmark")
          .foregroundStyle(DBTheme.orange)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        opportunity.saved ? "Unsave \(opportunity.title)" : "Save \(opportunity.title)")
    }
  }
  private func openExplore(_ filter: DBFilter) {
    exploreFilter = filter
    search = ""
    tab = .explore
  }
  private func openOpportunity(_ opportunity: DBOpportunity) {
    reviewConsent = false
    selectedOpportunity = opportunity
  }
  private func toggleSaved(_ opportunity: DBOpportunity) {
    guard let index = opportunities.firstIndex(where: { $0.id == opportunity.id }) else { return }
    opportunities[index].saved.toggle()
  }
  private var applications: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Applications").font(.title2.bold())
        Text("\(appliedCount) demo applications").font(.caption).foregroundStyle(DBTheme.secondary)
        ForEach(appliedOpportunities) { opportunity in
          Button {
            openOpportunity(opportunity)
          } label: {
            VStack(alignment: .leading, spacing: 6) {
              Text(opportunity.title).font(.headline)
              Text(opportunity.company).font(.caption).foregroundStyle(DBTheme.secondary)
              Label(opportunity.applicationStatus ?? "Submitted", systemImage: "checkmark.circle")
                .font(.caption).foregroundStyle(DBTheme.blue)
            }.frame(maxWidth: .infinity, alignment: .leading).dbCard()
          }.buttonStyle(.plain)
        }
      }.padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
    }
  }
  private var messages: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Messages").font(.title2.bold())
      Text("No conversations yet.").foregroundStyle(DBTheme.secondary)
      Spacer()
    }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  private var profile: some View {
    Form {
      Section("Your profile") {
        TextField("Name", text: $name)
        TextField("Course and year", text: $course)
      }.listRowBackground(DBTheme.surface)
      Section("Case study draft") {
        TextEditor(text: $caseStudy).scrollContentBackground(.hidden).frame(minHeight: 150)
          .accessibilityLabel("Case study draft")
      }.listRowBackground(DBTheme.surface)
      Section {
        Text(
          "Edits are retained for this session only. The example 78% completeness indicator is not recalculated from this draft."
        )
        .font(.caption).foregroundStyle(DBTheme.secondary)
      }.listRowBackground(DBTheme.surface)
    }.scrollContentBackground(.hidden)
  }
  private func opportunitySheet(_ opportunity: DBOpportunity) -> some View {
    NavigationStack {
      Form {
        Section("Opportunity") {
          Text(opportunity.title).font(.headline)
          Text(opportunity.company)
          Text("\(opportunity.location) · \(opportunity.duration)")
          LabeledContent("Sample alignment", value: "\(opportunity.fit)%")
          Text(opportunity.skills.joined(separator: " · "))
        }.listRowBackground(DBTheme.surface)
        Section("Application") {
          if let status = opportunities.first(where: { $0.id == opportunity.id })?.applicationStatus
          {
            Label(status, systemImage: "checkmark.circle")
            Text("Example record only; no application has been sent by this prototype.")
              .font(.caption).foregroundStyle(DBTheme.secondary)
          } else {
            Toggle("I confirm this demo application", isOn: $reviewConsent)
            Button("Apply (demo)") {
              guard reviewConsent,
                let index = opportunities.firstIndex(where: { $0.id == opportunity.id }),
                opportunities[index].applicationStatus == nil
              else { return }
              opportunities[index].applicationStatus = "Submitted"
              selectedOpportunity = nil
            }.disabled(!reviewConsent)
            Text("Records a local demo application only. Nothing is sent to an employer.")
              .font(.caption).foregroundStyle(DBTheme.secondary)
          }
        }.listRowBackground(DBTheme.surface)
      }
      .scrollContentBackground(.hidden).background(DBTheme.background)
      .navigationTitle("Opportunity details").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { selectedOpportunity = nil } }
      }
    }.foregroundStyle(DBTheme.text).tint(DBTheme.blue).preferredColorScheme(.dark)
  }
  private var notificationsSheet: some View {
    NavigationStack {
      List {
        Section("Sample notifications") {
          Text("3 new matches are available.")
          Text("Add project evidence to strengthen your profile.")
        }.listRowBackground(DBTheme.surface)
      }.scrollContentBackground(.hidden).background(DBTheme.background)
        .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { showNotifications = false }
          }
        }
    }.foregroundStyle(DBTheme.text).tint(DBTheme.blue).preferredColorScheme(.dark)
  }
  private var bottomBar: some View {
    HStack(spacing: 0) {
      ForEach(DBTab.allCases) { item in
        bottomTabButton(item)
      }
    }
    .padding(.vertical, 8)
    .background(DBTheme.surface)
  }
  private func bottomTabButton(_ item: DBTab) -> some View {
    let selected: Bool = tab == item
    let labelColor: Color = selected ? DBTheme.orange : DBTheme.secondary
    let labelWeight: Font.Weight = selected ? .bold : .regular
    let traits: AccessibilityTraits = selected ? .isSelected : []
    return Button {
      tab = item
    } label: {
      VStack(spacing: 5) {
        Image(systemName: item.icon).font(.system(size: 19))
        Text(item.rawValue).font(.system(size: 9, weight: labelWeight))
      }
      .frame(maxWidth: .infinity, minHeight: 44)
      .foregroundStyle(labelColor)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(item.rawValue)
    .accessibilityAddTraits(traits)
  }

}
private struct DBProfileRing: View {
  let value: Int
  var body: some View {
    ZStack {
      Circle().stroke(DBTheme.background, lineWidth: 8)
      Circle().trim(from: 0, to: CGFloat(value) / 100)
        .stroke(DBTheme.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(value)%").font(.system(size: 23, weight: .bold))
    }.frame(width: 80, height: 80)
      .accessibilityElement(children: .ignore).accessibilityLabel(
        "Example profile completeness, \(value) percent")
  }
}
private struct DBStatCard: View {
  let title: String
  let value: Int
  let symbol: String
  let accent: Color
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: symbol).foregroundStyle(accent)
          Spacer()
          Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(accent)
            .accessibilityHidden(true)
        }
        Text(String(value)).font(.title.bold())
        Text(title).font(.caption.weight(.semibold)).foregroundStyle(DBTheme.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading).dbCard(padding: 12)
    }.buttonStyle(.plain)
  }
}
private enum DBTab: String, Identifiable, CaseIterable {
  case home = "Home"
  case explore = "Explore"
  case applications = "Applications"
  case messages = "Messages"
  case profile = "Profile"
  var id: String { rawValue }
  var icon: String {
    switch self {
    case .home: return "house"
    case .explore: return "magnifyingglass"
    case .applications: return "briefcase"
    case .messages: return "bubble.left"
    case .profile: return "person"
    }
  }
}
private enum DBFilter: String, Identifiable, CaseIterable {
  case all = "All"
  case saved = "Saved"
  case new = "New"
  var id: String { rawValue }
}
private struct DBOpportunity: Identifiable {
  let id: String
  let title: String
  let company: String
  let location: String
  let duration: String
  let skills: [String]
  let fit: Int
  let isNew: Bool
  var saved: Bool
  var applicationStatus: String? = nil
  static let samples: [DBOpportunity] = makeSamples()
  private static func makeSamples() -> [DBOpportunity] {
    var result: [DBOpportunity] = []
    for index in 0..<24 {
      result.append(makeSample(index: index))
    }
    return result
  }
  private static func makeSample(index: Int) -> DBOpportunity {
    if index == 0 {
      return DBOpportunity(
        id: "role-0", title: "Product Design Intern", company: "Orbit Labs",
        location: "Remote", duration: "12 weeks",
        skills: ["Figma", "User research", "Prototyping"], fit: 94,
        isNew: true, saved: true, applicationStatus: nil)
    }
    if index == 1 {
      return DBOpportunity(
        id: "role-1", title: "Mobile Developer Intern", company: "Northstar Labs",
        location: "Hybrid · Cape Town", duration: "10 weeks",
        skills: ["SwiftUI", "Git", "Accessibility"], fit: 88,
        isNew: false, saved: false, applicationStatus: nil)
    }
    let design: Bool = index % 2 == 0
    let title: String = design ? "UX Design Intern" : "Software Intern"
    let skills: [String] =
      design
      ? ["Research", "Figma", "Teamwork"]
      : ["Swift", "Git", "Problem-solving"]
    let score: Int = index == 2 ? 93 : 89 - index
    let isNew: Bool = index == 2 || index == 3
    let isSaved: Bool = (2...8).contains(index)
    let appliedIndices: [Int] = [4, 9, 13]
    let status: String? = appliedIndices.contains(index) ? "Under review" : nil
    return DBOpportunity(
      id: "role-\(index)", title: title, company: "Demo Partner \(index - 1)",
      location: "Remote", duration: "12 weeks", skills: skills, fit: score,
      isNew: isNew, saved: isSaved, applicationStatus: status)
  }

}
private enum DBTheme {
  static let background = Color(dbHex: 0x153A55)
  static let surface = Color(dbHex: 0x1D4865)
  static let orange = Color(dbHex: 0xFF6825)
  static let blue = Color(dbHex: 0x159BE8)
  static let red = Color(dbHex: 0xC4432A)
  static let text = Color(dbHex: 0xF7F9FA)
  static let secondary = Color(dbHex: 0x89929A)
}
extension Color {
  fileprivate init(dbHex: UInt32) {
    self.init(
      .sRGB, red: Double((dbHex >> 16) & 255) / 255,
      green: Double((dbHex >> 8) & 255) / 255,
      blue: Double(dbHex & 255) / 255, opacity: 1)
  }
}
extension View {
  fileprivate func dbCard(padding: CGFloat = 16) -> some View {
    self.padding(padding).background(DBTheme.surface, in: RoundedRectangle(cornerRadius: 20))
      .overlay(
        RoundedRectangle(cornerRadius: 20).strokeBorder(DBTheme.blue.opacity(0.25), lineWidth: 1))
  }
}
struct StudentDashboardView_Previews: PreviewProvider {
  static var previews: some View { StudentDashboardView() }
}
