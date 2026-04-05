# Stack Research

**Domain:** Claude Code-native writing workflow system (CLI tool, no web app)
**Researched:** 2026-04-05
**Confidence:** HIGH — primary sources are official Claude Code documentation fetched directly from code.claude.com and platform.claude.com

---

## Recommended Stack

### Core Primitives

| Primitive | Format | Purpose | Why |
|-----------|--------|---------|-----|
| `CLAUDE.md` | Markdown | Persistent repo-wide instructions loaded every session | Official Claude Code memory system. Loaded from project root and all parent directories. Use for project-level behavioral rules, voice preservation mandates, system conventions. Target under 200 lines per file for reliable adherence. |
| `.claude/skills/<name>/SKILL.md` | Markdown + YAML frontmatter | Executable writing skills invocable as `/skill-name` | Official first-class primitive as of Claude Code v2.x. Replaces the older `.claude/commands/*.md` pattern (which still works but skills are the forward path). Skills have a directory for supporting files and can be model-invoked automatically. |
| `.claude/settings.json` | JSON | Project-level hook configuration, permissions, tool settings | Official settings layer. Committed to version control. Controls hooks, allowed tools, permission modes. Use `.claude/settings.local.json` for per-developer overrides (gitignore this). |
| `.claude/rules/*.md` | Markdown + optional YAML frontmatter | Modular scoped rules organized by topic or file path | Official alternative to a monolithic CLAUDE.md. Supports `paths:` frontmatter to activate rules only when Claude works with matching files. Prefer this over putting everything in CLAUDE.md when rules exceed 200 lines. |
| `.claude/agents/<name>.md` | Markdown + YAML frontmatter | Custom subagent definitions for specialized evaluation or mutation roles | Official subagent system. Markdown body becomes the subagent's system prompt. Use for the eval agent (critic) and the autoloop mutation agent — these need separate context and identity from the writing agent. |

### File Formats for Data

| Format | Use Case | Why |
|--------|----------|-----|
| JSON | Preset schemas, eval results, run snapshots, diff records | Machine-readable, human-diffable, no install required. Claude can read/write JSON natively. jq available for shell pipeline processing. Strict schema validation possible with JSON Schema. |
| Markdown | Drafts, revised outputs, explanations, skill instructions | Natural format for writing content — Claude operates on Markdown natively, diffs are readable, and the output format matches common publishing targets. |
| YAML frontmatter | Skill/agent metadata only | YAML is used exclusively within SKILL.md and agent `.md` files for frontmatter (name, description, invocation control). Do NOT use YAML for preset schemas or eval data — use JSON for all structured data files so jq can process them. |

### Skill Structure

Every Autowrite skill follows this directory layout:

```
.claude/skills/<skill-name>/
├── SKILL.md           # Required: YAML frontmatter + instructions
├── examples/
│   └── sample.md      # Example input/output pairs showing expected behavior
└── scripts/
    └── validate.sh    # Optional shell scripts Claude can execute
```

**SKILL.md frontmatter fields used in this project:**

| Field | Value pattern | Rationale |
|-------|---------------|-----------|
| `name` | kebab-case, max 64 chars | Becomes the `/slash-command` |
| `description` | Third-person, 250 chars max, front-load the use case | Critical for model auto-invocation — Claude uses this to decide when to load the skill |
| `disable-model-invocation` | `true` for destructive or staged passes | Prevents Claude from auto-triggering revision passes; user controls when passes run |
| `allowed-tools` | `Read Write Bash(python *)` etc. | Restricts tool surface to what the skill actually needs |
| `effort` | `high` for diagnostic and eval passes | Ensures quality on assessment steps |
| `context` | `fork` for eval agent invocations | Runs eval in isolation without conversation history contaminating the score |
| `agent` | name of the critic subagent | Routes forked context to the specialized eval agent |

### Hook Events Used

| Hook event | Matcher | Purpose |
|------------|---------|---------|
| `PostToolUse` | `Write` | After any Write, log the output path to `runs/<session>/writes.log` for run reconstruction |
| `SessionStart` | `compact` | Re-inject critical preset context after compaction to prevent context loss mid-revision |
| `Stop` | (none) | Finalize the run snapshot: copy eval scores, diffs, and explanation to `runs/<session>/` |

