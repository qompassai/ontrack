#!/usr/bin/env bash

# build-web.sh
# Qompass AI — build the browser (wasm) bundle of the desktop egui app
# ----------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/crates/ontrack-desktop"

echo "→ building wasm bundle with Trunk (release)"
trunk build --release

echo "→ bundle written to crates/ontrack-desktop/dist/"
echo "  preview it with: (cd crates/ontrack-desktop && trunk serve)"
