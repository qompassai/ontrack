---
name: ontrack-bsp-debug
description: "Build, debug, and verify OnTrack (Rust + Slint): cargo-bsp build-server cards, bacon continuous watch, lldb-dap sessions against the desktop/preview binaries, Android APK builds and emulator verification on the ontrack-pixel AVD. Use when building, debugging, or smoke-testing ontrack."
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite, WebFetch, WebSearch
metadata:
  repo: qompassai/ontrack
  user-invocable: "false"
---

# ontrack-bsp-debug

## Build & debug OnTrack (Rust + Slint)

OnTrack is Rust + Slint, not Gradle/Kotlin: `ontrack-core` (route-optimization
library), `ontrack-desktop` (egui binary `ontrack`), `ontrack-mobile` (Slint
`cdylib` + `ontrack-mobile-preview` binary; Android packaging is cargo-ndk plus
a thin Gradle wrapper that only assembles the APK). The optional `voice`
feature is broken upstream (whisper-rs 0.13.2) — default features only until
whisper-rs ships a fix.

## Activation

- **Resources**: `bacon.toml` (jobs incl. `bacon-ls`), `.bsp/cargo.json`,
  `deny.toml`, `scripts/build-android.sh`, `scripts/test.sh`, AVD
  `ontrack-pixel` (API 36, x86_64).
- **Per-session dedup**: load once per session; re-read only if `bacon.toml`,
  `.bsp/`, or the scripts changed mid-session.
- **Subagent delegation**: one agent per workstream (native gates / android /
  debug). Disjoint file ownership; point at paths, never paste file contents.

## Build paths

**BSP**: `.bsp/cargo.json` is the connection card Matt's Neovim BSP client
reads. cargo-bsp itself is unmaintained and normally not installed — the card
records the intent; the working fallback is plain cargo (or bacon).

**bacon** (preferred loop): `bacon clippy`, `bacon test`, `bacon check`.
bacon-ls runs `bacon --headless -j bacon-ls` in the background and writes
`.bacon-locations`. Do not run bare `cargo check` repeatedly when bacon is
available.

**Android APK**: `scripts/build-android.sh apk` — cargo-ndk builds
`aarch64-linux-android` + `armv7-linux-androideabi`, then the Gradle wrapper
runs `:app:assembleRelease`. Unsigned release APK lands at
`crates/ontrack-mobile/android/app/build/outputs/apk/release/`. Needs
`ANDROID_HOME` (defaults to `/opt/android-sdk`) and an NDK (r28).

## DAP debugging (lldb-dap)

Debug the native binaries — never the on-device `.so` directly:

```
cargo build -p ontrack-mobile --bin ontrack-mobile-preview
# or: cargo build -p ontrack-desktop --bin ontrack
```

lldb-dap launch: `program` = `target/debug/ontrack-mobile-preview` (or
`target/debug/ontrack`), `cwd` = repo root. Set breakpoints (e.g. on `main`
or a Slint callback), launch, verify the stop, inspect locals, disconnect.
The preview binary opens a window — break at/before `main` so the session
proves the stop without needing a display. `continue` past window creation
headless may fail without X/Wayland; that is expected, not a bug.

## Emulator verification (AVD `ontrack-pixel`, API 36)

```
adb install -r <apk>
adb shell monkey -p ai.qompass.ontrack -c android.intent.category.LAUNCHER 1
adb exec-out screencap -p > screenshots/<descriptive-name>.png
```

Prove UI fixes with screenshots: exercise the exact broken flow (add a stop;
tap each tab via `adb shell input tap <x> <y>`), save under `screenshots/`
with descriptive names. The x86_64 emulator runs the ARM build through the
Berberis translator — a translator panic is an emulator artifact, not an app
bug; verify on the symptom, not the translator.

## Gates

```
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --check
cargo deny check
```

Report exact counts; never claim a gate without running it. Zero clippy
warnings. `voice` feature excluded until whisper-rs is fixed upstream.

## Structured subagent use

When delegating ontrack build/debug work, wrap each brief in this structure:

```
objective: <one sentence, verifiable>
scope: <files/crates it may touch; everything else is read-only>
toolchain: <bacon job / cargo cmd / DAP / adb as appropriate>
gates: <exact commands that must pass>
report: <files changed, test counts, failures, skips — deltas, not transcripts>
stop: <when to stop and ask instead of pushing through>
```

One agent per workstream. Bounded, disjoint file ownership; no two agents
edit the same file.
