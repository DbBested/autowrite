# Concision Pass Rules

## Scope: What This Pass Does

- Remove redundant phrases and sentences that restate a point already made without adding new information
- Cut filler words and phrases (very, really, basically, actually, just, in order to, the fact that) unless they serve a specific voice purpose
- Remove paragraphs that restate earlier points without adding new information or emphasis
- Tighten wordy constructions ("due to the fact that" → "because", "at this point in time" → "now")
- Reduce throat-clearing openings that delay the actual content

## DO NOT Touch (Out of Scope)

- Section order — do not reorder content while cutting; cuts only
- Arguments and claims — do not cut supporting evidence thinking it is redundant; verify redundancy before cutting
- The author's intentional repetition for rhetorical effect — check `diagnosis.md` for noted rhetorical patterns (anaphora, callback structures, deliberate restatement)
- Opening and closing paragraphs — these are handled by the hook and ending passes if present in the preset stages; do not preempt those passes

## Voice Preservation

- If the author's style includes deliberate verbosity (e.g., conversational asides, winding explanations in blog posts), preserve the texture while cutting mechanical redundancy
- Read the preset's `voiceBehaviors` for guidance — "conversational digression allowed" means some apparent redundancy is stylistic
- Cut mechanical redundancy (repeated words, empty transitions, filler phrases) — not stylistic texture (asides, examples that expand a point, rhetorical buildup)
- If unsure whether a passage is redundant or stylistic, keep it — the risk of cutting voice is higher than the risk of leaving mild redundancy

## Factual Integrity

- Do not cut factual qualifications and hedges (e.g., "in most cases", "typically", "under these conditions") — they may be intentional precision that changes the claim
- Do not cut an example assuming the main point stands without it — examples often carry evidence weight that is not visible from the surrounding prose alone
- Verify that cutting a "redundant" paragraph does not remove the only instance of a piece of evidence or a sub-claim