Hooks are configured in `.claude/settings.json`. Hook scripts live in `.claude/hooks/` and must be executable. Hooks receive event data as JSON on stdin; use `jq` to extract fields.

### Shell Scripting Conventions

| Tool | Purpose | Notes |
|------|---------|-------|
| `bash` | Primary automation language for all hook scripts and pipeline glue | Available everywhere, no install. Use POSIX-compatible syntax for portability. |
| `jq` | JSON processing in shell scripts | Parse preset schemas, extract eval scores, transform run data. `jq -r` for raw string output. Install: `brew install jq` / `apt install jq` / `winget install jqlang.jq`. |
| `diff` / `git diff --no-index` | Produce human-readable diffs between draft versions | `git diff --no-index --color-words original.md revised.md` produces word-level diffs. Pipe to a `.diff` file in `runs/`. |
| `python3` (stdlib only) | Complex string processing, JSON schema validation when jq is insufficient | Use only stdlib — no pip dependencies. `json`, `difflib`, `textwrap` cover the needed cases. |

**Shell dynamic context injection in SKILL.md:** Use the `` !`command` `` syntax to inject live data into skills before Claude sees them:

```yaml
---
name: diagnose-draft
description: Diagnoses weaknesses in a draft before revision
---

## Current preset
!`cat presets/$0.json`

## Draft content
!`cat drafts/$1`

Diagnose the draft against the preset criteria above...
```

This preprocesses before Claude sees the skill — the output of the shell commands replaces the backtick blocks. Use `$0`, `$1` etc. for positional arguments passed at invocation.

### Preset Schema (JSON)

Presets are the central configuration artifact. They are JSON files in `presets/` that define "good" for a writing form comprehensively enough to drive both revision and evaluation.

**Recommended schema structure:**

```json
{
  "id": "blog-post",
  "form": "blog-post",
  "version": "1.0.0",
  "description": "Conversational, opinion-driven blog post",
  "goals": ["persuade", "inform", "engage"],
  "voice_rules": {
    "preserve": ["first-person", "colloquialisms", "sentence-fragments"],
    "forbid": ["passive-voice-excess", "corporate-hedging"],
    "default_stance": "preserve"
  },
  "structure": {
    "hook": "required",
    "sections": ["argument", "evidence", "objection", "resolution"],
    "ending": "strong-close"
  },
  "stages": ["diagnose", "revision-plan", "structure", "clarity", "argument", "tone", "concision", "hook", "ending", "final-review"],
  "rubric": {
    "criteria": ["novelty", "clarity", "structure", "voice_preservation", "audience_fit", "concision", "factual_integrity"],
    "passing_threshold": 3.5,
    "critical_criteria": ["factual_integrity", "voice_preservation"]
  },
  "constraints": {
    "no_citation_invention": true,
    "no_stance_shift": true,
    "aggressive_rewrite_requires_explicit_request": true
  },
  "transformation_defaults": {
    "trim_target_percent": 15,
    "strengthen_argument": true,
    "preserve_examples": true
  }
}
```

Use JSON Schema Draft 7 to validate presets before a revision run. Keep schemas in `presets/` alongside the preset files.

### Eval Output Schema (JSON)

Eval results are written to `evals/<run-id>.json`:

```json
{
  "run_id": "20260405-143212",
  "preset": "blog-post",
  "draft_path": "drafts/my-draft.md",
  "timestamp": "2026-04-05T14:32:12Z",
  "scores": {
    "novelty": 3.8,
    "clarity": 4.1,
    "structure": 3.5,
    "voice_preservation": 4.4,
    "audience_fit": 3.9,
    "concision": 3.2,
    "factual_integrity": 5.0
  },
  "aggregate": 3.99,
  "failure_points": [
    {"criterion": "concision", "explanation": "Paragraph 3 repeats the thesis unnecessarily"}
  ],
  "passed": true
}
```

Aggregate score formula: mean of all criteria, with `factual_integrity` and `voice_preservation` as hard blockers (any score below 2.5 on these forces `passed: false` regardless of aggregate).

### Run Snapshot Structure

Each revision run produces a snapshot in `runs/<run-id>/`:

