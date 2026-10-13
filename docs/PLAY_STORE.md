# Uploading OnTrack to Google Play Console

A step-by-step runbook for shipping `ontrack` to the Play Console
from an Arch Linux dev box.

## 1. Prerequisites (one-time)

```bash
# Toolchain
rustup target add aarch64-linux-android armv7-linux-androideabi
cargo install cargo-ndk

# Android SDK / NDK / JDK (Arch + AUR)
yay -S android-sdk android-sdk-platform-tools android-sdk-build-tools \
       android-sdk-cmdline-tools-latest android-ndk jdk17-openjdk

# Accept all licenses
yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses

# Install platform 36 + matching build-tools + NDK 28
/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-36" "build-tools;36.0.0" "ndk;28.0.12674087"
```

## 2. Create the upload keystore

Signing keys live in one XDG system for every app and channel:
`$XDG_DATA_HOME/keystores/<app>/<channel>-upload.jks`
(default `$XDG_DATA_HOME` is `~/.local/share`). A keystore is
irreplaceable *data*, not configuration — never `~/.android` (that
directory belongs to the SDK's own tooling: debug key, adb keys, AVDs)
and never loose in `$HOME`.

Creation is a script, not a manual command — `scripts/keystore.sh`
(the light-show pattern: canonical path as its default, refuses to
overwrite an existing keystore, `chmod 600`, passwords prompted by
keytool itself so they never appear in argv; `--dry-run` proves the
command line first with a throwaway key):

```bash
scripts/keystore.sh --dry-run   # rehearse
scripts/keystore.sh             # create the real key (interactive)
```

Then add credentials to ~/.gradle/gradle.properties — the script prints
these same four lines at the end with the absolute path already filled
in; complete the two passwords with the ones you just gave keytool:

```properties
ONTRACK_KEYSTORE=/home/phaedrus/.local/share/keystores/ontrack/google-play-upload.jks
ONTRACK_KEY_ALIAS=ontrack-upload
ONTRACK_KEYSTORE_PASS=<set-me>
ONTRACK_KEY_PASS=<set-me>
```

(The same four names work as environment variables instead;
`build.gradle.kts` reads the environment first.)

## 3. Configure SDK path

```bash
cp crates/ontrack-mobile/android/local.properties.example \
   crates/ontrack-mobile/android/local.properties
# Edit if paths differ.
```

## 4. Build a signed AAB

```bash
bash scripts/build-android.sh
# Produces: crates/ontrack-mobile/android/app/build/outputs/bundle/release/app-release.aab
```

To build with the signing passwords fed from `pass` instead of
`gradle.properties` (the same four names, supplied as environment
variables), use the wrapper: it exports the inputs from the
`qompassai/ontrack/upload-keystore-password` and
`qompassai/ontrack/upload-key-password` entries in memory and then
runs the build above. `--dry-run` proves the keystore and the pass
entries resolve without building:

```bash
bash scripts/build-release.sh            # signed AAB, credentials from pass
bash scripts/build-release.sh --dry-run  # resolve-only check
```

Or directly via Gradle:

```bash
cd crates/ontrack-mobile/android
./gradlew :app:bundleRelease
```

## 5. Play Console steps

1. <https://play.google.com/console> → **All apps → Create app**.
   - App name: **OnTrack**
   - Default language: **English (United States)**
   - Type: **App**
   - Free
   - Accept all declarations.
2. **Set up your app** checklist — fill out at minimum:
   - **App access**: confirm no login walls (or supply test credentials).
   - **Ads**: No.
   - **Content rating**: complete questionnaire (likely *Everyone*).
   - **Target audience**: 18+ (TDS internal field tool).
   - **News app**: No.
   - **Data safety**: declare no data collection (the app stores
     addresses on-device only; no upload to TDS servers).
3. **Store listing**:
   - Short description: *Route optimizer for TDS field service.*
   - Full description: copy from `README.md`.
   - Screenshots: capture 5+ phone screenshots in 9:16 or 16:9 at
     1080px shortest side.
   - Feature graphic: 1024×500 PNG/JPG.
   - App icon: 512×512 PNG — replace `assets/icon.png`'s placeholder
     before submission.
4. **Release → Internal testing → Create new release**:
   - Upload `app-release.aab`.
   - Add release notes (e.g. *Initial pure-Rust build*).
   - Save → Review release → **Start rollout to Internal testing**.
5. Add testers (your own Google account is fine) and click the
   testing URL to download the app via Play.
6. When stable, promote to **Closed → Open → Production**.

## 6. Subsequent versions

Each upload must have a higher `versionCode` than the previous one.
Bump it in `crates/ontrack-mobile/android/app/build.gradle.kts`:

```kotlin
versionCode  = 201   // was 200
versionName  = "2.0.1"
```

Then rebuild with `scripts/build-android.sh`.

## Troubleshooting

- **`License for package … not accepted`** — re-run the
  `sdkmanager --licenses` step.
- **NDK ABI mismatch** — ensure `ndkVersion` in `app/build.gradle.kts`
  matches the one in `sdkmanager` (currently `27.0.12077973`).
- **`linker not found`** — `cargo install cargo-ndk` and re-run.
- **AAB rejected by Play (signing)** — verify `keytool -list -v
  -keystore "${XDG_DATA_HOME:-$HOME/.local/share}/keystores/ontrack/google-play-upload.jks"`
  shows the alias and that `gradle.properties` matches.
