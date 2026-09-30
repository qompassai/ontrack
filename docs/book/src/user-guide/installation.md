# Installation

## In plain terms

You have three doors in: build the desktop app with Rust's package manager (`cargo`), enter a ready-made Nix shell that has every dependency preinstalled, or build the Android app for your phone. None of the doors require paying for anything.

## Desktop: build with cargo

Prerequisites: a Rust toolchain (the repo pins one in `rust-toolchain`; the Nix shell provides it too).

```bash
git clone https://github.com/qompassai/ontrack.git
cd ontrack

# Build and run the desktop GUI
cargo build --release -p ontrack-desktop
./target/release/ontrack

# Run the core library's tests
cargo test -p ontrack-core
```

The desktop binary is named `ontrack` and opens an 1100×720 window titled "OnTrack — TDS Telecom Route Optimizer".

## Nix: development shells

The flake (`flake.nix`) provides three development shells — note it exposes **shells, not runnable apps**, so the command is `nix develop`, not `nix run`:

```bash
nix develop              # Linux desktop build deps (Rust, OpenSSL, GL, X11/Wayland, ALSA…)
nix develop .#android    # Android NDK/SDK, cargo-ndk, JDK 17 — for the mobile build
nix develop .#windows    # MinGW cross toolchain — for Windows builds
```

The default shell exports `PKG_CONFIG_PATH` for OpenSSL; the android shell exports `ANDROID_HOME` and `ANDROID_NDK_HOME`. The Rust toolchain comes from `rust-overlay` with the `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-unknown-linux-gnu`, and `x86_64-pc-windows-gnu` targets preinstalled.

## Configuration: the `.env` file

Copy the example and fill in what you need:

```bash
cp .env.example .env
```

```env
GOOGLE_MAPS_API_KEY=<redacted>
OSRM_BASE_URL="http://router.project-osrm.org"
ARCGIS_ITEM_ID=""         # optional — your ArcGIS Online web map ID, for FieldMaps deep links
ONTRACK_WHISPER_MODEL="base"
```

**No API key is required.** Without one, the app uses Nominatim (OpenStreetMap) for geocoding, the public OSRM router (or offline haversine math) for drive times, and plain Google Maps / Waze / Apple Maps URL schemes for navigation. See [Settings](settings.md) for what each option does and where it is stored on each platform.

## Android: APK and AAB

The Android app is built in two stages: `cargo-ndk` compiles the Rust core into `libontrack_mobile.so` for `arm64-v8a` and `armeabi-v7a`, then Gradle packages it into an APK/AAB. Nothing is committed as a prebuilt binary — both the Play Store and F-Droid build from source (metadata lives in `fastlane/` and `fdroiddata/`).

```bash
# One-shot build (AAB for Play Store, APK for sideloading/F-Droid, or both)
./scripts/build-android.sh both

# Local emulator smoke test (SDK setup, AVD, install, launch, screenshot)
./scripts/acli.sh full ontrack 4
```

Application ID: `ai.qompass.ontrack`. Minimum SDK 26, target/compile SDK 36 (per the crate metadata). The app declares the GPS hardware feature as *not required* and requests `INTERNET` and `ACCESS_NETWORK_STATE` permissions.

## Preview the mobile UI on desktop

You don't need a phone to see the Slint UI — there is a desktop preview binary:

```bash
cargo run -p ontrack-mobile --bin ontrack-mobile-preview
```

It runs the exact same `ui/app.slint` interface (412×892, dark navy `#002855` background) with the same controller wiring, using IP-based geolocation instead of the Android GPS.
