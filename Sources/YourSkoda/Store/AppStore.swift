import Foundation
import SwiftUI
import Combine

@MainActor
final class VehicleState: ObservableObject, @MainActor Identifiable {
    let vin: String
    @Published var response: VehicleResponse?
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var lastError: SkodaAPIError?
    @Published var pendingActions: Set<String> = []

    var id: String { vin }

    var vehicle: Vehicle? { response?.vehicle }

    init(vin: String) {
        self.vin = vin
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var apiKey: String = ""
    @Published var spin: String = ""
    @Published var vehicles: [SavedVehicle] = []
    @Published var selectedVIN: String?
    @Published var states: [String: VehicleState] = [:]
    @Published var pollingEnabled: Bool
    @Published var pollingInterval: TimeInterval
    @Published var apiKeyExpiresAt: Date?
    @Published var rateLimitRemaining: Int?
    @Published var rateLimitLimit: Int?
    @Published var toast: ToastMessage?

    private let client = SkodaAPIClient()
    private let keychain = KeychainStore()
    private let garage = GarageStore()
    private var pollTask: Task<Void, Never>?

    struct ToastMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    init() {
        self.pollingEnabled = garage.pollingEnabled
        self.pollingInterval = garage.pollingInterval
        self.apiKey = keychain.read(account: "apiKey") ?? ""
        self.spin = keychain.read(account: "spin") ?? ""
        self.vehicles = garage.loadVehicles()
        self.selectedVIN = garage.selectedVIN ?? vehicles.first?.vin
        for v in vehicles {
            states[v.vin] = VehicleState(vin: v.vin)
        }
        startPollingIfNeeded()
    }

    // MARK: - Settings persistence

    func saveAPIKey(_ key: String) {
        apiKey = key
        keychain.save(key, account: "apiKey")
    }

    func saveSPIN(_ pin: String) {
        spin = pin
        keychain.save(pin, account: "spin")
    }

    func setPollingEnabled(_ enabled: Bool) {
        pollingEnabled = enabled
        garage.pollingEnabled = enabled
        startPollingIfNeeded()
    }

    func setPollingInterval(_ interval: TimeInterval) {
        pollingInterval = interval
        garage.pollingInterval = interval
        startPollingIfNeeded()
    }

    // MARK: - Garage management

    func addVehicle(vin: String, nickname: String?) {
        let trimmed = vin.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count == 17 else {
            toast = ToastMessage(text: "VIN must be exactly 17 characters.", isError: true)
            return
        }
        guard !vehicles.contains(where: { $0.vin == trimmed }) else { return }
        let saved = SavedVehicle(vin: trimmed, nickname: nickname)
        vehicles.append(saved)
        garage.saveVehicles(vehicles)
        states[trimmed] = VehicleState(vin: trimmed)
        if selectedVIN == nil {
            selectedVIN = trimmed
            garage.selectedVIN = trimmed
        }
        Task { await refresh(vin: trimmed) }
    }

    func removeVehicle(vin: String) {
        vehicles.removeAll { $0.vin == vin }
        garage.saveVehicles(vehicles)
        states.removeValue(forKey: vin)
        if selectedVIN == vin {
            selectedVIN = vehicles.first?.vin
            garage.selectedVIN = selectedVIN
        }
    }

    func selectVehicle(vin: String) {
        selectedVIN = vin
        garage.selectedVIN = vin
        if states[vin]?.response == nil {
            Task { await refresh(vin: vin) }
        }
    }

    func state(for vin: String) -> VehicleState {
        if let s = states[vin] { return s }
        let s = VehicleState(vin: vin)
        states[vin] = s
        return s
    }

    // MARK: - Refresh

func refreshAll() async {
        for v in vehicles {
            await refresh(vin: v.vin)
        }
    }

    func refresh(vin: String, include: Set<VehiclePart> = []) async {
        guard !apiKey.isEmpty else {
            toast = ToastMessage(text: "Add your API key in Settings first.", isError: true)
            return
        }
        let state = state(for: vin)
        state.isLoading = true
        do {
            let response = try await client.getVehicle(vin: vin, apiKey: apiKey, include: include)
            state.response = response
            state.lastUpdated = Date()
            state.lastError = nil
            applyMeta()
        } catch let error as SkodaAPIError {
            state.lastError = error
            applyMeta()
        } catch {
            state.lastError = .network(error)
        }
        state.isLoading = false
    }

    private func applyMeta() {
        guard let meta = client.lastResponseMeta else { return }
        if let expires = meta.apiKeyExpiresAt { apiKeyExpiresAt = expires }
        if let limit = meta.rateLimitLimit { rateLimitLimit = limit }
        if let remaining = meta.rateLimitRemaining { rateLimitRemaining = remaining }
    }

    // MARK: - Polling

    func startPollingIfNeeded() {
        pollTask?.cancel()
        guard pollingEnabled else { return }
        let interval = pollingInterval
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard let self else { return }
                if Task.isCancelled { return }
                await self.refreshAll()
            }
        }
    }

    // MARK: - Actions (with optimistic pending state + toasts)

    private func runAction(vin: String, key: String, _ operation: @escaping () async throws -> Void) {
        let state = state(for: vin)
        state.pendingActions.insert(key)
        Task {
            do {
                try await operation()
                toast = ToastMessage(text: successMessage(for: key), isError: false)
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await refresh(vin: vin)
            } catch let error as SkodaAPIError {
                toast = ToastMessage(text: error.errorDescription ?? "Action failed.", isError: true)
            } catch {
                toast = ToastMessage(text: error.localizedDescription, isError: true)
            }
            state.pendingActions.remove(key)
        }
    }

    private func successMessage(for key: String) -> String {
        switch key {
        case "chargeStart": return "Charging started."
        case "chargeStop": return "Charging stopped."
        case "acStart": return "Air conditioning starting."
        case "acStop": return "Air conditioning stopped."
        case "auxStart": return "Auxiliary heating starting."
        case "auxStop": return "Auxiliary heating stopped."
        case "ventStart": return "Active ventilation starting."
        case "ventStop": return "Active ventilation stopped."
        default: return "Done."
        }
    }

    func startCharging(vin: String) {
        runAction(vin: vin, key: "chargeStart") { [client, apiKey] in
            try await client.startCharging(vin: vin, apiKey: apiKey)
        }
    }

    func stopCharging(vin: String) {
        runAction(vin: vin, key: "chargeStop") { [client, apiKey] in
            try await client.stopCharging(vin: vin, apiKey: apiKey)
        }
    }

    func startAirConditioning(vin: String, targetTemperatureCelsius: Double, allowWithoutExternalPower: Bool) {
        runAction(vin: vin, key: "acStart") { [client, apiKey] in
            let config = StartAirConditioningConfiguration(
                targetTemperature: TargetTemperature(value: targetTemperatureCelsius, unit: "CELSIUS"),
                airConditioningWithoutExternalPower: allowWithoutExternalPower
            )
            try await client.startAirConditioning(vin: vin, apiKey: apiKey, config: config)
        }
    }

    func stopAirConditioning(vin: String) {
        runAction(vin: vin, key: "acStop") { [client, apiKey] in
            try await client.stopAirConditioning(vin: vin, apiKey: apiKey)
        }
    }

    func startAuxiliaryHeating(vin: String, targetTemperatureCelsius: Double, durationInSeconds: Int, startMode: String) {
        runAction(vin: vin, key: "auxStart") { [client, apiKey, spin] in
            let config = StartAuxiliaryHeatingConfiguration(
                targetTemperature: TargetTemperature(value: targetTemperatureCelsius, unit: "CELSIUS"),
                spin: spin,
                durationInSeconds: durationInSeconds,
                startMode: startMode
            )
            try await client.startAuxiliaryHeating(vin: vin, apiKey: apiKey, config: config)
        }
    }

    func stopAuxiliaryHeating(vin: String) {
        runAction(vin: vin, key: "auxStop") { [client, apiKey] in
            try await client.stopAuxiliaryHeating(vin: vin, apiKey: apiKey)
        }
    }

    func startActiveVentilation(vin: String) {
        runAction(vin: vin, key: "ventStart") { [client, apiKey] in
            try await client.startActiveVentilation(vin: vin, apiKey: apiKey)
        }
    }

    func stopActiveVentilation(vin: String) {
        runAction(vin: vin, key: "ventStop") { [client, apiKey] in
            try await client.stopActiveVentilation(vin: vin, apiKey: apiKey)
        }
    }
}
