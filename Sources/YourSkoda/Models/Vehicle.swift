import Foundation

// MARK: - Top level response

struct VehicleResponse: Codable {
    var vehicle: Vehicle
    var errors: [VehicleError]?
}

struct VehicleError: Codable, Identifiable, Hashable {
    var type: String
    var description: String?

    var id: String { type }

    /// Human friendly label derived from the machine type, e.g. "Charging unavailable".
    var friendlyMessage: String {
        let lowered = type.lowercased().replacingOccurrences(of: "_", with: " ")
        return lowered.prefix(1).uppercased() + lowered.dropFirst()
    }

    var severity: Severity {
        if type.hasSuffix("UNSUPPORTED") { return .info }
        if type.hasSuffix("DISABLED") { return .warning }
        return .error
    }

    enum Severity {
        case info, warning, error
    }
}

// MARK: - Vehicle

struct Vehicle: Codable, Identifiable, Hashable {
    var vin: String
    var name: String?
    var licensePlate: String?
    var renderUrl: String?
    var status: VehicleStatus?
    var fuelStatus: FuelStatus?
    var odometer: Odometer?
    var parkingPosition: ParkingPosition?
    var airConditioning: AirConditioning?
    var auxiliaryHeating: AuxiliaryHeating?
    var activeVentilation: ActiveVentilation?
    var charging: Charging?
    var chargingProfiles: ChargingProfiles?

    var id: String { vin }

    var displayName: String { name?.isEmpty == false ? name! : "Škoda \(vin.suffix(6))" }
}

struct VehicleStatus: Codable, Hashable {
    var overall: OverallVehicleStatus?
    var detail: VehicleStatusDetail?
    var carCapturedTimestamp: Date?
}

struct OverallVehicleStatus: Codable, Hashable {
    var doorsLocked: String?
    var locked: String?
    var doors: String?
    var windows: String?
    var lights: String?
    var reliableLockStatus: String?
}

struct VehicleStatusDetail: Codable, Hashable {
    var sunroof: String?
    var trunk: String?
    var bonnet: String?
}

struct Odometer: Codable, Hashable {
    var mileageInKm: Int?
    var carCapturedTimestamp: Date?
}

struct FuelStatus: Codable, Hashable {
    var carType: String?
    var adBlueRange: Double?
    var totalRangeInKm: Double?
    var primaryEngineRange: EngineRange?
    var secondaryEngineRange: EngineRange?
    var carCapturedTimestamp: Date?
}

struct EngineRange: Codable, Hashable {
    var engineType: String?
    var currentSoCInPercent: Double?
    var currentFuelLevelInPercent: Double?
    var remainingRangeInKm: Double?
}

// MARK: - Climate

struct AirConditioning: Codable, Hashable {
    var state: String?
    var targetTemperature: TargetTemperature?
    var estimatedReachOfTargetTemperatureAt: Date?
    var airConditioningWithoutExternalPower: Bool?
    var airConditioningAtUnlock: Bool?
    var windowHeating: WindowHeating?
    var carCapturedTimestamp: Date?
}

struct AuxiliaryHeating: Codable, Hashable {
    var state: String?
    var startMode: String?
    var durationInSeconds: Int?
    var targetTemperature: TargetTemperature?
    var estimatedReachOfTargetTemperatureAt: Date?
    var carCapturedTimestamp: Date?
}

struct ActiveVentilation: Codable, Hashable {
    var state: String?
    var durationInSeconds: Int?
    var carCapturedTimestamp: Date?
}

struct TargetTemperature: Codable, Hashable {
    var value: Double
    var unit: String
}

struct WindowHeating: Codable, Hashable {
    var enabled: Bool?
    var front: String?
    var rear: String?
}

// MARK: - Charging

struct Charging: Codable, Hashable {
    var isVehicleInSavedLocation: Bool?
    var status: ChargingStatus?
    var settings: ChargingSettings?
    var carCapturedTimestamp: Date?
}

struct ChargingStatus: Codable, Hashable {
    var chargingRateInKilometersPerHour: Double?
    var chargePowerInKw: Double?
    var remainingTimeToFullyChargedInMinutes: Int?
    var fullyChargedAt: Date?
    var state: String?
    var chargeType: String?
    var battery: BatteryStatus?
}

struct BatteryStatus: Codable, Hashable {
    var remainingCruisingRangeInMeters: Int?
    var stateOfChargeInPercent: Int?
}

struct ChargingSettings: Codable, Hashable {
    var targetStateOfChargeInPercent: Int?
    var batteryCareModeTargetValueInPercent: Int?
    var preferredChargeMode: String?
    var availableChargeModes: [String]?
    var chargingCareMode: String?
    var autoUnlockPlugWhenCharged: String?
    var maxChargeCurrentAc: String?
    var maxChargeCurrentAcAmpere: Int?
}

struct ChargingProfiles: Codable, Hashable {
    var profiles: [ChargingProfile]?
    var currentVehiclePositionProfile: CurrentVehiclePositionProfile?
    var carCapturedTimestamp: Date?
}

struct ChargingProfile: Codable, Hashable, Identifiable {
    var id: Int
    var name: String
    var settings: ChargingProfileSettings?
    var preferredChargingTimes: [ChargingTime]?
    var timers: [Timer_]?
}

struct CurrentVehiclePositionProfile: Codable, Hashable {
    var id: Int
    var name: String
    var targetStateOfChargeInPercent: Int?
    var nextChargingTime: String?
}

struct ChargingProfileSettings: Codable, Hashable {
    var maxChargingCurrent: String?
    var minBatteryStateOfCharge: MinBatteryStateOfCharge?
    var targetStateOfChargeInPercent: Int?
    var autoUnlockPlugWhenCharged: String?
}

struct MinBatteryStateOfCharge: Codable, Hashable {
    var enabled: Bool?
    var minimumBatteryStateOfChargeInPercent: Int?
}

struct ChargingTime: Codable, Hashable, Identifiable {
    var id: Int
    var enabled: Bool
    var startTime: String
    var endTime: String
}

/// Renamed from `Timer` to avoid clashing with Foundation.Timer.
struct Timer_: Codable, Hashable, Identifiable {
    var id: Int
    var enabled: Bool
    var time: String?
    var type: String
    var oneOffDay: String?
    var recurringOn: [String]?
}

// MARK: - Parking

struct ParkingPosition: Codable, Hashable {
    var state: String?
    var gpsCoordinates: GPSCoordinates?
    var formattedAddress: String?
}

struct GPSCoordinates: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}
