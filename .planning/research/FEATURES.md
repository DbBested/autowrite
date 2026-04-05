# Feature Research

**Domain:** AI writing improvement and revision systems (iterative, preset-based, eval-driven)
**Researched:** 2026-04-05
**Confidence:** HIGH (table stakes and differentiators confirmed across multiple sources; anti-features verified against known failure modes)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Diagnose before rewriting | Every serious revision tool (ProWritingAid, Sudowrite) surfaces weakness before suggesting fixes. Users who have been burned by blind AI rewrites expect a diagnosis step. | MEDIUM | Must identify specific failure points (weak thesis, unclear structure, buried evidence) not generic impressions. |
| Explain changes made | Grammarly, ProWritingAid, and Sudowrite all provide rationale for every suggestion. Users will not accept unexplained rewrites — they need to learn or disagree. | MEDIUM | Explanation must be per-change, not a single summary. Diff output + rationale per pass. |
| Produce a diff between input and output | Any tool touching existing text must show what changed. Users need to accept/reject at the delta level, not re-read the entire revised piece. | MEDIUM | Full unified diff is fine for CLI context; must be human-readable. |
| Voice preservation by default | This is the top complaint about AI writing tools across every review source: AI strips author voice and produces generic output. Users assume a "revision" tool will preserve their style unless asked otherwise. | HIGH | Requires explicit voice-rule enforcement in prompts, not just a disclaimer. Hard to get right without a voice profile or example text. |
| Grammar and mechanics correction | All writing tools fix this. Users expect it as a baseline, not a feature. | LOW | Not a differentiator. Autowrite should handle it as part of a cleanup pass, not as a headline feature. |
| Support multiple writing forms | ProWritingAid has 20+ report types. Grammarly has 6 writing modes. Users expect the tool to understand that a blog post is not an argumentative essay. | MEDIUM | Autowrite's three presets (blog post, essay, technical explainer) satisfy this at MVP. Form-aware passes are the implementation. |
| Preserve factual integrity | Users submitting drafts with citations, statistics, or specific claims assume the tool will not alter those claims. Any tool that silently changes factual content is a liability. | HIGH | This is a constraint as much as a feature. Verified by the well-documented ~36% citation hallucination rate in LLMs. Must be enforced at the prompt level per pass. |
| Iterative improvement (multiple passes) | Sudowrite's revision flow, ProWritingAid's report cycle, and Thesify's feedback loop all confirm that users expect to run multiple focused passes, not one mega-rewrite. | HIGH | Autowrite's staged pass architecture (diagnose → plan → structure → clarity → argument → etc.) directly satisfies this. Pass isolation is the key implementation requirement. |
| Produce a final, clean revised draft | Whatever the intermediate steps, the user needs a single output file they can use. Multi-pass tools must consolidate to one deliverable. | LOW | Simple file output requirement. Complexity is in the revision passes, not the output format. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Preset schema with full voice + structure + rubric spec | No competitor bundles voice rules, structural expectations, goal definitions, and evaluation rubric into a single reusable artifact. Grammarly's "tone modes" are shallow; ProWritingAid's reports are form-agnostic. A fully specified preset makes revision reproducible and transferable. | HIGH | Preset schema must define: form, goals, per-stage instructions, voice rules, structure expectations, rubric criteria, constraints, and transformation defaults. Preset creation (analyze examples → infer schema → confirm) is itself a differentiator. |
| Specialized eval agent (separate from writing agent) | All major competitors self-evaluate using the same model that generated the rewrite. This produces sycophantic scores. A separate, hyper-critical eval agent with criterion-level scoring (novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity) is rare and valuable. | HIGH | Eval consistency across runs is the hard requirement. Agent must be prompted to be adversarial, not supportive. Confirmed by research: automated scoring that maps to rubric dimensions outperforms self-assessment. |
| Eval-driven self-improvement loop for system assets | No consumer writing tool mutates its own prompts or presets using eval scores. This is an "Auto Research"-style capability borrowed from ML tooling (PromptBreeder, PromptWizard). Enables systematic improvement of the system itself, not just individual drafts. | HIGH | This is the highest-complexity feature and the hardest to find in competing tools. Mutation acceptance rule (aggregate improves, no critical regressions, factual integrity and voice preservation pass) must be strictly enforced. |
| Revision plan before applying changes | Most tools apply suggestions immediately. A generated revision plan (what will change and why, ordered by priority) gives users the ability to scope, approve, or redirect the revision before any text is altered. | MEDIUM | Plan is a structured document, not a free-form paragraph. Should reference specific weaknesses from the diagnosis. |
| Preset creation from example texts | Users can submit 1-3 examples of writing they admire and get a synthesized, editable preset that captures form, voice, and structure. Jasper's "Jasper IQ" does brand voice training but produces opaque style guides. Autowrite's preset is fully inspectable and editable. | HIGH | This is the primary preset creation flow. The inferred fields must be shown to the user before saving — no silent preset creation. |
| Claude Code-native workflow (no GUI, fully inspectable) | Every revision artifact (draft, plan, eval, diff, preset, log) is a local file. Users can inspect, edit, version-control, and script around the entire system. No competitor in the consumer space does this. Targets developers and writers who live in Claude Code. | MEDIUM | This is as much an architecture choice as a feature. Inspectability and hackability are the value proposition, not a specific UI feature. |
| Form-aware staged passes (not form-agnostic generic improvement) | Hemingway is purely readability-focused. Grammarly's passes are form-agnostic. ProWritingAid's reports are run-on-demand. Autowrite's preset-driven pass sequence means the sequence, depth, and criteria of each pass are tuned to the writing form. An argumentative essay gets an objection-steelmanning pass; a technical explainer does not. | HIGH | Pass selection and sequencing must be driven by the active preset, not hardcoded. This requires preset schema to specify which passes are active and in what order. |
| Structured eval snapshot as a persistent artifact | No consumer tool saves a normalized, criterion-level eval score alongside the draft for later comparison. Autowrite's eval snapshots enable before/after comparison, trend analysis over a project, and self-improvement loop input. | MEDIUM | Eval snapshot format must be stable and machine-readable (JSON). Schema: criterion → score → explanation → failure_points. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| First-draft generation from scratch | Users see AI writing tools and assume they can generate from nothing. | Autowrite's value is iterative improvement, not blank-page generation. First-draft generation is a different product (Jasper, Sudowrite, Copy.ai). Building it muddies the core value and creates scope creep that compromises revision quality. | Explicitly gate the system: require a draft or notes as input. The "notes → polished piece" flow is already supported as a form of revision from a rough starting point. |
| Real-time suggestion-as-you-type | Grammarly's inline UI is familiar and frequently requested. | Autowrite is Claude Code-native and operates on complete drafts, not live text streams. Real-time suggestions require a GUI, an event loop, and delta-aware diffing infrastructure that adds enormous complexity for no additional revision quality. | Batch revision model: user submits full draft, receives full revised output. This is a deliberate design choice, not a limitation. |
| Integration with Google Docs, Notion, Obsidian, etc. | Users want their revision tool where their writing lives. | Each integration is a maintenance surface, an authentication layer, and a platform-specific API. None of them improve revision quality. The integration problem is a distribution problem, not a product quality problem. | Users can copy-paste from any tool. The Claude Code-native file system approach is simpler and more durable. Defer integrations to v2+ only after core revision quality is proven. |
| More than three presets in v1 | Users will immediately request "newsletter," "LinkedIn post," "personal essay," "README." | Each preset requires hand-tuning the voice rules, structure expectations, stage sequence, and rubric. A poorly tuned preset produces worse results than a well-tuned generic prompt. Three presets, tuned deeply, is better than ten presets tuned shallowly. | Ship three high-quality presets. Preset creation flow (from examples) lets power users build their own. Expand to additional first-party presets in v2 after validation. |
| Aggressive rewrite mode as default | Users frustrated with weak AI suggestions want a "just fix it" button. | Aggressive rewriting systematically destroys author voice. This is the top complaint across every competitor. Voice drift is a violation of Autowrite's core constraint. | Aggressive rewrite is an opt-in pass, not default behavior. Default mode is minimal-intervention improvement with explicit voice-preservation rules active. Users who want aggressive rewriting can invoke it explicitly per pass. |
| AI-generated citations and references | Users want AI to find supporting evidence for their claims. | LLMs fabricate citations at a ~36% rate (confirmed by GPTZero analysis of ICLR 2026 submissions). No writing improvement tool should generate new citations. This is a known, high-severity failure mode. | Eval agent flags unsupported claims as a rubric item ("evidence" criterion). The system identifies where evidence is weak and tells the user — it does not fabricate evidence to fill the gap. |
| Single-shot mega-rewrite (one prompt, full document) | Seems faster. Users who don't know about staged revision assume one call is sufficient. | Single-shot rewrites accumulate all failure modes simultaneously: voice drift, factual alteration, structural changes that obscure the original argument, uncontrolled scope expansion. Staged passes allow each problem to be addressed in isolation with appropriate constraints per pass. | Staged pass architecture is mandatory. The revision plan step makes the multi-pass approach transparent to users so they understand why it takes multiple steps. |
| Tone adjustment sliders / style intensity controls | Every commercial tool has these (Grammarly's "formality" slider, Jasper's tone presets). | Tone sliders are shallow proxies for voice. They adjust superficial markers (contractions, formality) without understanding the author's actual voice patterns. This produces consistent-sounding but still generic output. | Voice rules in the preset schema capture actual voice characteristics (sentence rhythm, hedging patterns, use of first person, vocabulary register) extracted from example texts. This is deeper and more accurate than a slider. |
| Auto-publish or export to CMS | Some writing tools offer direct publishing to WordPress, Ghost, etc. | Out of scope for a revision system. Writing quality improvement has nothing to do with publication pipelines. Adding CMS integration conflates content creation workflow with content quality tooling. | Users export the final revised draft file. Anything beyond that is a different tool. |

