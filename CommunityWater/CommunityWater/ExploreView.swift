import SwiftUI
import MapKit

struct ExploreView: View {
    @EnvironmentObject private var store: WaterStore
    @StateObject private var location = LocationService()
    @State private var tab = 0
    @State private var search = ""
    @State private var condition: Condition?
    @State private var type: SourceType?
    @State private var listMode = false
    @State private var selected: WaterPoint?
    @State private var settings = false
    @State private var camera: MapCameraPosition = .automatic

    private var visible: [WaterPoint] {
        store.points.filter {
            (tab != 1 || store.saved.contains($0.id)) &&
            (condition == nil || $0.condition == condition) &&
            (type == nil || $0.type == type) &&
            (search.isEmpty || "\($0.name) \($0.area)".localizedCaseInsensitiveContains(search))
        }.sorted { first, second in
            guard let coordinate = location.coordinate else { return first.name < second.name }
            return distance(first, coordinate) < distance(second, coordinate)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                connectionBanner
                if tab == 2 { reports } else { explore }
                HStack {
                    tabButton("Explore", symbol: "map", value: 0)
                    Spacer()
                    tabButton("Saved", symbol: "bookmark", value: 1)
                    Spacer()
                    tabButton("My reports", symbol: "clock.arrow.circlepath", value: 2)
                }.padding(.horizontal, 28).padding(.vertical, 12).background(.background)
            }
            .background(WaterTheme.paper)
            .navigationTitle("Community Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "drop.circle.fill").foregroundStyle(WaterTheme.teal).font(.title2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings and community connection")
                }
            }
            .sheet(item: $selected) { DetailView(pointID: $0.id).environmentObject(store) }
            .sheet(isPresented: $settings) { SettingsView().environmentObject(store) }
            .alert("Storage", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
            .alert("Location", isPresented: Binding(get: { location.message != nil }, set: { if !$0 { location.message = nil } })) {
                Button("OK") { location.message = nil }
            } message: { Text(location.message ?? "") }
            .onChange(of: location.coordinate?.latitude) { _, _ in
                if let center = location.coordinate {
                    camera = .region(.init(center: center, span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                }
            }
        }
    }

    private var connectionBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: store.isDemo ? "sparkles" : (store.connected ? "icloud" : "wifi.slash"))
            Text(store.isDemo ? "Demo · Illustrative locations. Reports stay on this device." :
                    (store.connected ? "Community reports · \(store.pending.count) pending" : "Offline · \(store.pending.count) pending. Browse saved details."))
                .font(.caption)
            Spacer(minLength: 0)
            if store.syncing { ProgressView().controlSize(.small) }
        }.padding(12).foregroundStyle(WaterTheme.teal).background(WaterTheme.teal.opacity(0.07))
    }

    private var explore: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if tab == 0 { hero }
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search water points or areas", text: $search).autocorrectionDisabled()
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search")
                    }
                }.padding(13).background(.background, in: RoundedRectangle(cornerRadius: 14))
                HStack {
                    Menu {
                        Picker("Condition", selection: $condition) {
                            Text("All conditions").tag(nil as Condition?)
                            ForEach(Condition.allCases) { Text($0.title).tag(Optional($0)) }
                        }
                    } label: { Label(condition?.title ?? "All conditions", systemImage: "line.3.horizontal.decrease.circle") }
                    Spacer()
                    Menu {
                        Picker("Source type", selection: $type) {
                            Text("All types").tag(nil as SourceType?)
                            ForEach(SourceType.allCases) { Text($0.title).tag(Optional($0)) }
                        }
                    } label: { Label(type?.title ?? "All types", systemImage: "drop") }
                }.font(.subheadline.weight(.semibold))
                HStack {
                    Text(tab == 1 ? "Saved places" : "Water around you").font(.title2.bold())
                    Spacer()
                    Button { listMode.toggle() } label: {
                        Label(listMode ? "Map" : "List", systemImage: listMode ? "map" : "list.bullet")
                    }.font(.subheadline)
                }
                if !listMode && !visible.isEmpty { communityMap }
                HStack {
                    Text("\(visible.count) water points")
                    Spacer()
                    if location.coordinate != nil { Text("Nearest first") }
                }.font(.caption).foregroundStyle(.secondary)
                if visible.isEmpty {
                    ContentUnavailableView("No water points to show", systemImage: "drop", description:
                        Text(store.points.isEmpty ? "Connect to your community and sync in Settings. An administrator must add water points to the backend." : "Try another filter or search, or save a point from its details."))
                }
                ForEach(visible) { point in
                    Button { selected = point } label: { pointCard(point) }.buttonStyle(.plain)
                }
                Text("Community reports describe availability. They do not confirm drinking-water quality.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.refreshable { await store.sync() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Every drop\nconnects us.").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Find water. Share an update.\nHelp your neighbours.").font(.subheadline)
            HStack {
                Label("\(store.points.filter { $0.condition == .working }.count) reported working", systemImage: "drop.fill")
                Spacer()
                Text("\(store.points.count) sources")
            }.font(.caption.weight(.semibold)).padding(.top, 5)
        }.foregroundStyle(.white).padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(WaterTheme.teal.gradient, in: RoundedRectangle(cornerRadius: 24))
    }

    private var communityMap: some View {
        Map(position: $camera) {
            if location.coordinate != nil { UserAnnotation() }
            ForEach(visible) { point in
                Annotation(point.name, coordinate: .init(latitude: point.latitude, longitude: point.longitude)) {
                    Button { selected = point } label: {
                        Image(systemName: point.condition.symbol).font(.headline).foregroundStyle(.white)
                            .frame(width: 40, height: 40).background(point.condition.color, in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 3)).shadow(radius: 2)
                    }.accessibilityLabel("\(point.name), \(point.condition.title)")
                }.annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 14) {
                Button { location.request() } label: { Image(systemName: "location.fill") }.accessibilityLabel("Find my location")
                Button { camera = .automatic } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }.accessibilityLabel("Show all filtered water points")
            }.padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14)).padding(12)
        }
        .onChange(of: condition) { _, _ in camera = .automatic }
        .onChange(of: type) { _, _ in camera = .automatic }
    }

    private func pointCard(_ point: WaterPoint) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: point.type == .tap ? "spigot.fill" : "drop.fill")
                    .foregroundStyle(WaterTheme.teal).font(.title2).padding(12)
                    .background(WaterTheme.paper, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    Text(point.name).font(.headline)
                    Text("\(point.area) · \(point.type.title)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                StatusBadge(condition: point.condition)
                if point.latest?.crowding == .crowded { Label("Crowded", systemImage: "person.2.fill").font(.caption).foregroundStyle(.orange) }
                Spacer(minLength: 0)
            }
            if let report = point.latest {
                Text("Last reported \(report.observedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2).foregroundStyle(.secondary)
            } else { Text("Unknown — no reports yet").font(.caption).foregroundStyle(.secondary) }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var reports: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("My reports").font(.largeTitle.bold())
                Text("Updates from this device, including reports waiting to upload.").font(.subheadline).foregroundStyle(.secondary)
                let local = store.points.flatMap { point in
                    point.reports.filter(\.isMine).map { (point, $0) }
                }.sorted { $0.1.observedAt > $1.1.observedAt }
                if local.isEmpty {
                    ContentUnavailableView("No reports yet", systemImage: "checkmark.icloud", description: Text("Select a water point to share an update."))
                }
                ForEach(local, id: \.1.id) { point, report in
                    Button { selected = point } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(point.name).font(.headline)
                            ReportCard(report: report)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }.refreshable { await store.sync() }
    }

    private func tabButton(_ title: String, symbol: String, value: Int) -> some View {
        Button { tab = value } label: {
            VStack(spacing: 5) { Image(systemName: symbol).font(.title3); Text(title).font(.caption2) }
                .foregroundStyle(tab == value ? WaterTheme.teal : .secondary)
                .frame(minWidth: 65, minHeight: 44)
        }.accessibilityAddTraits(tab == value ? [.isSelected] : [])
    }

    private func distance(_ point: WaterPoint, _ coordinate: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: point.latitude, longitude: point.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
