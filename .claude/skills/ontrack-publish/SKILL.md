---
name: "ontrack-publish"
description: "Publish ONTrack (ai.qompass.ontrack) to Google Play and F-Droid: fastlane metadata tree, fdroiddata recipe, Android build and test gates on the primo toolchain, TODO.md tracking, and the operator-only boundary. Trigger when Matt asks to finish, publish, or ship ONTrack."
metadata:
  includeInPrompt: "true"
---

# ONTrack Publish

Take ONTrack from source to a merged F-Droid submission and a Play-ready
build, without the agent ever touching signing material.

ELI5: publishing an Android app means proving to two stores that your app is
what you say it is, built from the exact code you point at, with honest
descriptions and screenshots. F-Droid rebuilds your app itself from your
recipe, so the recipe must describe the build so precisely that a stranger's
machine reproduces your APK. This skill is the complete procedure that was
used to get ONTrack publish-ready: every gate, every trap found the hard way.

## Standing contracts

1. **Primo is the build machine.** All cargo/gradle work runs on primo via
   `~/workspace/bin/primo-ssh` (wrapper: `ssh -F /home/hatch/.ssh/config
   primo`). Never `ssh primo` bare from a root shell — it reads the wrong
   ssh config. The sandbox has no Android toolchain.
2. **Primo is authoritative** whenever it disagrees with the sandbox.
3. **Never generate or handle signing material.** No keystores, no upload
   keys, no passwords, no Play credentials. Those are operator-only (Matt).
4. **Push discipline:** every push needs Matt's explicit one-time
   authorization naming the commits; authorizations are consumed on use.
   Fast-forward only — never force-push. Re-read the remote (`git ls-remote`)
   before pushing and verify byte-identical after.
5. **Never reconstruct lost work** — the 2026-09-25 WIP-loss rule: restore
   only Matt's exact machine copies.
6. **Report exactly what passed, failed, was skipped, or was pre-existing.**
   Never claim a gate you didn't run. Never weaken a gate to make it green.

## The app

- Repo: `qompassai/ontrack` — Rust workspace, Android app at
  `crates/ontrack-mobile/android` (Gradle 9, NDK r28).
- Application ID: `ai.qompass.ontrack`
- versionName `2.0.0`, versionCode `201` — as **literals** in
  `crates/ontrack-mobile/android/app/build.gradle.kts`
  (`versionCode   = 201`, `versionName   = "2.0.0"`).
  F-Droid needs literals; a computed versionCode is a recipe FAIL.
- Build script: `scripts/build-android.sh apk` (run from the repo root).
  Output: `crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release-unsigned.apk`.

## Phase 1 — fastlane metadata tree

Location: `fastlane/metadata/android/en-US/`. F-Droid renders the store
listing from this tree, so the recipe must NOT set `Name:`, `Summary:`, or
`Description:` (they override the fastlane tree — caught 2026-09-30).

Required files and their contracts:

| File | Contract |
|---|---|
| `title.txt` | ≤ 50 chars |
| `short_description.txt` | ≤ 80 chars, **must end with a period** |
| `full_description.txt` | ≤ 4000 chars |
| `changelogs/201.txt` | ≤ 500 chars, describes this versionCode |
| `images/icon.png` | 512×512 |
| `images/featureGraphic.png` | Play feature graphic |
| `images/phoneScreenshots/` | **≥ 2 real phone screenshots** (Play recommends 4–8) |

Style rules (both stores enforce these): no emojis, no ALL-CAPS, short
description ends with a period. Screenshots must be real captures of the
app on a phone — not mockups.

Worked example — verifying the tree with the fdroid-publish skill's
checker (handles nested Android projects):

```bash
python3 bin/fdroid-publish-check --repo . --appid ai.qompass.ontrack --vercode 201
```

Gate: all five lines PASS, final line `appid ai.qompass.ontrack: READY`,
exit 0. The gates are: `license` (LICENSE file present), `fastlane` (tree
complete), `tags` (release tags exist), `nonfree` (no Firebase/GMS markers
in build files), `versions` (versionCode/versionName as literals).

