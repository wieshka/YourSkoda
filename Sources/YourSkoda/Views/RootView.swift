import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingAddVehicle = false
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            SidebarView(showingAddVehicle: $showingAddVehicle, showingSettings: $showingSettings)
        } detail: {
            if let vin = store.selectedVIN {
                VehicleDetailView(vin: vin)
                    .id(vin)
            } else {
                EmptyGarageView(showingAddVehicle: $showingAddVehicle)
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .frame(width: 480, height: 420)
        }
        .toast($store.toast)
        .task {
            if store.apiKey.isEmpty {
                showingSettings = true
            } else {
                await store.refreshAll()
            }
        }
    }
}

struct EmptyGarageView: View {
    @Binding var showingAddVehicle: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.skodaGreen)
            Text("Your garage is empty")
                .font(.title2.weight(.semibold))
            Text("Add a vehicle by VIN to start monitoring and controlling it.")
                .foregroundStyle(.secondary)
            Button {
                showingAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.skodaGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
