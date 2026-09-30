# ontrack — TODO for store publication (2026-09-29)

Release candidate: v2.0.0 (versionCode 201). Repo: `qompassai/ontrack`
(route planner for field teams).

Items marked ★ need Matt personally (accounts, keys, console clicks).
Everything else is doable by agents.

The detailed runbooks already live in this repo —
`docs/SUBMISSION_CHECKLIST_FDROID.md`, `docs/SUBMISSION_CHECKLIST_PLAY_STORE.md`,
`docs/PLAY_STORE.md` — and are accurate as of this writing except where
noted below. This file tracks only what is still open.

## F-Droid

- [x] **Recipe commit pinned to SHA (2026-09-30).** `fdroiddata/ai.qompass.ontrack.yml`
      pins the full 40-char SHA of the tree containing the Android build fixes
      (F-Droid requires a SHA, never a tag). The earlier pin (5001419..., the
      fastlane-metadata commit) predated the Gradle 9.4.1 + llvm-strip fixes, so
      the farm would have checked out a tree that cannot build. `ndk:` is now the
      official scheme `28.0.12674087` (the bare `ANDROID_NDK_HOME` value was
      invalid). (Correction: the `v2.0.0` tag DOES exist on the remote; the
      earlier note claiming it was missing was a truncated `git ls-remote`
      listing.)
      2026-09-30 recipe fixes (verified against installed fdroidserver 2.4.5
      source): (a) dropped the subdir field — fdroidserver runs build steps
      with cwd=root_dir=subdir, and the old cd-REPO_ROOT step referenced an
      env var fdroidserver never defines (fatal under bash -u); the recipe now
      has no subdir and all paths are repo-root-relative; (b) removed the
      recipe Description field — the fastlane tree exists, so the field
      would override it (fdroid-publish Gate 3); (c) recipe is now
      fdroid rewritemeta-canonical (zero diff) and fdroid lint-clean
      (only the canonical trailing-space warnings remain).
      Categories [Navigation] and NonFreeNet verified valid against
      fdroiddata master config/categories.yml and config/antiFeatures.yml.
- [x] **fastlane metadata tree added (2026-09-29).** `fastlane/metadata/android/en-US/`
      now has title.txt, short_description.txt (no trailing dot), full_description.txt,
      images/icon.png (512x512), images/phoneScreenshots/1.png, changelogs/201.txt.
- [x] Build recipe dry-run against the re-pinned SHA (2026-09-30, on primo).
      Clean worktree of 4d181c1: ran scripts/build-android.sh apk with
      ANDROID_NDK_HOME pinned to NDK r28 (28.0.12674087, matching the recipe)
      -> DRYRUN_EXIT=0, app-release-unsigned.apk (24,898,552 bytes) at exactly
      the recipe output path, both ABIs inside (arm64-v8a 14.3 MB,
      armeabi-v7a 9.9 MB). The armv7 full Skia source build succeeded once
      ANDROID_NDK was exported (the 20e91fa fix). Re-ran at the final commit
      d4e8f1c (warm cargo cache): DRYRUN2_EXIT=0, byte-identical APK size.
      Recipe gates: fdroid readmeta OK, rewritemeta zero-diff, lint clean
      (only canonical trailing-space warnings), fdroid-publish-check 5/5
      PASS (READY). checkupdates Tags-mode replicated manually (fdroidserver
      git wrapper cannot clone from this network): latest tags resolve to
      versionName 2.0.0 / versionCode 201, matching CurrentVersion.
- [ ] Submit the fdroiddata MR (fork, copy recipe to
      `metadata/ai.qompass.ontrack.yml`, lint, open MR, answer reviewers).

## Google Play

- [x] Phone screenshots: 2 captured of the actual running app on the
      x86_64 emulator (2026-09-29): `images/phoneScreenshots/1.png` (Home,
      empty) and `2.png` (address entry). Replaced the previous placeholder
      `1.png` (corrupt). Play minimum (2) met; 4-8 recommended. Tablet
      screenshots: none.
- [ ] Build + smoke test: `cargo test --workspace` passes on primo (13 passed,
      0 failed, 2026-09-29); unsigned `.apk` builds (see above). Emulator
      smoke (2026-09-29): x86_64 build launches and runs on the API-36
      emulator (Berberis ARM-to-x86 translator caused the earlier ARM
      `jni-0.22.4` panic, not an app bug). UI issues found: (1) adding a stop
      renders a giant gray rectangle where the row trailing widget should
      be; (2) Home/Results/Settings tabs ignore adb taps. Still open:
      signed `.aab` (needs Matt's keystore), full `scripts/test.sh` device step,
      and manual end-to-end exercise on a real device.
- [ ] ★ Upload keystore + key passwords: MISSING — Matt must create
      (outside the repo; loss means a new listing).
- [ ] ★ Invite the service account (`pass` `google/ontrack-fastlane`,
      already exists, shared with light-show) as release-manager on the
      ontrack app in Play Console.
- [ ] ★ Play Console: create the app ("OnTrack"), Data Safety form
      (transcribe from `playstore/google-play.json`), confirm the privacy
      policy URL is live, store listing from the drafted copy, upload to
      the Internal testing track first.

## Notes

- `local.properties` for the Android SDK path is gitignored by design —
      copy from `local.properties.example` on the build machine; never
      commit your own.
- Versioning: every future release needs a new tag + a new `Builds:`
      entry in the fdroiddata recipe; F-Droid only discovers versions from
      tags.
- Secrets inventory (names only):
      `~/workspace/release-scripts/docs/secrets-inventory.md` — Matt
      handles all keys; agents never generate or touch them.
