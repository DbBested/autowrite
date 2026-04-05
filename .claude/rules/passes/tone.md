# Tone Pass Rules

## Scope: What This Pass Does

- Adjust register consistency throughout the piece — inconsistent formality shifts (casual opener, suddenly formal body, casual close) undermine reader trust
- Ensure consistent formality level per the preset's `voice.formality` setting throughout the entire piece
- Fix shifts between casual and formal that are not intentional stylistic choices (check `diagnosis.md` for noted intentional patterns)
- Adjust address forms (you/we/one/they) for consistency per the preset's `voiceBehaviors` array
- Standardize any inconsistent second-person or first-person usage across sections

## DO NOT Touch (Out of Scope)

- Section structure — locked after the structure pass
- Arguments and claims — tone adjustments must not alter the meaning or strength of any position
- Evidence and citations — do not rewrite evidence presentation to change its register
- Paragraph ordering — not this pass's scope

## Voice Preservation

- This pass IS about voice — read the preset's `voice` block and `voiceBehaviors` array completely before making any changes; this is the most important instruction for this pass
- Every change must move toward the preset's defined voice, not toward generic polished prose
- If the preset says "contractions allowed", do not remove contractions in the name of "consistency"
- If the preset says "casual register", a formal sentence is out of scope to "correct" — it is only out of scope if it is inconsistent with the rest of the piece AND the preset
- Intentional register shifts (e.g., a sudden formal tone for a serious point in an otherwise casual piece) may be in `diagnosis.md` as noted patterns — do not flatten them

## Factual Integrity

- Tone adjustments must not change the meaning or strength of any claim
- Do not replace hedged language with confident language in the name of "consistent assertive tone" — hedging may be intentional precision
- Removing qualifiers ("I think", "in my experience") changes the epistemological claim, not just the tone — these are out of scope for this pass
