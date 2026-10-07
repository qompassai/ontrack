# Web (WASM) build of the egui desktop app — 2026-10-06

Finding: `ontrack-desktop` now runs in the browser. The same `OnTrackApp`
is served by `eframe::run_native` on desktop and `eframe::WebRunner`
(canvas `#ontrack_canvas`) on `wasm32`. Build: `trunk build --release`
in `crates/ontrack-desktop` (see `scripts/build-web.sh`, `docs/WEB.md`).
Deployed by `.github/workflows/pages.yml` to GitHub Pages
(build_type=workflow; site https://qompassai.github.io/ontrack/).

Key facts for future work:

- Core needed async twins (`geocode_addresses_async`,
  `build_distance_matrix_async`) because core's reqwest client was
  blocking-only and its `tokio` feature set does not compile for wasm.
  The wasm reqwest build is fetch-backed and has NO client-side timeout
  (`ClientBuilder::timeout` does not exist on wasm).
- Default OSRM base URL differs per target: browsers get
  `https://router.project-osrm.org` (`OSRM_PUBLIC_DEFAULT`) — the
  `http://` default would be blocked as mixed content from the
  HTTPS Pages origin.
- CORS verified 2026-10-06: Nominatim, OSRM (HTTPS), and Google
  geocoding all send `Access-Control-Allow-Origin: *`.
- Verified end-to-end in headless Chromium: two Spokane stops
  geocoded via Nominatim, OSRM table fetched over HTTPS, solver
  produced a route (Results view, 6 min total drive time).
- Native-only on web: Whisper voice (already feature-gated off),
  `.env` API-key persistence (in-memory for the session), the
  "Use Current Location" button (hidden), HTTP timeouts.
