# Requirements: Autowrite

**Defined:** 2026-04-05
**Core Value:** When a user submits a draft, Autowrite must produce a measurably better revision that preserves the author's voice — diagnosed, planned, and improved through form-aware staged passes.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Foundation

- [x] **FOUND-01**: Repository structure created with drafts/, presets/, skills/, evals/, autoloop/, scripts/, runs/ directories
- [x] **FOUND-02**: CLAUDE.md defines universal safety rules (no fabricated citations, voice preservation defaults, factual integrity constraints)
- [x] **FOUND-03**: .claude/rules/*.md files provide context-lean, path-scoped behavioral rules for skills and passes

### Presets

- [x] **PRES-01**: Preset schema defined in JSON covering form, goals, stages, voice rules, structure expectations, rubric criteria, constraints, and transformation defaults
- [x] **PRES-02**: Blog post preset hand-tuned with form-specific voice, structure, rubric, and pass sequence
- [x] **PRES-03**: Argumentative essay preset hand-tuned with form-specific voice, structure, rubric, and pass sequence
- [x] **PRES-04**: Technical explainer preset hand-tuned with form-specific voice, structure, rubric, and pass sequence
- [x] **PRES-05**: Preset validation script catches malformed preset JSON before use

### Writing Engine

- [x] **WRIT-01**: User can submit a draft or notes file and select a preset to begin a revision workflow
- [x] **WRIT-02**: System diagnoses specific weaknesses in the draft (weak thesis, unclear structure, buried evidence, etc.) before any rewriting
- [x] **WRIT-03**: System generates a structured revision plan referencing specific diagnosis findings before applying changes
- [x] **WRIT-04**: System applies staged passes in preset-defined sequence with per-pass scope constraints (DO NOT touch rules)
- [x] **WRIT-05**: Each pass preserves author voice by default using preset voice rules
- [x] **WRIT-06**: System enforces factual integrity per pass — no new claims, no altered citations, no fabricated facts
- [x] **WRIT-07**: System produces a unified diff between input and output
- [x] **WRIT-08**: System produces per-change explanations (not just a summary)
- [x] **WRIT-09**: System outputs a final clean revised draft as a single deliverable file
- [x] **WRIT-10**: User can build from notes or outline into a polished piece (notes-to-draft flow)
- [ ] **WRIT-11**: User can adapt a piece into another form by switching presets

### Run Logging

- [x] **RUNL-01**: Each revision run saves to an immutable timestamped directory in runs/
- [x] **RUNL-02**: Run directory contains input draft, diagnosis, revision plan, per-pass outputs, final draft, diffs, and eval snapshot
- [x] **RUNL-03**: Run metadata (preset used, pass sequence, timestamps) saved as JSON

### Eval System

- [ ] **EVAL-01**: Specialized eval critic agent runs as an isolated subagent (separate context window from writing agent)
- [ ] **EVAL-02**: Eval agent produces criterion-level scores for: novelty, clarity, structure, voice preservation, audience fit, concision, factual integrity
- [ ] **EVAL-03**: Eval agent produces specific failure points with concrete explanations per criterion
- [ ] **EVAL-04**: Eval rubric criteria and weights driven by the active preset
- [ ] **EVAL-05**: Eval snapshot saved as stable, machine-readable JSON (criterion → score → explanation → failure_points)
- [ ] **EVAL-06**: Eval agent uses adversarial framing (hyper-critical, not supportive)

### Preset Creation

- [ ] **PCRE-01**: User can create a new preset from one or more example texts
- [ ] **PCRE-02**: System analyzes examples for form, tone, structure, rhetorical moves, and priorities
- [ ] **PCRE-03**: System shows inferred preset fields for user editing before saving
- [ ] **PCRE-04**: User can refine an existing preset by providing additional examples

### Self-Improvement Loop

- [ ] **LOOP-01**: Autoloop can pick one asset to mutate (skill instruction, preset stage order, rubric wording, few-shot example, output format)
- [ ] **LOOP-02**: Autoloop runs baseline eval before mutation
- [ ] **LOOP-03**: Autoloop applies one mutation and reruns eval
- [ ] **LOOP-04**: Autoloop keeps mutation only if aggregate score improves with no critical regressions and factual integrity + voice preservation remain acceptable
- [ ] **LOOP-05**: Autoloop logs all mutation attempts with before/after scores and acceptance decision
- [ ] **LOOP-06**: Holdout set checked for divergence from loop scores to prevent Goodhart's Law overfitting

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Additional Presets

- **PRES-06**: Business memo preset
- **PRES-07**: Newsletter preset
- **PRES-08**: Personal essay preset

### Advanced Features

- **ADVF-01**: Pairwise comparison mode (before/after eval with baseline)
- **ADVF-02**: Trend analysis across multiple runs for the same draft
- **ADVF-03**: Pass context isolation via context: fork subagents for drafts exceeding 5k words
- **ADVF-04**: Preset sharing and import/export between users

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| First-draft generation from scratch (no input) | Core value is iterative improvement, not generation. Different product category. |
| Real-time suggestion-as-you-type | Claude Code-native batch model. Real-time requires GUI and event loop — enormous complexity for no revision quality gain. |
| GUI or web interface | Deliberately CLI-only. Inspectability and hackability are the value proposition. |
| Integration with Google Docs, Notion, Obsidian | Each integration is a maintenance surface. Distribution problem, not quality problem. Defer to v2+. |
| AI-generated citations and references | LLMs fabricate citations at ~36% rate. System flags weak evidence but never fabricates. |
| Tone adjustment sliders | Shallow proxies for voice. Preset voice rules are deeper and more accurate. |
| Auto-publish to CMS | Out of scope for a revision system. |
| More than three first-party presets in v1 | Poorly tuned presets produce worse results. Three deeply tuned > ten shallow. Preset creation flow covers power users. |
| Aggressive rewrite as default mode | Destroys author voice. Opt-in only. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| PRES-01 | Phase 1 | Complete |
| PRES-02 | Phase 1 | Complete |
| PRES-03 | Phase 1 | Complete |
| PRES-04 | Phase 1 | Complete |
| PRES-05 | Phase 1 | Complete |
| WRIT-01 | Phase 2 | Complete |
| WRIT-02 | Phase 2 | Complete |
| WRIT-03 | Phase 2 | Complete |
| WRIT-04 | Phase 2 | Complete |
| WRIT-05 | Phase 2 | Complete |
| WRIT-06 | Phase 2 | Complete |
| WRIT-07 | Phase 2 | Complete |
| WRIT-08 | Phase 2 | Complete |
| WRIT-09 | Phase 2 | Complete |
| WRIT-10 | Phase 2 | Complete |
| WRIT-11 | Phase 2 | Pending |
| RUNL-01 | Phase 2 | Complete |
| RUNL-02 | Phase 2 | Complete |
| RUNL-03 | Phase 2 | Complete |
| EVAL-01 | Phase 3 | Pending |
| EVAL-02 | Phase 3 | Pending |
| EVAL-03 | Phase 3 | Pending |
| EVAL-04 | Phase 3 | Pending |
| EVAL-05 | Phase 3 | Pending |
| EVAL-06 | Phase 3 | Pending |
| PCRE-01 | Phase 4 | Pending |
| PCRE-02 | Phase 4 | Pending |
| PCRE-03 | Phase 4 | Pending |
| PCRE-04 | Phase 4 | Pending |
| LOOP-01 | Phase 4 | Pending |
| LOOP-02 | Phase 4 | Pending |
| LOOP-03 | Phase 4 | Pending |
| LOOP-04 | Phase 4 | Pending |
| LOOP-05 | Phase 4 | Pending |
| LOOP-06 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 38 total
- Mapped to phases: 38
- Unmapped: 0

---
*Requirements defined: 2026-04-05*
*Last updated: 2026-04-05 after roadmap creation*