```
runs/20260405-143212/
├── meta.json          # preset, draft path, stages run, timestamps
├── original.md        # input draft (copy)
├── revised.md         # output draft
├── revision-plan.md   # the plan produced before changes
├── diagnosis.md       # pre-revision diagnosis
├── changes.md         # explanation of what changed and why
├── diff.patch         # git diff --no-index word-level diff
└── eval.json          # eval scores for the revised draft
```

The run snapshot is the system's audit trail. Scripts assemble it from the outputs of individual pass skills.

### Subagent Definitions

**Eval critic agent** (`.claude/agents/eval-critic.md`):

```yaml
---
name: eval-critic
description: Specialized writing evaluation agent. Produces criterion-level scores, failure points, and actionable explanations. Runs in isolation from the writing agent.
model: claude-sonnet-4-6
effort: high
allowed-tools: Read
---

You are a hyper-critical writing evaluator. Your role is to identify weaknesses, not validate choices...
```

**Autoloop mutation agent** (`.claude/agents/mutation-agent.md`):

Responsible for proposing and applying controlled mutations to a single asset (skill, preset field, or CLAUDE.md rule) for the self-improvement loop. Operates on structured JSON diff of the mutation so the eval loop can measure before/after.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| SKILL.md in `.claude/skills/` | Legacy `.claude/commands/*.md` | Commands still work but lack supporting-file directories, invocation control, and subagent routing. Skills are the forward path per official docs. |
| JSON for preset/eval data | YAML for preset/eval data | YAML cannot be processed with `jq` in shell scripts without an extra parser. JSON is natively supported by `jq`, Python stdlib `json`, and Claude itself. |
| `.claude/rules/*.md` with path scoping | Monolithic CLAUDE.md | CLAUDE.md degrades in adherence above 200 lines. Rules files allow modular, path-scoped loading. Use rules for form-specific guidance. |
| Separate eval critic subagent | Self-eval (writing agent scores its own output) | Self-eval inflates scores and lacks objectivity. The eval agent must be a separate identity with a separate context. Official pattern for critic separation. |
| `context: fork` skill for eval invocation | Inline eval in main conversation | Forked context prevents conversation history from contaminating eval scores. Eval must see only the draft and the rubric, not the revision history. |
| `git diff --no-index --color-words` for diffs | Custom diff implementation | Git is available everywhere, `--color-words` produces readable human-facing diffs, `--no-index` works on untracked files. No dependency. |
| Auto memory (`~/.claude/projects/*/memory/`) | Manual CLAUDE.md updates for learnings | Auto memory accumulates session-specific learnings automatically. Use for build patterns and debugging insights. Use CLAUDE.md for permanent behavioral rules. |
| Shell scripts + jq for pipeline glue | Python CLI for pipeline glue | Shell + jq has zero install friction and works with Claude Code hooks natively. Python stdlib only when jq is insufficient. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| YAML for structured data files (presets, evals, runs) | Cannot be processed by `jq` in shell hooks. Parsing requires an external tool not available everywhere. | JSON — jq-processable, human-readable, Python-parseable with stdlib |
| `python-jose` or any third-party JSON schema validator as a hard dependency | This project has no install step — zero Python package dependencies outside stdlib | `python3 -c "import json; ..."` with stdlib validation, or manual field checks in `jq` |
| Deeply nested skill references (SKILL.md → A.md → B.md → content) | Claude may partial-read files when following references more than one level deep, producing incomplete context | Keep all reference files one level deep from SKILL.md. If content is complex, use a flat `reference/` directory |
| `allowed-tools: Bash` without restrictions on writing skills | Unrestricted Bash in a writing revision pass creates unnecessary blast radius | Scope to `Bash(python scripts/*)` or `Bash(git diff *)` as needed per skill |
| Self-eval (writing agent scoring its own output) | Inflates scores, misses blind spots, defeats the purpose of independent evaluation | Dedicated eval critic subagent with `context: fork` |
| Storing raw API keys or secrets in `.claude/` config files | `.claude/settings.json` is committed to version control | Use environment variables via `CLAUDE_ENV_FILE` or system keychain |
| Global hooks in `~/.claude/settings.json` for project-specific behavior | Global hooks affect all projects, not just Autowrite | Project hooks in `.claude/settings.json`, committed to the repo |

---

## Stack Patterns by Variant

