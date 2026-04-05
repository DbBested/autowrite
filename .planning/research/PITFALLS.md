# Pitfalls Research

**Domain:** AI writing improvement / revision workflow system (Claude Code native)
**Researched:** 2026-04-05
**Confidence:** HIGH (voice/eval pitfalls), MEDIUM (self-improvement loop specifics, Claude Code integration edge cases)

---

## Critical Pitfalls

### Pitfall 1: Voice Homogenization — The Model's Default Wins

**What goes wrong:**
The revision system rewrites the author's prose and the output reads well by general standards, but the distinctive voice is gone. Register, vocabulary, and emotional tone drift toward the model's statistical average — "professional but approachable," even when the author writes with sharp specificity or deliberate informality. This is the most common complaint from users of AI writing tools.

**Why it happens:**
LLMs are trained on broad corpora and optimized for readability. Generic language is statistically safer than distinctive language. When asked to "improve" or "clarify" text, the model defaults to register smoothing and vocabulary normalization. It does not erase voice intentionally — it simply has no mechanism for preferring the author's specific patterns over its own defaults unless explicitly constrained.

**How to avoid:**
- Never issue open-ended "improve this" instructions. Every revision pass must be scoped: "improve structure without changing vocabulary" or "tighten argument without altering register."
- The diagnose pass must extract voice fingerprints (sentence length distribution, characteristic vocabulary, register markers, rhetorical patterns) before any revision pass runs. These fingerprints become hard constraints on all subsequent passes.
- Voice preservation must be an eval criterion with explicit failure criteria, not a soft guideline.
- Treat voice drift as a hard regression: any revision that degrades voice score below a threshold should be rejected, regardless of other score improvements.

**Warning signs:**
- Output sentences are longer and more syntactically uniform than the input.
- The draft gains hedging language ("it is worth noting that," "this suggests") not present in original.
- Distinctive vocabulary is replaced with more common synonyms.
- Emotional specificity flattens ("furious" becomes "frustrated," "delighted" becomes "pleased").
- User feedback: "This sounds like ChatGPT, not me."

**Phase to address:**
Voice preservation must be designed into the preset schema (Phase: Preset System) and enforced in the eval rubric (Phase: Eval System). The diagnose pass must extract fingerprints before any modification (Phase: Writing Engine Core). This is foundational — get it wrong in phase 1 and every subsequent phase builds on a broken assumption.

---

### Pitfall 2: Single-Shot Rewriting Disguised as Staged Passes

**What goes wrong:**
The system is designed with named passes (structure, clarity, tone, etc.) but each pass secretly attempts a full rewrite of whatever it touches. The cumulative effect is that by pass 3 or 4, the output bears little resemblance to the input. Staging is theatrical rather than structural.

**Why it happens:**
Without explicit scope constraints, an LLM given a "clarity pass" prompt will opportunistically fix structure, argument, tone, and voice while it is in the text. The model cannot resist. Without hard boundaries on what each pass is permitted to touch, every pass becomes a full rewrite.

**How to avoid:**
- Each pass prompt must contain explicit DO NOT touch instructions: "On this clarity pass: simplify sentence structure and replace vague nouns with specific ones. Do NOT restructure paragraphs, do NOT change argument order, do NOT alter vocabulary register."
- After each pass, run a diff-aware check: if more than X% of tokens changed, flag the pass as over-reaching and do not accept it.
- Design passes with ranked priority: earlier passes make structural decisions that later passes must respect and cannot override.
- The revision plan pass should generate explicit constraints that get passed as context to each subsequent pass.

**Warning signs:**
- Diffs show wholesale paragraph replacement rather than targeted edits.
- A "tone" pass also changes argument structure.
- The final output has no continuity with the original sentence structure.
- Pass outputs are nearly the same length regardless of input length (indicates rewriting rather than editing).

**Phase to address:**
Pass scope design (Phase: Writing Engine Core — pass architecture). Revision plan generation must produce per-pass constraints. Diff-aware validation must be built into pass execution from the start.

---

### Pitfall 3: Eval Agent Using the Same Model as the Writing Agent

**What goes wrong:**
The eval agent is Claude, and the writing agent is Claude. Claude exhibits measurable self-preference bias — it systematically rates its own outputs higher than equally good outputs from other sources. This means the eval will inflate scores for any output the writing agent produces, making the self-improvement loop a closed positive-feedback system that optimizes for "sounds like Claude" rather than "is actually good writing."

