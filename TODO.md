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

- [ ] **Missing tag.** `fdroiddata/ai.qompass.ontrack.yml` pins
      `commit: v2.0.0`, but no `v2.0.0` tag exists locally or on the remote
      (the F-Droid checklist states it was created and pushed — it is not
      present now). Create + push the tag, or switch the recipe to the full
      40-char commit SHA (F-Droid requires a SHA, never a tag).
- [ ] **fastlane metadata tree missing.** `fastlane/` holds only
      Appfile/Fastfile — there is no `metadata/android/` listing for
      F-Droid to render. Verified by `fdroid-publish-check`, 2026-09-29:
      FAIL.
- [ ] Dry-run the build recipe from a clean checkout
      (F-Droid checklist §1 — never done; needs a real Linux machine with
      Rust/cargo-ndk/NDK).
- [ ] Submit the fdroiddata MR (fork, copy recipe to
      `metadata/ai.qompass.ontrack.yml`, lint, open MR, answer reviewers).

## Google Play

- [ ] Phone screenshots: only `screenshots/ontrack-home.png` exists; Play
      needs at least 2, recommends 4–8, of the actual running app.
      Tablet screenshots: none.
- [ ] Build + smoke test: `scripts/build-android.sh` → signed `.aab`,
      `scripts/test.sh`, then install and exercise end-to-end on a real
      device or emulator. Nothing here has been compiled or run in a
      sandbox.
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
