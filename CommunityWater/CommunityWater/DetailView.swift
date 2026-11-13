import SwiftUI
import MapKit

struct DetailView: View {
    @EnvironmentObject private var store: WaterStore
    @Environment(\.dismiss) private var dismiss
    let pointID: String
    @State private var reporting = false

    var body: some View {
        NavigationStack {
            Group {
                if let point = store.points.first(where: { $0.id == pointID }) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Map(initialPosition: .region(.init(center: .init(latitude: point.latitude, longitude: point.longitude), span: .init(latitudeDelta: 0.012, longitudeDelta: 0.012)))) {
                                Marker(point.name, systemImage: point.condition.symbol, coordinate: .init(latitude: point.latitude, longitude: point.longitude)).tint(point.condition.color)
                            }.frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 20))
                            HStack {
                                StatusBadge(condition: point.condition)
                                Spacer()
                                Text(point.type.title).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(point.name).font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Label(point.area, systemImage: "mappin.and.ellipse").foregroundStyle(.secondary)
                            if let report = point.latest {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Latest community report").font(.headline)
                                    ReportCard(report: report)
                                    if Date().timeIntervalSince(report.observedAt) > 86400 {
                                        Label("Over a day old. Conditions may have changed.", systemImage: "clock.badge.exclamationmark").font(.caption).foregroundStyle(.orange)
                                    }
                                }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 18))
                            } else {
                                Label("Unknown — no reports yet", systemImage: "questionmark.circle").foregroundStyle(.secondary)
                            }
                            Button { reporting = true } label: {
                                Label("Report an update", systemImage: "plus.circle.fill").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                            }.buttonStyle(.borderedProminent)
                            Button { directions(point) } label: { Label("Open directions in Maps", systemImage: "arrow.triangle.turn.up.right.diamond") }
                            Text("Availability is community reported. Water quality has not been verified.").font(.caption).foregroundStyle(.secondary)
                            Text("Problem & repair history").font(.title2.bold())
                            ForEach(point.history) { report in
                                ReportCard(report: report).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                            }
                        }.padding(20)
                    }.background(WaterTheme.paper)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { store.toggleSaved(point.id) } label: {
                                    Image(systemName: store.saved.contains(point.id) ? "bookmark.fill" : "bookmark")
                                }.accessibilityLabel(store.saved.contains(point.id) ? "Unsave water point" : "Save water point")
                            }
                        }
                        .sheet(isPresented: $reporting) { ReportForm(point: point).environmentObject(store) }
                } else {
                    ContentUnavailableView("Water point unavailable", systemImage: "mappin.slash", description: Text("This point is no longer in the community list."))
                }
            }
            .navigationTitle("Water point").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } } }
        }
    }

    private func directions(_ point: WaterPoint) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: point.latitude, longitude: point.longitude)))
        item.name = point.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

struct ReportCard: View {
    let report: WaterReport
    private var delivery: String {
        switch report.delivery {
        case .sample: "Sample report"
        case .local: "Saved on this device"
        case .pending: "Pending sync"
        case .uploaded: "Shared with community"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { StatusBadge(condition: report.condition); Spacer() }
            if report.crowding != .unknown {
                Label(report.crowding.title, systemImage: "person.2").font(.caption)
            }
            if report.repaired {
                Label("Recently repaired", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.blue)
            }
            if !report.note.isEmpty { Text(report.note).font(.subheadline) }
            Text("Observed \(report.observedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption2).foregroundStyle(.secondary)
            Label(delivery, systemImage: report.delivery == .pending ? "clock.arrow.circlepath" : "checkmark.circle")
                .font(.caption2).foregroundStyle(report.delivery == .pending ? .orange : .secondary)
        }
    }
}

struct ReportForm: View {
    @EnvironmentObject private var store: WaterStore
    @Environment(\.dismiss) private var dismiss
    let point: WaterPoint
    @State private var condition: Condition = .working
    @State private var crowding: Crowding = .unknown
    @State private var repaired = false
    @State private var note = ""
    @State private var observedAt = Date()
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Form {
                Section { Text(point.name).font(.headline) }
                Section("What did you observe?") {
                    Picker("Operating condition", selection: $condition) {
                        ForEach(Condition.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) }
                    }
                    Picker("Crowding", selection: $crowding) {
                        ForEach(Crowding.allCases) { Text($0.title).tag($0) }
                    }
                    Toggle("Recently repaired", isOn: $repaired)
                    DatePicker("Observed at", selection: $observedAt, in: ...Date())
                }
                Section("Note (optional)") {
                    TextField("Queue length, pump problems or repair details…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: note) { _, value in note = String(value.prefix(500)) }
                    Text("\(note.count)/500").font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    Label(store.isDemo ? "Demo reports are stored on this device and never uploaded." : "Saved on this device first, then shared when connected.", systemImage: "internaldrive")
                        .font(.caption).foregroundStyle(.secondary)
                    Button {
                        if store.report(pointID: point.id, condition: condition, crowding: crowding, repaired: repaired, note: note, observedAt: observedAt) {
                            Task { await store.sync() }
                            dismiss()
                        } else { failed = true }
                    } label: {
                        Text("Save update").font(.headline).frame(maxWidth: .infinity).padding(8)
                    }.buttonStyle(.borderedProminent).listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Share an update").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Report not saved", isPresented: $failed) { Button("OK", role: .cancel) {} } message: {
                Text("Check storage and the observation time. If saved data is damaged, recover storage in Settings.")
            }
        }
    }
}