## Feature Dependencies

```
Staged revision passes
    └──requires──> Revision plan
                       └──requires──> Draft diagnosis

Preset-driven pass selection
    └──requires──> Preset schema (form + goals + stage list + voice rules + rubric)

Eval agent scoring
    └──requires──> Preset schema (rubric criteria)
    └──requires──> Staged revision passes (before/after drafts)

Self-improvement loop (asset mutation)
    └──requires──> Eval agent scoring
    └──requires──> Eval snapshot (persistent artifact)

Preset creation from examples
    └──requires──> Preset schema (schema must exist before examples can be mapped to it)

Voice preservation enforcement
    └──requires──> Preset schema (voice rules field)
    └──enhances──> Staged revision passes (voice-preservation constraint active per pass)

Diff output
    └──requires──> Staged revision passes (need before + after to diff)

Factual integrity enforcement
    └──requires──> Staged revision passes (pass-level constraint, not post-hoc check)

Eval snapshot (persistent artifact)
    └──enhances──> Self-improvement loop
    └──enhances──> Before/after comparison
```

### Dependency Notes

- **Staged revision passes requires revision plan:** The plan determines which passes run, in what order, and with what scope. Running passes without a plan is the single-shot mega-rewrite anti-feature.
- **Preset schema is the foundational artifact:** Voice rules, rubric criteria, pass selection, and structural expectations all live in the preset. Every other system feature depends on the preset schema being well-defined first.
- **Eval agent requires preset rubric:** The eval agent must score against a preset-specific rubric, not a generic quality heuristic. Generic evaluation is what every competitor does and it produces inconsistent, uninformative scores.
- **Self-improvement loop requires eval agent + snapshot:** Mutation acceptance (keep or discard a mutated asset) is impossible without a reliable, consistent eval baseline. Building the loop before the eval system is stable is wasted work.
- **Voice preservation enhances staged passes:** Voice rules must be injected into every pass that touches prose, not applied as a final post-processing step. Post-hoc voice restoration is harder and less accurate than voice-preservation-as-constraint.

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] Draft diagnosis — surfaces specific weaknesses before any rewriting occurs
- [ ] Revision plan generation — structured plan from diagnosis, user-visible before passes begin
- [ ] Staged revision passes (at minimum: structure, clarity, argument, tone, concision, final review) — controlled per-form improvement
- [ ] Three hand-tuned presets (blog post, argumentative essay, technical explainer) — sufficient coverage for target users
- [ ] Voice preservation enforcement via preset voice rules — default behavior, not opt-in
- [ ] Factual integrity constraint active on all passes — non-negotiable safety property
- [ ] Diff output (input vs. revised draft) — user must see exactly what changed
- [ ] Change explanation per pass — rationale for what each pass did and why
- [ ] Eval agent with criterion-level scoring — diagnosis is only useful if there is a consistent quality signal to improve against
- [ ] Eval snapshot (JSON artifact per run) — required for before/after comparison and self-improvement loop input

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Self-improvement loop for preset mutation — add once eval agent scoring is proven consistent across runs
- [ ] Preset creation from example texts — add once preset schema is stable and well-understood
- [ ] Notes-to-draft flow (rough outline → polished piece) — add once standard draft revision is validated

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Additional first-party presets (newsletter, business memo, personal essay, README) — defer until three v1 presets are thoroughly validated and user demand for specific new forms is confirmed
- [ ] Adapt-a-piece flow (transform one form to another, e.g., blog → essay) — requires two presets and a specialized bridging pass; defer until core revision is stable
- [ ] External tool integrations (Google Docs, Notion, Obsidian) — defer indefinitely unless user demand is overwhelming and does not compromise core quality

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Draft diagnosis | HIGH | MEDIUM | P1 |
| Revision plan generation | HIGH | MEDIUM | P1 |
| Staged revision passes | HIGH | HIGH | P1 |
| Three hand-tuned presets | HIGH | HIGH | P1 |
| Voice preservation enforcement | HIGH | HIGH | P1 |
| Factual integrity constraint | HIGH | MEDIUM | P1 |
| Diff output | HIGH | LOW | P1 |
| Change explanation per pass | HIGH | MEDIUM | P1 |
| Eval agent (criterion-level scoring) | HIGH | HIGH | P1 |
| Eval snapshot (JSON artifact) | MEDIUM | LOW | P1 |
| Self-improvement loop (asset mutation) | HIGH | HIGH | P2 |
| Preset creation from examples | HIGH | HIGH | P2 |
| Notes-to-draft flow | MEDIUM | MEDIUM | P2 |
| Additional first-party presets (v2) | MEDIUM | HIGH | P3 |
| Adapt-a-piece flow | MEDIUM | HIGH | P3 |
| External integrations | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when core is validated
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Grammarly / ProWritingAid | Sudowrite | Hemingway Editor | Autowrite Approach |
|---------|--------------------------|-----------|-------------------|-------------------|
| Pre-revision diagnosis | ProWritingAid has report types; no explicit "diagnose first" gate | Feedback tool on demand; no mandatory diagnosis step | Readability flags only (passive voice, sentence length) | Mandatory diagnosis pass before any revision begins |
| Form-aware passes | Grammarly has 6 tone modes (shallow); ProWritingAid reports are form-agnostic | Fiction-focused (Show Not Tell, Expand, Rewrite); not generalized | Form-agnostic readability only | Preset-driven pass sequence tuned to writing form |
| Voice preservation | Jasper IQ learns brand voice; others are weak on this | Muse calibrates to prose samples | No AI voice features | Voice rules in preset schema, enforced per pass |
| Eval with criterion-level scores | ProWritingAid's reports cover style/grammar/pacing; no structured rubric scoring | No eval system | Readability score only | Specialized eval agent with rubric from preset; JSON snapshot per run |
| Self-improvement loop | None in any consumer tool | None | None | Auto Research-style preset/prompt mutation with eval-gated acceptance |
| Diff output | Grammarly shows inline suggestions; ProWritingAid highlights issues | Tracked changes for rewrites | No diff feature | Full diff between input and revised draft per run |
| Revision plan | None; suggestions are immediate | None | None | Structured revision plan generated from diagnosis, shown before passes begin |
| Reusable preset / schema | Grammarly style profiles (shallow); Jasper brand voices (opaque) | None | None | Full preset schema: form, goals, stage list, voice rules, rubric, constraints |
| Factual integrity constraint | None explicitly; tools will rewrite facts | None; aggressive rewrite by default | No rewriting | Hard constraint on all passes: never alter facts, citations, or author stance |
| Claude Code native / inspectable | None; all GUI-based with opaque internals | GUI-based | GUI-based | All artifacts are local files; fully inspectable, version-controllable, scriptable |

