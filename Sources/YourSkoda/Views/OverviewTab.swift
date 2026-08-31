import SwiftUI

struct OverviewTab: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    var body: some View {
        let vehicle = store.state(for: vin).vehicle

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], alignment: .leading, spacing: 16) {
            statusCard(vehicle)
            odometerCard(vehicle)
            if let charging = vehicle?.charging {
                batterySummaryCard(charging)
            }
            if let fuel = vehicle?.fuelStatus {
                fuelCard(fuel)
            }
            if let parking = vehicle?.parkingPosition {
                parkingSummaryCard(parking)
            }
        }
    }

    private func statusCard(_ vehicle: Vehicle?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Doors & Windows", systemImage: "car.side")
            let overall = vehicle?.status?.overall
            let detail = vehicle?.status?.detail
            VStack(spacing: 8) {
                statusLine("Doors", overall?.doors)
                statusLine("Locked", overall?.locked)
                statusLine("Windows", overall?.windows)
                statusLine("Lights", overall?.lights)
                statusLine("Trunk", detail?.trunk)
                statusLine("Bonnet", detail?.bonnet)
                if let sunroof = detail?.sunroof, sunroof != "UNSUPPORTED" {
                    statusLine("Sunroof", sunroof)
                }
            }
            if let ts = vehicle?.status?.carCapturedTimestamp {
                Text("Captured \(ts.formatted(.relative(presentation: .named)))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func odometerCard(_ vehicle: Vehicle?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Odometer", systemImage: "gauge")
            if let km = vehicle?.odometer?.mileageInKm {
                Text("\(km)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    + Text(" km").font(.title3).foregroundStyle(.secondary)
            } else {
                Text("No data").foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func batterySummaryCard(_ charging: Charging) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Battery", systemImage: "bolt.fill")
            if let soc = charging.status?.battery?.stateOfChargeInPercent {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(soc)").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("%").font(.title3).foregroundStyle(.secondary)
                    Spacer()
                    if let state = charging.status?.state {
                        PillLabel(text: state.replacingOccurrences(of: "_", with: " ").capitalized,
                                  color: state == "CHARGING" ? Theme.skodaGreen : .secondary,
                                  systemImage: state == "CHARGING" ? "bolt.fill" : nil)
                    }
                }
                ProgressView(value: Double(soc), total: 100)
                    .tint(Theme.batteryColor(soc))
                if let range = charging.status?.battery?.remainingCruisingRangeInMeters {
                    Text("\(range / 1000) km remaining")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("No data").foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func fuelCard(_ fuel: FuelStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Fuel", systemImage: "fuelpump.fill")
            if let level = fuel.primaryEngineRange?.currentFuelLevelInPercent {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(level))").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("%").font(.title3).foregroundStyle(.secondary)
                }
                ProgressView(value: level, total: 100).tint(Theme.warnOrange)
            }
            if let range = fuel.totalRangeInKm {
                Text("\(Int(range)) km total range").font(.caption).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func parkingSummaryCard(_ parking: ParkingPosition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Location", systemImage: "mappin.circle.fill")
            if parking.state == "IN_MOTION" {
                Label("Vehicle is in motion", systemImage: "location.fill")
                    .foregroundStyle(.secondary)
            } else {
                Text(parking.formattedAddress ?? "Parked")
                    .font(.callout)
            }
        }
        .card()
    }

    private func statusLine(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(friendly(value)).font(.body.weight(.medium))
        }
        .font(.callout)
    }

    private func friendly(_ value: String?) -> String {
        guard let value else { return "—" }
        return value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
