import SwiftUI

struct AddVehicleSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var vin: String = ""
    @State private var nickname: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "car.side.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.skodaGreen)
                Text("Add Vehicle")
                    .font(.title2.weight(.semibold))
            }

            Text("Enter the Vehicle Identification Number (VIN). Your API key must include this vehicle.")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("VIN").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                TextField("e.g. TMBJB9NY5RF999999", text: $vin)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: vin) { _, newValue in
                        if newValue.count > 17 {
                            vin = String(newValue.prefix(17))
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nickname (optional)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                TextField("My Enyaq", text: $nickname)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    store.addVehicle(vin: vin, nickname: nickname.isEmpty ? nil : nickname)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.skodaGreen)
                .disabled(vin.trimmingCharacters(in: .whitespaces).count != 17)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420, height: 300)
    }
}
