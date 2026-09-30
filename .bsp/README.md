# `.bsp/` — Build Server Protocol connection cards

`cargo.json` is the BSP connection card Matt's Neovim BSP client
(`lua/bsp/servers/cargo.lua` in the diver config) reads: `name`, `argv`,
`bspVersion`, `languages`.

**Status: inert by default.** `cargo-bsp` is unmaintained upstream (last push
2023-10-12) and is not installed on this machine, so `argv: ["cargo-bsp"]`
does not resolve to an executable today. The card is kept so the intent is
recorded and any future maintained Rust BSP server can drop in.

**Fallback (what to actually run):** plain cargo —

```
cargo check --workspace --all-targets
cargo build --workspace
```

or the bacon jobs in `bacon.toml` (`bacon check`), which is the preferred
continuous loop.
