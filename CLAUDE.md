<!-- GSD:project-start source:PROJECT.md -->
## Project

**Autowrite**

Autowrite is a Claude Code-native writing workflow system that improves rough notes or drafts into stronger final writing through preset-based workflows, staged revision passes, and an eval-driven self-improvement loop. It is built entirely on Claude Code primitives (CLAUDE.md, SKILL.md, local files, scripts, hooks) and targets developers and writers who use Claude Code as their primary tool.

**Core Value:** When a user submits a draft, Autowrite must produce a measurably better revision that preserves the author's voice — diagnosed, planned, and improved through form-aware staged passes, not blind rewriting.

### Constraints

- **Platform**: Claude Code native — all functionality through CLAUDE.md, SKILL.md, local files, and scripts
- **Voice preservation**: Revisions must preserve author voice by default; aggressive rewrites only when explicitly requested
- **Safety**: Must not invent citations, fabricate facts, or silently shift author stance
- **Eval consistency**: Eval agent must produce consistent scores across runs for the same input
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
### Shell Scripting Conventions
| Tool | Purpose | Notes |
|------|---------|-------|
| `bash` | Primary automation language for all hook scripts and pipeline glue | Available everywhere, no install. Use POSIX-compatible syntax for portability. |
| `jq` | JSON processing in shell scripts | Parse preset schemas, extract eval scores, transform run data. `jq -r` for raw string output. Install: `brew install jq` / `apt install jq` / `winget install jqlang.jq`. |
| `diff` / `git diff --no-index` | Produce human-readable diffs between draft versions | `git diff --no-index --color-words original.md revised.md` produces word-level diffs. Pipe to a `.diff` file in `runs/`. |
| `python3` (stdlib only) | Complex string processing, JSON schema validation when jq is insufficient | Use only stdlib — no pip dependencies. `json`, `difflib`, `textwrap` cover the needed cases. |
## Current preset
## Draft content
### Preset Schema (JSON)
### Eval Output Schema (JSON)
### Run Snapshot Structure
### Subagent Definitions
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
## Stack Patterns by Variant
- Add `disable-model-invocation: true` — user controls when passes run
- Use explicit `$ARGUMENTS` for the draft path and preset name so Claude cannot hallucinate them
- Leave `disable-model-invocation` unset (false by default) — Claude loads it automatically when relevant
- Add `user-invocable: false` if it should be background context only, not a slash command
- Add `context: fork` and `agent: eval-critic`
- The forked context sees only SKILL.md content + CLAUDE.md, not the conversation history
- Scores are returned to the main conversation as a summary
- Use `jq -r '.field'` to extract values
- Use `jq -c` for compact single-line JSON output (useful for appending to JSONL log files)
- Parse `stdin` with `INPUT=$(cat)` then `echo "$INPUT" | jq ...`
- Use a `SessionStart` hook with `matcher: compact`
- `echo` the current preset name and active run ID to stdout — Claude receives this as a system reminder
- This prevents preset drift mid-session when the context window compacts
- Write the mutation diff to a JSON file before applying it
- Run eval on both original and mutated asset
- Compare `aggregate` scores and check `critical_criteria` — keep mutation only if aggregate improves and no critical criteria regression
- Use a separate `mutation-agent` subagent to propose changes so the main writing agent is not influenced
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
## Sources
- [Claude Code Skills documentation](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter schema, invocation control, supporting files, dynamic context injection, `context: fork` — HIGH confidence, official docs fetched directly
- [Claude Code Hooks guide](https://code.claude.com/docs/en/hooks-guide) — Hook events, JSON stdin/stdout protocol, exit codes, matchers, `if` field, settings file format — HIGH confidence, official docs
- [Claude Code Memory documentation](https://code.claude.com/docs/en/memory) — CLAUDE.md format, `.claude/rules/` path scoping, auto memory, file hierarchy — HIGH confidence, official docs
- [Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — SKILL.md authoring patterns, eval-driven development, JSON eval schema structure, progressive disclosure — HIGH confidence, official Anthropic docs
- [agentskills.io open standard](https://agentskills.io) — Base SKILL.md standard that Claude Code extends — MEDIUM confidence (referenced in official docs, site not directly verified)
- [GitHub anthropics/skills](https://github.com/anthropics/skills) — Community skill examples including skill-creator — MEDIUM confidence, community ecosystem
- [Claude Code subagents documentation](https://code.claude.com/docs/en/sub-agents) — Agent YAML frontmatter, storage paths, system prompt structure — HIGH confidence, official docs
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
