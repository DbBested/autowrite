---
phase: 02-writing-engine
plan: 03
subsystem: writing-engine
tags: [skills, build, adapt, notes-to-draft, form-adaptation, improve-engine]
dependency_graph:
  requires: [02-01, 02-02]
  provides: [build-skill, adapt-skill]
  affects: [writing-engine]
tech_stack:
  added: []
  patterns: [thin-wrapper-skill, improve-engine-delegation, target-preset-loading]
key_files:
  created:
    - .claude/skills/build/SKILL.md
    - .claude/skills/adapt/SKILL.md
  modified: []
decisions:
  - "/build forces notes-to-draft classification — input_type is always 'rough notes', structure pass gets expanded latitude"
  - "/adapt requires --to flag (no auto-inference) — loads target preset for all passes, not source form preset"
  - "Voice handling differentiated: /build=ESTABLISHMENT, /adapt=ADAPTATION, /improve=PRESERVATION"
  - "/adapt diagnosis includes Form Gaps section — identifies what draft is missing for the target form"
  - "/adapt depth defaults to deep (not standard) — form adaptation is more substantial than in-form revision"
metrics:
  duration_minutes: 2
  completed_date: "2026-04-05"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 02 Plan 03: /build and /adapt Variant Skills Summary

Two thin-wrapper SKILL.md files that delegate to the /improve engine with mode-specific overrides: /build forces notes-to-draft classification with expanded pass latitude, /adapt requires a --to target preset and adds form gap diagnosis with voice adaptation mode.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create /build SKILL.md — notes-to-draft workflow | 8e05de1 | .claude/skills/build/SKILL.md |
| 2 | Create /adapt SKILL.md — form adaptation workflow | 3c13186 | .claude/skills/adapt/SKILL.md |

## What Was Built

### /build Skill

`.claude/skills/build/SKILL.md` wraps the /improve engine for notes-to-draft use cases. Key behaviors:

- Input classification is force-set to "rough notes" — the diagnosis step skips auto-detection
- Structure pass gets broader latitude: may create new sections, reorganize, and expand undeveloped points
- Argument pass may expand notes-level points (within factual integrity rules)
- Voice behavior is ESTABLISHMENT — notes may lack a consistent voice; do not anchor to an incoherent register
- Depth defaults to standard (notes benefit from all passes)
- Follows /improve workflow exactly (7 steps) with one override in Step 4

### /adapt Skill

`.claude/skills/adapt/SKILL.md` wraps the /improve engine for form adaptation use cases. Key behaviors:

- `--to` flag is REQUIRED — specifies target preset ID, no auto-inference
- Loads target preset for all passes (not source form preset)
- Diagnosis includes Form Gaps section identifying what the draft is missing for the target form
- Voice behavior is ADAPTATION — preserve author's core voice patterns, shift register to match target form
- Depth defaults to deep (form adaptation is a substantial transformation)
- metadata.json records `input_type: "adaptation"` and `adapted_from` field
- Follows /improve workflow with five targeted overrides

## Voice Handling Summary

| Skill | Voice Mode | Rationale |
|-------|-----------|-----------|
| /improve | PRESERVATION | Draft has an established voice; preserve it |
| /build | ESTABLISHMENT | Notes may lack coherent voice; target form's voice is the anchor |
| /adapt | ADAPTATION | Preserve author's core patterns; shift register to target form |

## Deviations from Plan

None — plan executed exactly as written. Both SKILL.md files follow the content structure specified in the plan tasks, include all required acceptance criteria, and delegate to /improve without duplicating the pass execution loop.

## Known Stubs

None. Both SKILL.md files are complete workflow specifications. No data sources, no stubs, no placeholder content.

## Self-Check: PASSED

Files exist:
- FOUND: .claude/skills/build/SKILL.md
- FOUND: .claude/skills/adapt/SKILL.md

Commits exist:
- FOUND: 8e05de1 (feat(02-03): create /build SKILL.md)
- FOUND: 3c13186 (feat(02-03): create /adapt SKILL.md)
