#!/usr/bin/env bash

# emulate.sh
# Qompass AI - quick emulator bootstrap + install + screenshot
# Copyright (C) 2026 Qompass AI, All rights reserved
# ----------------------------------------
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
sdkmanager "platform-tools" "emulator" "platforms;android-36" "system-images;android-36;google_apis;x86_64"
avdmanager create avd -n ontrack-pixel -k "system-images;android-36;google_apis;x86_64" -d pixel
emulator -avd ontrack-pixel &
adb wait-for-device
adb install -r "$PROJECT_ROOT/crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release.apk"
adb exec-out screencap -p > "$PROJECT_ROOT/ontrack-home.png"
