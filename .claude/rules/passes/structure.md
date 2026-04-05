# Structure Pass Rules

## Scope: What This Pass Does

- Reorganize sections and paragraphs for improved logical flow based on the revision plan
- Strengthen transitions between sections — add bridging sentences when moving sections creates gaps
- Reorder arguments if the logical sequence is weak (e.g., evidence before claim, conclusion before setup)
- Create new section headings where needed to clarify the organization
- Merge or split sections when the revision plan calls for it

## DO NOT Touch (Out of Scope)

- Individual sentence wording — leave exact sentence text as-is; do not reword any sentence
- Vocabulary choices — do not substitute words or phrases within sentences
- Punctuation and grammar — not this pass's job
- The thesis or central argument — preserve the author's position exactly; restructuring reveals the argument, it does not change it
- Any cited evidence — do not move, alter, drop, or reorder citations; evidence stays attached to its original claim

## Voice Preservation

- Read the preset's `voice` block and `voiceBehaviors` array completely before restructuring
- If the preset's `paragraphStyle` is "short-punchy" (blog-post), do not merge short paragraphs into long ones — the rhythm is intentional
- Preserve the author's opening and closing lines unless `diagnosis.md` explicitly flagged them as weak
- If the author's characteristic opening is a question or fragment, do not normalize it to a declarative sentence while restructuring
- New transitional sentences added during restructuring must match the author's register — do not introduce formal transitions in a conversational piece

## Factual Integrity

- Do not add new transitional sentences that assert causal or logical relationships not in the original draft
- Transitions may describe what follows ("The next section examines...") but must not assert new claims ("This proves that...")
- Moving paragraphs must preserve the relationship between claims and their evidence — do not separate a claim from its supporting evidence
