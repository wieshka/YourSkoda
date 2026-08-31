# yourSkoda

A native macOS desktop app for the **Škoda Connect Public API (B2C, Beta)** —
monitor and control your Škoda (e.g. Enyaq Coupe) from your Mac: battery &
charging, climate (A/C, auxiliary heating, active ventilation), doors/windows/
lights status, odometer, and last known parking position.

Built with SwiftUI + Swift Package Manager, no Xcode project required. Not
affiliated with Škoda Auto; this is an unofficial client for the public API
documented at https://public.api.connect.skoda-auto.cz/docs/swagger-ui/index.html.

## Features

Implements every operation exposed by the Public API (v1.0.0-beta.6):

- **Vehicle overview** — name, license plate, render image, doors/windows/
  lights status, odometer, fuel status (combustion/hybrid).
- **Charging** — live battery %, range, charge power/rate, state, start/stop
  charging, charging settings (target SoC, care mode, max AC current, ...),
  and saved charging profiles with preferred times and timers.
- **Climate** — start/stop air conditioning with target temperature, start/
  stop auxiliary heating (requires your vehicle's S-PIN), start/stop active
  ventilation, window heating state.
- **Location** — last known parking position on an interactive map, or "in
  motion" state.
- **Multi-vehicle garage** — add any number of VINs your API key covers.
- **Auto-refresh** with a configurable interval, rate-limit visibility, and
  API key expiry tracking (the API exposes both via response headers).

## Getting your API key

The Public API authenticates with a simple API key header (`X-API-Key`), not
OAuth. Create one from the MyŠkoda app or https://go.skoda.eu/api-keys — keys
are scoped to the vehicles you select and they expire, so you'll need to
rotate them periodically. Paste the key into the app's Settings window
(`⌘,`); it's stored in the macOS Keychain, never in plain text on disk.

If you plan to use auxiliary heating, also set your vehicle's **S-PIN** in
Settings — the API requires it for that specific operation.

## Building & running

Requires Xcode 15+ / Swift 5.10+ command line tools on macOS 14 or later.

```sh
# Run directly (debug, launches in Terminal's window session)
swift run

# Or build a proper double-clickable .app bundle into ./build
./scripts/build_app.sh

# ...and install it to /Applications
./scripts/build_app.sh --install
```

`scripts/build_app.sh` builds a release binary, packages it with the
generated icon (`Resources/AppIcon.icns`) and `Info.plist` into
`build/yourSkoda.app`, and ad-hoc code-signs it so Keychain access works
consistently between launches.

To regenerate the app icon (`scripts/generate_icon.swift`, pure AppKit/Core
Graphics, no external assets):

```sh
swift scripts/generate_icon.swift
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
```

## Project layout

```
Sources/YourSkoda/
  Models/        Codable types mirroring the OpenAPI schema (Vehicle, Charging, ...)
  Networking/     SkodaAPIClient — async/await URLSession client, error mapping
  Persistence/    Keychain wrapper + UserDefaults-backed garage/settings store
  Store/          AppStore — the app's observable state, polling, actions
  Views/          SwiftUI screens (sidebar, overview, climate, charging, map, profiles, settings)
scripts/          Icon generator + .app bundler
```

## Notes on the API

- There is no "list my vehicles" endpoint in the Public API, so vehicles are
  added by VIN manually (the app remembers them).
- Control actions (`/charging/start`, `/air-conditioning/start`, etc.) return
  `202 Accepted` immediately — the app polls the vehicle a couple of seconds
  later to reflect the new state.
- The API is in beta; some fields/operations may be absent for a given
  vehicle, which the app surfaces as a dismissible "data unavailable" banner
  rather than an error.
