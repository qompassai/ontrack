#!/usr/bin/env bash
# keystore.sh -- create the Google Play upload keystore for ontrack.
#
# Matt-only: this generates a real signing key. Agents never run this for
# real; it exists so Matt can do the one step only he can do, exactly once,
# with the exact parameters the release runbook expects. Modeled on
# light-show's scripts/publish/tbr-keystore.sh.
#
# Usage:
#   scripts/keystore.sh --dry-run   # prove the keytool command works (throwaway keystore in a mktemp dir, deleted after)
#   scripts/keystore.sh             # create the real keystore (interactive)
#
# After creation:
#   1. Back up the keystore file OFFLINE (USB stick / encrypted backup).
#      Losing it ends updates under the Play listing.
#   2. Put the four ONTRACK_* lines the script prints at the end into
#      ~/.gradle/gradle.properties, filling in the two passwords.
#   3. Never commit the keystore or passwords to git.

set -euo pipefail

((BASH_VERSINFO[0] >= 4)) || {
    echo "ERROR: bash 4+ required" >&2
    exit 1
}

KEYTOOL=/usr/lib/jvm/java-17-openjdk/bin/keytool
ALIAS="${ONTRACK_KEY_ALIAS:-ontrack-upload}"
KEYSTORE_OUT="${ONTRACK_KEYSTORE_OUT:-${XDG_DATA_HOME:-$HOME/.local/share}/keystores/ontrack/google-play-upload.jks}"
KEY_SIZE=4096
VALIDITY_DAYS=10000

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[ -x "$KEYTOOL" ] || die "keytool not found at $KEYTOOL"

case "${1:-}" in
    --dry-run)
        echo "dry-run: validating keytool command line with a throwaway keystore"
        echo "keytool: $KEYTOOL"
        DRYRUN_DIR="$(mktemp -d)"
        trap 'rm -rf "$DRYRUN_DIR"' EXIT
        "$KEYTOOL" -genkeypair -v \
            -keystore "$DRYRUN_DIR/ontrack-keystore-dryrun.jks" \
            -alias dryrun-throwaway \
            -keyalg RSA -keysize 2048 -validity "$VALIDITY_DAYS" \
            -storepass "dryrun-storepass-123" \
            -keypass "dryrun-keypass-123" \
            -dname "CN=Dry Run, OU=Qompass AI, O=Qompass AI, L=Unknown, ST=Unknown, C=US" \
            2>&1 | tail -3
        echo "dry-run: verifying throwaway keystore"
        "$KEYTOOL" -list -v -keystore "$DRYRUN_DIR/ontrack-keystore-dryrun.jks" \
            -storepass "dryrun-storepass-123" -alias dryrun-throwaway 2>/dev/null |
            grep -E "Alias name|Valid from" || die "throwaway keystore verification failed"
        echo "dry-run: PASS (throwaway keystore created, verified, deleted; nothing real was written)"
        echo "real run would write: $KEYSTORE_OUT (alias: $ALIAS)"
        exit 0
        ;;
    "")
        ;;
    *)
        echo "usage: $0 [--dry-run]" >&2
        exit 2
        ;;
esac

echo "This will create the REAL Play upload keystore."
echo "Target: $KEYSTORE_OUT"
echo "Alias:  $ALIAS"
echo ""

# Refuse before prompting for anything: a second key at this path would
# silently diverge from the one the listing gets enrolled with.
[ -e "$KEYSTORE_OUT" ] && die "$KEYSTORE_OUT already exists; refusing to overwrite"

read -rp "Your name for the certificate CN [Qompass AI]: " CN
CN="${CN:-Qompass AI}"

KEY_DIR="$(dirname "$KEYSTORE_OUT")"
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
KEY_PARENT="$(dirname "$KEY_DIR")"
if [ "$(basename "$KEY_PARENT")" = "keystores" ]; then
    chmod 700 "$KEY_PARENT"
fi

# Passwords are deliberately NOT passed via -storepass/-keypass: anything on
# the command line is visible in `ps` output to every local user. With those
# flags omitted, keytool prompts for both passwords itself on its
# controlling terminal, so the secrets never appear in argv, the
# environment, or shell history.
"$KEYTOOL" -genkeypair -v \
    -keystore "$KEYSTORE_OUT" \
    -alias "$ALIAS" \
    -keyalg RSA -keysize "$KEY_SIZE" -validity "$VALIDITY_DAYS" \
    -dname "CN=${CN}, OU=Qompass AI, O=Qompass AI, C=US"

chmod 600 "$KEYSTORE_OUT"
echo ""
echo "Created: $KEYSTORE_OUT"
echo ""
echo "Next: back it up OFFLINE. Then add these lines to"
echo "$HOME/.gradle/gradle.properties (create it if needed, chmod 600 it),"
echo "filling in the two passwords you just entered:"
echo ""
echo "ONTRACK_KEYSTORE=$KEYSTORE_OUT"
echo "ONTRACK_KEY_ALIAS=$ALIAS"
echo "ONTRACK_KEYSTORE_PASS=<the store password you just entered>"
echo "ONTRACK_KEY_PASS=<the key password you just entered>"
echo ""
echo "(The same four names work as environment variables instead;"
echo "build.gradle.kts reads the environment first.)"
