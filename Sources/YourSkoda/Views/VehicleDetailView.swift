import SwiftUI

enum DetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case climate = "Climate"
    case charging = "Charging"
    case location = "Location"
    case profiles = "Charging Profiles"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview: return "speedometer"
        case .climate: return "thermometer.sun"
        case .charging: return "bolt.car"
        case .location: return "map"
        case .profiles: return "list.bullet.rectangle"
        }
    }
}

struct VehicleDetailView: View {
    @EnvironmentObject var store: AppStore
    let vin: String
    @State private var tab: DetailTab = .overview

    var body: some View {
        let state = store.state(for: vin)

        VStack(spacing: 0) {
            VehicleHeaderView(vin: vin)
                .padding([.horizontal, .top], 20)
                .padding(.bottom, 8)

            Picker("", selection: $tab) {
                ForEach(DetailTab.allCases) { t in
                    Label(t.rawValue, systemImage: t.systemImage).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errors = state.response?.errors, !errors.isEmpty {
                        ErrorsBanner(errors: errors)
                    }
                    if let error = state.lastError {
                        SkodaErrorBanner(error: error) {
                            Task { await store.refresh(vin: vin) }
                        }
                    }

                    switch tab {
                    case .overview:
                        OverviewTab(vin: vin)
                    case .climate:
                        ClimateTab(vin: vin)
                    case .charging:
                        ChargingTab(vin: vin)
                    case .location:
                        LocationTab(vin: vin)
                    case .profiles:
                        ProfilesTab(vin: vin)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: vin) {
            if state.response == nil {
                await store.refresh(vin: vin)
            }
        }
    }
}

struct ErrorsBanner: View {
    let errors: [VehicleError]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                    Text("\(errors.count) data part\(errors.count == 1 ? "" : "s") unavailable")
                        .font(.callout.weight(.medium))
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.warnOrange)

            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(errors) { e in
                        Text("• \(e.friendlyMessage)\(e.description.map { ": \($0)" } ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.warnOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SkodaErrorBanner: View {
    let error: SkodaAPIError
    let retry: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.dangerRed)
            Text(error.errorDescription ?? "Something went wrong.")
                .font(.callout)
            Spacer()
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Theme.dangerRed.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
