# ot-release: cut a GitHub release end to end.
#
# Usage: nix run .#release -- <version> [--dry-run]
#   <version>  REQUIRED, e.g. v1.2.3 - validated vMAJOR.MINOR.PATCH semver,
#              and the tag must not already exist. No default, no accidents.
#   --dry-run  build artifacts + generate notes, but skip tag creation,
#              tag push, and `gh release create`.
#
# Flow:
#   1. validate version arg + tag-not-exists
#   2. build the release artifacts deterministically (pinned flake toolchain)
#   3. generate changelog notes (git-cliff, git-log fallback - never hand-written)
#   4. create + push the annotated tag
#   5. `gh release create` with the artifacts as release assets
#
# GitHub Releases ONLY. The tbr-* scripts, signing keys, Play Console and
# F-Droid submissions stay OUT by design - a release app must never mint
# signing identities or submit to a store.

DRY_RUN=0
VERSION=""
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=1 ;;
        -*) echo "FATAL: unknown flag '${arg}'" >&2; exit 2 ;;
        *)
            if [ -n "${VERSION}" ]; then
                echo "FATAL: only one version argument allowed" >&2
                exit 2
            fi
            VERSION="${arg}"
            ;;
    esac
done

# --- 1. version validation (before any work) ----------------------------------
if [ -z "${VERSION}" ]; then
    echo "FATAL: a version is required: nix run .#release -- v1.2.3 [--dry-run]" >&2
    exit 2
fi
if ! printf '%s' "${VERSION}" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
    echo "FATAL: version '${VERSION}' is not vMAJOR.MINOR.PATCH semver" >&2
    exit 2
fi
if git rev-parse -q --verify "refs/tags/${VERSION}" >/dev/null; then
    echo "FATAL: tag ${VERSION} already exists; refusing to re-release" >&2
    exit 2
fi

ot_check_deps cargo rustc git git-cliff gh python3 tar gzip sha256sum
ot_start_report "release"

ot_section "Version"
ot_result "version argument" PASS "${VERSION} (dry-run: ${DRY_RUN})"

# --- GitHub auth (ambient only; this app never accepts tokens) -----------------
ot_section "GitHub auth"
if gh auth status >/dev/null 2>&1; then
    ot_result "gh auth" PASS "ambient auth OK"
else
    if [ "${DRY_RUN}" -eq 1 ]; then
        ot_result "gh auth" SKIP "not authenticated; a real release would fail fast here"
    else
        echo "FATAL: gh is not authenticated." >&2
        echo "Authenticate ambiently (gh auth login) and re-run." >&2
        echo "This app never accepts tokens via arguments or environment." >&2
        exit 2
    fi
fi

# --- 2. release artifacts -------------------------------------------------------
ot_section "Release artifacts"
mkdir -p dist
ot_step "cargo build --release -p ontrack-desktop --locked" \
    cargo build --release -p ontrack-desktop --locked
BIN="target/release/ontrack"
ART="dist/ontrack-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
if [ -x "${BIN}" ]; then
    stage="${OT_SCRATCH}/stage"
    mkdir -p "${stage}"
    cp "${BIN}" LICENSE.md README.md "${stage}/"
    if tar -czf "${ART}" -C "${stage}" ontrack LICENSE.md README.md >>"${OT_REPORT}" 2>&1; then
        ot_result "release tarball" PASS "${ART} ($(du -h "${ART}" | cut -f1))"
        sha256sum "${ART}" >>"${OT_REPORT}"
    else
        ot_result "release tarball" FAIL "tar failed"
        OT_FAILED=1
    fi
else
    ot_result "release tarball" FAIL "no binary at ${BIN} after build"
    OT_FAILED=1
fi

# --- Android artifacts: primo-local by design --------------------------------
ot_section "Android artifacts"
# ONTrack's Android path is scripts/build-android.sh (cargo-ndk + Gradle),
# which needs the Android SDK/NDK (not in nixpkgs) and Matt's keystore for
# release signing (human-gated). It is never run from this app; this block
# only records why. Unsigned local APK builds remain a primo-local step.
if command -v cargo-ndk >/dev/null 2>&1 \
    && { [ -n "${ANDROID_HOME:-}" ] || [ -n "${ANDROID_NDK_HOME:-}" ]; }; then
    ot_result "Android APK/AAB" SKIP \
        "cargo-ndk + SDK present, but release APK/AAB signing is human-gated (Matt's keystore); Android releases stay primo-local per docs/FLAKE.md"
