# Argument Pass Rules

## Scope: What This Pass Does

- Clarify existing claims that `diagnosis.md` flagged as vague — make the claim's scope, conditions, and target precise
- Tighten the connection between claims and their supporting evidence — ensure a reader can see why the evidence supports the claim
- Ensure each flagged claim is stated once, clearly, in the right location (per the revision plan)
- Flag (but do not invent) evidence gaps where a claim has no support — these flags are notes to the author, not rewrites

## DO NOT Touch (Out of Scope)

- Section structure and paragraph order — locked after the structure pass
- Sentence-level wording unrelated to claim precision or claim-evidence connection
- The author's actual position — clarify and make precise, do not strengthen or weaken the thesis or any individual claim
- Voice register and style — argument tightening must not make a casual piece sound academic
- Evidence and citations — do not add, alter, move, or remove citations; NEVER add new evidence

## Voice Preservation

- Argument strengthening must use the author's register, not academic-formal by default
- If the author makes claims conversationally ("I think X works because Y"), do not convert to formal assertion style ("It is argued that X functions as a result of Y") unless the preset's formality level requires it
- Check the preset's `voiceBehaviors` array before any rewrite — if "contractions allowed" or "first-person encouraged" appears, maintain that register

## Factual Integrity

- NEVER add new evidence, statistics, or citations — this is the hard constraint of this pass
- Only work with evidence the author provided in the draft
- If a claim is unsupported and the evidence gap cannot be addressed without fabrication, flag it: "Claim in paragraph N has no supporting evidence — requires author input" and leave the claim as-is
- Do not improve an argument by inferring what evidence the author "probably" had in mind — inference is fabrication
