import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WaterStore
    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var key = ""
    @State private var invalid = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Community connection") {
                    Text(store.isDemo ? "Demo mode" : "Connected to \(store.configuration?.endpoint?.host ?? "community")").font(.headline)
                    Text("Your community administrator supplies a Supabase project URL and its public publishable key. Never enter a service-role or secret key.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("https://your-project.supabase.co", text: $url)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    SecureField("Public publishable / anon key", text: $key)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Connect community") {
                        let config = BackendConfiguration(url: url.trimmingCharacters(in: .whitespacesAndNewlines), key: key.trimmingCharacters(in: .whitespacesAndNewlines))
                        guard config.isValid, !key.hasPrefix("sb_secret_"), store.configure(config) else { invalid = true; return }
                        Task { await store.sync() }
                    }.disabled(store.syncing)
                    if !store.isDemo {
                        Button("Return to demo") { _ = store.configure(nil) }.disabled(store.syncing)
                    }
                    Text("Each community and demo mode have separate caches. Switching connections keeps pending reports in their original community.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Sync & offline access") {
                    LabeledContent("Connection", value: store.connected ? "Online" : "Offline")
                    LabeledContent("Pending reports", value: String(store.pending.count))
                    if !store.syncMessage.isEmpty { Text(store.syncMessage).font(.caption) }
                    Button { Task { await store.sync() } } label: {
                        HStack { Text("Sync now"); Spacer(); if store.syncing { ProgressView() } }
                    }.disabled(store.isDemo || store.syncing || !store.connected)
                    Text("Previously loaded lists, details and history work offline. Map tiles and directions require Maps connectivity or its existing cache.").font(.caption).foregroundStyle(.secondary)
                }
                if store.recoveryRequired {
                    Section("Storage recovery") {
                        Button("Back up damaged cache and start again") { store.recoverStorage() }
                        Text("Preserves the original file as a backup. Unsynced reports in a damaged file may need manual recovery.").font(.caption)
                    }
                }
                Section("About") {
                    Text("Community Water Point Monitor").font(.headline)
                    Text("Find usable water sources, record problems and follow repairs. Demo locations are illustrative and unverified.").font(.subheadline)
                    Text("Reports are public when connected. Keep personal information out of notes.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { url = store.configuration?.url ?? ""; key = store.configuration?.key ?? "" }
            .alert("Check community settings", isPresented: $invalid) { Button("OK", role: .cancel) {} } message: {
                Text("Enter an HTTPS Supabase project URL and public publishable or anon key. Wait for any current sync to finish.")
            }
        }
    }
}
