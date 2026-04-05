---
phase: 02-writing-engine
plan: 02
subsystem: writing-engine
tags: [skill, improve, revision, diagnosis, passes, voice-preservation, factual-integrity, run-directory, diff, metadata]

requires:
  - phase: 02-writing-engine/02-01
    provides: "14 per-pass scope rules in .claude/rules/passes/*.md covering all pass types"

provides:
  - ".claude/skills/improve/SKILL.md — complete /improve skill orchestrating diagnosis, revision planning, multi-pass execution, diff generation, explanation writing, and metadata logging"

affects:
  - 02-writing-engine/02-03
  - eval-system
  - autoloop

tech-stack:
  added: []
  patterns:
    - "SKILL.md as orchestration prompt: single file defines the full workflow Claude Code executes when user invokes /improve"
    - "Per-pass voice injection: preset voice block and voiceBehaviors injected into every pass context, not stated once globally"
    - "Revision chain vs planning chain: input.md -> pass-1.md -> pass-2.md (revision); diagnosis.md + plan.md are reference only"
    - "Timestamped run directories: runs/YYYY-MM-DD_HH-MM-SS_preset-id/ with runs/latest symlink"
    - "Preset.stages as authoritative pass sequence: SKILL.md never hardcodes pass list"

key-files:
  created:
    - ".claude/skills/improve/SKILL.md — full /improve revision engine orchestration (390 lines)"
  modified: []

key-decisions:
  - "Voice rules are injected per-pass at each individual pass execution context, not stated once at SKILL.md header level — this is the only defense against incremental voice drift across multi-pass execution"
  - "SKILL.md reads pass sequence from preset.stages at runtime — no hardcoded stage list in the skill itself"
  - "diff -u runs on input.md vs output.md (pristine original vs final output), never between intermediate pass files"
  - "explanation.md uses per-change entries with location references (paragraph N, sentence N), not summaries"
  - "Notes-to-draft detection at diagnosis step: expanded structure pass latitude when input is rough notes; voice establishment (not preservation) in that mode"

patterns-established:
  - "SKILL.md orchestration pattern: load preset → create run dir → detect input type → diagnose → plan → passes → final review → artifacts"
  - "Per-pass context injection: voice block + voiceBehaviors + scope rules + plan assignments + CLAUDE.md rules"
  - "Run directory as immutable snapshot: never overwrite, symlink latest for quick access"

requirements-completed: [WRIT-01, WRIT-02, WRIT-03, WRIT-04, WRIT-05, WRIT-06, WRIT-07, WRIT-08, WRIT-09, WRIT-10, RUNL-01, RUNL-02, RUNL-03]

duration: 3min
completed: 2026-04-05
---

# Phase 02 Plan 02: /improve SKILL.md — Core Revision Engine Summary

**390-line /improve SKILL.md orchestrating preset-driven staged revision from diagnosis through multi-pass execution, diff generation, explanation, and metadata logging — with per-pass voice injection and factual integrity contracts**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-05T23:33:13Z
- **Completed:** 2026-04-05T23:35:52Z
- **Tasks:** 2 (1 creation, 1 validation)
- **Files modified:** 1

## Accomplishments

- Created the central orchestration prompt for the /improve skill — the most complex SKILL.md in the system
- Addressed all 13 requirements (WRIT-01 through WRIT-10, RUNL-01 through RUNL-03) in a single file
- Enforced per-pass voice injection pattern (not global) to prevent voice drift across multi-pass execution
- Documented the data flow anti-pattern explicitly: revision chain reads previous pass output, not diagnosis or plan

## Task Commits

Each task was committed atomically:

1. **Task 1: Create /improve SKILL.md — full revision engine orchestration** - `f58ae03` (feat)
2. **Task 2: Validate /improve skill against all requirements** - no file changes (validation only — all 13 requirements found, no anti-patterns detected)

## Files Created/Modified

- `.claude/skills/improve/SKILL.md` — Complete /improve revision engine (390 lines): load preset with auto-inference, create timestamped run directory, detect input type, execute diagnosis and revision-plan passes, run multi-pass revision with per-pass voice/scope/plan injection, generate diff.patch, write explanation.md and metadata.json

## Decisions Made

- Voice rules are injected per-pass (at each individual pass execution context) rather than stated once globally. Research Pitfall 1 confirmed this is required: voice constraints stated once at the SKILL.md header level are forgotten as subsequent passes run in fresh context.
- Preset.stages is the single source of truth for pass sequence — SKILL.md uses `STAGES_TO_RUN` derived from `preset.stages` with no hardcoded list.
- diff computed between `input.md` (pristine original copied at run start) and `output.md` (final pass output) — never between intermediate pass files.
- explanation.md format requires location references per entry: paragraph N, sentence N, why (diagnosis finding). Summaries rejected.
- Notes-to-draft mode detected at diagnosis step using 5-signal criteria. When classified as rough notes: expanded structure pass latitude, voice establishment goal (not preservation).

## Deviations from Plan

None — plan executed exactly as written. SKILL.md met all acceptance criteria on first write. Task 2 validation found all 13 requirements addressed with no anti-patterns present.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `/improve` SKILL.md is complete. Phase 02 Plan 03 can now create the `/build` and `/adapt` SKILL.md files using this as the canonical pattern.
- The run directory structure, artifact naming conventions, and metadata.json format established here are consumed by Phase 03 (eval system) and Phase 04 (autoloop).
- No blockers.

## Self-Check

Checking created files and commits exist:

- `.claude/skills/improve/SKILL.md`: created and committed
- Commit `f58ae03`: Task 1 feat commit

## Known Stubs

None — SKILL.md is an orchestration prompt. It does not wire data to a UI and contains no hardcoded empty values or placeholder text. The pass sequence reads from `preset.stages` at runtime. All artifact paths are parameterized by `${RUN_DIR}`.

---
*Phase: 02-writing-engine*
*Completed: 2026-04-05*
