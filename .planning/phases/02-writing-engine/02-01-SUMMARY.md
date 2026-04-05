---
phase: 02-writing-engine
plan: 01
subsystem: writing-engine
tags: [passes, scope-isolation, voice-preservation, factual-integrity, rules-files]

# Dependency graph
requires:
  - phase: 01-foundation-and-presets
    provides: "Preset schema with stages arrays, voice/voiceBehaviors fields, and rubric criteria that pass rules reference"
provides:
  - "14 per-pass scope constraint rules files in .claude/rules/passes/ — one per pass type across all three presets"
  - "diagnose.md: read-only analysis with input classification (rough notes vs polished draft)"
  - "revision-plan.md: planning-only pass producing plan.md with diagnosis-referenced changes"
  - "structure.md through final-review.md: full scope/exclusion/voice/factual-integrity constraints for every revision pass"
affects:
  - 02-writing-engine (plans 02-03 — SKILL.md files load these rules explicitly per pass)
  - 03-eval-system (eval agent reads pass rules to understand scope boundaries)
  - 04-autoloop (mutation system must not mutate pass rules without eval before/after)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-pass scope constraint file pattern: 4-section structure (Scope, DO NOT Touch, Voice Preservation, Factual Integrity)"
    - "Pass rules loaded explicitly by SKILL.md at pass execution time, not via paths: frontmatter auto-activation"
    - "Voice preservation is per-pass, not global: preset voice block and voiceBehaviors injected at every pass"

key-files:
  created:
    - .claude/rules/passes/diagnose.md
    - .claude/rules/passes/revision-plan.md
    - .claude/rules/passes/structure.md
    - .claude/rules/passes/clarity.md
    - .claude/rules/passes/argument.md
    - .claude/rules/passes/tone.md
    - .claude/rules/passes/concision.md
    - .claude/rules/passes/hook.md
    - .claude/rules/passes/ending.md
    - .claude/rules/passes/evidence.md
    - .claude/rules/passes/objection.md
    - .claude/rules/passes/precision.md
    - .claude/rules/passes/examples.md
    - .claude/rules/passes/final-review.md
  modified: []

key-decisions:
  - "4-section structure enforced for every pass rules file: Scope, DO NOT Touch, Voice Preservation, Factual Integrity — prevents scope creep and voice drift cross-pass"
  - "Analysis passes (diagnose, revision-plan) explicitly read-only: they produce artifacts (diagnosis.md, plan.md) but must not modify the draft"
  - "final-review is fully READ-ONLY: produces explanation.md, output.md, diff.patch, metadata.json — no draft modifications ever"
  - "evidence.md carries CRITICAL fabrication warning as the highest-risk pass for invented content"

patterns-established:
  - "Pattern: Per-pass scope constraint file — every pass has a named .md file defining what it MAY and MUST NOT change"
  - "Pattern: Voice preservation is per-pass — read preset voice block and voiceBehaviors at every individual pass, not just globally"
  - "Pattern: Analysis-before-revision separation — diagnose and revision-plan must not touch the draft; revision passes follow the plan"
  - "Pattern: Flag-not-fill — when a gap requires author input (evidence, counterarguments, examples), flag it rather than fabricating content"

requirements-completed: [WRIT-04, WRIT-05, WRIT-06]

# Metrics
duration: 3min
completed: 2026-04-05
---

# Phase 2 Plan 01: Per-Pass Scope Constraint Rules Summary

**14 per-pass scope constraint rules files covering every pass type across all three presets, with explicit DO NOT touch boundaries, voice preservation instructions, and factual integrity constraints in every file**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-05T23:27:01Z
- **Completed:** 2026-04-05T23:30:00Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Created 14 markdown rules files in `.claude/rules/passes/` — one per pass type referenced in any preset's `stages` array
- Every file enforces the 4-section structure: Scope, DO NOT Touch, Voice Preservation, Factual Integrity
- Analysis passes (diagnose, revision-plan) explicitly marked read-only with artifact-only outputs
- final-review pass explicitly READ-ONLY with defined output artifacts (explanation.md, output.md, diff.patch, metadata.json)
- Evidence pass carries CRITICAL fabrication warning as the highest-risk pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Analysis and universal revision pass rules (7 files)** - `5014e11` (feat)
2. **Task 2: Form-specific and final-review pass rules (7 files)** - `177a5a3` (feat)

## Files Created/Modified

- `.claude/rules/passes/diagnose.md` — Read-only analysis with input classification criteria (rough notes vs polished draft detection)
- `.claude/rules/passes/revision-plan.md` — Planning-only pass; produces plan.md referencing specific diagnosis findings
- `.claude/rules/passes/structure.md` — Section/paragraph reorganization; must not edit individual sentence wording
- `.claude/rules/passes/clarity.md` — Sentence-level rewrites only; must not restructure paragraphs or sections
- `.claude/rules/passes/argument.md` — Claim precision and claim-evidence tightening; NEVER add new evidence
- `.claude/rules/passes/tone.md` — Register consistency driven by preset voiceBehaviors; most voice-critical pass
- `.claude/rules/passes/concision.md` — Cuts only; must not reorder; preserves intentional repetition and factual qualifiers
- `.claude/rules/passes/hook.md` — Opening paragraph(s) only; must not touch body content
- `.claude/rules/passes/ending.md` — Closing paragraph(s) only; must not touch body content
- `.claude/rules/passes/evidence.md` — CRITICAL: only reorganize existing evidence, NEVER add or alter evidence
- `.claude/rules/passes/objection.md` — Counterargument handling; do not invent counterarguments, flag missing ones
- `.claude/rules/passes/precision.md` — Technical accuracy only; must not restructure; do not infer missing specs
- `.claude/rules/passes/examples.md` — Improve existing examples only; do not invent new examples
- `.claude/rules/passes/final-review.md` — READ-ONLY; produces explanation.md, output.md, diff.patch, metadata.json

## Decisions Made

- 4-section structure enforced for every file (Scope, DO NOT Touch, Voice Preservation, Factual Integrity) — uniform structure prevents uneven enforcement across passes
- Analysis passes made explicitly read-only with artifact names stated — removes ambiguity about what these passes produce vs modify
- evidence.md given strongest fabrication warning language because it is the highest-risk pass for invented citations
- final-review.md specifies the exact explanation.md entry format to prevent "improved structure" summary-level entries

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All 14 pass rules files are in place; SKILL.md files in Phase 2 plans 02-03 can load them explicitly by file path at pass execution time
- Pass scope isolation is complete: every pass type that appears in any preset's `stages` array has a corresponding scope constraint file
- Voice preservation and factual integrity constraints are consistent across all 14 files

## Known Stubs

None — all files are complete scope constraint definitions. No placeholder content.

## Self-Check: PASSED

- All 14 pass rules files verified present on disk
- Both task commits verified in git log (5014e11, 177a5a3)

---
*Phase: 02-writing-engine*
*Completed: 2026-04-05*
