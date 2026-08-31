import Foundation

/// Persists the list of VINs the user has added ("garage") plus small per-vehicle
/// preferences (nickname override, last selected). The Public API has no endpoint to
/// list a user's vehicles, so the app tracks VINs the user enters manually.
struct SavedVehicle: Codable, Identifiable, Hashable {
    var vin: String
    var nickname: String?

    var id: String { vin }
}

final class GarageStore {
    private let defaults = UserDefaults.standard
    private let vehiclesKey = "garage.vehicles"
    private let selectedKey = "garage.selectedVIN"
    private let pollingKey = "garage.pollingEnabled"
    private let pollingIntervalKey = "garage.pollingInterval"

    func loadVehicles() -> [SavedVehicle] {
        guard let data = defaults.data(forKey: vehiclesKey) else { return [] }
        return (try? JSONDecoder().decode([SavedVehicle].self, from: data)) ?? []
    }

    func saveVehicles(_ vehicles: [SavedVehicle]) {
        if let data = try? JSONEncoder().encode(vehicles) {
            defaults.set(data, forKey: vehiclesKey)
        }
    }

    var selectedVIN: String? {
        get { defaults.string(forKey: selectedKey) }
        set { defaults.set(newValue, forKey: selectedKey) }
    }

    var pollingEnabled: Bool {
        get { defaults.object(forKey: pollingKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: pollingKey) }
    }

    var pollingInterval: TimeInterval {
        get { defaults.object(forKey: pollingIntervalKey) as? TimeInterval ?? 60 }
        set { defaults.set(newValue, forKey: pollingIntervalKey) }
    }
}
