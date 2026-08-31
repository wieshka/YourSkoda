import SwiftUI
import MapKit

struct LocationTab: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    var body: some View {
        let parking = store.state(for: vin).vehicle?.parkingPosition

        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Parking Position", systemImage: "mappin.and.ellipse")

                if let parking, parking.state == "IN_MOTION" {
                    HStack {
                        Image(systemName: "location.north.line.fill").foregroundStyle(Theme.electric)
                        Text("Vehicle is currently in motion — no fixed position available.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else if let coords = parking?.gpsCoordinates {
                    MapPreview(latitude: coords.latitude, longitude: coords.longitude)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let address = parking?.formattedAddress {
                        Label(address, systemImage: "mappin.circle.fill")
                            .font(.callout)
                    }
                    Text(String(format: "%.5f, %.5f", coords.latitude, coords.longitude))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } else {
                    Text("No position data available.").foregroundStyle(.secondary)
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                }
            }
            .card()
        }
    }
}

struct MapPreview: View {
    let latitude: Double
    let longitude: Double

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 400, longitudinalMeters: 400))) {
            Marker("Vehicle", systemImage: "car.side.fill", coordinate: coordinate)
                .tint(Theme.skodaGreen)
        }
        .mapControls {
            MapCompass()
            MapPitchToggle()
        }
    }
}
