# Precision Pass Rules

## Scope: What This Pass Does

- Tighten technical accuracy throughout the piece — replace vague quantifiers with specific values where the draft provides them elsewhere
- Ensure technical terms are used consistently — if the draft uses "function" and "method" interchangeably for the same concept, standardize to one term
- Fix imprecise language that could mislead a practitioner (e.g., "the function returns data" → "the function returns a JSON object" if the draft says so elsewhere)
- Identify and correct technically incorrect statements where the draft provides the correct information elsewhere

## DO NOT Touch (Out of Scope)

- Section structure — locked after the structure pass
- Non-technical prose style — this pass is for technical accuracy, not general writing quality
- Explanatory analogies — analogies serve a different purpose than precise technical description; they are correct to be imprecise in ways that aid understanding
- Examples section — that is the examples pass's domain; do not modify example content here

## Voice Preservation

- Technical precision should not make the prose robotic — clarity of expression and technical accuracy are not in conflict
- Read the preset's `voiceBehaviors` — if the style is "accessible-expert", maintain warmth and approachability while tightening accuracy
- Do not remove the author's characteristic ways of explaining technical concepts in favor of pure specification language unless the preset requires it
- If the author explains both the concept and the mechanism, do not reduce this to mechanism-only in the name of precision

## Factual Integrity

- Do not add technical details not in the original draft — if a value, spec, or behavior is not stated in the draft, do not infer or supply it
- If a technical specification is unclear or incomplete, flag it: "Specification for X is not stated in draft — value or behavior is unverified"
- Do not "correct" a technical claim by introducing external knowledge not present in the draft — the author's stated spec is the ground truth for this document
- If the draft contains a genuine technical error (inconsistency within the draft itself), flag it for author review rather than silently correcting it
