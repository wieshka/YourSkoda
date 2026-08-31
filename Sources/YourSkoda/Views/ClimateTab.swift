import SwiftUI

struct ClimateTab: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    @State private var acTemp: Double = 22.0
    @State private var acAllowWithoutPower = true
    @State private var auxTemp: Double = 22.0
    @State private var auxDuration: Double = 600
    @State private var auxStartMode = "HEATING"

    var body: some View {
        let state = store.state(for: vin)
        let vehicle = state.vehicle

        VStack(alignment: .leading, spacing: 16) {
            airConditioningCard(vehicle?.airConditioning, state: state)
            auxiliaryHeatingCard(vehicle?.auxiliaryHeating, state: state)
            activeVentilationCard(vehicle?.activeVentilation, state: state)
        }
    }

    // MARK: Air Conditioning

    private func airConditioningCard(_ ac: AirConditioning?, state: VehicleState) -> some View {
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Air Conditioning", systemImage: "thermometer.sun.fill")
                Spacer()
                if let s = ac?.state {
                    PillLabel(text: s.replacingOccurrences(of: "_", with: " ").capitalized,
                              color: s == "OFF" ? .secondary : Theme.electric)
                }
            }

            if let target = ac?.targetTemperature {
                Text("Current target: \(target.value.formatted(.number.precision(.fractionLength(1))))°\(target.unit == "CELSIUS" ? "C" : "F")")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Text("Target temperature").font(.callout)
                Spacer()
                Text("\(acTemp.formatted(.number.precision(.fractionLength(1))))°C")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.electric)
            }
            Slider(value: $acTemp, in: 16...30, step: 0.5)
                .tint(Theme.electric)

            Toggle("Allow without external power", isOn: $acAllowWithoutPower)
                .toggleStyle(.switch)

            if let heating = ac?.windowHeating {
                HStack(spacing: 16) {
                    windowHeatingBadge("Front", heating.front)
                    windowHeatingBadge("Rear", heating.rear)
                }
            }

            HStack {
                LoadingButton(title: "Start", systemImage: "play.fill", isLoading: state.pendingActions.contains("acStart")) {
                    store.startAirConditioning(vin: vin, targetTemperatureCelsius: acTemp, allowWithoutExternalPower: acAllowWithoutPower)
                }
                LoadingButton(title: "Stop", systemImage: "stop.fill", isLoading: state.pendingActions.contains("acStop"), tint: .secondary) {
                    store.stopAirConditioning(vin: vin)
                }
                Spacer()
            }
        }
        .card()
    }

    private func windowHeatingBadge(_ label: String, _ value: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "windshield.front.and.wiper.intermittent")
                .font(.caption)
            Text("\(label): \(value?.capitalized ?? "—")")
                .font(.caption)
        }
        .foregroundStyle(value == "ON" ? Theme.skodaGreen : .secondary)
    }

    // MARK: Auxiliary Heating

    private func auxiliaryHeatingCard(_ aux: AuxiliaryHeating?, state: VehicleState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Auxiliary Heating", systemImage: "flame.fill")
                Spacer()
                if let s = aux?.state {
                    PillLabel(text: s.replacingOccurrences(of: "_", with: " ").capitalized,
                              color: s == "OFF" ? .secondary : Theme.warnOrange)
                }
            }

            if store.spin.isEmpty {
                Label("Set your S-PIN in Settings to enable starting auxiliary heating.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Theme.warnOrange)
            }

            HStack {
                Text("Target temperature").font(.callout)
                Spacer()
                Text("\(auxTemp.formatted(.number.precision(.fractionLength(1))))°C").font(.callout.weight(.semibold)).foregroundStyle(Theme.warnOrange)
            }
            Slider(value: $auxTemp, in: 16...30, step: 0.5).tint(Theme.warnOrange)

            HStack {
                Text("Duration").font(.callout)
                Spacer()
                Text("\(Int(auxDuration / 60)) min").font(.callout.weight(.semibold))
            }
            Slider(value: $auxDuration, in: 60...1800, step: 60).tint(Theme.warnOrange)

            Picker("Mode", selection: $auxStartMode) {
                Text("Heating").tag("HEATING")
                Text("Ventilation").tag("VENTILATION")
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)

            HStack {
                LoadingButton(title: "Start", systemImage: "play.fill", isLoading: state.pendingActions.contains("auxStart"), tint: Theme.warnOrange) {
                    store.startAuxiliaryHeating(vin: vin, targetTemperatureCelsius: auxTemp, durationInSeconds: Int(auxDuration), startMode: auxStartMode)
                }
                .disabled(store.spin.isEmpty)
                LoadingButton(title: "Stop", systemImage: "stop.fill", isLoading: state.pendingActions.contains("auxStop"), tint: .secondary) {
                    store.stopAuxiliaryHeating(vin: vin)
                }
                Spacer()
            }
        }
        .card()
    }

    // MARK: Active Ventilation

    private func activeVentilationCard(_ vent: ActiveVentilation?, state: VehicleState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Active Ventilation", systemImage: "wind")
                Spacer()
                if let s = vent?.state {
                    PillLabel(text: s.replacingOccurrences(of: "_", with: " ").capitalized,
                              color: s == "OFF" ? .secondary : Theme.electric)
                }
            }
            if let duration = vent?.durationInSeconds {
                Text("Runs for \(duration / 60) min when started").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                LoadingButton(title: "Start", systemImage: "play.fill", isLoading: state.pendingActions.contains("ventStart"), tint: Theme.electric) {
                    store.startActiveVentilation(vin: vin)
                }
                LoadingButton(title: "Stop", systemImage: "stop.fill", isLoading: state.pendingActions.contains("ventStop"), tint: .secondary) {
                    store.stopActiveVentilation(vin: vin)
                }
                Spacer()
            }
        }
        .card()
    }
}
