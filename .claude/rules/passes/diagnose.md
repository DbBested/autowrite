# Diagnose Pass Rules

## Scope: What This Pass Does

- Read the draft and identify specific, located weaknesses — name the paragraph and sentence where each issue occurs ("buried thesis in paragraph 4, sentence 2", not "thesis is weak")
- Classify the input as rough notes or a polished draft using the detection criteria below and record the classification as the first line of `diagnosis.md`: `Input classified as: [rough notes | polished draft]`
- Note the author's characteristic voice patterns (contractions, fragments, first-person, register, sentence length habits) for preservation in later passes
- Flag unsubstantiated claims, structural gaps, and evidence weaknesses by location — do not suggest rewrites, only name problems and their exact location
- Produce `diagnosis.md` as the sole output of this pass

## Input Classification Criteria

**Rough Notes** if three or more of these are true:
- Contains bullet points or numbered lists as primary structure
- Contains sentence fragments (not stylistic — genuinely incomplete thoughts)
- Contains "TODO:", "expand this:", or similar placeholder notes
- Fewer than 40% of the expected word count for this writing form
- Claims without supporting evidence or elaboration

**Polished Draft** if:
- Full sentences throughout
- Recognizable introduction, body, and closing structure
- Arguments have at least partial evidence
- Word count is 60%+ of expected form length

## DO NOT Touch (Out of Scope)

- The draft text itself — this pass is read-only analysis; do not modify any word in the source
- Do not suggest rewrites or rewordings — only name problems and locations
- Do not produce a revision plan (that is `revision-plan` pass scope)
- Do not evaluate the author's stylistic choices as weaknesses unless the preset's rubric explicitly rates them as deficiencies

## Voice Preservation

- Before diagnosing, read the active preset's `voice` block and `voiceBehaviors` array
- Note the author's characteristic patterns explicitly in `diagnosis.md` — these are not bugs to fix; they are anchors for every subsequent pass
- If the author uses fragments intentionally (e.g., blog-post conversational style), note this as an established pattern, not a weakness
- Voice observations go into a dedicated "Author Voice Patterns" section in `diagnosis.md`

## Factual Integrity

- Flag any unsubstantiated claims by location — do not invent supporting evidence or suggest what evidence might exist
- Never fabricate statistics, citations, or examples when describing what is missing
- "Claim in paragraph 3 has no supporting evidence" is correct; "This claim could be supported by citing X" is out of scope for this pass
