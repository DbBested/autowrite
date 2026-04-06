---
name: eval
description: Evaluate any text against a preset rubric. Runs a hyper-critical subagent to produce criterion-level scores, located failure points, and a machine-readable eval snapshot. Usage: /eval @<file> --preset <id>
disable-model-invocation: true
context: fork
agent: eval-critic
allowed-tools: Read Write Bash(jq *) Bash(wc *) Bash(date *) Bash(ls *) Bash(cat *) Bash(mkdir *)
effort: high
---

# /eval

Evaluate any text against a preset rubric. Dispatches a hyper-critical subagent (eval-critic) to produce criterion-level scores, located failure points, and a machine-readable eval snapshot.

---

## Invocation

```
/eval @<file> --preset <preset-id>
/eval @<file>                        (auto-detect preset from latest run)
```

- `@<file>` is required — the text file to evaluate
- `--preset` is optional — if omitted, auto-detect from latest run directory

---

## Step 1: Argument Parsing and Validation

### Step 1a — Resolve text file

Read the file at the path provided by the user.

If file not found, STOP with error:
> "Text file not found: \<path\>"

### Step 1b — Resolve preset

**If `--preset` is provided:**
Load `presets/<preset-id>.json`.

**If `--preset` is NOT provided:**
Auto-detect from latest run:
1. Try to read `runs/latest.txt` (Windows) — extract the run directory path from its contents
2. If `runs/latest.txt` does not exist, try to follow `runs/latest` symlink (POSIX)
3. Read `<run-dir>/metadata.json` and extract `preset_id`
4. Load `presets/<preset_id>.json`

If preset file not found, STOP with error:
> "Preset not found: presets/\<id\>.json. Available presets: blog-post, argumentative-essay, technical-explainer"

If preset loaded but `rubric.criteria` is empty or missing, STOP with error:
> "Preset \<id\> has no rubric criteria defined"

### Step 1c — Word count edge case warnings

Count words in the text file:
```bash
wc -w < "<text-file-path>"
```

- If word count < 150: display warning and continue:
  > "Warning: Text is very short (N words). Eval scores for very short texts may not be reliable."
- If word count > 5000: display warning and continue:
  > "Warning: Text is long (N words). Eval quality may degrade due to context window pressure on the critic."

Do NOT block the eval for either case — continue after displaying the warning.

---

## Step 2: Determine Output Location

**If the text file is inside a `runs/` directory** (path matches `runs/<run-dir>/...`):
Write eval.json to that run directory: `runs/<run-dir>/eval.json`

**If the text file is NOT inside a `runs/` directory** (standalone eval):
Create the `evals/` directory if it does not exist:
```bash
mkdir -p evals
```
Generate output path:
```
evals/<timestamp>_<preset-id>_<text-slug>.json
```
Where:
- `<timestamp>` is the current UTC time: `date -u +"%Y-%m-%d_%H-%M-%S"`
- `<preset-id>` is the preset id string (e.g., `blog-post`)
- `<text-slug>` is the text filename without its extension (e.g., `my-draft` from `my-draft.md`)

---

## Step 3: Inject Context for Critic

**CRITICAL — isolation guarantee:** The critic receives ONLY these two inputs. Nothing else.

1. **Rubric criteria** — read from the preset JSON:
   - The full `preset.rubric.criteria` array (name, description, weight for each criterion)
   - The `preset.rubric.critical_criteria` array (criteria that force aggregate_pass: false if they score < 6)

2. **Text to evaluate** — the full contents of the text file.

**Do NOT inject any of the following:**
- `diagnosis.md` from any run
- `plan.md` from any run
- `explanation.md` from any run
- Any other revision artifact from the run history
- The main conversation history

The critic must evaluate the text blind — with no knowledge of what the writing engine thought it fixed. Only the text and the rubric.

---

## Step 4: Scoring Protocol

Instruct the critic with these scoring rules (include in the context injected to the forked agent):

