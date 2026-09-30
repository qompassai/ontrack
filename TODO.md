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

- [x] **Recipe commit pinned to SHA (2026-09-29).** `fdroiddata/ai.qompass.ontrack.yml`
      now pins `commit: 50014198c73a93bf747984759c1e6aea11f59777` (the fastlane-metadata
      commit) — F-Droid requires a full 40-char SHA, never a tag. (Correction: the
      `v2.0.0` tag DOES exist on the remote; the earlier note claiming it was missing
      was a truncated `git ls-remote` listing.)
- [x] **fastlane metadata tree added (2026-09-29).** `fastlane/metadata/android/en-US/`
      now has title.txt, short_description.txt (no trailing dot), full_description.txt,
      images/icon.png (512x512), images/phoneScreenshots/1.png, changelogs/201.txt.
- [x] Build recipe dry-run (2026-09-29, on primo from a clean clone).
      `bash scripts/build-android.sh apk` produced
      `crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release-unsigned.apk`
      (24.9 MB) — exactly the path the recipe declares. Fixes committed:
      llvm-strip symlink discovery in build-android.sh, Gradle wrapper 8.7 -> 9.4.1.
      KNOWN ISSUES for the F-Droid submission: (1) skia-bindings 0.90.0 prebuilt
      binaries 404 for armv7-linux-androideabi, forcing a full Skia source build;
      (2) that source build needs ANDROID_NDK set and FAILS on NDK r30
      ("Unversioned target triples are not supported") — built here with NDK r28.
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
