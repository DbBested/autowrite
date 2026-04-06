# Roadmap: Autowrite

## Overview

Autowrite is built in four phases that follow a strict dependency order: the preset schema (the shared definition of "good") must exist before the writing engine can run passes; the writing engine must produce stable outputs before the eval critic can be calibrated; the eval critic must produce reliable signals before the self-improvement loop can make meaningful mutation decisions. Each phase delivers a coherent, independently verifiable capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation and Presets** - Repo structure, universal safety rules, and three hand-tuned preset JSON files with validated schema
- [x] **Phase 2: Writing Engine** - Staged revision workflow from user-submitted draft to revised output with diffs, explanations, and run logs (completed 2026-04-05)
- [ ] **Phase 3: Eval System** - Isolated critic subagent producing criterion-level scores and stable eval snapshot JSON
- [x] **Phase 4: Autoloop and Preset Creation** - Mutation-eval self-improvement cycle and user-facing preset creation skill (completed 2026-04-06)

## Phase Details

### Phase 1: Foundation and Presets
**Goal**: The repo structure, universal behavioral rules, and all three hand-tuned presets exist as the stable shared foundation that every other component reads from
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, PRES-01, PRES-02, PRES-03, PRES-04, PRES-05
**Success Criteria** (what must be TRUE):
  1. Running the preset validation script against each of the three preset files produces zero errors
  2. CLAUDE.md contains universal safety rules (no fabricated citations, voice preservation default, no silent stance shifts) and stays under 300 lines
  3. All required repo directories exist and a new revision run can write artifacts to the correct locations without path errors
  4. Each preset file contains all schema-required fields: form, goals, stages, voice rules, structure expectations, rubric criteria, constraints, and transformation defaults
**Plans:** 2 plans

Plans:
- [x] 01-01-PLAN.md — Repo scaffold, CLAUDE.md safety rules, preset-editing rules, JSON Schema, validation script
- [x] 01-02-PLAN.md — Three hand-tuned presets (blog post, argumentative essay, technical explainer)

### Phase 2: Writing Engine
**Goal**: A user can submit a draft or notes file, select a preset, and receive a revised output with diagnosis, revision plan, per-pass outputs, a unified diff, per-change explanations, and a complete run log
**Depends on**: Phase 1
**Requirements**: WRIT-01, WRIT-02, WRIT-03, WRIT-04, WRIT-05, WRIT-06, WRIT-07, WRIT-08, WRIT-09, WRIT-10, WRIT-11, RUNL-01, RUNL-02, RUNL-03
**Success Criteria** (what must be TRUE):
  1. User can invoke the /improve skill on a draft file and receive a final revised draft without intervening errors
  2. A diagnosis document naming specific weaknesses (not generic advice) appears in the run directory before any rewriting begins
  3. A unified diff file is generated programmatically comparing the input draft to the final output
  4. Each revision pass writes only within its defined scope — running a diff after a clarity pass shows no structural changes and running a diff after a structure pass shows no sentence-level edits
  5. Each run directory in runs/ contains the full artifact set: input, diagnosis, revision plan, per-pass outputs, final draft, diff, and run metadata JSON
**Plans:** 3/3 plans complete

Plans:
- [x] 02-01-PLAN.md — Per-pass scope constraint rules (14 pass rule files for all preset stage types)
- [x] 02-02-PLAN.md — /improve SKILL.md core revision engine
- [x] 02-03-PLAN.md — /build and /adapt variant skills (notes-to-draft and form adaptation)

### Phase 3: Eval System
**Goal**: A dedicated critic subagent running in a separate context window can evaluate any revision output and produce a stable, machine-readable eval snapshot with criterion-level scores and failure points
**Depends on**: Phase 2
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, EVAL-06
**Success Criteria** (what must be TRUE):
  1. Running the /eval skill on the same draft three times produces scores that differ by no more than 0 points per criterion (temperature=0, calibration test passes)
  2. Eval output contains a score, at least one failure point with a concrete explanation, and a pass/fail flag for each of the seven criteria: novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity
  3. Eval rubric weights and criteria are loaded from the active preset, not hardcoded — swapping presets produces a different rubric emphasis
  4. Eval snapshot is a valid JSON file that can be parsed by jq without errors
**Plans:** 1 plan

Plans:
- [x] 03-01-PLAN.md — Eval critic subagent and /eval skill (agent definition, anchored rubric, invocation, dispatch, eval.json output)

### Phase 4: Autoloop and Preset Creation
**Goal**: The system can run a mutation-eval cycle that improves a preset or skill asset only when scores measurably improve, and a user can create a new preset from example texts without writing JSON by hand
**Depends on**: Phase 3
**Requirements**: LOOP-01, LOOP-02, LOOP-03, LOOP-04, LOOP-05, LOOP-06, PCRE-01, PCRE-02, PCRE-03, PCRE-04
**Success Criteria** (what must be TRUE):
  1. Running /autoloop produces an append-only mutation log showing before/after scores for each attempted mutation and the acceptance decision
  2. A mutation that produces a lower aggregate score or a critical criterion regression is automatically rejected and the original asset is restored
  3. After N iterations, the holdout set scores are checked — if holdout scores diverge from loop scores by more than the defined threshold, the loop halts and logs the divergence
  4. User can run /create-preset with one or more example text files and see all inferred preset fields displayed for review before any file is written
**Plans:** 2/2 plans complete

Plans:
- [x] 04-01-PLAN.md — /create-preset skill (text analysis, preset synthesis, annotated display, approval gate, --refine mode)
- [x] 04-02-PLAN.md — /autoloop skill (mutation-eval cycle, acceptance rules, JSONL logging, holdout divergence checks)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Presets | 2/2 | Complete | 2026-04-05 |
| 2. Writing Engine | 3/3 | Complete   | 2026-04-05 |
| 3. Eval System | 0/1 | Planning complete | - |
| 4. Autoloop and Preset Creation | 2/2 | Complete   | 2026-04-06 |
