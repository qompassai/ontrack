# Crate Tour

## In plain terms

This chapter walks through each crate file by file — what it does, what it exports, and which UI pieces call it. Read it with the [Architecture](architecture.md) pipeline diagram in mind.

---

## `ontrack-core` — the library

Pure logic, zero UI. Every public item is re-exported from `lib.rs`.

### `config.rs` — settings and constants

Defines `APP_NAME` (`"OnTrack"`), `APP_VERSION` (`"2.0.0"`), `ORG_NAME` (`"TDS Telecom"`), and `OSRM_PUBLIC` (`"http://router.project-osrm.org"`). The `Settings` struct holds `google_maps_api_key`, `osrm_base_url`, `arcgis_item_id`, and `whisper_model`; `Settings::from_env()` loads a `.env` file via `dotenvy` and reads the four `GOOGLE_MAPS_API_KEY` / `OSRM_BASE_URL` / `ARCGIS_ITEM_ID` / `ONTRACK_WHISPER_MODEL` variables with the documented defaults. `Default` gives the same values without touching the environment.

### `parser.rs` — reading stop lists from files

`parse_addresses(path)` dispatches on file extension: `.csv` goes to a `csv`-crate reader (headers required, `flexible(true)`, looks for an `address` column case-insensitively, skips blank cells); `.xlsx`/`.xls`/`.xlsm`/`.xlsb`/`.ods` go to `calamine`, which reads the **first sheet**. Anything else is an error. Returns `Vec<String>`.

### `geocoder.rs` — addresses to coordinates

`Location { address, lat: Option<f64>, lng: Option<f64> }` with `is_resolved()` (true when both coordinates are `Some`). `geocode_address_nominatim` hits OpenStreetMap's Nominatim; `geocode_address_google(addr, api_key)` hits Google; `geocode_addresses(addrs, use_google, key, progress_cb)` maps the batch with an optional `(done, total)` progress callback. `get_current_location()` does a keyless `ip-api.com` lookup and returns a `Location` addressed `"Current Location"`.

### `matrix.rs` — the travel-time table

`Backend::{Osrm, Google, Haversine}` (plus `Backend::parse` from a string). `haversine(lat1, lng1, lat2, lng2)` is the great-circle fallback. `build_distance_matrix(locs, backend, osrm_url, google_key)` returns the square `Vec<Vec<f64>>` of seconds the solver consumes — OSRM via the table/routing service, Google via its distance API, Haversine purely offline.

### `solver.rs` — the route optimizer

The heart of the app. `SolverConfig { depot_index, two_opt_passes, backend: SolverBackend::{NearestNeighbor, NearestNeighborTwoOpt} }` (defaults: depot 0, 50 passes, NN+2opt). `solve_tsp` validates inputs, seeds with greedy nearest-neighbor from the depot, then runs 2-opt: for each pair of edges `(a,b)`, `(c,d)` it checks whether swapping to `(a,c)`, `(b,d)` shortens the tour (`delta < -1e-9`) and reverses the segment in place, repeating until a full pass finds no improvement (bounded by `two_opt_passes`). `solve_open_tsp` handles non-returning routes by appending a zero-cost `"__end__"` sentinel. `RouteResult` carries `ordered_addresses`, `ordered_indices`, `total_duration_seconds`, `dropped_nodes` (unreachable stops), and `backend_used` (`"nearest-neighbor"` or `"nearest-neighbor+2opt"`). The README's benchmark framing: ≤ 50 stops solves in well under a second.

### `exporter.rs` — getting the route out

`export_csv` writes `stop,address` rows with quote-escaping. `build_maps_url` builds a `https://www.google.com/maps/dir/?api=1` URL with origin/destination/waypoints and `travelmode=driving` (single-stop and empty-list special cases included); `build_maps_url_chunked` splits long routes into chunks of 10. `build_streetview_url` / `build_streetview_embed_url`, `build_fieldmaps_url` (ArcGIS deep link from address + coordinates + item ID), `build_waze_url(lat, lng)`, and `format_duration` (seconds → human string) round it out.

### `voice.rs` — optional on-device voice input