**Why it happens:**
Research demonstrates that GPT-4o and Claude 3.5 Sonnet both display self-preference bias and family-bias. LLMs assign lower perplexity to their own outputs and score them higher as a result. Because Autowrite runs everything in Claude Code on Claude, the eval agent and writing agent share the same statistical priors.

**How to avoid:**
- The eval agent must be architecturally separated from the writing agent even if both run on Claude. This means: separate context windows, separate system prompts, no shared conversation state.
- The eval agent's prompt must be explicitly adversarial and hyper-critical: "Your job is to find every weakness. You are not trying to help. You are trying to break the argument." Hostile framing counteracts self-preference bias partially.
- Eval criteria must be anchored to observable, specific signals rather than holistic quality judgments. "Count the number of sentences that begin with 'The'" is more reliable than "rate voice preservation 1-10."
- Where possible, the eval agent should compare the revised output against the original using explicit before/after analysis rather than scoring in isolation.
- Log raw scores and the model version producing them. If the system is ever ported to a different model, recalibrate eval baselines.

**Warning signs:**
- Eval scores trend uniformly upward even when subjective quality has not improved.
- The eval agent agrees with every revision the writing agent makes.
- Voice preservation scores are consistently high even as outputs sound more generic.
- No output ever fails the eval acceptance threshold.

**Phase to address:**
Eval system design (Phase: Eval Agent). The separation of eval from writing must be architectural, not just a prompt instruction. Address before the self-improvement loop is wired up.

---

### Pitfall 4: Goodhart's Law in the Self-Improvement Loop

**What goes wrong:**
The self-improvement loop mutates prompts and presets, evals before and after, and keeps improvements. Within a small number of iterations, the system learns to optimize for the metrics rather than the underlying quality they were meant to measure. Scores trend up. Actual writing quality stagnates or degrades. Common manifestation: the optimizer discovers that verbose, confident-sounding output scores higher on "clarity" and "structure" and begins producing padded text that scores well and reads poorly.

**Why it happens:**
Goodhart's Law: when a measure becomes the target, it ceases to be a good measure. This is not a theoretical concern — it has been observed in LLM leaderboard gaming, RLHF training, and prompt optimization experiments. Self-improving systems that optimize against their own evals are especially vulnerable because there is no external ground truth to check against.

**How to avoid:**
- Hold out a fixed set of human-written reference examples that never participate in the improvement loop. Periodically score mutated prompts/presets against this holdout set. If holdout scores diverge from loop scores, the loop is gaming its metrics.
- Require that mutations improve aggregate score without any critical criterion regressing below a hard floor. "No regression" guards prevent the optimizer from trading voice for clarity.
- Include at least one eval criterion that is structurally resistant to gaming: word count ratio (output/input), sentence start diversity, use of distinctive source vocabulary. These are harder to inflate than holistic scores.
- Limit iteration depth. After N iterations without real holdout improvement, stop and require human review.
- Log every mutation and its scores permanently. Never overwrite — the history is necessary to detect drift.

**Warning signs:**
- Loop scores improve each iteration but holdout set scores flatline.
- Outputs get longer over iterations without corresponding increase in argument density.
- The improvement loop converges very fast (fewer than 5 iterations) — signals it found a shortcut, not genuine quality.
- Distinct writing samples begin to converge in style after multiple passes.

**Phase to address:**
Self-improvement loop design (Phase: Autoloop). Must be built with holdout validation from the start. The acceptance rule in PROJECT.md ("aggregate score improves, no critical regressions") is necessary but not sufficient without the holdout mechanism.

---

### Pitfall 5: Diagnosis Without Form Awareness

**What goes wrong:**
The diagnose pass identifies "weaknesses" using generic writing criteria, not form-specific criteria. A blog post is diagnosed for weak thesis statement (essay criteria). A technical explainer is diagnosed for not having a strong opening hook (blog criteria). The revision plan becomes noise, and the revision passes apply inappropriate transformations to structurally sound work.

**Why it happens:**
Without explicitly loading the preset before diagnosis, the model defaults to a generic "good writing" framework that blends criteria from multiple forms. The model does not know it is looking at a technical explainer unless told — and even when told, without a formal preset defining what "good technical explainer" means structurally, the model applies its priors.

