# Introduction

ONTrack is a **field route optimizer** built for TDS Telecom technicians and service/delivery crews. The whole idea fits in one sentence:

> Give ONTrack a list of stops, and it hands back an efficient driving order — then opens that order in the maps app of your choice.

## The ELI5 version

Imagine you start your workday with 20 customer addresses scribbled on a clipboard. Driving them in the order they were assigned wastes gas and time. ONTrack is the friend who looks at your whole list, figures out the shortest sensible loop through all of them, and then opens turn-by-turn directions on your phone. You stay in control — it plans, you drive.

## What it is, technically

ONTrack is **pure Rust**, with **no cloud backend, no Python runtime, and no OR-Tools dependency**. Everything — parsing your stop list, geocoding addresses to coordinates, computing drive times, and solving the route — happens on your own machine or phone, using free public services (OpenStreetMap's Nominatim for geocoding, the public OSRM router for drive times) unless you configure your own keys.

It ships as **two native apps sharing one core library**:

| App | UI framework | Platforms | Binary / package |
|---|---|---|---|
| **Desktop** | [egui](https://github.com/emilk/egui) (immediate-mode GUI) | Linux, Windows, macOS | `ontrack` (cargo binary) |
| **Mobile** | [Slint](https://slint.dev) (declarative UI) | Android | `ai.qompass.ontrack` (Play Store + F-Droid, built from source) |

Both apps are thin shells around the same pipeline in the shared `ontrack-core` library:

1. **Parse** — read addresses from typed input or CSV/Excel files.
2. **Geocode** — turn addresses into latitude/longitude (Nominatim, or Google with an API key).
3. **Matrix** — build a stop-to-stop travel-time table (OSRM router, Google, or offline haversine).
4. **Solve** — order the stops with a nearest-neighbor seed refined by 2-opt local search.
5. **Export** — CSV file, Google Maps URL, Waze and ArcGIS FieldMaps deep links.

## Who this book is for

- **Users** — the *User Guide* chapters cover installing the apps, every control on screen, every setting, and the day-to-day workflows.
- **Developers** — the *Code* chapters walk the workspace architecture and each crate module by module, so you can see exactly how the pipeline and the two UIs fit together.

Everything in this book is grounded in the repository source at `qompassai/ontrack`. If a control or setting is not in the source, it is not documented here.
