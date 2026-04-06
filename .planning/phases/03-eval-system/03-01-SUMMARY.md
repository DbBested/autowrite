---
phase: 03-eval-system
plan: 01
subsystem: eval
tags: [eval, critic, subagent, rubric, json, scoring]

requires:
  - phase: 01-foundation-and-presets
    provides: preset JSON files with rubric.criteria arrays that the eval critic reads
  - phase: 02-writing-engine
    provides: run directory structure (runs/<run>/) where eval.json is co-located with revision artifacts

provides:
  - eval-critic.md adversarial subagent with anchored rubric scoring for 7 criteria
  - /eval skill with preset loading, critic dispatch, and eval.json snapshot writing
  - Isolated eval pipeline: critic receives only text and rubric, no revision history
  - Machine-readable eval snapshot schema (eval.json) ready for Phase 4 autoloop consumption

affects:
  - 04-autoloop (eval system is the scoring infrastructure for mutation acceptance decisions)

tech-stack:
  added: []
  patterns:
    - "context:fork + agent: frontmatter for isolated critic subagent dispatch"
    - "Anchored scoring rubric: 4 score levels (9-10, 6-8, 3-5, 1-2) with observable behavioral descriptions per criterion"
    - "Two-input isolation: critic receives only text + rubric criteria, never revision artifacts"
    - "Pass threshold hardcoded in skill (>= 6), not read from preset.passing_threshold legacy field"

key-files:
  created:
    - .claude/agents/eval-critic.md
    - .claude/skills/eval/SKILL.md

key-decisions:
  - "Pass threshold hardcoded at score >= 6 (not read from preset.passing_threshold which holds legacy 1-5 value of 3.5)"
  - "Critic allowed-tools restricted to Read only — SKILL.md writes eval.json after receiving critic's JSON output"
  - "Critic receives ONLY text + rubric — no diagnosis.md, plan.md, explanation.md injected (prevents self-preference bias)"
  - "Standalone eval writes to evals/<timestamp>_<preset>_<slug>.json; run-directory eval writes to runs/<run>/eval.json"
  - "Aggregate pass requires ALL criteria pass AND weighted average >= 6; critical criteria (factual_integrity, voice_preservation) force aggregate_pass: false if < 6"

patterns-established:
  - "Adversarial critic pattern: explicit prohibitions on suggestions, fixes, praise — find flaws only"
  - "Anchored scoring: observable behavioral descriptions per score band reduce eval variance across runs"
  - "Generic scoring contract: agent scores 'each criterion provided in the rubric' — supports custom presets without agent changes"
  - "Location requirement: every failure_point must name Paragraph N, sentence N — vague locations are invalid"

requirements-completed: [EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, EVAL-06]

duration: 72min
completed: 2026-04-06
---

# Phase 03 Plan 01: Eval System Summary

**Adversarial eval critic subagent with anchored 7-criterion rubric and preset-driven /eval skill producing isolated, located, machine-readable eval.json snapshots**

## Performance

- **Duration:** 72 min
- **Started:** 2026-04-06T00:05:31Z
- **Completed:** 2026-04-06T01:18:25Z
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- Built `.claude/agents/eval-critic.md` — adversarial subagent with anchored scoring rubric for all 7 core criteria (novelty, clarity, structure, voice_preservation, audience_fit, concision, factual_integrity), 4 score levels each with observable behavioral descriptions, JSON output contract, location requirement, fabrication prohibition, and critical criteria rule
- Built `.claude/skills/eval/SKILL.md` — complete `/eval` invocation flow: argument parsing, preset loading with auto-detect fallback from latest run, word count edge case warnings, output path routing (run-directory vs standalone), two-input critic isolation, pass threshold enforcement, eval.json writing, and user summary display
- Established the scoring infrastructure Phase 4 autoloop depends on: stable machine-readable eval.json schema, consistent anchored scores, and per-criterion failure points located to specific paragraph and sentence numbers

## Task Commits

Each task was committed atomically:

1. **Task 1: Create eval-critic.md adversarial subagent** — `80f9201` (feat)
2. **Task 2: Create /eval SKILL.md invocation and dispatch** — `2d2e0ff` (feat)

## Files Created/Modified

- `.claude/agents/eval-critic.md` — Adversarial critic subagent: identity, output contract, location requirement, fabrication prohibition, anchored scoring for 7 criteria, scope constraint
- `.claude/skills/eval/SKILL.md` — /eval skill: invocation syntax, argument parsing, preset loading, critic dispatch via context:fork, eval.json writing, user summary

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

Files exist check:
- `.claude/agents/eval-critic.md` — created
- `.claude/skills/eval/SKILL.md` — created

Commit existence check:
- `80f9201` — feat(03-01): create eval-critic.md adversarial subagent
- `2d2e0ff` — feat(03-01): create /eval SKILL.md — preset-driven eval dispatch
