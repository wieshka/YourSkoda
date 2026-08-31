import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyInput: String = ""
    @State private var spinInput: String = ""
    @State private var revealKey = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "key.fill").foregroundStyle(Theme.skodaGreen)
                        Text("Škoda B2C API Key").font(.headline)
                    }
                    Text("Create and manage keys in the MyŠkoda app under **Profile > API Keys**, or at go.skoda.eu/api-keys. Keys expire and are scoped to the vehicles selected when created.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Group {
                            if revealKey {
                                TextField("API Key", text: $apiKeyInput)
                            } else {
                                SecureField("API Key", text: $apiKeyInput)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        Button {
                            revealKey.toggle()
                        } label: {
                            Image(systemName: revealKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }
                    if let expiry = store.apiKeyExpiresAt {
                        Label("Expires \(expiry.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "lock.shield.fill").foregroundStyle(Theme.skodaGreen)
                        Text("S-PIN").font(.headline)
                    }
                    Text("Required by the vehicle to start auxiliary heating. Stored securely in the Keychain, never leaves your Mac except inside the encrypted request to Škoda.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("4-digit S-PIN", text: $spinInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section("Refresh") {
                Toggle("Auto-refresh vehicle data", isOn: Binding(
                    get: { store.pollingEnabled },
                    set: { store.setPollingEnabled($0) }
                ))
                if store.pollingEnabled {
                    Picker("Interval", selection: Binding(
                        get: { store.pollingInterval },
                        set: { store.setPollingInterval($0) }
                    )) {
                        Text("30 seconds").tag(TimeInterval(30))
                        Text("1 minute").tag(TimeInterval(60))
                        Text("5 minutes").tag(TimeInterval(300))
                        Text("15 minutes").tag(TimeInterval(900))
                    }
                }
                if let remaining = store.rateLimitRemaining, let limit = store.rateLimitLimit {
                    Label("Rate limit: \(remaining) / \(limit) remaining", systemImage: "gauge.with.dots.needle.50percent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save") {
                        store.saveAPIKey(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines))
                        store.saveSPIN(spinInput.trimmingCharacters(in: .whitespacesAndNewlines))
                        Task { await store.refreshAll() }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.skodaGreen)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 4)
        .onAppear {
            apiKeyInput = store.apiKey
            spinInput = store.spin
        }
    }
}