**If a skill is destructive or staged (revision passes):**
- Add `disable-model-invocation: true` — user controls when passes run
- Use explicit `$ARGUMENTS` for the draft path and preset name so Claude cannot hallucinate them

**If a skill is reference knowledge (voice rules, form conventions):**
- Leave `disable-model-invocation` unset (false by default) — Claude loads it automatically when relevant
- Add `user-invocable: false` if it should be background context only, not a slash command

**If a skill needs isolation from conversation history (eval runs):**
- Add `context: fork` and `agent: eval-critic`
- The forked context sees only SKILL.md content + CLAUDE.md, not the conversation history
- Scores are returned to the main conversation as a summary

**If processing JSON in hooks:**
- Use `jq -r '.field'` to extract values
- Use `jq -c` for compact single-line JSON output (useful for appending to JSONL log files)
- Parse `stdin` with `INPUT=$(cat)` then `echo "$INPUT" | jq ...`

**If re-injecting context after compaction:**
- Use a `SessionStart` hook with `matcher: compact`
- `echo` the current preset name and active run ID to stdout — Claude receives this as a system reminder
- This prevents preset drift mid-session when the context window compacts

**If creating a self-improvement mutation run:**
- Write the mutation diff to a JSON file before applying it
- Run eval on both original and mutated asset
- Compare `aggregate` scores and check `critical_criteria` — keep mutation only if aggregate improves and no critical criteria regression
- Use a separate `mutation-agent` subagent to propose changes so the main writing agent is not influenced

---

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| Claude Code | v2.1.59+ | Required for auto memory. v2.1.85+ required for `if` field in hooks. v2.x for skills as first-class primitive (skills directory, invocation control, `context: fork`). |
| SKILL.md frontmatter | agentskills.io open standard + Claude Code extensions | Claude Code adds `disable-model-invocation`, `context: fork`, `agent`, `hooks`, `paths`, `shell`, `effort`, `model` on top of the base standard |
| `.claude/settings.json` | Valid JSON, single root object, no trailing commas, no comments | Trailing commas or comments cause silent hook failures. Verify with `jq . .claude/settings.json` |
| Hook stdin JSON | Event-specific schemas per hook type | `PreToolUse`/`PostToolUse`: `tool_name`, `tool_input`, `session_id`, `cwd`. `SessionStart`: `source` field (`startup`, `resume`, `clear`, `compact`). `Stop`: `stop_hook_active` boolean (check this to prevent infinite loop). |
| jq | 1.6+ | 1.6 introduced `@base64`, `@uri`, `env` object. All hook scripts assume 1.6+. |
| python3 | 3.8+ stdlib only | Used only for complex text processing where jq is insufficient. No pip packages — zero install dependency. |
| Eval JSON schema | Custom (defined above) | Not tied to any external schema version. Validate with `jq 'has("scores") and has("aggregate") and has("passed")'` in hooks. |

---

## Sources

- [Claude Code Skills documentation](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter schema, invocation control, supporting files, dynamic context injection, `context: fork` — HIGH confidence, official docs fetched directly
- [Claude Code Hooks guide](https://code.claude.com/docs/en/hooks-guide) — Hook events, JSON stdin/stdout protocol, exit codes, matchers, `if` field, settings file format — HIGH confidence, official docs
- [Claude Code Memory documentation](https://code.claude.com/docs/en/memory) — CLAUDE.md format, `.claude/rules/` path scoping, auto memory, file hierarchy — HIGH confidence, official docs
- [Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — SKILL.md authoring patterns, eval-driven development, JSON eval schema structure, progressive disclosure — HIGH confidence, official Anthropic docs
- [agentskills.io open standard](https://agentskills.io) — Base SKILL.md standard that Claude Code extends — MEDIUM confidence (referenced in official docs, site not directly verified)
- [GitHub anthropics/skills](https://github.com/anthropics/skills) — Community skill examples including skill-creator — MEDIUM confidence, community ecosystem
- [Claude Code subagents documentation](https://code.claude.com/docs/en/sub-agents) — Agent YAML frontmatter, storage paths, system prompt structure — HIGH confidence, official docs

---

*Stack research for: Claude Code-native writing workflow system (Autowrite)*
*Researched: 2026-04-05*
