# FLAKE — deterministic Nix environments for ontrack

`flake.nix` (+ `flake.lock`) pins the entire native toolchain and exposes it
as four deterministic apps. Same program as `qompassai/light-show`, adapted
for this repo (Rust + Slint workspace, **not** Kotlin/Gradle).

## Pinned inputs (flake.lock, committed)

| Input       | Revision | Date       |
|-------------|----------|------------|
| nixpkgs     | `7fc6f2c20af09cdcaf48b92ec3121860139ec668` (`nixos-26.05`) | 2026-09-28 |
| flake-utils | `11707dc2f618dd54ca8739b309ec4fc024de578b` | 2024-11-13 |
| fenix       | (pinned revision recorded in flake.lock) | |

Toolchain (recorded 2026-09-30):

- Rust via **fenix** (same pattern as phlow): `nightly-2026-09-25`
  (rustc 1.100.0-nightly), pinned by the flake.lock `fenix` input AND the
  date-pinned channel manifest
  (`https://static.rust-lang.org/dist/2026-09-25/channel-rust-nightly.toml`,
  sha256 `3ok3kaNc8lhDSnZ9bZAJwmHgUrdB9CC5m+ZJBwFPWnA=`), declared in
  `nix/rust-toolchain.toml`. Components: cargo, clippy, rust-src, rustc, rustfmt.
- cargo-deny 0.19.6, cargo-audit 0.22.1, git-cliff 2.14.2, bacon, lldb (lldb-dap)

Why fenix instead of nixpkgs rustc: nixpkgs rustc 1.95.0 cannot build this
workspace -- it dies with E0463 (`can't find crate for 'slint_macros'`) on
the large slint-macros dylib while rustup toolchains build it fine. The
repo-root `rust-toolchain` file (unpinned nightly, for rustup users outside
nix) is untouched; the flake never consults it.

Root cause of the E0463 (verified 2026-09-30, corrected -- it is NOT a rustc
packaging bug): primo's ambient `~/.cargo/config.toml` sets
`linker = "/usr/bin/clang"`, which links the **host glibc (2.43)**. The fenix
(and nixpkgs) rustc runs on the **nix glibc (2.42)**. A proc-macro dylib linked
against host glibc 2.43 fails dlopen inside the nix-glibc rustc_driver
(`libm.so.6: version GLIBC_2.43 not found`), and rustc surfaces the dlopen
failure as the misleading E0463 "can't find crate". Evidence: the identical
.so loads fine under the rustup nightly-2026-09-25 rustc (same compiler
version `1.100.0-nightly f7575a9da`, system glibc), while a C dlopen probe
linked against the nix glibc reproduces the exact version error. (This also
explains why tiny proc macros seemed to work under nix rustc -- they never
referenced the newer glibc symbols.)

Fix: the flake adds nix `clang` to devTools and exports
`CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER` (nix clang wrapper) in the
devShell and every app, overriding the ambient config's linker for flake
builds only. All artifacts -- including proc-macro dylibs -- then link the
nix glibc, matching the rustc runtime. Matt's ambient config is untouched,
so his non-nix builds keep using /usr/bin/clang.

Safety-check agreement: `cargo deny check` honors `deny.toml`'s `[advisories]`
ignore list (accepted risks with rationale, e.g. quick-xml < 0.41.0), but
`cargo audit` does not read deny.toml. `nix/lib/common.sh` translates the
deny.toml ignore IDs into `cargo audit --ignore` flags, so both tools enforce
the same policy and anything NOT listed in deny.toml still fails the gate.

## Apps

```
nix develop            # pinned toolchain + bacon + lldb + deny/audit
nix run .#gates         # build / clippy / fmt / test + safety + debugger smoke
nix run .#publish-check # store-metadata readiness (dry run; human gates excluded)
nix run .#debug-smoke   # standalone lldb-dap breakpoint smoke test
nix run .#release -- v2.0.1 [--dry-run]   # GitHub release end to end
```

**gates.** `cargo build --workspace --locked`; `cargo build -p ontrack-mobile
--bin ontrack-mobile-preview --features slint/backend-winit --locked`;
`cargo clippy --workspace --all-targets --locked -- -D warnings`;
`cargo fmt --all -- --check`; `cargo test --workspace --locked`; then
cargo-deny, cargo-audit, the lldb-dap breakpoint smoke test, and a
worktree-clean check. Mirrors the `bacon.toml` jobs and then some.