**How to avoid:**
- Diagnosis must always load and apply the form-specific preset before running. The preset defines the evaluation criteria — the diagnose pass must not invent its own.
- The preset schema must include form-specific "success looks like" and "failure looks like" descriptions for every criterion. Not just a criterion name — a behavioral description.
- Create three distinct diagnosis prompt templates (one per preset) rather than a single generic diagnosis prompt with the preset appended.
- Test each preset's diagnosis pass against examples of both good and bad writing for that form, not just generic examples.

**Warning signs:**
- Diagnosis identifies "weak thesis" on a listicle (not a thesis-driven form).
- Diagnosis identifies "missing hook" on a technical explainer (wrong form priority).
- Diagnose output applies the same structural critique pattern to every submitted draft regardless of form.
- Preset field `form` is populated but diagnosis output does not reference it.

**Phase to address:**
Preset schema design (Phase: Preset System) and diagnose pass implementation (Phase: Writing Engine Core). The preset must be loaded first — diagnose must never run without a preset in context.

---

### Pitfall 6: CLAUDE.md / SKILL.md Bloat Causes Instruction Dropout

**What goes wrong:**
As the system grows, CLAUDE.md and skill files accumulate instructions, conventions, pass definitions, preset schemas, and examples. Claude begins ignoring specific instructions because they are buried in the noise. The effective reliable context range is roughly 200-256K tokens before performance degrades. Even well below that limit, instruction density beyond 150-200 items causes measurable consistency drops in Claude's ability to follow every rule.

**Why it happens:**
CLAUDE.md loads into every session unconditionally. Every token in the file consumes context before a single task token is processed. When the file grows beyond ~300 lines, Claude begins to lose precision on specific rules buried in the middle. Skill files have the same problem — a bloated SKILL.md describing all twelve revision passes is a context burden whether the current task uses two passes or all twelve.

**How to avoid:**
- Keep CLAUDE.md under 300 lines and restricted to repo-wide universal behavior only. Writing-specific behavior belongs in skill files.
- Use on-demand skill loading: each pass should have its own skill file loaded only when that pass runs. Do not load all pass definitions into every session.
- Pass-specific constraints (what each pass can and cannot touch) belong in the pass's own skill file or prompt template, not in a central configuration file.
- Periodically audit: if an instruction in CLAUDE.md has not been visibly enforced in the last N sessions, it probably is not being respected — investigate and tighten.

**Warning signs:**
- Claude applies a revision pass correctly in isolation but ignores a constraint when running the full pipeline.
- Instructions in the lower half of CLAUDE.md are followed less consistently than instructions in the top half.
- Adding a new rule to CLAUDE.md breaks an existing behavior (instruction conflict that Claude resolves by dropping one silently).
- Skills load fine in isolation but produce different behavior when the full pipeline is active.

**Phase to address:**
Architecture / CLAUDE.md structure design (Phase 1 / Foundation). The skill file structure must be designed for on-demand loading from the start. Retrofitting a bloated CLAUDE.md late in the project is painful.

---

### Pitfall 7: Factual Stance Mutation Without Author Awareness

**What goes wrong:**
During argument or evidence passes, the revision system strengthens claims, adds supporting assertions, or softens objections — and in doing so, silently shifts the author's position on contested claims. The diff looks clean (minor wording changes) but the argumentative stance of the piece has changed. The author publishes something they do not actually believe.

**Why it happens:**
The model is instructed to "strengthen the argument." Strengthening an argument sometimes means making claims more assertive, removing qualifications the author intended as honest hedges, or adding supporting logic the author did not endorse. The model does not distinguish between intentional ambiguity and unintentional weakness.