## Phase 2 — pin the real commit, not a tag name

Trap found 2026-09-30: the `v2.0.0` tag pointed at a commit that did **not**
contain the F-Droid recipe or the build fixes. A tag name is a promise, not
proof — verify what tree it resolves to:

```bash
git rev-list -n 1 v2.0.0
git ls-tree <sha> fdroiddata/ai.qompass.ontrack.yml scripts/build-android.sh
```

The recipe's `commit:` field must be the **full 40-character SHA of the
tree that actually builds** (the tree containing the ANDROID_NDK script fix
and the Gradle/NDK fixes). If implementation files change after pinning,
re-pin to the new full SHA. The recipe SHA is a build input: treat any
change to it as invalidating prior dry-run evidence.

## Phase 3 — the fdroiddata recipe

File: `fdroiddata/ai.qompass.ontrack.yml` (staged in-repo; the real
submission copies it into the fdroiddata fork). Every field below was
verified against installed fdroidserver 2.4.5 source on 2026-09-30.

```yaml
Builds:
  - versionName: 2.0.0
    versionCode: 201
    commit: <full-40-char-SHA-of-build-fixed-tree>
    sudo:
      - apt-get update
      - apt-get install -y curl build-essential
    init:
      - curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
      - source "$HOME/.cargo/env"
      - rustup target add aarch64-linux-android armv7-linux-androideabi
      - cargo install cargo-ndk
    output: crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release-unsigned.apk
    build:
      - source "$HOME/.cargo/env"
      - ./scripts/build-android.sh apk
    ndk: 28.0.12674087
```

Field contracts (each is a trap that fired once):

1. **`commit:`** — full 40-char SHA (Phase 2). Never a tag, never a short SHA.
2. **`ndk:`** — official version scheme (`28.0.12674087`), NOT an environment
   variable name. fdroidserver exports `ANDROID_NDK`, `NDK`, and
   `ANDROID_NDK_HOME` from this value. NDK r28 is pinned because NDK r30
   fails Skia with `Unversioned target triples are not supported!`
   (verified on primo).
3. **No `subdir:` field.** fdroidserver executes `build:` steps with
   `cwd = build_dir/subdir` under `bash -u`. The old recipe had
   `subdir: crates/ontrack-mobile/android` plus `cd "$REPO_ROOT"` in the
   build step — but fdroidserver **never defines `$REPO_ROOT`**, so that
   step died on an unbound variable. With no `subdir:`, `build:` runs at
   the repo root and `output:` is repo-root-relative. `output:` resolves
   as `os.path.join(root_dir, output)` with the `raw` output method.
4. **rustup goes in `init:`, not `sudo:`.** `sudo:` runs as root; `init:`
   runs as the build user. Installing rustup under `sudo:` puts it in
   root's home, and then `source "$HOME/.cargo/env"` in `init:` fails.
   Keep only OS packages under `sudo:`.
5. **No `Description:` / `Name:` / `Summary:`** when the fastlane tree
   exists — those fields override the tree.
6. **`AutoUpdateMode: None`** with `UpdateCheckMode: Tags` — decide with
   Matt whether `Version` mode fits before the MR.

Recipe gates (run in a real fdroiddata checkout, not a scratch tree):

```bash
fdroid readmeta                                  # must be clean
fdroid rewritemeta ai.qompass.ontrack            # run twice; second must be zero-diff (canonical)
fdroid lint ai.qompass.ontrack                   # clean; only rewritemeta's canonical trailing-space warnings are acceptable
fdroid checkupdates --allow-dirty ai.qompass.ontrack
```

Known tooling caveat: fdroidserver's git wrapper rewrites GitHub HTTPS URLs
to `https://u:p@github.com/...`, which GitHub rejects on some networks even
when plain `git ls-remote` works. If `checkupdates` cannot clone, replicate
Tags-mode manually (`git ls-remote --tags`, resolve the newest tag's tree,
confirm versionName/versionCode) and say so explicitly — never claim
`checkupdates` passed when it didn't run.

