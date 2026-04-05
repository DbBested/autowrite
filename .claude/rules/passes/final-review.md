# Final Review Pass Rules

## Scope: What This Pass Does

This is a READ-ONLY pass. Do NOT modify the draft text.

- Read the final draft (output of the last revision pass) and produce `explanation.md` documenting all changes made across all previous passes
- Write `output.md` as a clean copy of the last revision pass output — no annotations, no markup, no comments; just the final revised text
- Generate `diff.patch` by running: `diff -u runs/CURRENT_RUN/input.md runs/CURRENT_RUN/output.md > runs/CURRENT_RUN/diff.patch`
- Write `metadata.json` with run metadata (see format below)

## explanation.md Format

Entries are grouped by pass. One entry per substantive change, not per word change.

Each entry must include:
- Which pass made the change
- What was changed (specific sentence or paragraph reference)
- Where the change was made (paragraph N, sentence N)
- Why the change was made (referencing the specific diagnosis finding or revision plan item it addressed)

Example format:
```
## Structure Pass
- Moved thesis to opening paragraph: The central claim was in paragraph 4. Moved to paragraph 1, sentence 2. Reason: diagnosis item "buried lede."
```

Summaries like "improved the structure" are not acceptable — every entry must be traceable to a specific change at a specific location for a specific reason.

## output.md

Clean copy of the final revised draft. No annotations, no markup, no tracked changes, no explanatory comments. This is the deliverable the user reads.

## metadata.json Required Fields

```json
{
  "run_id": "YYYY-MM-DD_HH-MM-SS_preset-id",
  "preset_id": "...",
  "preset_version": "...",
  "input_file": "drafts/FILENAME.md",
  "input_type": "draft | rough notes",
  "depth": "light | standard | deep",
  "stages_run": ["diagnose", "revision-plan", "..."],
  "timestamps": {
    "run_start": "ISO 8601",
    "run_end": "ISO 8601"
  },
  "word_counts": {
    "input": 0,
    "output": 0
  }
}
```

## DO NOT Touch (Out of Scope)

- The draft text — this pass is entirely read-only; do not change any word in the final draft
- Any previous pass output files — the final-review pass reads them, it does not modify them
- Do not make any additional revision judgments — all revision is complete before this pass runs

## Voice Preservation

- Note in `explanation.md` any voice preservation decisions made during earlier passes — these are part of the revision record
- If a pass chose not to change something in order to preserve the author's voice, that decision belongs in `explanation.md`

## Factual Integrity

- Note in `explanation.md` any factual integrity checks performed during earlier passes
- If an evidence gap was flagged during an earlier pass and left unresolved (correctly, per the pass rules), record this in `explanation.md` so the author knows what requires their input
