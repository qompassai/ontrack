#!/usr/bin/env bash

# test.sh
# Qompass AI - full local test loop: cargo tests, native build, on-device smoke test
# ----------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "→ running cargo tests"
cargo test --workspace

echo "→ building native libs + release APK (cargo-ndk)"
"$ROOT/scripts/build-android.sh" apk

echo "→ install + screenshot on a running emulator/device"
"$ROOT/scripts/acli.sh" full ontrack 4
