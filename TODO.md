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
- [ ] Build recipe dry-run against the re-pinned SHA (2026-09-30, on primo from
      a clean worktree of the pinned commit): `bash scripts/build-android.sh apk`
      with `ANDROID_NDK_HOME` pinned to NDK r28 (28.0.12674087, matching the
      recipe). The 2026-09-29 dry run was on a later tree, not the pinned SHA.
      Fixes since: build-android.sh now exports ANDROID_NDK (skia-bindings
      0.90.0 requires it; fdroidserver sets it on the farm only when `ndk:` is a
      valid version). KNOWN ISSUES for the F-Droid submission: (1) skia-bindings
      0.90.0 prebuilt binaries 404 for armv7-linux-androideabi, forcing a full
      Skia source build (slow but works); (2) that source build FAILS on NDK r30
      ("Unversioned target triples are not supported") — hence the r28 pin.
      F-Droid's farm will hit both; expect reviewer questions.
- [ ] Submit the fdroiddata MR (fork, copy recipe to
      `metadata/ai.qompass.ontrack.yml`, lint, open MR, answer reviewers).

## Google Play

- [ ] Phone screenshots: only `screenshots/ontrack-home.png` exists; Play
      needs at least 2, recommends 4–8, of the actual running app.
      Tablet screenshots: none.
- [ ] Build + smoke test: `cargo test --workspace` passes on primo (13 passed,
      0 failed, 2026-09-29); unsigned `.apk` builds (see above). Still open:
      signed `.aab` (needs Matt's keystore), full `scripts/test.sh` device step
      (`acli.sh` needs a running emulator/device), and manual end-to-end exercise
      on a real device.
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
