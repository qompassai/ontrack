# Patterns — ONTrack

## Publication

- Skill: `~/workspace/skills/fdroid-publish/SKILL.md` for F-Droid
  submission (eligibility → fastlane → fdroiddata → MR).
- Publication skill codification is a tracked goal
  (goal_9ad79210c27c): everything learned shipping light-show and
  ONTrack should become reusable skills.

## Repomap: read first, verify fresh

`.repomap.txt` (repo root) is the always-fresh codebase map. **Read it
before exploring the tree** — it lists the highest-signal definitions
first (ranked by cross-file references), then a complete per-file table
of contents. Cheaper than walking the tree yourself.

**Verify it's current before trusting it.** The map is a derived artifact;
it goes stale when sources change outside a `nix develop` session.

```bash
# Is the map newer than every .rs file? (empty output = fresh)
find . -name '*.rs' -newer .repomap.txt 2>/dev/null | head -5
# If stale or missing, regenerate (no flake changes needed):
nix run github:qompassai/nix?dir=repomap -- . --budget 15000 --out .repomap.txt
```

The devShell `shellHook` auto-regenerates the map on every `nix develop`
entry when an `.rs` file is newer than it. If you edited sources without
entering the shell, regenerate manually with the command above.

`.repomap.txt` is gitignored — never commit it. If it's missing, the
one-shot command recreates it.
