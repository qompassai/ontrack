# OnTrack in the browser (web build)

The desktop egui app also runs as a WebAssembly page. The native and web
builds are the *same* `ontrack-desktop` binary crate and the same
`OnTrackApp`; only the entry point differs (`eframe::run_native` vs.
`eframe::WebRunner` in `crates/ontrack-desktop/src/main.rs`), plus
target-gated code paths described below.

## Build and run locally

Prerequisites: the repo's Rust toolchain (the `rust-toolchain` file
already includes the `wasm32-unknown-unknown` target) and
[Trunk](https://trunkrs.dev).

```bash
# from the repo root — builds into crates/ontrack-desktop/dist/
scripts/build-web.sh

# or, with live reload while developing:
cd crates/ontrack-desktop
trunk serve          # http://127.0.0.1:8080
```

## Deployment

`.github/workflows/pages.yml` rebuilds the bundle with
`trunk build --release --public-url /ontrack/` and deploys it to GitHub
Pages on every push to `main` that touches the desktop/core crates, so
the live demo is <https://qompassai.github.io/ontrack/>.

## How the browser build differs

| Area | Native | Web |
| --- | --- | --- |
| Optimize pipeline | worker OS thread, blocking HTTP | `spawn_local` future, async fetch-backed HTTP (`*_async` functions in `ontrack-core`) |
| Geocoding / routing calls | reqwest + rustls | Browser fetch API; Nominatim, Google, and OSRM are called directly |
| OSRM default endpoint | `http://router.project-osrm.org` | `https://router.project-osrm.org` (an HTTPS page cannot fetch plain HTTP — mixed content) |
| Import CSV/Excel | `rfd` sync dialog + path parser | `rfd` async dialog (web file input) + byte parser (`parse_addresses_from_bytes`) |
| Export CSV | `rfd` sync save dialog | `rfd` async save dialog, CSV generated in memory (`route_csv_string`) |
| Settings persistence | "Save to .env" writes a local `.env` | Session only — there is no filesystem; settings reset with the tab |
| "Use Current Location" | IP geolocation button | Not offered (endpoint is plain HTTP; blocked as mixed content) |
| Voice input (Whisper) | optional `voice` feature | Not available (native-only feature, never enabled for web) |
| HTTP timeouts | 10 s geocode / 30 s matrix | None — reqwest's fetch backend has no per-request timeout API |

## CORS

The browser build calls the public endpoints cross-origin. Verified
2026-10-06 — all send `Access-Control-Allow-Origin: *`:

- Nominatim (`nominatim.openstreetmap.org`) — geocoding works.
- OSRM demo router (`router.project-osrm.org`, HTTPS) — matrix works.
- Google Maps Platform — geocoding/distance matrix work if the user
  pastes an API key in Settings (key restrictions are the user's own
  Cloud Console concern; a key restricted by HTTP referrer to the Pages
  domain is the right setup for the web build).