## Phase 4 — build and test on the primo toolchain

Environment (verified 2026-09-30):

- NDKs: `/opt/android-sdk/ndk/28.0.12674087` (use this),
  `/opt/android-sdk/ndk/30.0.16248370` (breaks Skia — do not use).
- `cargo-ndk` must be on `PATH` in the build step (the recipe sources
  `$HOME/.cargo/env` for this). On primo rustup came from the system
  package manager, so there is no `$HOME/.cargo/env` — export
  `PATH="$HOME/.cargo/bin:$PATH"` in dry runs instead.

The Skia trap: `skia-bindings 0.90.0` reads **`ANDROID_NDK`** specifically
(`cargo::env_var("ANDROID_NDK").expect("ANDROID_NDK variable not set")`)
and panics without it. `scripts/build-android.sh` exports
`ANDROID_NDK="$ANDROID_NDK_HOME"` for exactly this reason. The armv7
prebuilt Skia tarball 404'd upstream, so armv7 does a **full Skia source
build** (slow — tens of minutes, normal).

Recipe dry-run procedure (the exact-pinned-SHA gate):

1. Fresh detached worktree at the **exact recipe SHA**:
   `git worktree add /tmp/ontrack-dryrun <full-sha>`.
2. Run only the recipe's `build:` steps, in order, with the pinned NDK —
   no extra setup, no reliance on the main worktree's cache:
   ```bash
   export PATH="$HOME/.cargo/bin:$PATH"
   cd /tmp/ontrack-dryrun
   ANDROID_NDK_HOME=/opt/android-sdk/ndk/28.0.12674087 \
     bash scripts/build-android.sh apk
   ```
3. Verify: exit 0, and
   `crates/ontrack-mobile/android/app/build/outputs/apk/release/app-release-unsigned.apk`
   exists (the recipe's declared `output:` path) with both
   `lib/arm64-v8a/libontrack_mobile.so` and
   `lib/armeabi-v7a/libontrack_mobile.so` inside
   (`unzip -l ... | grep 'lib/.*\.so'`).
4. Remove the worktree when done: `git worktree remove --force`.

Tests:

```bash
cargo test --workspace   # 13 passed, 0 failed (2026-09-30)
```

`scripts/test.sh` ends with `scripts/acli.sh full ontrack 4` — run it
only with a running emulator or device attached.

## Phase 5 — TODO.md

`TODO.md` is the publication ledger. Mark items `[x]` only with evidence:
the SHA built, the gate output, the byte counts. Keep the remaining
operator-only items (`keystore`, Play Console, fdroiddata MR, screenshots)
as open `[ ]` items so nothing silently drops.

## Operator-only (Matt) — agents never do these

- Generate and securely back up the upload keystore and its passwords
  **outside the repository**.
- Invite the service account stored at `pass google/ontrack-fastlane`
  as release-manager for the ONTrack app in Play Console.
- Configure the Play Console listing, complete Data Safety, ensure the
  privacy-policy URL is live.
- Upload a signed `.aab` to Internal testing and promote it.
- Fork `fdroid/fdroiddata`, copy the recipe in, open the GitLab MR, and
  handle reviewer responses.
- Final real-device end-to-end validation.

If any step asks for a keystore, a password, a Play credential, or a
signature — stop. That is the operator boundary, not a missing setup step.

## Definition of done

- [ ] fastlane tree complete; `fdroid-publish-check` 5/5 PASS, READY.
- [ ] Recipe pins the full SHA of the tree that builds; `commit:` matches.
- [ ] `fdroid readmeta` clean, `rewritemeta` zero-diff, `lint` clean,
      `checkupdates` actually run (or its manual replication documented).
- [ ] Dry-run from a clean worktree at the exact recipe SHA: exit 0, APK at
      the declared `output:` path, both ABIs inside.
- [ ] `cargo test --workspace` green for the pushed tree.
- [ ] TODO.md reflects the evidence; operator-only items remain open.
- [ ] Commits pushed fast-forward with Matt's one-time authorization,
      remote verified byte-identical.
