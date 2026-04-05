# Examples Pass Rules

## Scope: What This Pass Does

- Improve the quality of existing examples — ensure each example illustrates exactly the point it is attached to, not a tangential or adjacent point
- Ensure each introduced concept has at least one concrete example; flag concepts with no example (do not invent examples)
- Ensure code examples (if present) match the described behavior in the surrounding text
- Tighten examples so they are efficient — remove scaffolding in an example that does not contribute to the point being illustrated

## DO NOT Touch (Out of Scope)

- Section structure — locked after the structure pass
- Technical explanations — those are the precision pass's domain; do not modify explanatory content while improving examples
- Arguments and claims — examples illustrate; they do not make new claims
- Non-example content — this pass focuses only on example blocks and illustrative content

## Voice Preservation

- Examples should match the tone of the surrounding explanation — do not make examples overly formal if the explanation is conversational, and do not make examples casual if the surrounding text is formal
- The author's characteristic example style (code blocks, analogies, numbered steps, narrative illustration) should be preserved — do not convert analogy-style examples to code blocks or vice versa without a clear reason
- Read the preset's `voiceBehaviors` to understand the expected example register for this form

## Factual Integrity

- Do not invent new examples — improve existing ones only
- If a concept has no example, flag it: "Concept in paragraph N has no illustrative example — recommend author provide one" — do not fabricate an example
- Never alter code examples to show behavior the author did not describe — if the code example is incorrect per the surrounding text, flag the inconsistency for the author rather than "fixing" it by rewriting the code
- Do not add hypothetical examples as if they were real cases — "for example, if..." framing that introduces invented scenarios is out of scope
