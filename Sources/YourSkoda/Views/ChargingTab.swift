import SwiftUI

struct ChargingTab: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    var body: some View {
        let state = store.state(for: vin)
        let charging = state.vehicle?.charging

        VStack(alignment: .leading, spacing: 16) {
            batteryCard(charging, state: state)
            if let settings = charging?.settings {
                settingsCard(settings)
            }
        }
    }

    private func batteryCard(_ charging: Charging?, state: VehicleState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Charging", systemImage: "bolt.car.fill")
                Spacer()
                if let s = charging?.status?.state {
                    PillLabel(text: s.replacingOccurrences(of: "_", with: " ").capitalized,
                              color: s == "CHARGING" ? Theme.skodaGreen : .secondary,
                              systemImage: s == "CHARGING" ? "bolt.fill" : nil)
                }
            }

            HStack(spacing: 28) {
                BatteryRing(percent: charging?.status?.battery?.stateOfChargeInPercent ?? 0)
                    .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 10) {
                    metricRow("Range", value: charging?.status?.battery?.remainingCruisingRangeInMeters.map { "\($0 / 1000) km" } ?? "—")
                    metricRow("Charge power", value: charging?.status?.chargePowerInKw.map { "\($0.formatted(.number.precision(.fractionLength(1)))) kW" } ?? "—")
                    metricRow("Charge rate", value: charging?.status?.chargingRateInKilometersPerHour.map { "\(Int($0)) km/h" } ?? "—")
                    metricRow("Type", value: charging?.status?.chargeType ?? "—")
                    if let mins = charging?.status?.remainingTimeToFullyChargedInMinutes, mins > 0 {
                        metricRow("Time to full", value: "\(mins / 60)h \(mins % 60)m")
                    }
                    if let loc = charging?.isVehicleInSavedLocation {
                        metricRow("At saved location", value: loc ? "Yes" : "No")
                    }
                }
                Spacer()
            }

            HStack {
                LoadingButton(title: "Start Charging", systemImage: "play.fill", isLoading: state.pendingActions.contains("chargeStart")) {
                    store.startCharging(vin: vin)
                }
                LoadingButton(title: "Stop Charging", systemImage: "stop.fill", isLoading: state.pendingActions.contains("chargeStop"), tint: .secondary) {
                    store.stopCharging(vin: vin)
                }
                Spacer()
            }
        }
        .card()
    }

    private func settingsCard(_ settings: ChargingSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Charging Settings", systemImage: "slider.horizontal.3")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                labeledValue("Target SoC", settings.targetStateOfChargeInPercent.map { "\($0)%" })
                labeledValue("Battery care target", settings.batteryCareModeTargetValueInPercent.map { "\($0)%" })
                labeledValue("Preferred mode", settings.preferredChargeMode?.replacingOccurrences(of: "_", with: " ").capitalized)
                labeledValue("Care mode", settings.chargingCareMode?.capitalized)
                labeledValue("Auto unlock plug", settings.autoUnlockPlugWhenCharged?.capitalized)
                labeledValue("Max AC current", settings.maxChargeCurrentAc.map { current in
                    settings.maxChargeCurrentAcAmpere.map { "\(current.capitalized) (\($0)A)" } ?? current.capitalized
                })
            }
            if let modes = settings.availableChargeModes, !modes.isEmpty {
                Text("Available modes: \(modes.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func metricRow(_ label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 20)
            Text(value).font(.callout.weight(.medium))
        }
        .font(.callout)
        .frame(minWidth: 220)
    }

    private func labeledValue(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value ?? "—").font(.callout.weight(.medium))
        }
    }
}

struct BatteryRing: View {
    let percent: Int

    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 12)
            Circle()
                .trim(from: 0, to: min(max(Double(percent) / 100, 0), 1))
                .stroke(Theme.batteryColor(percent), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percent)
            VStack(spacing: 2) {
                Text("\(percent)").font(.system(size: 30, weight: .bold, design: .rounded))
                Text("%").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