Gated behind the `voice` cargo feature (`#![cfg(feature = "voice")]`). Captures microphone audio with `cpal` at 16 kHz mono, up to 60 seconds (`SAMPLE_RATE`, `CHANNELS`, `MAX_RECORD_S`), and transcribes with on-device Whisper — model path from `ONTRACK_WHISPER_MODEL_PATH` or the configured model size. `VoiceResult { text, language, duration, elapsed, error }` and a `RecordingState::{Idle, Recording, Processing, Error}` state machine. The mobile UI's 🎤 button is currently a stub (see [Controls](../user-guide/controls.md)); this module is the engine waiting to be wired.

---

## `ontrack-desktop` — the egui binary

Crate `ontrack-desktop`, binary name `ontrack`.

- **`main.rs`** — loads `.env`, inits `env_logger`, and launches `eframe::run_native` with a 1100×720 window (min 720×540) titled "OnTrack — TDS Telecom Route Optimizer".
- **`app.rs`** — `OnTrackApp` state (`view`, `addresses`, `address_input`, `backend`, `use_google`, `settings`, `worker: Arc<Mutex<WorkerState>>`) and `run_optimize()`, which snapshots state, flips `busy`, and spawns the pipeline thread with the geocoding progress callback. The `App::update` impl draws the top nav (Home/Results/Settings + `v2.0.0` label), auto-switches Home→Results when a run completes, dispatches to the view functions, and repaints at 10 Hz while busy.
- **`views/home.rs`** — the stop-list panel: address `TextEdit` (Enter key *or* Add button; `lost_focus() + key_pressed(Enter)`), Import CSV/Excel via `rfd` (filters `csv/xlsx/xls/xlsm/ods`), Use Current Location, scrollable stop rows with ✕ buttons, the backend `ComboBox`, the "Use Google for geocoding" checkbox, and the 🚀 button with spinner/status/progress/error rendering.
- **`views/results.rs`** — the summary line and the Copy-Maps-URL / Export-CSV buttons, plus per-stop Maps / FieldMaps / Waze buttons that appear only when the stop has coordinates (URLs copied via `copied_text`).
- **`views/settings.rs`** — the four-field grid (API key as password field) and `save_env`, which writes the `.env` file in the working directory.

---

## `ontrack-mobile` — the Slint Android app

Crate `ontrack-mobile`: `cdylib` (Android) + `rlib`, plus an `ontrack-mobile-preview` desktop binary. Feature `voice = ["ontrack-core/voice"]` exists but is not on by default.

- **`ui/app.slint`** — the entire UI as data: the `AppWindow` component (412×892, `#002855` background), the `StopItem{label, address}` struct, all `in-out` properties, and the nine callbacks listed in [Architecture](architecture.md). Home/Results/Settings tabs are custom `Button`s with `if current-tab == N` sections; the address `LineEdit` binds `text <=> new-stop-text` and fires `accepted => root.add-stop()`; the backend `ComboBox` offers the three backends bound to `backend-index`; the 🚀 button is `enabled: !busy && stops.length > 0`. The file's comments document the two Slint-1.16.1 `Flickable` workarounds (custom tab bar, no `ScrollView`).
- **`build.rs`** — one line that matters: `slint_build::compile("ui/app.slint")`, generating the Rust `AppWindow` type.
- **`lib.rs`** — `slint::include_modules!()` pulls in the generated code; `run()` builds the window, calls `controller::wire`, and runs the event loop. On Android, `android_main` inits logging and `slint::android::init(app)` before `run()`.
- **`controller.rs`** — `wire(ui)` connects every Slint callback to a closure: add/remove stop (with blank-input guard and index-bounds check), current location (Android GPS first, IP fallback), optimize (snapshot settings from UI properties → `std::thread` → geocode → matrix → solve → `slint::invoke_from_event_loop` to publish `result-summary`, `ordered-stops`, `busy`, `status-text`), open-maps, export-csv (Android files dir or temp dir), save-settings (in-memory), and the voice stubs.
- **`gps.rs`** (Android only) — the JNI `LocationManager` bridge described in [Architecture](architecture.md): `getLastKnownLocation` over gps/network/passive providers.
- **`preview_main.rs`** — six lines: init logging, call `ontrack_mobile::run()`. This is the desktop preview binary from [Installation](../user-guide/installation.md).

### Crate metadata (Android)

`[package.metadata.android]`: package `ai.qompass.ontrack`, build targets `aarch64-linux-android` + `armv7-linux-androideabi`, resources from `android/app/src/main/res`, assets from `../../assets`, min SDK 26 / target & compile SDK 36, GPS hardware feature not required, `INTERNET` + `ACCESS_NETWORK_STATE` permissions.
