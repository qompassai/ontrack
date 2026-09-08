#!/usr/bin/env bash

# sign.sh
# Qompass AI - verify release APK/AAB signatures
# Copyright (C) 2026 Qompass AI, All rights reserved
# ----------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="$ROOT/crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release.apk"
AAB="$ROOT/crates/ontrack-mobile/android/app/build/outputs/bundle/release/app-release.aab"

[ -f "$APK" ] && apksigner verify --print-certs "$APK" || echo "⚠ no release APK at $APK, skipping"
[ -f "$AAB" ] && jarsigner -verify -verbose -certs "$AAB" || echo "⚠ no release AAB at $AAB, skipping"
