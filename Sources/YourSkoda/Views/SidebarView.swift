import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: AppStore
    @Binding var showingAddVehicle: Bool
    @Binding var showingSettings: Bool

    var body: some View {
        List(selection: Binding(
            get: { store.selectedVIN },
            set: { if let v = $0 { store.selectVehicle(vin: v) } }
        )) {
            Section("Garage") {
                ForEach(store.vehicles) { saved in
                    VehicleRow(saved: saved)
                        .tag(saved.vin)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.removeVehicle(vin: saved.vin)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("yourSkoda")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Label("Add Vehicle", systemImage: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.skodaGreen)
                    Spacer()
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { await store.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddVehicle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct VehicleRow: View {
    @EnvironmentObject var store: AppStore
    let saved: SavedVehicle

    var body: some View {
        let state = store.state(for: saved.vin)
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.skodaGreen.opacity(0.15))
                Image(systemName: "car.side.fill")
                    .foregroundStyle(Theme.skodaGreen)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(saved.nickname?.isEmpty == false ? saved.nickname! : (state.vehicle?.displayName ?? "Škoda \(saved.vin.suffix(6))"))
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let soc = state.vehicle?.charging?.status?.battery?.stateOfChargeInPercent {
                        Text("\(soc)%")
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                    } else if let mileage = state.vehicle?.odometer?.mileageInKm {
                        Text("\(mileage) km")
                    } else {
                        Text(saved.vin)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if state.isLoading {
                ProgressView().controlSize(.small)
            } else if state.lastError != nil {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Theme.dangerRed)
            }
        }
        .padding(.vertical, 4)
    }
}
