# Autowrite

## What This Is

Autowrite is a Claude Code-native writing workflow system that improves rough notes or drafts into stronger final writing through preset-based workflows, staged revision passes, and an eval-driven self-improvement loop. It is built entirely on Claude Code primitives (CLAUDE.md, SKILL.md, local files, scripts, hooks) and targets developers and writers who use Claude Code as their primary tool.

## Core Value

When a user submits a draft, Autowrite must produce a measurably better revision that preserves the author's voice — diagnosed, planned, and improved through form-aware staged passes, not blind rewriting.

## Requirements

### Validated

- ✓ Repository structure with drafts/, presets/, skills/, evals/, autoloop/, scripts/, runs/ — v1.0
- ✓ CLAUDE.md universal safety rules (factual integrity, voice preservation, stance integrity, pass scope) — v1.0
- ✓ Path-scoped behavioral rules via .claude/rules/*.md — v1.0
- ✓ Preset schema (JSON) with form, goals, stages, voice, structure, rubric, constraints, transformations — v1.0
- ✓ Three hand-tuned presets: blog post, argumentative essay, technical explainer — v1.0
- ✓ Preset validation script (jq-based) — v1.0
- ✓ /improve skill: draft → diagnosis → plan → staged passes → diff → explanation → output — v1.0
- ✓ /build skill: notes-to-draft via /improve with forced notes classification — v1.0
- ✓ /adapt skill: form adaptation via /improve with target preset — v1.0
- ✓ 14 per-pass scope constraint rules with DO NOT touch boundaries — v1.0
- ✓ Immutable timestamped run directories with full artifact set — v1.0
- ✓ /eval skill: isolated adversarial critic with 7-criterion anchored rubric — v1.0
- ✓ Eval snapshots as stable machine-readable JSON (eval.json) — v1.0
- ✓ /create-preset skill: example text analysis → annotated preset → approval gate → save — v1.0
- ✓ /autoloop skill: mutation-eval cycle with holdout protection and JSONL logging — v1.0

### Active

(None — next milestone requirements TBD)

### Out of Scope

- First-draft generation from scratch (no input) — Autowrite focuses on iterative improvement, not generation
- Real-time collaborative editing — single-user workflow system
- GUI or web interface — Claude Code native, CLI-only
- Integration with external writing tools (Google Docs, Notion, etc.) — out of scope
- More than three first-party presets — /create-preset covers custom presets

## Context

- **v1.0 shipped:** 4 phases, 8 plans, 46 commits, 80 files, ~12,170 lines
- **Architecture:** Four subsystems — writing engine (/improve, /build, /adapt), preset system (JSON presets + validation), eval system (/eval + isolated critic), self-improvement loop (/autoloop + /create-preset)
- **Claude Code native:** CLAUDE.md for safety rules, SKILL.md per writing task, .claude/rules/passes/ for per-pass scope constraints, .claude/agents/ for eval critic
- **Tech debt:** 2 items — preset-schema.json missing voiceBehaviors in properties; /autoloop eval.json path resolution ambiguous

## Constraints

- **Platform**: Claude Code native — all functionality through CLAUDE.md, SKILL.md, local files, and scripts
- **Voice preservation**: Revisions must preserve author voice by default; aggressive rewrites only when explicitly requested
- **Safety**: Must not invent citations, fabricate facts, or silently shift author stance
- **Eval consistency**: Eval agent must produce consistent scores across runs for the same input

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude Code native (no GUI) | Inspectable, hackable, aligned with existing Claude Code workflows | ✓ Good |
| Staged revision passes (not single-shot rewrite) | Controlled improvement preserves voice better than wholesale rewriting | ✓ Good |
| Specialized eval agent (not self-eval) | Objective, hyper-critical, consistent evaluation requires separation from the writing agent | ✓ Good |
| Auto Research-style self-improvement loop | Systematic prompt/preset improvement through measured mutation rather than guessing | ✓ Good |
| Preset schema with full voice/structure/rubric spec | Presets must define "good" comprehensively enough to guide both revision and evaluation | ✓ Good |
| JSON for all structured data (not YAML) | Processable by jq, Python stdlib, and Claude natively | ✓ Good |
| One SKILL.md per writing task | Clean separation of concerns; each skill has its own context and supporting files | ✓ Good |
| CLAUDE.md under 300 lines + path-scoped rules | Prevents instruction dropout; rules activate only when relevant | ✓ Good |
| Adversarial eval critic with context: fork | Prevents self-preference bias; critic sees only text and rubric | ✓ Good |
| Holdout set for autoloop (checked every 3 iterations) | Prevents Goodhart's Law overfitting | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-06 after v1.0 milestone*
