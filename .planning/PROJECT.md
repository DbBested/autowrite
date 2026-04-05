# Autowrite

## What This Is

Autowrite is a Claude Code-native writing workflow system that improves rough notes or drafts into stronger final writing through preset-based workflows, staged revision passes, and an eval-driven self-improvement loop. It is built entirely on Claude Code primitives (CLAUDE.md, SKILL.md, local files, scripts, hooks) and targets developers and writers who use Claude Code as their primary tool.

## Core Value

When a user submits a draft, Autowrite must produce a measurably better revision that preserves the author's voice — diagnosed, planned, and improved through form-aware staged passes, not blind rewriting.

## Requirements

### Validated

- ✓ Three hand-tuned presets available: blog post, argumentative essay, technical explainer — Phase 1
- ✓ Preset schema defines form, goals, stages, voice rules, structure expectations, rubric criteria, constraints, and transformation defaults — Phase 1

### Active

- [ ] User can improve an existing draft through staged revision passes
- [ ] User can build from notes or outline into a polished piece
- [ ] User can adapt a piece into another writing form
- [ ] User can create a reusable preset from one or more example texts
- [ ] System diagnoses what is weak in a draft before rewriting
- [ ] System generates a revision plan before applying changes
- [ ] System applies controlled passes appropriate to the writing form
- [ ] System preserves author voice by default
- [ ] Specialized writing evaluation agent produces criterion-level scores, failure points, and concrete explanations
- [ ] Eval metrics include novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity
- [ ] Self-improvement loop can mutate one asset, eval before/after, and keep only improvements
- [ ] Outputs include revised draft, explanation of changes, diff, and eval snapshot
- [ ] System exposes diffs and explains major changes
- [ ] System never invents citations, fabricates facts, or silently shifts author stance

### Out of Scope

- First-draft generation from scratch (no input) — Autowrite focuses on iterative improvement, not generation
- Real-time collaborative editing — single-user workflow system
- GUI or web interface — Claude Code native, CLI-only
- More than three presets in v1 — business memo, newsletter, personal essay deferred to v2
- Integration with external writing tools (Google Docs, Notion, etc.) — out of scope for v1

## Context

- **Architecture:** Four subsystems — writing engine (ingests drafts, runs passes), preset system (defines "good" per form), eval system (specialized critic agent), self-improvement loop (Auto Research-style mutation framework)
- **Claude Code native:** Uses CLAUDE.md for repo-wide behavior, SKILL.md skills for writing tasks, local files for drafts/presets/diffs/evals/logs, scripts and hooks for automation
- **Repo structure:** `drafts/`, `presets/`, `skills/`, `evals/`, `autoloop/`, `scripts/`, `runs/`
- **Core passes:** diagnose, revision plan, structure, clarity, argument, evidence, objection, tone, concision, hook, ending, final review
- **Preset creation flow:** analyze examples → synthesize blueprint → show inferred fields → save approved preset
- **Eval acceptance rule for mutations:** aggregate score improves, no critical regressions, factual integrity and voice preservation remain acceptable

## Constraints

- **Platform**: Claude Code native — all functionality through CLAUDE.md, SKILL.md, local files, and scripts
- **Voice preservation**: Revisions must preserve author voice by default; aggressive rewrites only when explicitly requested
- **Safety**: Must not invent citations, fabricate facts, or silently shift author stance
- **Eval consistency**: Eval agent must produce consistent scores across runs for the same input

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude Code native (no GUI) | Inspectable, hackable, aligned with existing Claude Code workflows | — Pending |
| Staged revision passes (not single-shot rewrite) | Controlled improvement preserves voice better than wholesale rewriting | — Pending |
| Specialized eval agent (not self-eval) | Objective, hyper-critical, consistent evaluation requires separation from the writing agent | — Pending |
| Auto Research-style self-improvement loop | Systematic prompt/preset improvement through measured mutation rather than guessing | — Pending |
| Preset schema with full voice/structure/rubric spec | Presets must define "good" comprehensively enough to guide both revision and evaluation | — Pending |

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
*Last updated: 2026-04-05 after Phase 1 completion*
