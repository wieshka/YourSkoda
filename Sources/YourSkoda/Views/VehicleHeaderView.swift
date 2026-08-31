import SwiftUI

struct VehicleHeaderView: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    var body: some View {
        let state = store.state(for: vin)
        let vehicle = state.vehicle

        HStack(alignment: .center, spacing: 20) {
            AsyncImage(url: vehicle?.renderUrl.flatMap(URL.init)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    Image(systemName: "car.side.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Theme.skodaGreen.opacity(0.5))
                        .padding(20)
                }
            }
            .frame(width: 140, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(Theme.skodaGreen.opacity(0.08))
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(vehicle?.displayName ?? "Škoda")
                    .font(.largeTitle.weight(.bold))
                HStack(spacing: 8) {
                    if let plate = vehicle?.licensePlate {
                        PillLabel(text: plate, systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    PillLabel(text: vin, color: .secondary)
                    if let ts = state.lastUpdated {
                        PillLabel(text: "Updated \(ts.formatted(date: .omitted, time: .shortened))", color: .secondary, systemImage: "clock")
                    }
                }
                statusRow(vehicle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Button {
                    Task { await store.refresh(vin: vin) }
                } label: {
                    if state.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(state.isLoading)
            }
        }
    }

    @ViewBuilder
    private func statusRow(_ vehicle: Vehicle?) -> some View {
        HStack(spacing: 10) {
            if let locked = vehicle?.status?.overall?.doorsLocked {
                statusChip(icon: locked == "YES" ? "lock.fill" : "lock.open.fill",
                           text: locked == "YES" ? "Locked" : "Unlocked",
                           color: locked == "YES" ? Theme.skodaGreen : Theme.warnOrange)
            }
            if let windows = vehicle?.status?.overall?.windows, windows != "UNSUPPORTED" {
                statusChip(icon: windows == "CLOSED" ? "square.fill" : "square.dashed",
                           text: "Windows \(windows.lowercased())",
                           color: windows == "CLOSED" ? Theme.skodaGreen : Theme.warnOrange)
            }
            if let soc = vehicle?.charging?.status?.battery?.stateOfChargeInPercent {
                statusChip(icon: "bolt.fill", text: "\(soc)%", color: Theme.batteryColor(soc))
            }
            if let range = vehicle?.fuelStatus?.totalRangeInKm {
                statusChip(icon: "gauge.with.needle", text: "\(Int(range)) km range", color: .secondary)
            }
        }
        .padding(.top, 2)
    }

    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(color)
    }
}
