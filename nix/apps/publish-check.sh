# ot-publish-check: deterministic store-metadata readiness checks.
#
# Verifies, without touching anything human-gated:
#   - fastlane metadata tree completeness (title, descriptions, icon,
#     feature graphic, screenshots, changelogs)
#   - fdroiddata recipe presence and versionName/versionCode consistency
#     with the Cargo workspace version and build.gradle.kts
#   - LICENSE.md presence
# then runs the safety checks (cargo-deny, cargo-audit) and the lldb-dap
# breakpoint smoke test.
#
# HUMAN-GATED BOUNDARY (documented, never executed here):
#   scripts/sign.sh                - verifies release APK/AAB signatures
#                                    (needs artifacts signed with Matt's key)
#   scripts/build-android-release.sh - builds the release APK/AAB
#                                    (signing needs Matt's keystore)
#   Play Console submission, F-Droid submission, keystore generation.
# A deterministic sandbox must never mint signing identities or submit
# anything to a store. Those stay Matt-only.
ot_check_deps cargo python3 lldb-dap git cargo-deny
ot_start_report "publish-check"

ot_section "Fastlane metadata completeness"
_required_file() {
    if [ -s "$1" ]; then
        ot_result "fastlane: $1" PASS "present, non-empty"
    else
        ot_result "fastlane: $1" FAIL "missing or empty"
        OT_FAILED=1
    fi
}
_required_file "fastlane/metadata/android/en-US/title.txt"
_required_file "fastlane/metadata/android/en-US/short_description.txt"
_required_file "fastlane/metadata/android/en-US/full_description.txt"
_required_file "fastlane/metadata/android/en-US/images/icon.png"
_required_file "fastlane/metadata/android/en-US/images/featureGraphic.png"
if ls fastlane/metadata/android/en-US/images/phoneScreenshots/*.png >/dev/null 2>&1; then
    ot_result "fastlane: phoneScreenshots" PASS "at least one screenshot present"
else
    ot_result "fastlane: phoneScreenshots" FAIL "no screenshots"
    OT_FAILED=1
fi
if ls fastlane/metadata/android/en-US/changelogs/*.txt >/dev/null 2>&1; then
    ot_result "fastlane: changelogs" PASS "changelog entries present"
else
    ot_result "fastlane: changelogs" WARN "no changelog entries"
fi

ot_section "F-Droid recipe and version consistency"
if [ -f "fdroiddata/ai.qompass.ontrack.yml" ]; then
    ot_result "fdroiddata recipe" PASS "fdroiddata/ai.qompass.ontrack.yml present"
else
    ot_result "fdroiddata recipe" FAIL "fdroiddata/ai.qompass.ontrack.yml missing"
    OT_FAILED=1
fi
_ws_version="$(grep -E '^version' Cargo.toml | head -n 1 | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')"
_fd_version="$(grep -E 'versionName:' fdroiddata/ai.qompass.ontrack.yml | head -n 1 | sed -E 's/.*versionName: *//')"
_gradle_version="$(grep -E 'versionName' crates/ontrack-mobile/android/app/build.gradle.kts | head -n 1 | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')"
_fd_code="$(grep -E 'versionCode:' fdroiddata/ai.qompass.ontrack.yml | head -n 1 | sed -E 's/.*versionCode: *//')"
_gradle_code="$(grep -E 'versionCode' crates/ontrack-mobile/android/app/build.gradle.kts | head -n 1 | sed -E 's/.*= *([0-9]+).*/\1/')"
ot_result "workspace version" PASS "Cargo.toml workspace.package.version = ${_ws_version}"
if [ "${_ws_version}" = "${_fd_version}" ] && [ "${_ws_version}" = "${_gradle_version}" ]; then
    ot_result "versionName consistency" PASS "Cargo=${_ws_version} fdroiddata=${_fd_version} gradle=${_gradle_version}"
else
    ot_result "versionName consistency" FAIL "Cargo=${_ws_version} fdroiddata=${_fd_version} gradle=${_gradle_version}"
    OT_FAILED=1
fi
if [ "${_fd_code}" = "${_gradle_code}" ]; then
    ot_result "versionCode consistency" PASS "fdroiddata=${_fd_code} gradle=${_gradle_code}"
else
    ot_result "versionCode consistency" FAIL "fdroiddata=${_fd_code} gradle=${_gradle_code}"
    OT_FAILED=1
fi
if [ -f "LICENSE.md" ]; then
    ot_result "LICENSE.md" PASS "present"
else
    ot_result "LICENSE.md" FAIL "missing"
    OT_FAILED=1
fi

ot_section "Human-gated boundary (intentionally not run)"
{
    echo "These steps are excluded from all flake apps by design:"
    echo "- scripts/sign.sh (verifies release APK/AAB signatures; needs Matt's signed artifacts)"
    echo "- scripts/build-android-release.sh (builds release APK/AAB; signing needs Matt's keystore)"
    echo "- Play Console submission, F-Droid submission, keystore generation"
    echo "They must be run by Matt himself."
} >>"${OT_REPORT}"
ot_result "human-gated steps excluded" PASS "signing/submission untouched by design"

ot_safety_checks
ot_debug_smoke
ot_verify_clean

echo "report: ${OT_REPORT}"
if [ "${OT_FAILED}" -ne 0 ]; then
    echo "PUBLISH-CHECK FAILED - see ${OT_REPORT}" >&2
fi
exit "${OT_FAILED}"
