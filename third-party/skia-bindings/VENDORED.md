# Vendored: skia-bindings 0.90.0 (patched)

This directory is a vendored copy of the crates.io release
`skia-bindings 0.90.0` (rust-skia), wired in through the
`[patch.crates-io]` table in the workspace `Cargo.toml`. It is
byte-identical to the published crate except for the four edits
listed below. The `skia/` source tree is not vendored: the build
downloads it on first use, exactly as the published crate does
(`.cargo_vcs_info.json` is preserved so the prebuilt-binary cache
keys are unchanged — the aarch64 Android build still downloads its
official prebuilt binaries).

## Why the patch exists

rust-skia publishes **no prebuilt binaries for `armv7-linux-androideabi`**
(verified against the `rust-skia/skia-binaries` release asset lists for
0.90.0, 0.99.0, and 0.153.3 — Android assets exist only for aarch64,
i686, and x86_64). The armv7 build therefore always compiles Skia from
source. In that source build, skia-bindings passes clang the
**unversioned** target triple `armv7-linux-androideabi`. Since NDK r29,
the NDK headers reject unversioned Android triples:

```c
// sys/cdefs.h (NDK r30 sysroot)
#if !defined(__ANDROID_MIN_SDK_VERSION__)
#error Unversioned target triples are not supported!
#endif
```

`__ANDROID_MIN_SDK_VERSION__` is predefined by clang only for
versioned triples such as `armv7-linux-androideabi26`. With NDK
28.0.12674087 the header check did not exist and the build worked;
with NDK 30.0.16248370 the GN compile, the bindings shim compile, and
the bindgen header parse all fail. No upstream release fixes this
(the `--target` construction is identical in 0.91.0, 0.93.1, and
0.153.3), and a skia-safe bump is not available anyway: slint's
`i-slint-renderer-skia` pins the skia-safe version per slint release.

## The patch (4 edits, build-time only)

All four route clang `--target` strings through a new
`Target::clang_target()`, which appends the crate's own Android API
level (26, the same value passed to GN as `ndk_api`) to Android
target triples and leaves every other target unchanged. Runtime
code is untouched.

1. `build_support/cargo.rs` — add `Target::clang_target()`.
2. `build_support/platform/android.rs` — `API_LEVEL` becomes
   `pub(crate)`; `bindgen_args` passes `target.clang_target()` to
   `additional_clang_args` (covers both the bindgen parse and the
   bindings shim compile).
3. `build_support/platform.rs` — `GnArgsBuilder::new` stores
   `target.clang_target()` (covers the GN `extra_cflags` /
   `extra_asmflags`).
4. `build_support/skia_bindgen.rs` — the explicit bindgen
   `--target` uses `target.clang_target()`.

## Removal condition

Drop this vendoring (and the `[patch.crates-io]` entry) when an
upstream skia-bindings release both (a) emits versioned Android
target triples in its source build and (b) is admitted by the
skia-safe requirement of the slint version this workspace uses.
Re-check by building `armv7-linux-androideabi` against the current
NDK with the patch removed.
