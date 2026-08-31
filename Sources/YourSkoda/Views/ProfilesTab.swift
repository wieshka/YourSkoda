import SwiftUI

struct ProfilesTab: View {
    @EnvironmentObject var store: AppStore
    let vin: String

    var body: some View {
        let profiles = store.state(for: vin).vehicle?.chargingProfiles

        VStack(alignment: .leading, spacing: 16) {
            if let current = profiles?.currentVehiclePositionProfile {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Current Location Profile", systemImage: "location.fill")
                    Text(current.name).font(.title3.weight(.semibold))
                    HStack(spacing: 16) {
                        if let target = current.targetStateOfChargeInPercent {
                            Label("\(target)% target", systemImage: "target")
                        }
                        if let next = current.nextChargingTime {
                            Label("Next charge \(next)", systemImage: "clock")
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .card()
            }

            if let list = profiles?.profiles, !list.isEmpty {
                ForEach(list) { profile in
                    ProfileCard(profile: profile)
                }
            } else {
                VStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No saved charging profiles.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

struct ProfileCard: View {
    let profile: ChargingProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(profile.name).font(.headline)
                Spacer()
                if let target = profile.settings?.targetStateOfChargeInPercent {
                    PillLabel(text: "\(target)% target", color: Theme.skodaGreen, systemImage: "bolt.fill")
                }
            }

            if let settings = profile.settings {
                HStack(spacing: 16) {
                    if let current = settings.maxChargingCurrent {
                        Label(current.capitalized, systemImage: "bolt")
                    }
                    if let unlock = settings.autoUnlockPlugWhenCharged {
                        Label("Unlock: \(unlock.capitalized)", systemImage: "lock.open")
                    }
                    if let min = settings.minBatteryStateOfCharge, min.enabled == true, let pct = min.minimumBatteryStateOfChargeInPercent {
                        Label("Min \(pct)%", systemImage: "battery.25")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let times = profile.preferredChargingTimes, !times.isEmpty {
                Divider()
                Text("Preferred Charging Times").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(times) { t in
                    HStack {
                        Image(systemName: t.enabled ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(t.enabled ? Theme.skodaGreen : .secondary)
                        Text("\(t.startTime) – \(t.endTime)")
                        Spacer()
                    }
                    .font(.callout)
                }
            }

            if let timers = profile.timers, !timers.isEmpty {
                Divider()
                Text("Timers").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(timers) { timer in
                    HStack {
                        Image(systemName: timer.enabled ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(timer.enabled ? Theme.skodaGreen : .secondary)
                        Text(timer.time ?? "—")
                        PillLabel(text: timer.type.capitalized, color: .secondary)
                        if let day = timer.oneOffDay {
                            Text(day.capitalized).font(.caption).foregroundStyle(.secondary)
                        }
                        if let days = timer.recurringOn, !days.isEmpty {
                            Text(days.map { $0.prefix(3).capitalized }.joined(separator: ", "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .font(.callout)
                }
            }
        }
        .card()
    }
}
