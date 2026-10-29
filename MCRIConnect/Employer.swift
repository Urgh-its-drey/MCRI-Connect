import SwiftUI


struct EmployerPipelineView: View {
    @State private var candidates = PipelineCandidate.samples
    @State private var filter = PipelineFilter.strong
    @State private var stageFilter: PipelineStage?
    @State private var tableView = false
    @State private var highestFitFirst = true
    @State private var showAllMatches = false
    @State private var profile: PipelineCandidate?
    @State private var message: PipelineCandidate?
    @State private var search = ""
    @State private var showSearch = false
    @State private var drafts: [String: String] = [:]
    @State private var selectedFooterItem = "Candidates"

    private var strongCount: Int { candidates.filter { $0.fit >= 70 }.count }
    private func count(_ stage: PipelineStage) -> Int { candidates.filter { $0.stage == stage }.count }
    private var filtered: [PipelineCandidate] {
        candidates.filter { candidate in
            let matchesTab: Bool
            switch filter {
            case .all: matchesTab = true
            case .strong: matchesTab = candidate.fit >= 70
            case .shortlisted: matchesTab = candidate.shortlisted
            case .interview: matchesTab = candidate.stage == .interview
            }
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || candidate.name.localizedCaseInsensitiveContains(query) || candidate.skills.joined(separator: " ").localizedCaseInsensitiveContains(query)
            return matchesTab && matchesSearch && (stageFilter == nil || candidate.stage == stageFilter)
        }.sorted {
            if highestFitFirst && $0.fit != $1.fit { return $0.fit > $1.fit }
            return $0.order < $1.order
        }
    }
    private var visible: [PipelineCandidate] { showAllMatches ? filtered : Array(filtered.prefix(2)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if showSearch {
                        TextField("Search candidates or skills", text: $search)
                            .textFieldStyle(.plain).padding(12)
                            .background(PipelinePalette.surface, in: RoundedRectangle(cornerRadius: 12))
                            .autocorrectionDisabled()
                    }
                    opportunity
                    summary
                    stageBoard
                    filters
                    candidateList
                    Text("Demo · Changes and message drafts stay in this session.")
                        .font(.caption2).foregroundStyle(PipelinePalette.secondary)
                }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
                    .frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .background(PipelinePalette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { referenceFooter }
            .sheet(item: $profile) { candidate in profileSheet(candidate) }
            .sheet(item: $message) { candidate in draftSheet(candidate) }
            .onChange(of: stageFilter) { _ in showAllMatches = false }
        }
        .foregroundStyle(PipelinePalette.text)
        .tint(PipelinePalette.blue)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "building.2.crop.circle").font(.title2)
                .foregroundStyle(PipelinePalette.red)
            VStack(alignment: .leading, spacing: 3) {
                Text("Orbit Labs").font(.headline)
                Text("Talent team · 4 open roles").font(.caption).foregroundStyle(PipelinePalette.secondary)
            }
            Spacer()
            Button {
                showSearch.toggle()
                if !showSearch { search = "" }
            } label: { Image(systemName: "magnifyingglass").frame(width: 36, height: 36) }
                .accessibilityLabel("Show or hide candidate search")
            Text("TS").font(.caption.bold()).foregroundStyle(PipelinePalette.background).padding(12)
                .background(PipelinePalette.orange, in: Circle())
                .accessibilityLabel("Talent team account")
        }
    }
    private var opportunity: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Product Design Intern").font(.headline)
            Text("Posted 21 Sep · closes 14 Nov").font(.caption).foregroundStyle(PipelinePalette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).pipelineCard()
    }
    private var summary: some View {
        HStack(alignment: .top, spacing: 8) {
            metric("APPLICANTS", "\(candidates.count)", "+5 this week")
            metric("STRONG", "\(strongCount)", "\(Int((Double(strongCount) / Double(max(candidates.count, 1)) * 100).rounded()))% of pool")
            metric("INTERVIEWS", "\(count(.interview))", "\(candidates.filter { $0.stage == .interview && $0.interviewBooked }.count) booked")
        }
    }
    private func metric(_ title: String, _ value: String, _ note: String) -> some View {
        let valueColor: Color
        if title == "STRONG" {
            valueColor = PipelinePalette.orange
        } else if title == "INTERVIEWS" {
            valueColor = PipelinePalette.blue
        } else {
            valueColor = PipelinePalette.text
        }
        return VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(PipelinePalette.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(valueColor)
            Text(note).font(.system(size: 10)).foregroundStyle(PipelinePalette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).pipelineCard(padding: 12)
    }
    private var stageBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            stageBoardHeader
            stageBoardStages
            if let stage = stageFilter {
                Button("Clear \(stage.rawValue) stage filter") {
                    stageFilter = nil
                }
                .font(.caption)
            }
        }
    }

    private var stageBoardHeader: some View {
        HStack {
            Text("Stage board").font(.headline)
            Spacer()
            Button(tableView ? "Card view" : "Table view") {
                tableView.toggle()
            }
            .font(.subheadline)
        }
    }

    private var stageBoardStages: some View {
        HStack(spacing: 8) {
            ForEach(PipelineStage.allCases) { stage in
                stageButton(stage)
            }
        }
    }

    private func stageButton(_ stage: PipelineStage) -> some View {
        let isSelected: Bool = stageFilter == stage
        let selectionColor: Color = PipelinePalette.orange.opacity(isSelected ? 1 : 0)
        let selectionTraits: AccessibilityTraits = isSelected ? .isSelected : []
        let applicantCount: Int = count(stage)

        return Button {
            if isSelected {
                stageFilter = nil
            } else {
                filter = .all
                stageFilter = stage
            }
        } label: {
            stageCard(stage, applicantCount: applicantCount)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selectionColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stage.rawValue), \(applicantCount) applicants, filter stage")
        .accessibilityAddTraits(selectionTraits)
    }

    private func stageCard(_ stage: PipelineStage, applicantCount: Int) -> some View {
        let total: Double = Double(max(candidates.count, 1))
        let progress: Double = Double(applicantCount)
        let percentage: Int = Int((progress / total * 100).rounded())
        let progressColor: Color = stage == .interview ? PipelinePalette.orange : PipelinePalette.blue

        return VStack(alignment: .leading, spacing: 6) {
            Text("\(applicantCount)").font(.title3.bold())
            Text(stage.rawValue).font(.system(size: 11))
            ProgressView(value: progress, total: total)
                .tint(progressColor)
            Text("\(percentage)%")
                .font(.caption2)
                .foregroundStyle(PipelinePalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pipelineCard(padding: 10)
    }
    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PipelineFilter.allCases) { item in
                    Button(item == .all ? "All \(candidates.count)" : item.rawValue) {
                        filter = item; stageFilter = nil; showAllMatches = false
                    }
                    .font(.caption)
                    .buttonStyle(PipelineActionStyle(filled: filter == item))
                    .accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }.padding(.vertical, 2)
        }
    }
    private var candidateList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(filtered.count) candidates match this role").font(.subheadline.weight(.semibold))
                Spacer(minLength: 4)
                Button { highestFitFirst.toggle() } label: {
                    Label("Fit", systemImage: highestFitFirst ? "arrow.down" : "clock")
                        .font(.caption)
                }.accessibilityLabel(highestFitFirst ? "Sorted by fit. Switch to application order" : "Sorted by application order. Switch to fit")
            }
            if filtered.isEmpty {
                Text("No candidates in this filter yet.").foregroundStyle(PipelinePalette.secondary).pipelineCard()
            } else if tableView {
                VStack(spacing: 0) {
                    HStack { Text("Candidate"); Spacer(); Text("Fit"); Text("Stage").frame(width: 70) }
                        .font(.caption.bold()).padding(.bottom, 12)
                    ForEach(filtered) { candidate in
                        Divider()
                        Button { profile = candidate } label: {
                            HStack {
                                Text(candidate.name).frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(candidate.fit)").frame(width: 32)
                                Text(candidate.stage.rawValue).frame(width: 70)
                            }.font(.caption).padding(.vertical, 14).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.pipelineCard()
            } else {
                ForEach(visible) { candidate in candidateCard(candidate) }
                if filtered.count > visible.count {
                    Button { showAllMatches = true } label: {
                        VStack(spacing: 5) {
                            Text("\(filtered.count - visible.count) more candidates\(filter == .strong ? " at 70% fit or above" : " in this filter")")
                                .font(.caption.bold())
                            Text(filtered.dropFirst(visible.count).prefix(2).map(\.name).joined(separator: " · ") + (filtered.count - visible.count > 2 ? " · +\(filtered.count - visible.count - 2)" : ""))
                                .font(.caption2).foregroundStyle(PipelinePalette.secondary)
                        }.frame(maxWidth: .infinity).padding(12)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    private func candidateCard(_ candidate: PipelineCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(candidate.initials).font(.caption.bold()).frame(width: 34, height: 34)
                    .background(PipelinePalette.background, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(candidate.name).font(.subheadline.bold())
                        if candidate.fit == candidates.map(\.fit).max() { Text("Top pick").font(.system(size: 9)).foregroundStyle(PipelinePalette.orange).padding(4).background(PipelinePalette.orange.opacity(0.15), in: Capsule()) }
                    }
                    Text(candidate.skills.joined(separator: " · ")).font(.system(size: 10)).foregroundStyle(PipelinePalette.secondary)
                    Label(candidate.project, systemImage: "rectangle.stack").font(.system(size: 10)).foregroundStyle(PipelinePalette.secondary)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle().stroke(PipelinePalette.blue.opacity(0.18), lineWidth: 4)
                    Circle().trim(from: 0, to: CGFloat(candidate.fit) / 100)
                        .stroke(candidate.fit == candidates.map(\.fit).max() ? PipelinePalette.orange : PipelinePalette.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(candidate.fit)").font(.caption.bold())
                }.frame(width: 38, height: 38)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(candidate.fit) percent alignment")
            }
            HStack(spacing: 8) {
                Button(candidate.shortlisted ? "Shortlisted" : "Shortlist") { shortlist(candidate.id) }
                    .buttonStyle(PipelineActionStyle(filled: true)).disabled(candidate.shortlisted)
                Button("Message") { message = candidate }.buttonStyle(PipelineActionStyle(filled: false))
                Spacer(minLength: 0)
                Button("View profile") { profile = candidate }
            }.font(.system(size: 11))
        }.pipelineCard()
    }
    private func shortlist(_ id: String) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].shortlisted = true
        if candidates[index].stage == .new { candidates[index].stage = .screen }
    }
    private func profileSheet(_ candidate: PipelineCandidate) -> some View {
        NavigationStack {
            List {
                Section("Student") {
                    Text(candidate.name).font(.headline)
                    LabeledContent("Alignment", value: "\(candidate.fit)%")
                    LabeledContent("Stage", value: candidate.stage.rawValue)
                    LabeledContent("Shortlisted", value: candidate.shortlisted ? "Yes" : "No")
                }.listRowBackground(PipelinePalette.surface)
                Section("Skills") { ForEach(candidate.skills, id: \.self) { Text($0) } }
                    .listRowBackground(PipelinePalette.surface)
                Section("Project evidence") {
                    Text(candidate.project)
                    Text("Student-provided sample evidence. Review individual contribution and proficiency before deciding.")
                        .font(.caption).foregroundStyle(PipelinePalette.secondary)
                }
                .listRowBackground(PipelinePalette.surface)
                Section("Actions") {
                    Button(candidate.shortlisted ? "Already shortlisted" : "Shortlist candidate") {
                        shortlist(candidate.id); profile = nil
                    }.disabled(candidate.shortlisted)
                    if let next = candidate.stage.next {
                        Button("Move to \(next.rawValue.lowercased())") {
                            if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
                                candidates[index].stage = next
                                candidates[index].interviewBooked = false
                            }
                            profile = nil
                        }
                    }
                }
                .listRowBackground(PipelinePalette.surface)
                Section {
                    Text("Demo scores and evidence. Stage changes do not schedule interviews or send offers. Student acceptance and manager placement confirmation are separate.")
                        .font(.caption).foregroundStyle(PipelinePalette.secondary)
                }
                .listRowBackground(PipelinePalette.surface)
            }.scrollContentBackground(.hidden).background(PipelinePalette.background)
                .navigationTitle("Candidate profile").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { profile = nil } } }
        }
    }
    private func draftSheet(_ candidate: PipelineCandidate) -> some View {
        NavigationStack {
            Form {
                Section("To") { Text(candidate.name) }.listRowBackground(PipelinePalette.surface)
                Section("Message draft") {
                    TextEditor(text: Binding(get: { drafts[candidate.id, default: ""] }, set: { drafts[candidate.id] = $0 }))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180).accessibilityLabel("Message to \(candidate.name)")
                }
                .listRowBackground(PipelinePalette.surface)
                Section {
                    Text("Draft only. Text is retained during this session. No message is sent.")
                        .font(.caption).foregroundStyle(PipelinePalette.secondary)
                }
                .listRowBackground(PipelinePalette.surface)
            }.scrollContentBackground(.hidden).background(PipelinePalette.background)
                .navigationTitle("Message draft").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { message = nil } } }
        }
    }
  
    private var referenceFooter: some View {
        HStack(spacing: 0) {
            footerItem("Dashboard", "house")
            footerItem("Internships", "briefcase")
            footerItem("Candidates", "person.2.fill")
            footerItem("Messages", "bubble.left")
            footerItem("Company", "building.2")
        }.padding(.top, 12).padding(.bottom, 8).background(PipelinePalette.surface)

    }
    private func footerItem(_ title: String, _ icon: String) -> some View {
        let isSelected: Bool = selectedFooterItem == title
        let traits: AccessibilityTraits = isSelected ? .isSelected : []

        return Button {
            selectedFooterItem = title
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 18))
                Text(title)
                    .font(.system(size: 9, weight: isSelected ? .bold : .regular))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? PipelinePalette.orange : PipelinePalette.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(traits)
    }

}