**publish-check.** Verifies fastlane metadata completeness
(title/description/icon/feature graphic/screenshots/changelogs), the
`fdroiddata/ai.qompass.ontrack.yml` recipe, and versionName/versionCode
consistency across `Cargo.toml`, the fdroiddata recipe, and
`build.gradle.kts`. Then safety checks + debugger smoke + worktree clean.
Never executes anything human-gated.

**debug-smoke.** Drives lldb-dap over DAP against the `ontrack-core`
unit-test binary: breakpoint on `ontrack_core::solver::solve_tsp`
(source-line fallback), launches `solver::tests::solves_trivial_route
--exact`, confirms the stop with the function on the stack. Verdict is
PASS / FAIL / SKIP — never faked. Handles the verified lldb-dap quirks:
`initialized` arrives after `launch`, `configurationDone` is required
before the debuggee runs, and the set-breakpoint `verified` flag is not
trusted (the verdict rests on an actual stop).

**release.** `nix run .#release -- <version> [--dry-run]`:

1. Requires an explicit `vMAJOR.MINOR.PATCH` version; refuses existing tags.
2. Builds the release artifacts with the pinned toolchain
   (`cargo build --release -p ontrack-desktop --locked` → tarball with
   `LICENSE.md` + `README.md` in `dist/`, gitignored).
3. Generates notes with git-cliff (`nix/lib/cliff.toml`, conventional
   commits; no `skip_tags` — the tag-hygiene check in the app makes it
   unnecessary, and a `skip_tags` regex would substring-match the tag being
   generated), falling back to a `git log` summary.
4. Runs the safety + debugger gates; refuses to publish on failure.
5. Creates the annotated tag, pushes it, and runs
   `gh release create <version> --title ... --notes-file ... dist/*`.
6. `--dry-run` does everything except tag/push/release creation.
7. Uses ambient `gh` auth only; fails fast when unavailable; never takes
   tokens via arguments and hardcodes no credentials.

GitHub Releases only. Signing keys, `tbr-*` scripts, Play Console and
F-Droid submissions, and agreements are excluded by design.

## Reports and cleanup

Every app writes `reports/ot-<app>-<UTC timestamp>.md` (gitignored) with a
full transcript of each step. Scratch space is a `mktemp -d` dir removed by
an `EXIT` trap; `dist/` is removed after a successful real release. The
worktree-clean check fails only on *new* dirt (reports/, target/, and
`dist/` are excluded), so pre-existing uncommitted work never trips it.

## Deliberate non-goals

- **Android APK/AAB builds** need cargo-ndk + the Android SDK/NDK, which are
  not in nixpkgs. They stay primo-local (`scripts/build-android.sh`,
  `ANDROID_HOME=/opt/android-sdk`). The release app records this as SKIP.
- **No CI workflows.** Matt does not want CI; there is no
  `.github/workflows` and none will be added.
- **The `voice` feature is excluded** from all gates (default features
  only): whisper-rs 0.13.2's bindings are broken upstream. Re-add
  `--all-features` once whisper-rs ships a fixed release (see bacon.toml).
- **Slint desktop preview needs `--features slint/backend-winit`.** The
  workspace pins Slint's Android-only backend (`backend-android-activity-06`)
  for the APK; the preview binary only gets a desktop window with the winit
  backend feature enabled. The gates app builds both paths.
- **The repo's `rust-toolchain` file is bypassed inside flake apps.** It
  names an unpinned nightly, but the nix-provided `cargo` is not a rustup
  shim, so `rust-toolchain` is never consulted; nixpkgs' pinned rustc is the
  toolchain. Keep the file for rustup-based editor flows; the flake does not
  depend on it.

## Human-gated boundary (never executed by these apps)

- `scripts/sign.sh` — verifies release APK/AAB signatures (needs Matt's
  signed artifacts)
- `scripts/build-android-release.sh` — builds the release APK/AAB
  (signing needs Matt's keystore)
- Play Console submission, F-Droid submission, keystore generation

Finished state is everything done *except* those scripts, which Matt runs
himself.
