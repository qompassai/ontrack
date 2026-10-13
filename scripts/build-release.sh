#!/usr/bin/env bash
# build-release.sh -- build ontrack's signed Google Play release bundle
# (AAB) in one command, with the signing passwords fed from pass.
#
# Why this exists: build.gradle.kts reads the four ONTRACK_* signing
# inputs from the environment first, so the passwords never need to sit
# in a plaintext ~/.gradle/gradle.properties. This wrapper performs the
# pass -> environment hop in memory and then runs the documented build;
# the exports die with the build process. Passwords are never printed,
# logged, or written to a file by this script.
#
# Usage:
#   scripts/build-release.sh --dry-run   # prove keystore + pass resolve (no build)
#   scripts/build-release.sh             # build the signed AAB
#
# Inputs (environment; the same names keystore.sh and build.gradle.kts
# use):
#   ONTRACK_KEYSTORE       keystore path (default: the canonical XDG
#                          path below)
#   ONTRACK_KEYSTORE_OUT   creation-path override honored by
#                          keystore.sh; used when ONTRACK_KEYSTORE is
#                          unset
#   ONTRACK_KEY_ALIAS      key alias (default: ontrack-upload)
#
# Secrets come from pass, never from arguments or files:
#   qompassai/ontrack/upload-keystore-password -> ONTRACK_KEYSTORE_PASS
#   qompassai/ontrack/upload-key-password      -> ONTRACK_KEY_PASS
#
# The build itself is the documented one (docs/PLAY_STORE.md section
# 4): scripts/build-android.sh, which runs cargo-ndk and then the
# Gradle wrapper's :app:bundleRelease in crates/ontrack-mobile/android.
# This script execs it, so the build's exit code is this script's exit
# code.
# Output: crates/ontrack-mobile/android/app/build/outputs/bundle/release/app-release.aab

set -euo pipefail

((BASH_VERSINFO[0] >= 4)) || {
    echo "ERROR: bash 4+ required" >&2
    exit 1
}

STORE_PASS_ENTRY="qompassai/ontrack/upload-keystore-password"
KEY_PASS_ENTRY="qompassai/ontrack/upload-key-password"
ALIAS="${ONTRACK_KEY_ALIAS:-ontrack-upload}"
KEYSTORE="${ONTRACK_KEYSTORE:-${ONTRACK_KEYSTORE_OUT:-${XDG_DATA_HOME:-$HOME/.local/share}/keystores/ontrack/google-play-upload.jks}}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/scripts/build-android.sh"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

case "${1:-}" in
    --dry-run)
        DRY_RUN=1
        ;;
    "")
        DRY_RUN=0
        ;;
    *)
        echo "usage: $0 [--dry-run]" >&2
        exit 2
        ;;
esac

command -v pass >/dev/null || die "pass not found on PATH; the signing passwords live in pass"

[ -f "$KEYSTORE" ] || die "keystore not found at $KEYSTORE; create it with scripts/keystore.sh"

# The values land in variables only; nothing below ever prints them. If
# pass cannot read an entry (locked store, missing entry), fail here
# with the entry named -- never fall back to an unsigned build or a
# plaintext file.
ONTRACK_KEYSTORE_PASS="$(pass show "$STORE_PASS_ENTRY")" ||
    die "could not read pass entry $STORE_PASS_ENTRY"
[ -n "$ONTRACK_KEYSTORE_PASS" ] || die "pass entry $STORE_PASS_ENTRY is empty"
ONTRACK_KEY_PASS="$(pass show "$KEY_PASS_ENTRY")" ||
    die "could not read pass entry $KEY_PASS_ENTRY"
[ -n "$ONTRACK_KEY_PASS" ] || die "pass entry $KEY_PASS_ENTRY is empty"

export ONTRACK_KEYSTORE="$KEYSTORE"
export ONTRACK_KEY_ALIAS="$ALIAS"
export ONTRACK_KEYSTORE_PASS
export ONTRACK_KEY_PASS

if [ "$DRY_RUN" = "1" ]; then
    echo "dry-run: signing inputs resolve; no build run"
    echo "ONTRACK_KEYSTORE=$KEYSTORE"
    echo "ONTRACK_KEY_ALIAS=$ALIAS"
    echo "ONTRACK_KEYSTORE_PASS=<from pass: $STORE_PASS_ENTRY>"
    echo "ONTRACK_KEY_PASS=<from pass: $KEY_PASS_ENTRY>"
    echo "build: $BUILD"
    exit 0
fi

# build-android.sh needs cargo + cargo-ndk on PATH; a non-interactive
# shell may not have ~/.cargo/bin yet (the same fix
# build-android-release.sh applies).
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo "building signed release bundle (keystore: $KEYSTORE, alias: $ALIAS)"
exec bash "$BUILD"
