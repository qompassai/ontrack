---
name: rust-development
description: "Rust development wired to Matt's Neovim toolchain: rust-analyzer, bacon/bacon-ls background checks, lldb-dap debugging, cargo-bsp builds, cargo-deny policy, Tiger Style Rust. Use when writing, reviewing, debugging, or testing Rust code."
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite, WebFetch, WebSearch
metadata:
  adapted-from: laurigates/claude-plugins rust-plugin/skills/rust-development/SKILL.md
  user-invocable: "false"
---

# rust-development

## Rust Development (Matt's toolchain)

Expert Rust development that assumes the diver Neovim setup: rust-analyzer for
IDE services, **bacon-ls** for continuous background checks, **lldb-dap** for
debugging, **cargo-bsp** for build-server builds, **cargo-deny** for
license/advisory policy. Style authority is the `tiger-style-rust` skill —
this skill covers workflow and tooling, not style rules.

## When to Use This Skill

| Use this skill when... | Use a sibling skill instead when... |
| --- | --- |
| Writing, reviewing, debugging, or testing Rust code | Enforcing style/contracts in detail — use `tiger-style-rust` |
| Choosing crates (Tokio, Serde), designing modules/traits | Detecting unused dependencies — use `cargo-machete` |
| Running the bacon/clippy/test feedback loop | Parallel test isolation — use `cargo-nextest` |
| Debugging with lldb-dap or building via BSP | Coverage reports — use `cargo-llvm-cov` |

## Activation

- **Resources**: `bacon.toml` (jobs incl. `bacon-ls`), `deny.toml`, `.bsp/*.json`,
  rust-analyzer settings, lldb-dap adapter config.
- **Per-session dedup**: load once per session; re-read only if the repo's
  `bacon.toml`/`deny.toml` changed mid-session.
- **Subagent delegation**: Rust work fans out well — one subagent per crate or
  per workstream (build, test, debug). See "Structured subagent use" below.

## The toolchain (how Matt's setup actually works)

**rust-analyzer** (`rustana_ls`): assists, completions, diagnostics-as-you-type.
`checkOnSave` is **off** — on-save/on-change checking is bacon-ls's job, not
rust-analyzer's. Cargo integration has `allTargets` and `autoreload` on.

**bacon + bacon-ls**: bacon-ls runs `bacon --headless -j bacon-ls` in the
background, updating on change and on save (1s debounce), syncing open files
every 2s, writing diagnostics to `.bacon-locations`. The repo's `bacon.toml`
must define the `bacon-ls` job plus `check`, `clippy`, and `test` jobs.
Preferred loop: `bacon clippy` (or `bacon test`) in a terminal — do not run
bare `cargo check` repeatedly when bacon is available.

**DAP**: `lldb-dap` is the debug adapter. Use it for real debugging sessions
(breakpoints, stepping, locals) — not `println!` archaeology.

**BSP**: `.bsp/*.json` connection cards (cargo-bsp) let the editor drive builds
through the Build Server Protocol instead of shelling out to cargo. Rebuild
queries go through BSP where configured.

**cargo-deny** (`deny.toml`): licenses, advisories, bans, sources. Run
`cargo deny check` before pushing anything with new dependencies.

**Format/lint**: `cargo fmt` (rustfmt) and `cargo clippy --all-targets`
with `-D warnings` — zero warnings is the gate.

## Essential Commands

```
# Continuous feedback (preferred over one-shot cargo invocations)
bacon clippy            # watch + clippy on change
bacon test              # watch + tests on change
bacon --list-jobs       # what this repo's bacon.toml defines

# One-shot equivalents
cargo check --all-targets
cargo clippy --all-targets -- -D warnings
cargo fmt --check
cargo test
cargo test --doc

# Policy and supply chain
cargo deny check        # licenses + advisories + bans (deny.toml)
cargo audit             # advisory DB only
cargo machete           # unused dependencies

# Debugging
# via DAP (lldb-dap): breakpoints, stepping, locals — preferred
cargo expand            # macro expansion when types don't make sense
RUST_BACKTRACE=1 cargo test failing_test  # full backtraces

# Docs and deps
cargo doc --open
cargo add serde --features derive
cargo update -p <crate> # targeted updates, not blanket `cargo update`
```

## Working agreements

1. **Contracts first**: every public function gets documented preconditions /
   error behavior (tiger-style-rust owns the exact form).
2. **No new dependencies without `cargo deny check`** passing on the result.
3. **Zero clippy warnings** on `--all-targets`; fix, don't `#[allow]`, unless
   the allow carries a comment explaining why.
4. **Tests are half validation, half adversarial** — especially `unsafe` code,
   which also gets a Miri pass (`cargo miri test`) when feasible.
5. **Reproduce before fixing**: a failing test or DAP session that shows the
   bug comes before the patch.
6. Report exactly what ran: build / clippy / fmt / test counts, what was
   skipped, what failed. Never claim a gate passed without running it.

## Structured subagent use

When delegating Rust work, wrap each subagent brief in this structure:

```
objective: <one sentence, verifiable>
scope: <files/crates it may touch; everything else is read-only>
toolchain: <bacon job / cargo cmd / DAP as appropriate>
gates: <exact commands that must pass, e.g. cargo clippy --all-targets -- -D warnings>
report: <files changed, test counts, failures, skips — deltas, not transcripts>
stop: <when to stop and ask instead of pushing through>
```

One subagent per crate or per workstream. Subagents inherit the transcript —
point at paths, never paste file contents. Bounded, disjoint file ownership;
no two agents edit the same file.
