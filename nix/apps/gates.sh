# ot-gates: deterministic build / lint / test / safety / debugger gates.
#
# Mirrors the repo's bacon jobs and then some:
#   cargo build --workspace --locked
#   cargo build -p ontrack-mobile --bin ontrack-mobile-preview \
#       --features slint/backend-winit --locked  (desktop preview path;
#       the workspace pins Slint's Android-only backend, so the preview
#       needs the winit backend feature to build/run on desktop)
#   cargo clippy --workspace --all-targets --locked -- -D warnings
#   cargo fmt --all -- --check
#   cargo test --workspace --locked
# plus cargo-deny, cargo-audit, and the lldb-dap breakpoint smoke test.
# Default features only: the optional `voice` feature is broken upstream
# (whisper-rs 0.13.2); see bacon.toml and docs/FLAKE.md.
# Every step is transcribed into reports/ot-gates-<UTC timestamp>.md.
ot_check_deps cargo rustc clippy-driver cargo-fmt git python3 lldb-dap cargo-deny
ot_start_report "gates"

ot_section "Build and test gates"
ot_step "cargo build --workspace --locked" cargo build --workspace --locked
ot_step "cargo build -p ontrack-mobile --bin ontrack-mobile-preview --features slint/backend-winit --locked" \
    cargo build -p ontrack-mobile --bin ontrack-mobile-preview --features slint/backend-winit --locked
ot_step "cargo clippy --workspace --all-targets --locked -- -D warnings" \
    cargo clippy --workspace --all-targets --locked -- -D warnings
ot_step "cargo fmt --all -- --check" cargo fmt --all -- --check
ot_step "cargo test --workspace --locked" cargo test --workspace --locked

ot_safety_checks
ot_debug_smoke
ot_verify_clean

echo "report: ${OT_REPORT}"
if [ "${OT_FAILED}" -ne 0 ]; then
    echo "GATES FAILED - see ${OT_REPORT}" >&2
fi
exit "${OT_FAILED}"
