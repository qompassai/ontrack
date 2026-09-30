# Everyday Use

## In plain terms

Your day with ONTrack has four beats: **add your stops**, **pick how distances are measured**, **press the big button**, and **send the finished route to your maps app**. This chapter walks each beat the way the UI actually works.

## 1. Build your stop list

You have four ways to add stops (desktop has all four; mobile lacks file import):

- **Type + Enter.** Type an address in the field and press Enter (or tap Add). Leading/trailing whitespace is trimmed; empty input is ignored.
- **Import a file (desktop only).** The Import CSV/Excel button accepts `.csv`, `.xlsx`, `.xls`, `.xlsm`, and `.ods`. The CSV reader is strict about one thing: the file must have an `address` column (matched case-insensitively, headers expected, extra columns tolerated). Excel files are read from the **first sheet**. Parsed addresses are appended to your existing list.
- **Current location.** One tap inserts `"Current Location"` as your *first* stop — handy when your route starts wherever you are standing. On Android this uses the phone's GPS/network last-known fix; everywhere else (desktop, desktop mobile-preview) it uses IP-based geolocation, which is city-accurate at best. If the lookup fails, nothing is added.
- **Remove with ✕.** Every stop row has a ✕ button. There is no undo and no confirmation — the stop is just gone.

Tip: the first stop in your list is treated as the **depot** (the route starts there) by the solver's default configuration.

## 2. Choose the distance backend

Before optimizing, pick how the app measures travel between stops:

- **OSRM (free)** — real driving distances from an OSRM router (the public one by default, or yours via the OSRM Base URL setting). The default choice.
- **Google** — Google's distance data; requires your API key.
- **Haversine** — offline straight-line distance on the sphere. No network, no key, but it ignores roads, so treat times as rough.

Desktop additionally offers **"Use Google for geocoding"** (off by default): with it, the address→coordinates step uses Google instead of Nominatim. Mobile always geocodes with Nominatim.

## 3. Optimize

Press **🚀 Optimize Route**. The button disables itself while the run is in progress. Behind the scenes the app:

1. **Geocodes** every address to lat/lng (status: `Geocoding addresses…`, with a done/total counter on desktop). Addresses that fail to resolve are dropped from the solve — only resolved stops are routed.
2. **Builds the distance matrix** — a table of travel time from every stop to every other stop (`Building distance matrix…` on desktop).
3. **Solves** — seeds a route with nearest-neighbor, then uncrosses it with 2-opt (`Solving route…`).

The whole pipeline runs on a background thread, so the UI stays responsive. When it finishes, desktop auto-switches you to the Results tab; mobile shows `Done` in the status line. If anything fails, you get a plain-language status: `Error: …` on mobile, or a red `parse: …` / `matrix: …` / `solve: …` line on desktop naming the failed stage.

## 4. Use the results

The summary line reads `Total drive time: <formatted> · <solver backend used>` — for example, "Total drive time: 2h 14m · nearest-neighbor+2opt". Then get the route out:

- **Whole route → maps app.** Desktop copies a Google Maps directions URL (origin + destination + waypoints, driving mode) to the clipboard; mobile opens the same URL directly (Android intent, so your default maps app handles it).
- **CSV export.** Both apps write `ontrack_route.csv` with `stop,address` rows in optimized order — desktop asks where via a save dialog, mobile writes to the app's private files dir (or the system temp dir in the desktop preview) and reports the path.
- **Per-stop deep links (desktop only).** For any stop that resolved to coordinates, the Results list offers **Maps** (single-stop Google Maps URL, copied), **FieldMaps** (ArcGIS deep link using your ArcGIS Item ID, copied), and **Waze** (copied). Stops that didn't geocode show no link buttons.

## A note on the voice button

The mobile Home tab has a **🎤 Voice** button. Today it only displays the status message "Voice capture requires the `voice` feature." — the on-device Whisper engine exists in the core library (16 kHz mono capture, up to 60 seconds, model chosen by the Whisper model setting) but is not connected to the button yet, and the desktop UI has no voice button at all. Dictating an address by voice is future work, not a current workflow.
