# Architectural Decisions — ONTrack

## Stack split (2026-09-30)

**Decision**: Desktop = egui, mobile = Slint.

**Context**: Publication targets are Play Store + F-Droid (mobile) plus
desktop.

## Human-gated scripts (2026-09-29)

**Decision**: tbr-* scripts are human-gated. Workers must not run them
or generate signing keys.

**Consequence**: Publication automation stops at the signing boundary.
Matt runs tbr-* himself.