**How to avoid:**
- The diagnose pass must identify hedging language and flag whether it appears intentional (part of the author's epistemic position) or unintentional (weak writing). This flag must be passed to revision passes.
- Argument and evidence passes must be constrained: "strengthen clarity of existing claims, do NOT add new factual assertions, do NOT remove qualifications marked as intentional."
- Every argument pass output must be diffed against the original at the claim level, not just the token level. If a new factual assertion appears in the output that was not in the input, it must be flagged for human review.
- The constraint "System never invents citations, fabricates facts, or silently shifts author stance" from PROJECT.md must be implemented as an explicit post-pass validation check, not just a prompt instruction.

**Warning signs:**
- Evidence pass adds specific statistics or examples not present in the original draft.
- Argument pass removes qualifying language ("this suggests" → "this proves").
- Tone pass changes first-person claims to third-person assertions (distancing from author's direct voice).
- Revision explanation omits mention of stance changes.

**Phase to address:**
Writing Engine Core (argument, evidence, objection passes). The validation check for stance mutation must be built into the pass execution pipeline as a hard gate, not a soft heuristic.

---

### Pitfall 8: Eval Score Inconsistency Across Identical Inputs

**What goes wrong:**
The eval agent produces different scores for the same input in different runs. The self-improvement loop cannot detect real signal — a "better" mutation score may be noise. Users cannot trust whether a revision is genuinely better. The acceptance rule becomes meaningless.

**Why it happens:**
LLM judges exhibit high variance when criteria are vague or holistic. Research shows that if human evaluators would disagree on 40% of scores for a given rubric, the rubric is too vague. LLMs have equivalent variance on underspecified criteria. Temperature is also a factor — default temperature produces different scores on re-runs of the same input.

**How to avoid:**
- Eval criteria must be anchored to observable signals with specific score definitions. Not "is the hook engaging (1-5)" but "does the hook contain a specific concrete claim, image, or question? (yes=5, implicit=3, no=1)."
- Use temperature=0 (or lowest available setting) for the eval agent. Deterministic output is more important than creativity here.
- For each criterion, define the 1, 3, and 5 score cases with example sentences. Calibration examples reduce variance.
- Before deploying the eval system, run the same 10 test cases through the eval 3 times and measure variance. If any criterion has >1 point variance across runs, the criterion needs tighter specification.
- The self-improvement loop's acceptance threshold should account for eval variance: require improvement greater than the known noise floor, not just any positive delta.

**Warning signs:**
- Running eval twice on the same draft produces scores that differ by more than 1 point on any criterion.
- Different wording of the same quality judgment produces score swings of 2+ points.
- Eval scores correlate with output length rather than actual quality.
- Users report that obviously bad revisions pass eval and obviously good ones fail.

**Phase to address:**
Eval System design (Phase: Eval Agent). Calibration testing must be a required deliverable for the eval phase — not optional.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Single CLAUDE.md with all pass instructions | Simpler initial setup | Instruction dropout as system grows; voice rules ignored by pass 6 | Never — use skill files from the start |
| Generic diagnosis prompt (not form-specific) | One prompt to maintain | Diagnosis applies wrong criteria; revision plans are wrong-form by default | MVP only if single form is targeted |
| Self-eval (writing agent evals its own output) | No eval architecture needed | Self-preference bias inflates all scores; loop never detects real regressions | Never — architecturally separate eval from writing |
| Holistic eval scores ("quality 1-10") | Easy to prompt | High variance; gameable; meaningless for debugging | Never — always use criterion-level observable anchors |
| Voice preservation as prompt instruction only | No extra architecture | Voice drift proceeds unchecked; no signal when it happens | Never for a tool where voice preservation is a core promise |
| No holdout set for self-improvement loop | Loop starts immediately | Goodhart's Law kicks in within 10-20 iterations | Never if you ship the loop to real users |
| Mutation loop without permanent logging | Simpler filesystem | Impossible to audit drift, impossible to rollback bad mutations | Never — logs are cheap, rollbacks are priceless |

---

## Integration Gotchas

Autowrite is Claude Code native — no external services. Integration surface is the Claude Code environment itself.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CLAUDE.md loading | Putting pass-specific constraints in CLAUDE.md | Pass constraints belong in individual skill files loaded on demand |
| SKILL.md design | One monolithic skill file for all writing tasks | Separate skill files per pass; Claude loads only what the current pass needs |
| File-based state (runs/, evals/) | Overwriting previous run output | Always write to timestamped run directories; immutable history required for diff and regression detection |
| Diff generation | Relying on LLM to describe its own changes | Generate structural diffs programmatically (line-level or paragraph-level) before asking the model to explain them |
| Preset loading | Appending preset to the end of a long prompt | Load preset first; it is context that scopes everything else |
| Context window during full pipeline | Running all 12 passes in one conversation | Each pass should be a fresh context with only the relevant prior state injected; never chain passes in a single context window |

---

## Performance Traps

For Autowrite, "performance" means quality consistency across sessions, not throughput. These are the patterns that degrade consistency at scale.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Context accumulation across passes | Later passes contradict earlier passes; pass 8 undoes pass 3 | Fresh context per pass with only relevant prior constraints injected | After 4-5 chained passes in one window |
| Mutation loop without convergence detection | Loop runs 50 iterations and produces worse output than iteration 5 | Hard iteration cap; holdout evaluation; stop if holdout doesn't improve for N consecutive rounds | After ~10 iterations without holdout check |
| Eval rubric with open-ended criteria | Scores drift over model updates; same input scores differently after Claude updates | Anchored, observable criteria; re-calibrate after any model version change | After first model version update |
| Single preset covering multiple forms | Preset schema becomes internally contradictory; diagnosis gives conflicting signals | One preset per form; no shared "general" preset | When second form is added without dedicated preset |

---

## Security Mistakes

Autowrite is local-only and Claude Code native. The security surface is narrow but real.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing sensitive draft content in runs/ without access controls | Drafts with confidential content persisted in plaintext indefinitely | Document that runs/ is not encrypted; user should not submit confidential content unless they control filesystem access |
| Mutation loop modifying CLAUDE.md or skill files without human approval | Automated rewriting of core behavioral instructions; unpredictable behavior drift | Mutation loop must only mutate isolated prompt files in autoloop/; CLAUDE.md and skills/ are out of scope for mutation |
| Eval agent prompt contains examples from user drafts | Example leak across users if system is ever shared | Use synthetic calibration examples only; never store user content as eval anchors |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing only final output without diff | User cannot see what changed; cannot accept partial revisions | Always generate and surface the diff alongside the revised draft |
| No explanation of why changes were made | User either accepts blindly or rejects wholesale | Revision explanation is a required output artifact, not optional |
| Silent voice drift | User notices something is wrong but cannot articulate it | Voice score must appear in every eval output so users have a signal to react to |
| All-or-nothing acceptance | User must accept the entire revision or reject it | Structure output as diff blocks; user should be able to cherry-pick pass-level changes |
| Preset creation that infers too aggressively | User approves a preset that does not match their intent | Show every inferred field explicitly before saving; never silently write a preset |
| Eval scores without explanation | Scores feel arbitrary; user cannot improve from them | Every criterion score must include 1-2 concrete sentences explaining the rating |

---

## "Looks Done But Isn't" Checklist

- [ ] **Voice preservation:** Eval includes a voice criterion with anchored scoring — not just "sounds like the author." Verify with a test case where the original draft has a distinctive quirk (sentence fragments, unusual vocabulary) and confirm the revision retains it.
- [ ] **Factual integrity gate:** Post-pass validation checks that no new factual claims appear in the output that were not in the input. Verify by testing the argument pass on a claim-dense draft.
- [ ] **Eval consistency:** Run the same draft through eval three times at temperature=0. Scores must be identical. If any criterion varies, the rubric is too vague.
- [ ] **Pass scope enforcement:** Run the tone pass on a structurally flawed draft. Verify the pass does not fix the structure. If it does, scope constraints are not enforced.
- [ ] **Holdout set exists:** Before deploying the autoloop, a holdout set of 10 human-evaluated examples exists and is never used for training or calibration — only for drift detection.
- [ ] **Diff is programmatic:** The diff output is generated by a script, not described by the LLM. Verify by intentionally making a change the LLM would be unlikely to mention and confirm it still appears in the diff.
- [ ] **Preset approval gate:** Running preset creation on example texts shows every inferred field to the user before writing. Verify no silent preset writes occur.
- [ ] **CLAUDE.md length audit:** Before any phase launch, count lines in CLAUDE.md. If over 300, refactor into skill files before adding new instructions.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Voice homogenization shipped to users | HIGH | Re-design diagnose pass to extract voice fingerprints; add voice criterion to eval rubric; all previous preset outputs are unreliable until re-validated |
| Goodhart's Law — loop has gamed its metrics | HIGH | Discard loop history; re-design eval criteria with observable anchors; introduce holdout set; re-run from baseline |
| Eval inconsistency discovered post-loop | MEDIUM | Freeze mutation loop; audit all accepted mutations manually; tighten eval criteria; re-baseline scores on holdout set |
| CLAUDE.md bloat causing instruction dropout | MEDIUM | Audit which instructions are being followed; move non-universal instructions to skill files; re-test each pass in isolation |
| Factual stance mutation in shipped revisions | HIGH | Cannot auto-detect retroactively; surface all previous argument/evidence pass outputs to users with warning; add validation gate before re-enabling passes |
| Eval agent self-preference bias discovered | MEDIUM | Redesign eval prompts with adversarial framing; add holdout comparison; re-run eval calibration on known examples |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Voice homogenization | Phase: Preset schema + Eval system + Writing engine (diagnose pass) | Test: distinctive-voice draft survives all passes with voice score above threshold |
| Single-shot rewrite disguised as staged passes | Phase: Writing engine pass architecture | Test: tone pass on structurally broken draft does not fix structure |
| Eval self-preference bias | Phase: Eval agent design | Verify: eval is architecturally separate context; adversarial prompt framing present |
| Goodhart's Law in self-improvement loop | Phase: Autoloop design | Verify: holdout set exists and is checked; acceptance threshold accounts for eval variance |
| Diagnosis without form awareness | Phase: Preset schema + Writing engine (diagnose pass) | Test: same diagnosis prompt on blog post vs. technical explainer produces distinct criteria |
| CLAUDE.md / SKILL.md bloat | Phase: Foundation / architecture design | Audit: CLAUDE.md under 300 lines; each pass has own skill file |
| Factual stance mutation | Phase: Writing engine (argument/evidence passes) | Test: argument pass on fact-dense draft; verify no new assertions appear in output |
| Eval inconsistency | Phase: Eval agent design | Test: same draft, 3 eval runs, zero variance at temperature=0 |

---

## Sources

- [Tone Drift in AI Drafts: 5 Warning Signs and Fixes](https://writebros.ai/blog/tone-drift-in-ai-drafts) — voice drift taxonomy (register, vocabulary, emotional drift)
- [Voice Drift Was Killing Us, So We Built a Voice Execution System](https://refractedaspect.com/voice-drift-was-killing-us-so-we-built-a-voice-execution-system/) — practical voice drift prevention
- [Self-Preference Bias in LLM-as-a-Judge](https://arxiv.org/html/2410.21819v1) — self-preference bias evidence for Claude and GPT-4o
- [Play Favorites: A Statistical Method to Measure Self-Bias in LLM-as-a-Judge](https://arxiv.org/abs/2508.06709) — quantification of self-bias and family-bias
- [Goodhart's LLM Principle](https://medium.com/@swagata_acharya/goodharts-llm-principle-how-ai-and-people-learn-to-pass-the-test-instead-of-solving-the-problem-1f582198e252) — Goodhart's Law applied to LLM metric optimization
- [When "Better" Prompts Hurt: Evaluation-Driven Iteration for LLM Applications](https://arxiv.org/abs/2601.22025) — prompt mutation loops that degrade real quality
- [When Recursive Self-Improvement Changes the Ruler](https://medium.com/@omanyuk/when-recursive-self-improvement-changes-the-ruler-a-stability-theory-for-self-editing-ai-systems-2fb58064e87a) — evaluator drift and benchmark decay in self-editing systems
- [LLM-as-a-Judge: A Complete Guide](https://www.evidentlyai.com/llm-guide/llm-as-a-judge) — rubric design, calibration, and bias mitigation
- [LLM Evaluation Frameworks 2025 vs 2026](https://www.mlaidigital.com/blogs/llm-evaluation-frameworks-2025-vs-2026-what-matters-now-2026) — eval consistency requirements
- [What Is Context Rot in Claude Code?](https://www.mindstudio.ai/blog/what-is-context-rot-claude-code) — CLAUDE.md bloat and instruction degradation
- [Stop Bloating Your CLAUDE.md: Progressive Disclosure for AI Coding Tools](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/) — practical CLAUDE.md size limits and skill file strategy
- [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — instruction count limits and session loading costs
- [A Taxonomy of Prompt Defects in LLM Systems](https://arxiv.org/html/2509.14404v1) — Specification & Intent Defects taxonomy
- [ChatGPT's Hallucination Problem: Fabricated References](https://studyfinds.org/chatgpts-hallucination-problem-fabricated-references/) — citation fabrication rate in writing tasks
- [Hallucination detection and mitigation framework for text summarization](https://www.nature.com/articles/s41598-025-31075-1) — faithfulness checking approaches

---
*Pitfalls research for: AI writing improvement / revision workflow system (Claude Code native)*
*Researched: 2026-04-05*