else
    ot_result "Android APK/AAB" SKIP \
        "needs cargo-ndk + ANDROID_HOME/ANDROID_NDK_HOME (not in nixpkgs); APK/AAB builds stay primo-local per docs/FLAKE.md"
fi

# --- 3. changelog / release notes (generated, never hand-written) -----------------
ot_section "Changelog / release notes"
PREV_TAG="$(git tag --sort=-v:refname 2>/dev/null | head -n 1 || true)"
if [ -n "${PREV_TAG}" ]; then
    RANGE="${PREV_TAG}..HEAD"
else
    RANGE="HEAD"
fi
NOTES="${OT_SCRATCH}/release-notes.md"
{
    echo "# ONTrack ${VERSION}"
    echo
} >"${NOTES}"
CLIFF_OK=0
if git cliff --config nix/lib/cliff.toml --tag "${VERSION}" "${RANGE}" \
    >>"${NOTES}" 2>"${OT_SCRATCH}/cliff.err"; then
    if grep -q "^- " "${NOTES}"; then
        CLIFF_OK=1
    fi
else
    cat "${OT_SCRATCH}/cliff.err" >>"${OT_REPORT}"
fi
if [ "${CLIFF_OK}" -eq 0 ]; then
    {
        echo "## Changes"
        echo
        git log "${RANGE}" --pretty=format:'- %s (%h)'
        echo
    } >>"${NOTES}"
    ot_result "changelog source" WARN "git-cliff unusable on this history; fell back to git log"
else
    ot_result "changelog source" PASS "git-cliff (${PREV_TAG:-repo root}..HEAD)"
fi
{
    echo
    echo "## Artifacts"
    for f in dist/*; do
        [ -e "${f}" ] || continue
        echo "- $(basename "${f}") (sha256: $(sha256sum "${f}" | cut -d' ' -f1))"
    done
    if [ -n "${PREV_TAG}" ]; then
        echo
        echo "**Full changelog:** https://github.com/qompassai/ontrack/compare/${PREV_TAG}...${VERSION}"
    fi
} >>"${NOTES}"
{
    echo
    echo "### release notes (as uploaded)"
    echo
    cat "${NOTES}"
} >>"${OT_REPORT}"

# --- safety + debugger gates BEFORE anything is published -------------------------
ot_safety_checks
ot_debug_smoke

OT_CLEAN_EXTRAS="dist"   # dist/ is a report-time artifact dir, never "new dirt"
# --- 4+5. tag, push, create the GitHub release ------------------------------------
# Never publish when anything above failed.
if [ "${OT_FAILED}" -ne 0 ]; then
    echo "FATAL: refusing to publish with failing checks; see ${OT_REPORT}" >&2
    ot_verify_clean
    echo "report: ${OT_REPORT}"
    exit 2
fi

ot_section "Release creation"
if [ "${DRY_RUN}" -eq 1 ]; then
    ot_result "dry-run" PASS "skipped: git tag, tag push, gh release create"
    ot_result "would-be tag" SKIP "${VERSION} (not created in dry-run)"
else
    ot_step "git tag -a ${VERSION}" git tag -a "${VERSION}" -m "ONTrack ${VERSION}"
    ot_step "git push origin ${VERSION}" git push origin "${VERSION}"
    # shellcheck disable=SC2086
    ot_step "gh release create ${VERSION}" gh release create "${VERSION}" \
        --title "ONTrack ${VERSION}" \
        --notes-file "${NOTES}" \
        dist/*
fi

# On success the artifacts live on GitHub; drop the local copies.
if [ "${OT_FAILED}" -eq 0 ] && [ "${DRY_RUN}" -eq 0 ]; then
    rm -rf dist
    ot_result "dist/ cleaned after upload" PASS ""
else
    ot_result "dist/ retained" SKIP "dry-run or failure; inspect dist/ manually"
fi

ot_verify_clean

echo "report: ${OT_REPORT}"
if [ "${OT_FAILED}" -ne 0 ]; then
    echo "RELEASE FAILED - see ${OT_REPORT}" >&2
fi
exit "${OT_FAILED}"
