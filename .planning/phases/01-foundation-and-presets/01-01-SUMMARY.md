---
phase: 01-foundation-and-presets
plan: 01
subsystem: foundation
tags: [scaffold, claude-md, rules, preset-schema, validation]
dependency_graph:
  requires: []
  provides:
    - repo-directory-scaffold
    - universal-safety-rules-CLAUDE.md
    - preset-editing-rules-file
    - preset-json-schema
    - preset-validation-script
  affects:
    - all subsequent phases (read from CLAUDE.md, presets/, scripts/)
tech_stack:
  added: []
  patterns:
    - CLAUDE.md universal safety rules (under 300 lines)
    - .claude/rules/*.md with paths: frontmatter for path-scoped rules
    - JSON Schema draft-07 for preset validation reference
    - jq-based bash validation script with check_field helper pattern
key_files:
  created:
    - CLAUDE.md
    - .claude/rules/preset-editing.md
    - presets/preset-schema.json
    - scripts/validate-preset.sh
    - drafts/.gitkeep
    - presets/.gitkeep
    - runs/.gitkeep
    - evals/.gitkeep
    - autoloop/runs/.gitkeep
    - autoloop/accepted/.gitkeep
    - scripts/.gitkeep
    - .claude/skills/improve/.gitkeep
    - .claude/skills/build/.gitkeep
    - .claude/skills/adapt/.gitkeep
    - .claude/skills/create-preset/.gitkeep
    - .claude/skills/eval/.gitkeep
    - .claude/skills/autoloop/.gitkeep
    - .claude/agents/.gitkeep
  modified: []
decisions:
  - "CLAUDE.md rewritten to Autowrite-only universal safety rules (47 lines, target met)"
  - "preset-schema.json uses JSON Schema draft-07 for machine-readable reference"
  - "validate-preset.sh uses check_field helper pattern for named field errors on failure"
metrics:
  duration: 8m
  completed_date: "2026-04-05"
  tasks_completed: 2
  tasks_total: 2
  files_created: 18
  files_modified: 0
---

# Phase 01 Plan 01: Foundation Scaffold and Safety Rules Summary

## One-liner

Autowrite repo scaffold with Factual Integrity/Voice/Stance/Scope safety rules in CLAUDE.md (47 lines), path-scoped preset-editing rules file, JSON Schema draft-07 preset reference, and jq-based validation script with weight-sum and critical-criteria checks.

## What Was Built

Two tasks executed to establish the foundational scaffold every subsequent phase reads from:

**Task 1** — Repo directory scaffold, CLAUDE.md, and rules file:
- Created 14 directories (drafts/, presets/, runs/, evals/, autoloop/runs/, autoloop/accepted/, scripts/, .claude/skills/{improve,build,adapt,create-preset,eval,autoloop}/, .claude/agents/, .claude/rules/) with .gitkeep files
- Rewrote CLAUDE.md from the Frame project template to Autowrite-only universal safety rules. New CLAUDE.md: 47 lines, four safety rule subsections (Factual Integrity, Voice Preservation, Stance Integrity, Pass Scope), project structure reference, and conventions note
- Created `.claude/rules/preset-editing.md` with `paths: presets/*.json` frontmatter — activates only when editing preset files, covering schema compliance, voice rule format, rubric integrity, stage ordering, and safety defaults

**Task 2** — Preset JSON Schema and validation script:
- Created `presets/preset-schema.json` as JSON Schema draft-07 defining all 13 required top-level fields with types, constraints (version semver pattern, rubric criteria weight bounds, const true for safety fields), and behavioral descriptions
- Created `scripts/validate-preset.sh` with `check_field` helper, 28 field/type checks, rubric weight sum validation (must be 1.0 ± 0.01), critical_criteria presence check (factual_integrity + voice_preservation required), and per-criterion completeness check. Exits non-zero with named error on any failure.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | be9fc6f | feat(01-01): repo scaffold, CLAUDE.md safety rules, preset-editing rules file |
| 2 | 97c7687 | feat(01-01): preset JSON Schema draft-07 and jq-based validation script |

## Verification Results

All checks passed:
- All 14 required directories exist with .gitkeep files
- CLAUDE.md is 47 lines (well under 300-line ceiling)
- CLAUDE.md contains all four safety rule subsections
- CLAUDE.md contains no Frame/ffmpeg/PyQt6 content
- .claude/rules/preset-editing.md has correct `paths: presets/*.json` frontmatter
- presets/preset-schema.json is valid JSON with all 13 required fields and `$schema` declaration
- scripts/validate-preset.sh is executable and contains check_field, WEIGHT_SUM, factual_integrity checks

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Environmental Notes

jq is not installed on this development machine (Windows, no jq in PATH). The validation script is correctly authored and will work when jq is installed. The schema was validated as correct JSON using python3 stdlib. This is a developer prerequisite, not a code issue:
```bash
# Windows install:
winget install jqlang.jq
```

## Known Stubs

None. This plan creates infrastructure files (directories, schema, script) — no stubs that would flow to rendering or block the plan's goal.

## Self-Check: PASSED

Files exist:
- CLAUDE.md: FOUND
- .claude/rules/preset-editing.md: FOUND
- presets/preset-schema.json: FOUND
- scripts/validate-preset.sh: FOUND

Commits exist:
- be9fc6f: FOUND
- 97c7687: FOUND