private enum PipelineStage: String, CaseIterable, Identifiable {
    case new = "New", screen = "Screen", interview = "Interview", offer = "Offer"
    var id: String { rawValue }
    var next: PipelineStage? {
        switch self { case .new: return .screen; case .screen: return .interview; case .interview: return .offer; case .offer: return nil }
    }
}
private enum PipelineFilter: String, CaseIterable, Identifiable {
    case all = "All", strong = "Strong match", shortlisted = "Shortlisted", interview = "Interview"
    var id: String { rawValue }
}
private struct PipelineCandidate: Identifiable {
    let id: String
    let order: Int
    let name: String
    let fit: Int
    let skills: [String]
    let project: String
    var stage: PipelineStage
    var shortlisted: Bool
    var interviewBooked: Bool
    var initials: String { name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined() }
    static let samples: [PipelineCandidate] = {
        let names = ["Jordan Lee", "Maya Chen", "Sipho Dlamini", "Anele Ndlovu", "Lwazi Mokoena", "Nandi Dube", "Tariro Moyo", "Alex Mensah", "Amina Yusuf", "Noah Tembo", "Rudo Chirwa", "Chipo Dube", "Daniel Banda", "Lerato Ncube", "Sam Banda", "Ethan Ncube", "Ruth Moyo", "Tinashe Zhou"]
        let fits = [91, 86, 82, 78, 74, 71, 69, 66, 64, 61, 58, 55, 53, 49, 46, 42, 39, 35]
        let stages: [PipelineStage] = [.new, .new, .screen, .screen, .interview, .offer, .new, .new, .new, .new, .new, .new, .new, .screen, .screen, .screen, .interview, .interview]
        return names.indices.map { index in
            PipelineCandidate(id: "candidate-\(index)", order: index, name: names[index], fit: fits[index],
                skills: index == 0 ? ["Figma", "User research", "Communication"] : ["Figma", "Prototyping", "Teamwork"],
                project: index == 0 ? "Redesigned a campus events app" : index == 1 ? "Built a user research portfolio" : "Designed a student services prototype",
                stage: stages[index], shortlisted: index == 2 || index == 3,
                interviewBooked: index == 4 || index == 16)
        }
    }()
}
private extension View {
    func pipelineCard(padding: CGFloat = 14) -> some View {
        self.padding(padding).background(PipelinePalette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PipelinePalette.blue.opacity(0.25), lineWidth: 1))
    }
}


