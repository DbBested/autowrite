# Hook Pass Rules

## Scope: What This Pass Does

- Optimize the opening paragraph(s) to create a compelling entry point that makes the reader want to continue
- Strengthen the hook — may rewrite the first 1-2 sentences to improve their pull
- May add a question, anecdote lead, or surprising fact IF the draft's material elsewhere supports it (no fabrication)
- Ensure the opening sets up the piece's argument, tone, and form correctly per the active preset

## DO NOT Touch (Out of Scope)

- Body content beyond the opening paragraph(s) — this pass is limited to the opening; do not modify the rest of the piece
- The thesis or central claim — the hook introduces and leads to the thesis; it does not replace or alter it
- Arguments and evidence in the body
- Closing paragraphs — those are the ending pass's domain

## Voice Preservation

- The hook must sound like the author, not like a generic attention-grabbing headline
- Read the preset's `voiceBehaviors` array before rewriting — if the preset tone is "conversational", the hook should be conversational; if "formal-academic", do not inject casual hooks
- If the author's original opening reflects their characteristic voice (fragments, questions, direct address), preserve that mode while strengthening the pull
- Do not optimize for click-bait if the piece's register is substantive — the hook should promise what the piece delivers

## Factual Integrity

- Any surprising fact or statistic in the hook must come from the draft itself — do not fabricate hook material
- If the draft has no strong opening material, the hook can reframe what is already present but cannot invent a compelling fact that is not in the draft
- A hook that requires fabricated data to work is out of scope — flag this as "no fabrication-safe hook available; recommend author provide opening hook material"