## Sources

- ProWritingAid feature set: [ProWritingAid vs. Sudowrite comparison](https://sudowrite.com/blog/prowritingaid-vs-sudowrite-which-is-better-for-fiction-writers/) — MEDIUM confidence (product marketing)
- Sudowrite revision feature breakdown: [Sudowrite review — Kindlepreneur](https://kindlepreneur.com/sudowrite-review/) — MEDIUM confidence (third-party review)
- Grammarly/ProWritingAid/Hemingway comparison: [SaasCompared 2026](https://saascompared.io/blog/grammarly-vs-prowritingaid-vs-hemingway/) — MEDIUM confidence (current review)
- Hemingway Editor 2026 update: [Become A Writer Today](https://becomeawritertoday.com/hemingway-app-vs-grammarly/) — MEDIUM confidence (third-party review)
- Voice preservation failure as top complaint: [My Writing Twin AI assistant comparison 2026](https://www.mywritingtwin.com/blog/ai-writing-assistant-comparison-2026) — MEDIUM confidence (WebSearch verified, multiple sources agree)
- Citation hallucination rate (~36%): [Fake Citation Checker — aidetectors.io 2026](https://www.aidetectors.io/blog/fake-citation-checker) — MEDIUM confidence (WebSearch; verified against known LLM literature)
- Eval-driven development methodology: [Medium — Eval-Driven Development 2026](https://medium.com/@adnanmasood/eval-driven-development-the-missing-discipline-in-the-agentic-ai-lifecycle-5acaea1a49f9) — MEDIUM confidence
- Self-referential self-improvement / PromptBreeder: [Promptbreeder paper — OpenReview](https://openreview.net/forum?id=HKkiX32Zw1) — HIGH confidence (peer-reviewed research)
- Iterative revision improving writing quality: [AAAI 2026 — Democratizing Writing Support with AI](https://ojs.aaai.org/index.php/AAAI/article/view/41167) — HIGH confidence (peer-reviewed)
- AI track changes transparency feature: [Solve Intelligence blog](https://www.solveintelligence.com/blog/post/feature-update-ai-track-changes) — MEDIUM confidence (vendor blog, verifies industry direction)
- Multi-agent writing system architecture: [TrySight blog 2026](https://www.trysight.ai/blog/multi-ai-agent-writing-system) — LOW confidence (marketing content, architecture pattern is directionally correct)

---
*Feature research for: AI writing improvement and revision systems*
*Researched: 2026-04-05*
