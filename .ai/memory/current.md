# Current Work — ONTrack

TDS Telecom field route optimizer (NOT a medication tracker).
Desktop = egui, mobile = Slint.

## Active (2026-10-04)

- **Publication program**: Complete 2026-09-30. Targets: Play Store, F-Droid.
- **Two REAL UI bugs** in TODO.md before release:
  1. Giant gray rectangle on add-stop row.
  2. Home/Results/Settings tabs ignore touch.
- **Remaining** (Matt-only): tbr-* scripts, dotfiles commit/push once WIP
  resolved, the two UI bugs, real-device validation.

## Standing rules

- HARD BOUNDARY: workers must NOT run human-gated tbr-* scripts or
  generate signing keys.
- Goal: `goal_71668710736b` (ONTrack Play Store and F-Droid publication).