private enum PipelinePalette {
    static let background = Color(pipelineHex: 0x153A55)
    static let surface = Color(pipelineHex: 0x1D4865)
    static let orange = Color(pipelineHex: 0xFF6825)
    static let red = Color(pipelineHex: 0xC4432A)
    static let blue = Color(pipelineHex: 0x159BE8)
    static let text = Color(pipelineHex: 0xF7F9FA)
    static let charcoal = Color(pipelineHex: 0x55595C)
    static let secondary = Color(pipelineHex: 0x89929A)
}
private extension Color {
    init(pipelineHex: UInt32) {
        self.init(.sRGB, red: Double((pipelineHex >> 16) & 0xFF) / 255,
                  green: Double((pipelineHex >> 8) & 0xFF) / 255,
                  blue: Double(pipelineHex & 0xFF) / 255, opacity: 1)
    }
}
private struct PipelineActionStyle: ButtonStyle {
    let filled: Bool
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 13).padding(.vertical, 9)
            .foregroundStyle(isEnabled ? (filled ? PipelinePalette.background : PipelinePalette.blue) : PipelinePalette.secondary)
            .background(isEnabled && filled ? PipelinePalette.orange : PipelinePalette.background, in: Capsule())
            .overlay(Capsule().strokeBorder(isEnabled ? (filled ? PipelinePalette.orange : PipelinePalette.blue) : PipelinePalette.secondary, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct EmployerPipelineView_Previews: PreviewProvider {
    static var previews: some View { EmployerPipelineView() }
}

