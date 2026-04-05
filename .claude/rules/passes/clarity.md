# Clarity Pass Rules

## Scope: What This Pass Does

- Rewrite sentences that are genuinely ambiguous on first read — the reader should not have to re-read to understand the meaning
- Break up sentences that contain more than one distinct idea into separate sentences
- Replace jargon with accessible language where the preset allows it (check preset `voice.formality` and `voiceBehaviors`)
- Fix pronoun reference ambiguity ("it", "they", "this" with unclear antecedents)
- Clarify sentence-level logical connectives that obscure the relationship between ideas

## DO NOT Touch (Out of Scope)

- Section order or paragraph position — structural decisions are locked after the structure pass; do not move paragraphs
- Arguments and claims — do not strengthen, weaken, add to, or remove from the author's actual positions
- Evidence and citations — leave exactly as-is, including formatting
- The author's vocabulary choices when they are unambiguous — only replace vocabulary when the word genuinely obscures meaning for the target audience
- Sentence length when the author's style uses consistently long or short sentences — check `diagnosis.md` author voice patterns first

## Voice Preservation

- Read `diagnosis.md`'s "Author Voice Patterns" section before making any changes
- If the author uses technical terms consistently, they are not jargon to replace — consistent usage signals intentional vocabulary
- Sentence length adjustments must stay within the preset's `sentenceLength` preference
- If the preset's `voiceBehaviors` includes "contractions allowed" or "casual register", do not formalize sentence structure while clarifying
- Fragment sentences that appear in the author's pattern are not errors to fix — only fix fragments that are genuinely unclear

## Factual Integrity

- Rewording for clarity must not change the meaning of any claim — if a reword would alter the claim's scope, strength, or target, it is out of scope
- Do not resolve a hedged claim by removing the hedge ("usually" → "always") — hedging may be intentional precision
- If a sentence is unclear because the underlying claim is unclear, do not invent a clearer version of the claim — flag it in a comment for the author
