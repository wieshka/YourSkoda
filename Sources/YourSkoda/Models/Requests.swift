import Foundation

struct StartAirConditioningConfiguration: Codable {
    var targetTemperature: TargetTemperature?
    var airConditioningWithoutExternalPower: Bool?
}

struct StartAuxiliaryHeatingConfiguration: Codable {
    var targetTemperature: TargetTemperature?
    var spin: String
    var durationInSeconds: Int?
    var startMode: String?
}

enum VehiclePart: String, CaseIterable, Identifiable {
    case info, status, fuelStatus, odometer, parkingPosition
    case airConditioning, auxiliaryHeating, activeVentilation
    case charging, chargingProfiles

    var id: String { rawValue }
}