- Scores are 1-10 integers. No decimals.
- Pass threshold: score >= 6 is pass, score < 6 is fail
- Aggregate pass: ALL individual criteria must pass AND weighted average must be >= 6
- Critical criteria (from `preset.rubric.critical_criteria`): any critical criterion scoring < 6 forces `aggregate_pass: false`, even if the weighted average would otherwise pass
- Weight values come from `preset.rubric.criteria[].weight`

**Important:** Do NOT read `preset.rubric.passing_threshold` for pass/fail determination. That field is a legacy artifact from an earlier 1-5 scale and contains the value 3.5. The Phase 3 pass threshold is score >= 6 on the 1-10 integer scale. The threshold is hardcoded in this skill, not read from the preset.

---

## Step 5: Dispatch to Critic

The critic subagent (eval-critic) is dispatched via `context: fork` + `agent: eval-critic` declared in this skill's frontmatter. Claude Code routes execution to the critic in a clean, isolated context window.

The critic receives:
- Its system prompt from `.claude/agents/eval-critic.md`
- The injected rubric criteria and critical_criteria
- The injected text content
- The scoring protocol instructions from Step 4

The critic returns a JSON object matching the schema in `eval-critic.md`. It does not write any files.

---

## Step 6: Process Critic Output and Write eval.json

After the critic returns its JSON:

1. **Parse** the critic's JSON output: `criteria` array, `aggregate_score`, `aggregate_pass`

2. **Add envelope fields:**
   - `preset` — the preset id (e.g., `"blog-post"`)
   - `preset_version` — from `preset.version`
   - `timestamp` — current ISO 8601 UTC:
     ```bash
     date -u +"%Y-%m-%dT%H:%M:%SZ"
     ```
   - `text_path` — the path as provided by the user

3. **Validate:**
   - Every score is an integer between 1 and 10
   - Every `failure_point.location` is non-empty and names a specific paragraph and sentence
   - `aggregate_score` is approximately equal to the weighted sum of individual scores (within 0.1 rounding tolerance)
   - If a critical criterion scores < 6, `aggregate_pass` must be false — correct it if the critic returned true

4. **Write** the complete eval.json to the determined output path using the Write tool.

The final `eval.json` must match this schema:

```json
{
  "preset": "<preset-id>",
  "preset_version": "<preset.version>",
  "timestamp": "<ISO 8601 UTC>",
  "text_path": "<path as provided>",
  "criteria": [
    {
      "name": "<criterion name>",
      "score": 7,
      "weight": 0.20,
      "pass": true,
      "failure_points": [
        {
          "location": "Paragraph N, sentence N",
          "description": "<specific observable problem>",
          "severity": "critical|major|minor"
        }
      ],
      "explanation": "<1-2 sentences explaining the score>"
    }
  ],
  "aggregate_score": 6.8,
  "aggregate_pass": true
}
```

---

## Step 7: User Summary

After writing eval.json, display to the user:

```
Eval complete.

Preset:          <preset-id> v<version>
Text:            <text-path>
Aggregate score: <score> / 10  [PASS|FAIL]

Criterion scores:
  novelty              7  PASS
  clarity              5  FAIL  (2 failure points)
  structure            8  PASS
  voice_preservation   6  PASS
  audience_fit         7  PASS
  concision            6  PASS
  factual_integrity    9  PASS

Snapshot: <output-path>
```

Display each criterion from the eval output in order, showing:
- Criterion name (left-padded to align)
- Score as integer
- PASS or FAIL
- If FAIL: the number of failure points in parentheses — e.g., `(2 failure points)`

---

## Edge Case Reference

| Situation | Action |
|-----------|--------|
| Text file not found | STOP — "Text file not found: \<path\>" |
| Preset not found | STOP — "Preset not found: presets/\<id\>.json. Available presets: blog-post, argumentative-essay, technical-explainer" |
| Preset has empty rubric.criteria | STOP — "Preset \<id\> has no rubric criteria defined" |
| Text < 150 words | Warn, continue |
| Text > 5000 words | Warn, continue |
| Critical criterion scores < 6 but aggregate_pass is true | Correct aggregate_pass to false before writing eval.json |
| Critic returns non-integer scores | Correct to nearest integer before writing |
| failure_point.location is empty or vague | Remove that failure point before writing eval.json |
