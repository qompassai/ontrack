# BUILD — ontrack

OnTrack is Rust + Slint (`ontrack-core` lib, `ontrack-desktop` egui binary,
`ontrack-mobile` Slint cdylib + preview binary). The Android side is built
with cargo-ndk; the Gradle wrapper only assembles the APK/AAB.

## Continuous feedback: bacon

`bacon.toml` defines the jobs. The one that matters for the editor:

```
bacon --headless -j bacon-ls   # what bacon-ls runs in the background
bacon clippy                   # watch + clippy on change (preferred loop)
bacon test                     # watch + tests on change
bacon check                    # watch + cargo check on change
```

bacon-ls writes diagnostics to `.bacon-locations` (already wired in Matt's
Neovim config). Note: jobs use default features only — the optional `voice`
feature is broken upstream (whisper-rs 0.13.2).

## Build Server Protocol

`.bsp/cargo.json` is the BSP connection card for Matt's Neovim BSP client.
cargo-bsp is unmaintained and not installed, so the card is currently inert;
the working fallback is plain `cargo check` / `cargo build` (or bacon).
See `.bsp/README.md`.

## Debugging: lldb-dap

Debug native binaries, never the on-device `.so` directly:

```
cargo build -p ontrack-mobile --bin ontrack-mobile-preview
```

Point lldb-dap at `target/debug/ontrack-mobile-preview` (or
`target/debug/ontrack` for the desktop binary), break at/before `main`.

## Android

```
scripts/build-android.sh apk    # unsigned release APK (cargo-ndk + Gradle)
scripts/build-android.sh aab    # release bundle (needs Matt's keystore to sign)
scripts/build-android.sh both
```

Needs `ANDROID_HOME` (defaults to `/opt/android-sdk`) and NDK r28.
`scripts/test.sh` runs the full local loop: cargo tests, APK build,
emulator install + screenshot.

Emulator smoke (AVD `ontrack-pixel`, API 36):

```
adb install -r crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release-unsigned.apk
adb shell monkey -p ai.qompass.ontrack -c android.intent.category.LAUNCHER 1
adb exec-out screencap -p > screenshots/<name>.png
```

## Policy gates

```
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
cargo fmt --check
cargo deny check        # licenses/advisories/bans per deny.toml
```

Zero clippy warnings. `cargo deny check` must pass before any commit that
adds or updates dependencies.

## Deterministic builds: Nix flake

`flake.nix` (+ `flake.lock`) pins the native toolchain and exposes it as
apps — see [docs/FLAKE.md](FLAKE.md):

```
nix develop            # pinned Rust toolchain + bacon + lldb + deny/audit
nix run .#gates         # build/clippy/fmt/test + safety + debugger smoke
nix run .#publish-check # store-metadata readiness (dry run)
nix run .#debug-smoke   # standalone lldb-dap breakpoint smoke test
nix run .#release -- v2.0.1 [--dry-run]   # GitHub release end to end
```

Android APK/AAB builds stay primo-local (cargo-ndk + Android SDK are not in
nixpkgs). Release signing and store submissions are human-gated and excluded
from the flake apps by design.
