---
phase: 04-autoloop-and-preset-creation
plan: 02
subsystem: autoloop
tags: [autoloop, mutation-eval, self-improvement, preset-tuning, goodharts-law]
dependency_graph:
  requires:
    - .claude/skills/eval/SKILL.md
    - .claude/skills/improve/SKILL.md
    - scripts/validate-preset.sh
    - presets/preset-schema.json
  provides:
    - .claude/skills/autoloop/SKILL.md
    - autoloop/holdout/ directory
    - autoloop/reference-drafts/ directory
  affects:
    - presets/*.json (mutation targets)
    - autoloop/runs/ (run logs)
    - autoloop/accepted/ (accepted patches)
tech_stack:
  added: []
  patterns:
    - Weakest-criterion-first mutation selection with round-robin fallback
    - JSONL append-only mutation log (never read-parse-rewrite)
    - Backup-first/restore-on-reject for atomic reversibility
    - Holdout divergence check every 3 iterations for Goodhart's Law protection
key_files:
  created:
    - .claude/skills/autoloop/SKILL.md
    - autoloop/holdout/.gitkeep
    - autoloop/reference-drafts/.gitkeep
  modified: []
decisions:
  - Required --reference-draft flag (fail loudly if missing) — prevents eval on arbitrary text, which would destroy score comparability
  - Restricted --target to presets/*.json only — prevents mutation of core skills or CLAUDE.md (RESEARCH.md Pitfall 4)
  - Empty holdout warning with confirmation gate — not a silent skip; user must explicitly confirm Goodhart's Law risk
  - Backup updated after each accepted mutation — restore point tracks last accepted state, not initial state
metrics:
  duration: "3 minutes"
  completed: "2026-04-06T02:04:07Z"
  tasks_completed: 2
  files_created: 3
---

# Phase 04 Plan 02: /autoloop Skill Summary

Implemented the mutation-eval self-improvement cycle skill as `.claude/skills/autoloop/SKILL.md` and created the missing `autoloop/holdout/` and `autoloop/reference-drafts/` directories.

## One-liner

Mutation-eval self-improvement loop that accepts preset changes only when aggregate score improves with no critical regressions, guarded by a holdout divergence check against Goodhart's Law overfitting.

## What Was Built

### Task 1: /autoloop SKILL.md (499 lines)

The skill implements the full mutation-eval cycle in 5 steps:

1. **Argument parsing and validation** — validates `--target` is in `presets/`, `--iterations` is 1-20, `--reference-draft` file exists, and holdout directory has content (warns and pauses if empty)
2. **Run directory creation** — timestamped `autoloop/runs/<timestamp>/` with `backup/`, `reference-outputs/`, and `evals/` subdirectories; immediate backup of target preset
3. **Baseline eval** — runs `/improve` on the reference draft with the unmutated preset, then `/eval` on the output; records all per-criterion scores and aggregate
4. **Iteration loop** — for each iteration:
   - 4a: Weakest-criterion-first mutation selection with criterion-to-field mapping table; round-robin after 2 consecutive same-criterion targets
   - 4b: Apply mutation to one field, bump patch version, run `validate-preset.sh` (restore + log if fails)
   - 4c: Run `/improve` + `/eval` on reference draft with mutated preset
   - 4d: 4-condition acceptance decision; ACCEPT if all pass, REJECT + restore if any fail
   - 4e: Append one JSONL line to `mutations.jsonl` (append-only, never read-parse-rewrite)
   - 4f: Holdout check every 3 iterations — halt and restore if holdout-vs-loop delta > 1.0
5. **Completion summary** — score trajectory, per-iteration accepted/rejected breakdown, tuning advice if all rejected

### Task 2: Directory Setup

Created two directories identified as missing in RESEARCH.md Environment Availability:
- `autoloop/holdout/` — user places 1-3 holdout texts here before running the loop
- `autoloop/reference-drafts/` — recommended location for fixed reference drafts

## Requirements Addressed

| ID | Requirement | Status |
|----|-------------|--------|
| LOOP-01 | Pick one asset to mutate per cycle | Complete — weakest-criterion-first field selection |
| LOOP-02 | Baseline eval before mutation | Complete — Step 3 runs /improve + /eval before any mutation |
| LOOP-03 | Apply mutation and rerun eval | Complete — Step 4b-4c implements mutation + post-eval |
| LOOP-04 | Accept only with aggregate improvement and no critical regressions | Complete — 4-condition acceptance rule in Step 4d |
| LOOP-05 | JSONL log of all mutation attempts with before/after scores | Complete — append-only mutations.jsonl in Step 4e |
| LOOP-06 | Holdout divergence check to prevent overfitting | Complete — Step 4f, every 3 iterations, 1.0 point threshold |

## Decisions Made

**Explicit `--reference-draft` flag required:** The RESEARCH.md open question was resolved by requiring an explicit `--reference-draft @file.md` argument rather than auto-discovering from `autoloop/reference-drafts/`. Fail loudly if not provided. This prevents the most destructive pitfall (Pitfall 1): running eval on arbitrary text where score changes reflect input variance, not the preset mutation's effect.

**Target restriction to `presets/*.json` only:** LOOP-01 lists "skill instructions" as a mutable asset, but RESEARCH.md Pitfall 4 identifies mutating core skills as a safety risk. The SKILL.md restricts `--target` to `presets/` directory only. Skill instruction mutation is deferred to a future version.

**Backup updated after each accepted mutation:** The restore point tracks the last accepted state, not the initial pre-loop state. This means rejected mutations restore to the last known-good state rather than losing all prior iterations' accepted improvements.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan creates a SKILL.md (instructional document) and directories. No data-returning components, no UI, no stubs.

## Self-Check: PASSED

- `.claude/skills/autoloop/SKILL.md` exists: FOUND
- `autoloop/holdout/.gitkeep` exists: FOUND
- `autoloop/reference-drafts/.gitkeep` exists: FOUND
- Commit `6503304` (feat(04-02): create /autoloop SKILL.md): FOUND
- Commit `f168e76` (chore(04-02): create autoloop directories): FOUND
