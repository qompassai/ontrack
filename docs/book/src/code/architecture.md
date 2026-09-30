# Architecture

## ELI5

Think of ONTrack as one brain with two faces. The **brain** (`ontrack-core`) knows how to turn addresses into an ordered route. The **faces** (`ontrack-desktop` and `ontrack-mobile`) are just different ways to show that brain to a user — one speaks egui on a computer, the other speaks Slint on a phone. Neither face does any math; both hand work to the brain on a background thread so the buttons never freeze.

## Workspace layout

```
ontrack/
├── Cargo.toml                      # workspace: core + desktop + mobile
├── crates/
│   ├── ontrack-core/               # library — the brain (no UI)
│   │   └── src/{lib,config,parser,geocoder,matrix,solver,exporter,voice}.rs
│   ├── ontrack-desktop/            # binary `ontrack` — egui GUI
│   │   └── src/{main.rs,app.rs,views/{home,results,settings}.rs}
│   └── ontrack-mobile/             # cdylib + Android app — Slint UI
│       ├── src/{lib.rs,controller.rs,gps.rs,preview_main.rs}
│       ├── ui/app.slint            # the entire mobile UI, declarative
│       └── android/                # Gradle project (Play Store + F-Droid)
├── scripts/                        # Android build / emulator / signing toolchain
├── fastlane/  fdroiddata/  playstore/   # store metadata
└── flake.nix                       # devShells: default, android, windows
```

## The pipeline (shared by both apps)

Every optimization runs the same five-stage pipeline, always in this order:

```
addresses: Vec<String>
    │  1. geocode_addresses()      Nominatim or Google → Vec<Location{address, lat, lng}>
    ▼
    │  2. build_distance_matrix()  OSRM / Google / Haversine → Vec<Vec<f64>> seconds
    ▼
    │  3. filter is_resolved()     drop addresses that failed to geocode
    ▼
    │  4. solve_tsp()              nearest-neighbor seed + 2-opt → RouteResult
    ▼
RouteResult { ordered_addresses, ordered_indices,
              total_duration_seconds, dropped_nodes, backend_used }
    │  5. exporter::*              CSV, Maps/Waze/FieldMaps/StreetView URLs
```

The contract between stages is deliberately plain data: `Vec<String>` → `Vec<Location>` → a square `Vec<Vec<f64>>` matrix → `RouteResult`. The solver validates its inputs up front (non-empty locations, square matrix matching the location count, `depot_index` in range) and fails with a descriptive `anyhow` error otherwise. The `SolverConfig` defaults to `depot_index: 0` (the first stop is the route start), 50 two-opt passes, and the `NearestNeighborTwoOpt` backend; `solve_open_tsp` additionally supports open routes via a zero-cost `"__end__"` sentinel node.

## Threading model

Geocoding and matrix building hit the network; solving is CPU-bound. Both apps push the whole pipeline off the UI thread and marshal results back:

- **Desktop** (`app.rs`): `OnTrackApp` holds an `Arc<Mutex<WorkerState>>` (`busy`, `progress: (done,total)`, `status_line`, `error`, `result`, `locations`). `run_optimize()` snapshots the addresses/backend/settings, spawns a `std::thread`, and the thread updates the shared state under the mutex — including a progress callback wired into geocoding. The egui `update()` loop polls that state each frame and calls `ctx.request_repaint_after(100ms)` while busy so the spinner and counters stay live. Immediate-mode egui makes this natural: every frame just re-reads the mutex.
- **Mobile** (`controller.rs`): `wire()` keeps an `Arc<Mutex<Shared{addresses, settings}>>` beside the Slint `AppWindow`. Each Slint `callback` (add-stop, remove-stop, optimize-route, …) is connected to a Rust closure via `ui.on_*`. The optimize closure spawns a `std::thread`, then uses `slint::invoke_from_event_loop` to hop back onto the UI thread before touching any `in-out property` — the one hard rule of Slint's threading model.

## The two UI philosophies

- **Desktop is immediate-mode (egui/eframe).** There is no retained widget tree: `views/home.rs`, `views/results.rs`, and `views/settings.rs` are functions that draw the current `OnTrackApp` state every frame. Buttons return `clicked()` booleans inline; the top nav is `selectable_value` over a `View::{Home, Results, Settings}` enum. File dialogs come from the `rfd` crate; clipboard writes go through `ui.output_mut(|o| o.copied_text = …)`.
- **Mobile is retained/declarative (Slint).** `ui/app.slint` declares the whole interface: `in-out` properties (stops, new-stop-text, status-text, busy, result-summary, ordered-stops, the three settings, backend-index, current-tab) and callbacks (`add-stop`, `remove-stop(int)`, `optimize-route`, `open-maps`, `export-csv`, `use-current-location`, `start-voice`, `stop-voice`, `save-settings`). `build.rs` runs `slint_build::compile("ui/app.slint")`, generating the `AppWindow` Rust type consumed via `slint::include_modules!()`. Two deliberate Slint-1.16.1 workarounds are documented in the file's comments: a custom Button tab bar instead of `TabWidget`, and no `ScrollView` around the stops list (both avoid a 100 ms `Flickable` press-delay that drops taps on Android; upstream fixed it in 1.18.0).

## Android entry and platform bridges

`ontrack-mobile` is a `cdylib` (+ `rlib` for the preview). On Android, `android_main` initializes `android_logger`, calls `slint::android::init(app)`, and runs the same `run()` as desktop. Two JNI bridges in `controller.rs`/`gps.rs` reach into the JVM via `ndk-context`:

- **GPS** (`gps.rs`, Android only): `getSystemService("location")` → `getLastKnownLocation` over the `gps`, `network`, and `passive` providers, first non-null fix wins, returned as `Location{ address: "Current Location", … }`.
- **Open URL** (`open_url_android`): builds an `ACTION_VIEW` intent with `FLAG_ACTIVITY_NEW_TASK` and starts it — this is how "📋 Google Maps" hands the route to the user's maps app. Other platforms use `xdg-open` / `open` / `rundll32`.
- **Export dir**: the app's private files dir via `getFilesDir()` on Android, else `std::env::temp_dir()`.

The non-Android fallback for "current location" everywhere is `geocoder::get_current_location()`: a plain HTTP GET to `ip-api.com/json/` — no API key, coarse accuracy.

## Configuration flow

`Settings::from_env()` (dotenvy + `std::env`) is the single source of settings truth at startup in both apps. Desktop edits write back to `.env` (`settings.rs::save_env`); mobile edits stay in memory (`controller.rs::on_save_settings`). The optimize path re-reads the three mobile-editable fields from the UI properties into the shared `Settings` before spawning the worker, so edits apply to the next run even without saving.
