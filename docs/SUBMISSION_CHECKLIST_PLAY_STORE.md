# Google Play Store Submission Checklist — ONTrack

Package: `ai.qompass.ontrack` · Version: 2.0.0 (versionCode 201) · Tag: `v2.0.0`
Repo: https://github.com/qompassai/ontrack

Everything under "Done in the repo" is verified true of the current `main` branch as of
this checklist. Everything under "You still need to do" cannot be done inside this
sandbox (no Android/Rust toolchain, no Play Console access, no camera for real device
screenshots) and requires your own machine or account access.

## Done in the repo

- [x] License consistent everywhere: Apache-2.0 in `LICENSE.md`, `Cargo.toml`,
      `CITATION.cff`, `.zenodo.json`.
- [x] Single canonical application ID `ai.qompass.ontrack` in `build.gradle.kts`,
      `fastlane/Appfile`, `ontrack-mobile/Cargo.toml`, `proguard-rules.pro`, scripts.
- [x] `minSdk 26`, `targetSdk`/`compileSdk` both `36`, consistent in Gradle and Cargo.
- [x] `versionCode 201` / `versionName "2.0.0"` consistent in `build.gradle.kts` and
      `playstore/google-play.json`.
- [x] Gradle wrapper (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) present under
      `crates/ontrack-mobile/android/` so the project builds without a system Gradle.
- [x] `AndroidManifest.xml` permissions declared: `INTERNET`, `ACCESS_NETWORK_STATE`,
      `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`,
      `READ_EXTERNAL_STORAGE` (maxSdk 32).
- [x] `docs/PRIVACY_POLICY.md` rewritten to accurately describe what the app actually
      does: no backend server, which third-party geocoding/routing services receive
      address/coordinate data (Nominatim, OSRM public router, `ip-api.com` IP fallback,
      optional user-supplied Google Maps key), on-device-only location and voice use.
- [x] `playstore/google-play.json` Data Safety section updated to list every permission
      and data type actually collected (addresses, location, on-device voice), not just
      one of them.
- [x] `assets/icon.png` and all 5 mipmap density buckets
      (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi × `ic_launcher`/`ic_launcher_round`) are real,
      correctly-sized PNGs — not placeholders.
- [x] `v2.0.0` git tag created and pushed, matching versionCode 201 — needed because the
      F-Droid build recipe (see F-Droid checklist) builds from a tag, and it's good
      practice for Play releases too.
- [x] **Feature graphic** created at `playstore/feature-graphic.png` — exactly
      1024×500, 24-bit RGB PNG (no alpha), on-brand navy background matching the app
      icon's color, with the ONTrack wordmark, a minimal route/pin motif, and the
      tagline "Smarter Routes for Field Teams".

## You still need to do

### 1. Local build environment
- [ ] Install Rust + `cargo-ndk` + Android SDK/NDK/JDK 17 per `docs/PLAY_STORE.md` §1.
- [ ] Copy `crates/ontrack-mobile/android/local.properties.example` to
      `local.properties` and point it at your SDK (this file is gitignored and was
      just removed from tracking — do not re-commit your own copy).

### 2. Signing
- [ ] Generate an upload keystore (`docs/PLAY_STORE.md` §2) and keep it **outside** the
      repo. Losing this keystore means you can never update the app again under the
      same listing.
- [ ] Set `ONTRACK_KEYSTORE` / `ONTRACK_KEY_ALIAS` / `ONTRACK_KEYSTORE_PASS` /
      `ONTRACK_KEY_PASS` in `~/.gradle/gradle.properties` (not in the repo).

### 3. Build and smoke-test
- [ ] `bash scripts/build-android.sh` → produces
      `crates/ontrack-mobile/android/app/build/outputs/bundle/release/app-release.aab`.
- [ ] Run `scripts/test.sh` (now runs `cargo test --workspace` + a real device/emulator
      build) at least once before shipping.
- [ ] Install and manually exercise the signed build on a real device or emulator —
      nothing in this repo has been compiled or run in this sandbox.

### 4. Missing visual assets (real gaps, not yet in the repo)
- [x] ~~Feature graphic~~ — done, see above.
- [ ] **Phone screenshots** — only one exists (`screenshots/ontrack-home.png`). Play
      requires at least 2, and recommends 4–8, of the actual running app.
- [ ] **Tablet screenshots** — none exist. Optional but recommended if you declare
      tablet support.
- [ ] Capture these from a real build per `docs/book/playstore/release-checklist.md`'s
      emulator/`adb screencap` recipe, or ask me to generate a feature-graphic design
      once you have real in-app screenshots to base it on.

### 5. Play Console setup (one-time, needs your Google account)
- [ ] Create the app at [Play Console](https://play.google.com/console): name
      "OnTrack", free, no ads.
- [ ] **App content** section: Data Safety form — transcribe directly from the
      `dataCollected`/`permissions` list now in `playstore/google-play.json`; Content
      rating questionnaire (likely Everyone); Target audience 18+; Government apps: No;
      News apps: No.
- [ ] **Privacy policy URL**: `https://qompass.ai/ontrack/privacy` — confirm this URL
      will actually be live and hosting the current `docs/PRIVACY_POLICY.md` content
      before submission; Play will reject the listing if the URL 404s or the hosted text
      doesn't match your Data Safety answers.
- [ ] **Store listing**: title, short/full description are already drafted in
      `playstore/google-play.json` → `listing` — copy them in, add the feature graphic
      and screenshots from step 4.
- [ ] **App access**: declare no login wall (the app has no accounts).

### 6. Release
- [ ] Upload the signed `.aab` to an **Internal testing** track first.
- [ ] Add yourself as a tester, install via the Play testing link, confirm it launches
      and a route can be planned end-to-end.
- [ ] Promote Internal → Closed → Open → Production per your own comfort level; each
      new upload needs a strictly higher `versionCode` than 201.

## Reference docs already in the repo
- `docs/PLAY_STORE.md` — full step-by-step build/signing/console runbook.
- `docs/book/playstore/release-checklist.md` — mdbook version of the same, with
  emulator screenshot commands and a staged-rollout template.
