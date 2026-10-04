# ontrack - deterministic dev shell and validation apps (Nix).
#
# nix develop            # pinned Rust toolchain + bacon + lldb + deny/audit
# nix run .#gates         # build/clippy/fmt/test + safety + debugger smoke
# nix run .#publish-check # store-metadata readiness (dry run; human gates excluded)
# nix run .#debug-smoke   # standalone lldb-dap breakpoint smoke test
# nix run .#release -- v2.0.1 [--dry-run]  # GitHub release end to end
#
# Every app verifies its dependencies up front, transcribes everything into
# reports/ot-<app>-<UTC timestamp>.md (gitignored), and cleans up its
# scratch space via an EXIT trap. See docs/FLAKE.md.
#
# HUMAN-GATED BOUNDARY: release APK/AAB signing (scripts/sign.sh,
# scripts/build-android-release.sh), Play Console and F-Droid submissions,
# and keystore generation are INTENTIONALLY absent from these apps. A
# deterministic sandbox must never mint signing identities or submit
# anything to a store. Those stay Matt-only. The release app publishes
# to GitHub Releases only.
{
  description = "ontrack - deterministic dev/validation environments and script runners";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    # fenix: pinned Rust toolchains. Follows the same nixpkgs as everything
    # else; pinned in flake.lock like all other inputs.
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    repomap.url = "github:qompassai/nix?dir=repomap";
  };

  outputs = { self, nixpkgs, flake-utils, fenix, repomap }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # Pinned Rust toolchain via fenix (same pattern phlow uses).
      # nixpkgs rustc 1.95.0 CANNOT build this workspace: it dies with
      # E0463 (can't find crate for `slint_macros`) on the large
      # slint-macros dylib -- a nixpkgs rustc packaging bug, verified
      # 2026-09-30 against rustup 1.94.1 / 1.96.0 / nightly-2026-09-25,
      # which all build it fine. So the toolchain comes from fenix: pinned
      # by the flake.lock input AND the date-pinned channel manifest below.
      # The repo-root `rust-toolchain` file names an UNPINNED nightly for
      # rustup users outside nix; the flake never consults it (the fenix
      # cargo binary is not a rustup shim). Recorded in docs/FLAKE.md.
      rustToolchain = [
        (fenix.packages.${system}.fromToolchainFile {
          file = ./nix/rust-toolchain.toml;
          # Hash of the date-pinned channel manifest
          # https://static.rust-lang.org/dist/2026-09-25/channel-rust-nightly.toml
          # (immutable: the date is part of the URL). Same nightly phlow pins;
          # verified to build this full workspace on primo.
          sha256 = "sha256-3ok3kaNc8lhDSnZ9bZAJwmHgUrdB9CC5m+ZJBwFPWnA=";
        })
      ];

      # Native libs the workspace needs on Linux: ALSA (cpal), X11/XCursor/
      # XRandR/Xi (eframe/winit), libGL (eframe glow), fontconfig/freetype
      # (Slint skia renderer), xkbcommon/wayland, openssl (pinned pkg-config
      # surface, as in the pre-flake dev shell). Provided by nixpkgs and
      # wired via PKG_CONFIG_PATH/LD_LIBRARY_PATH below so builds do not
      # depend on whatever the host happens to have installed.
      nativeLibs = with pkgs; [
        alsa-lib
        fontconfig freetype
        libGL
        libxkbcommon wayland
        libX11 libXcursor libXi libXrandr
        openssl
      ];

      devTools = with pkgs; [
        # NOTE: clippy/rustfmt come from the fenix toolchain above, NOT
        # nixpkgs -- the nixpkgs pair is version-locked to nixpkgs rustc
        # and must never shadow the pinned toolchain.
        rust-analyzer bacon cargo-deny cargo-audit
        lldb # provides lldb-dap
        gcc # deterministic C/C++ toolchain (slint-build needs a C++ compiler)
        # clang: the Rust linker MUST be the nix clang, never the ambient
        # /usr/bin/clang from ~/.cargo/config.toml. The fenix rustc runs on
        # the nix glibc; artifacts linked against the host glibc fail dlopen
        # inside rustc with the misleading error[E0463] "can't find crate"
        # (seen on slint-macros). Wired via
        # CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER below.
        clang
        pkg-config
        cacert # TLS roots for cargo registry access
      ];

      baseInputs = rustToolchain ++ devTools ++ nativeLibs ++ [
        pkgs.python3 pkgs.git pkgs.coreutils pkgs.gnugrep pkgs.findutils
      ];

      commonLib = builtins.readFile ./nix/lib/common.sh;

      # Build one flake app: shared lib + deterministic native env + body.
      # writeShellApplication also runs shellcheck over the result.
      # SC2329 ("function never invoked") is excluded: common.sh is a
      # shared library and each app only calls a subset of its functions.
      mkApp = name: file: extraInputs: pkgs.writeShellApplication {
        inherit name;
        excludeShellChecks = [ "SC2329" ];
        runtimeInputs = baseInputs ++ extraInputs;
        text = ''
          # Deterministic native environment (eframe/Slint audio/windowing).
          export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" nativeLibs}''${PKG_CONFIG_PATH:-}"
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath nativeLibs}''${LD_LIBRARY_PATH:-}"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          # Link with the nix clang (see the clang NOTE in devTools): the
          # ambient ~/.cargo/config.toml points at /usr/bin/clang, which
          # links the host glibc -- unloadable by the nix-glibc rustc.
          export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="${pkgs.clang}/bin/clang"
        '' + commonLib + "\n" + builtins.readFile file;
      };

      releaseInputs = with pkgs; [ git-cliff gh gnutar gzip ];
    in {
      devShells.default = pkgs.mkShell {
        name = "ontrack-dev";
        packages = baseInputs
        # repomap: always-fresh codebase map for coding agents.
        ++ [ repomap.packages.${system}.repomap ];
        # Android SDK/NDK and cargo-ndk are NOT in nixpkgs: APK/AAB builds
        # stay a primo-local step (ANDROID_HOME=/opt/android-sdk).
        # Documented in docs/FLAKE.md; not faked here.
        shellHook = ''
          export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" nativeLibs}''${PKG_CONFIG_PATH:-}"
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath nativeLibs}''${LD_LIBRARY_PATH:-}"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          # Link with the nix clang (see the clang NOTE in devTools).
          export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="${pkgs.clang}/bin/clang"
          echo "ontrack dev shell: $(rustc --version)"
          echo "APK/AAB builds need the Android SDK/NDK + cargo-ndk (not in nixpkgs); see docs/FLAKE.md."
        '' + repomap.lib.refreshHook {
          pkg = repomap.packages.${system}.repomap;
        };
      };

      apps = {
        gates = {
          type = "app";
          program = "${mkApp "ot-gates" ./nix/apps/gates.sh [ ]}/bin/ot-gates";
        };
        publish-check = {
          type = "app";
          program = "${mkApp "ot-publish-check" ./nix/apps/publish-check.sh [ ]}/bin/ot-publish-check";
        };
        debug-smoke = {
          type = "app";
          program = "${mkApp "ot-debug-smoke" ./nix/apps/debug-smoke.sh [ ]}/bin/ot-debug-smoke";
        };
        release = {
          type = "app";
          program = "${mkApp "ot-release" ./nix/apps/release.sh releaseInputs}/bin/ot-release";
        };
      };
    });
}
