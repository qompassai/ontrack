# F-Droid Submission Checklist — ONTrack

Package: `ai.qompass.ontrack` · Version: 2.0.0 (versionCode 201) · Tag: `v2.0.0`
Source repo: https://github.com/qompassai/ontrack
Metadata file: `fdroiddata/ai.qompass.ontrack.yml` (to be submitted into F-Droid's
`fdroiddata` repo, not this one)

## Done in the repo

- [x] License is Apache-2.0 — F-Droid requires FOSS licensing, and this is now
      correct and consistent (was mistakenly AGPL-3.0 in one file, BSD-3-Clause in
      another, and an invalid SPDX id in a third — all fixed).
- [x] **No prebuilt binaries committed.** The two `libontrack_mobile.so` files under
      `crates/ontrack-mobile/android/app/src/main/jniLibs/` were removed from git and
      are now gitignored — F-Droid's build server must compile everything from source,
      and it previously could not have (it would have just repackaged your prebuilt
      `.so`, which F-Droid explicitly disallows).
- [x] `fdroiddata/ai.qompass.ontrack.yml` fully rewritten with:
  - Real `AuthorEmail` (`matt@aflabs.io`) instead of a placeholder.
  - Real `Description` describing what the app actually does.
  - Correct `License: Apache-2.0`.
  - Correct `WebSite`/`SourceCode`/`IssueTracker`/`Changelog` URLs, all pointing at
    `qompassai/ontrack` (post-rename).
  - A working `Builds:` recipe: installs `rustup` + `cargo-ndk` + the two Android
    targets, then runs `scripts/build-android.sh apk`, with `output:` pointed at the
    real Gradle APK path.
  - `AntiFeatures: NonFreeNet` declared honestly — the app can talk to Nominatim/OSRM
    public servers or an optional Google Maps key, so it is **not** offline-only by
    default (haversine-only mode is offline, but isn't the default).
- [x] `Builds:` recipe now references `commit: v2.0.0`, and that tag exists and is
      pushed (previously it pointed at a tag that didn't exist yet — F-Droid's build
      bot would have failed immediately on first ingestion).
- [x] `Categories: [Navigation]` set.
- [x] Root of the repo no longer has stray, unrelated `jadx`-tool Gradle scaffolding
      (`settings.gradle.kts`, `gradle.properties`, root `gradlew`) that could confuse
      F-Droid's build-recipe auto-detection — the real, only Android project is fully
      self-contained under `crates/ontrack-mobile/android/`.
- [x] Gradle wrapper added to `crates/ontrack-mobile/android/` so the build recipe's
      `./gradlew` invocation (inside `build-android.sh`) actually has something to run.

## You still need to do

### 1. Verify the build recipe actually works, from a clean checkout
F-Droid's build server starts from a bare clone of the tag and runs exactly the
`sudo:`/`init:`/`build:` steps in the yml — nothing else is pre-installed. This
sandbox has no Rust/NDK/Gradle toolchain, so **this has not been dry-run**. Before
submitting:
- [ ] On a real Linux machine (ideally Debian/Ubuntu, matching F-Droid's build
      containers), `git clone` a **fresh** copy of `https://github.com/qompassai/ontrack`
      at tag `v2.0.0` and run only the commands listed in the `Builds:` block of
      `fdroiddata/ai.qompass.ontrack.yml`, in order, with no other setup.
- [ ] Confirm the final output file exists at exactly
      `app/build/outputs/apk/release/app-release-unsigned.apk` relative to `subdir:`
      (`crates/ontrack-mobile/android`) — F-Droid's tooling checks this path literally.
- [ ] If the NDK isn't already on the build machine, F-Droid's `ndk: ANDROID_NDK_HOME`
      field tells its infra which NDK to provision automatically — you don't need to
      install it yourself on F-Droid's build servers, only on your local dry-run
      machine.

### 2. `fdroiddata` submission (F-Droid's own repo, not yours)
F-Droid apps are added by opening a merge request against F-Droid's own
`fdroiddata` repository, not by them pulling from an arbitrary metadata file in your
repo.
- [ ] Fork `https://gitlab.com/fdroid/fdroiddata`.
- [ ] Copy `fdroiddata/ai.qompass.ontrack.yml` from this repo into
      `metadata/ai.qompass.ontrack.yml` in your fork.
- [ ] Run F-Droid's own linter/build tools locally if possible
      (`fdroid checkupdates`, `fdroid build ai.qompass.ontrack -l -v`) — these require
      the `fdroidserver` Python package, which is not installed in this sandbox.
- [ ] Open a merge request into `fdroiddata` per
      [F-Droid's inclusion policy](https://f-droid.org/docs/Inclusion_Policy/) and
      [submission how-to](https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/).
- [ ] Respond to F-Droid reviewer feedback — first-time submissions almost always get
      at least one round of requested changes to the build recipe.

### 3. Anti-features and reproducibility
- [ ] Double check the `NonFreeNet` anti-feature description still matches reality at
      submission time — if you later make the Google Maps backend the default instead
      of opt-in, or add analytics, this needs updating (and a new anti-feature may
      apply).
- [ ] F-Droid may ask you to make the build fully reproducible (deterministic output
      bytes across rebuilds). `cargo` and Gradle builds can have non-determinism from
      timestamps or absolute paths — be ready to investigate if F-Droid's reproducible
      builds checker flags a mismatch after your first release.

### 4. Versioning going forward
- [ ] Every future F-Droid release needs its own new tag (`vX.Y.Z`) plus a new entry in
      the `Builds:` list in `fdroiddata/ai.qompass.ontrack.yml` — F-Droid does not
      auto-discover new versions from `main`, only from tags matching
      `UpdateCheckMode: Tags`.

## Not blocking, but worth knowing
- The app currently defaults to online geocoding/routing (Nominatim/OSRM). If you
  want a "no network features at all" F-Droid anti-feature-free variant later, that
  would need a separate build flavor defaulting to the offline haversine backend.
