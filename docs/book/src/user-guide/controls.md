# Controls

## In plain terms

Both apps have the same three tabs — **Home** (your stop list), **Results** (the optimized order), **Settings** (your keys and URLs) — but the buttons differ a little between desktop and phone. This chapter lists every control that exists in the source, what it does, and what happens when you use it.

There are no global keyboard shortcuts anywhere in the app. Keyboard input is limited to typing in text fields, and pressing **Enter** in the address field submits the stop.

---

## Desktop (egui)

The window opens at 1100×720 (minimum 720×540). A top bar holds the **Home / Results / Settings** tab selectors and a version label on the right. When an optimization finishes, the app switches you to the Results tab automatically.

### Home tab

| Control | What it does |
|---|---|
| Address text field | Type an address. The hint reads "Type an address and press Enter…". Pressing **Enter** (or clicking **Add**) appends the trimmed text to the stop list and clears the field. Empty input is ignored. |
| **Add** button | Same as pressing Enter in the address field. |
| **Import CSV/Excel** button | Opens a file picker (filters: `csv`, `xlsx`, `xls`, `xlsm`, `ods`). The chosen file's addresses are appended to the stop list. The CSV must have an `address` column (matched case-insensitively); Excel reads the first sheet. |
| **Use Current Location** button | Looks up your approximate location via IP geolocation and inserts `"Current Location"` as the first stop. If the lookup fails, nothing is added. |
| Stops list (scrollable) | One row per stop: a number, the address, and a **✕** button that removes that stop. |
| **Distance backend** dropdown | Picks how stop-to-stop travel times are computed: **OSRM (free)** (default), **Google**, or **Haversine** (offline straight-line math). |
| **Use Google for geocoding** checkbox | Off by default. When checked, addresses are geocoded with the Google API (needs a key); otherwise Nominatim (OpenStreetMap) is used. |
| **🚀 Optimize Route** button | Disabled while a run is in progress or when the stop list is empty. Starts geocoding → distance matrix → solve on a background thread. |
| Progress area | While busy: a spinner, a status line (`Geocoding addresses…` → `Building distance matrix…` → `Solving route…` → `Done`), and a `done/total` counter during geocoding. Errors appear in red, prefixed by which stage failed (`parse:`, `matrix:`, `solve:`). |

### Results tab

Before any run it shows: "No route has been optimized yet. Go to the Home tab to add stops." After a run:

| Control | What it does |
|---|---|
| Summary line | `Total drive time: <formatted> · Solver: <backend used>`, e.g. "nearest-neighbor+2opt". |
| **📋 Copy Google Maps URL** button | Copies a `google.com/maps/dir/?api=1` URL (origin, destination, waypoints, `travelmode=driving`) for the whole route to the clipboard. |
| **💾 Export CSV** button | Opens a save dialog (default name `ontrack_route.csv`) and writes `stop,address` rows in optimized order. |
| Ordered stops list | One row per stop in optimized order. For stops that resolved to coordinates, three extra buttons appear: **Maps** (copies a single-stop Google Maps URL), **FieldMaps** (copies an ArcGIS FieldMaps deep link built with your configured ArcGIS item ID), **Waze** (copies a Waze URL for the coordinates). Stops that failed to geocode get no link buttons. |

### Settings tab

A two-column grid of text fields, a save button, and a privacy note ("keys are stored only in your local `.env` file — never transmitted to TDS servers"):

| Control | What it does |
|---|---|
| Google Maps API key (password field) | Key used for the Google distance backend and, if enabled, Google geocoding. |
| OSRM Base URL | Base URL of the OSRM router; defaults to the public `http://router.project-osrm.org`. |
| ArcGIS Item ID | Your ArcGIS Online web map ID, used to build FieldMaps deep links. |
| Whisper model | Model size name for on-device voice input (default `base`). Desktop exposes the setting; there is currently no voice capture button in the desktop UI. |
| **💾 Save to .env** button | Writes all four values to a `.env` file in the working directory. Errors surface as `save: …` on the Home tab. |

---

## Mobile (Slint, Android)

The window is 412×892 with a dark navy (`#002855`) background. Navigation is a **custom tab bar of three plain Buttons** (Home / Results / Settings) — deliberately *not* Slint's `TabWidget`: on Slint 1.16.1 the tab headers sit inside a `Flickable` that delays every press by 100 ms, and on Android that delayed press never reaches the tab, so taps were silently dropped (upstream fixed this in 1.18.0). For the same reason the stops list intentionally avoids `ScrollView` — remove buttons stay directly tappable. Touch is the only input; the address field also submits on the keyboard's Enter/accept key.

### Home tab

| Control | What it does |
|---|---|
| Address field (`LineEdit`, placeholder "Add address…") | Type a stop. Accepting the text (Enter key) fires the add callback. |
| **Add** button | Adds the field's text as a stop and clears the field. Blank input is ignored. |
| **📍 Current** button | On Android, reads the last-known location from the GPS, network, and passive providers (first one that answers wins) and inserts `"Current Location"` as the first stop. On the desktop preview it falls back to IP geolocation. Shows "Could not determine current location" if all fail. |
| **🎤 Voice** button | Currently a stub: shows the status message "Voice capture requires the `voice` feature." The on-device Whisper engine exists in the core library but is not wired to this button yet. |
| Stops group | One row per stop: number, address, and a **✕** button removing that stop. |
| **Backend** dropdown | ComboBox with `OSRM (free)` / `Google` / `Haversine`, bound to the same three distance backends as desktop. |
| **🚀 Optimize Route** button | Disabled while busy or with an empty stop list. Runs the same geocode → matrix → solve pipeline on a background thread. |
| Progress + status | An indeterminate progress bar while busy; a status line showing `Geocoding addresses…`, `Done`, or `Error: …`. |

### Results tab

| Control | What it does |
|---|---|
| Summary line | `Total drive time: <formatted> · <backend used>`. |
| **📋 Google Maps** button | Opens the full-route Google Maps directions URL — on Android via an `ACTION_VIEW` intent, on desktop preview via `xdg-open`/`open`/`rundll32`. |
| **💾 Export CSV** button | Writes `ontrack_route.csv` (optimized order) to the app's private files dir on Android, or the system temp dir on desktop; the status line reports the path or `Export failed: …`. |
| Ordered Stops group | The optimized stop list, numbered. |

### Settings tab

Three text fields (Google Maps API key as a password field, OSRM Base URL, ArcGIS Item ID), a **💾 Save** button, and the note "Keys are stored locally on the device only."

Important difference from desktop: mobile's **Save is in-memory only** — the status line confirms "Settings saved (in-memory)". There is no `.env` file on Android; quitting the app discards changes. The mobile UI also has **no Whisper model field** (that setting stays at its default unless provided via environment).

> **Not in the source (do not expect these):** swipe gestures, long-press actions, pull-to-refresh, a hardware-back-button behavior, desktop keyboard shortcuts beyond Enter-to-add, or a desktop voice button. If you find yourself looking for them, they were never built.
