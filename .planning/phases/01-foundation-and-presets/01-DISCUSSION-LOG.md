# Phase 1: Foundation and Presets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 01-foundation-and-presets
**Areas discussed:** Preset file format, Skill structure, Rules architecture, Preset validation
**Mode:** Auto (all recommended defaults selected)

---

## Preset File Format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON | Processable by jq, Python stdlib, and Claude natively | ✓ |
| YAML | Human-readable but requires parser, inconsistent whitespace handling | |
| TOML | Good for config but verbose for nested structures like rubric criteria | |

**User's choice:** JSON (auto-selected recommended default)
**Notes:** Research confirmed JSON is the right choice — no additional dependencies, works with hooks and shell scripts via jq.

---

## Skill Structure

| Option | Description | Selected |
|--------|-------------|----------|
| One SKILL.md per task | Each writing task (diagnose, improve, eval) gets its own skill directory | ✓ |
| Monolithic skill | Single skill handles all writing tasks via arguments | |
| Dispatcher pattern | One entry skill routes to sub-skills | |

**User's choice:** One SKILL.md per task (auto-selected recommended default)
**Notes:** Matches Claude Code skill primitive directly. Each skill has its own context and supporting files.

---

## Rules Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| CLAUDE.md (<300 lines) + rules/*.md | Universal rules in CLAUDE.md, contextual rules in path-scoped files | ✓ |
| CLAUDE.md only | All rules in one file | |
| Rules files only | No CLAUDE.md, everything in .claude/rules/ | |

**User's choice:** CLAUDE.md + rules/*.md split (auto-selected recommended default)
**Notes:** Research confirmed CLAUDE.md instruction following degrades above 300 lines. Path-scoped rules keep context lean.

---

## Preset Validation

| Option | Description | Selected |
|--------|-------------|----------|
| Shell script with jq | No dependencies, runs in hooks, clear error output | ✓ |
| Python script | More expressive but adds runtime dependency | |
| JSON Schema | Declarative but requires a validator tool | |

**User's choice:** Shell script with jq (auto-selected recommended default)
**Notes:** Consistent with Claude Code-native approach. jq is commonly available and sufficient for field presence/type checking.

---

## Claude's Discretion

- Directory internal structure
- Voice rule granularity per preset
- Rubric weight distribution
- Whether to include JSON Schema alongside validation script

## Deferred Ideas

None — discussion stayed within phase scope
