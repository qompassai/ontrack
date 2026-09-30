# Settings

## ELI5

ONTrack needs to know four things: your Google key (optional), which routing server to ask (optional), your ArcGIS map ID (optional), and which Whisper voice model to use (optional). Everything has a sensible default, so the app works with zero configuration. The settings themselves live in a small Rust struct; each app loads it at startup and lets you edit the fields in the Settings tab.

## The settings, one by one

All four settings are defined in `ontrack-core/src/config.rs` as the `Settings` struct, loaded from environment variables (a `.env` file in the working directory is picked up automatically via `dotenvy`):

| Setting | Env var | Default | UI field |
|---|---|---|---|
| Google Maps API key | `GOOGLE_MAPS_API_KEY` | empty (unused) | Password field, both apps |
| OSRM Base URL | `OSRM_BASE_URL` | `http://router.project-osrm.org` (the free public router) | Text field, both apps |
| ArcGIS Item ID | `ARCGIS_ITEM_ID` | empty (FieldMaps links skipped) | Text field, both apps |
| Whisper model | `ONTRACK_WHISPER_MODEL` | `"base"` | Text field, **desktop only** |

The app also defines constants `APP_NAME = "OnTrack"`, `APP_VERSION = "2.0.0"`, and `ORG_NAME = "TDS Telecom"`; the desktop top bar renders the version as `v2.0.0`.

## What each one actually changes

- **Google Maps API key.** Without it, geocoding uses Nominatim (OpenStreetMap, no key needed) and distance matrices use OSRM or haversine. With it, you can select the Google distance backend, and (desktop only, via the "Use Google for geocoding" checkbox) Google geocoding. On mobile, geocoding always uses Nominatim regardless of the key.
- **OSRM Base URL.** Point this at your own OSRM instance if you run one; otherwise the public `router.project-osrm.org` is used for the OSRM distance backend.
- **ArcGIS Item ID.** Your ArcGIS Online web map ID. It is only used to build the per-stop **FieldMaps** deep links on the desktop Results tab; empty means those links simply aren't offered.
- **Whisper model.** The model-size name passed to the optional on-device Whisper voice engine (built only with the `voice` cargo feature). The desktop Settings tab edits it; the mobile UI has no field for it.

## Where settings are stored — this differs by app

**Desktop:** the Settings tab's **💾 Save to .env** button writes all four values to a `.env` file in the process working directory, overwriting it:

```env
GOOGLE_MAPS_API_KEY=<redacted>
OSRM_BASE_URL="http://router.project-osrm.org"
ARCGIS_ITEM_ID=""
ONTRACK_WHISPER_MODEL="base"
```

The note under the button is a promise from the source: keys are stored only in your local `.env` — never transmitted to TDS servers. On next launch, `Settings::from_env()` reads them back.

**Mobile:** the Settings tab's **💾 Save** button applies the three fields to the running app only — the status line says "Settings saved (in-memory)". There is no file written on Android, so **settings do not survive an app restart** unless they were provided through the environment at launch. Treat the mobile Settings tab as per-session overrides.

## What is *not* a setting

Anything else you might expect — units (miles vs km), dark/light mode, map tile style, default travel mode, a default backend remembered between launches — does not exist in the source. The distance backend picker and the geocoding checkbox reset to their defaults (OSRM, unchecked) every time the app starts.
