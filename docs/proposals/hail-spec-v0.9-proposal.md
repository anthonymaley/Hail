# Claude Review Prompt

```text
Review this Hail v0.9 proposal as a spec reviewer, not as a cheerleader.

File:
/Users/anthonymaley/hail/hail-spec-v0.8-proposal_0.9.md

Context:
- The current source spec is at /Users/anthonymaley/hail/SPEC.md
- The previous proposal was reviewed in /Users/anthonymaley/hail/proposal_review_claude_0.8.md
- The short version of that review was: the three-channel split is right, v0.8 is close, and the remaining issues are mostly about clarifying overlap and scoping
- This draft is meant to absorb that review and tighten the spec without adding new machinery

Please do four things:

1. Review the proposed diff critically.
Focus on ambiguity, parsing hazards, scoping clarity, and whether the remaining rules are still minimal enough for Hail.

2. Evaluate whether the draft resolves the main issues from the v0.8 review.
Especially:
- `^:status:` vs `^:blocked:`
- `<<:context:` vs `^:context:`
- whether `^:` scoping by position is now clear enough

3. Call out what should be accepted, modified, rejected, or deferred.
Be concrete. If something should change, propose better wording or a better rule.

4. Say whether this is ready to merge back into the main spec as the next draft direction.
If not, say exactly what still needs to change first.

Output format:
- Brief overall judgment
- Findings ordered by severity
- Recommended edits
- Final take on readiness

Be blunt and precise.
```

# Hail v0.9 Proposal

Date: 2026-03-20

Purpose:
- respond to the `v0.8` review
- keep the three-channel model
- resolve the remaining ambiguities without adding new mechanism

This draft assumes the `v0.8` review was directionally correct: the architecture is right, the spec is close, and the remaining work is mainly clarification.

## Summary Of Changes From v0.8

This draft keeps:
- `^:` as durable shared collaboration state
- `<<:` as human-to-AI flow directives
- `>>:` as AI-to-human flow directives
- `^:artifact:` as the durable pointer directive
- `^:blocked:` as a first-class durable shared directive

This draft clarifies:
- `^:` scoping is semantic, not positional
- `^:` directives may appear anywhere in a document
- `^:status:` and `^:blocked:` have distinct roles
- `^:context:` is the default for persistent shared context
- `<<:context:` remains valid for flow-specific context

## Core Model

Hail uses three directive channels:

- `^:` for durable shared collaboration state
- `<<:` for human-to-AI flow directives
- `>>:` for AI-to-human flow directives

The channels answer different questions:

- `^:` answers: what state should remain true for this collaboration until changed?
- `<<:` answers: how should the current or upcoming AI work be guided?
- `>>:` answers: what should the AI report back about its work, assumptions, limits, or sources?

This lets multiple humans and multiple agents share stable state without collapsing conversational direction.

## Proposed Spec Diff

```diff
--- a/SPEC.md
+++ b/SPEC.md
@@
-# Hail: Human-AI Language
+# Hail: Human-AI Language
 
-Version 0.5.0 (draft)
+Version 0.9.0 (draft)
 
@@
 ## Design principles
 
 Plain text is valid Hail. Any natural language sentence works. You add structure only when freeform language isn't cutting it.
 
 Directives are persistent. You set `<<:context:` once and it holds across the conversation until you override it. The scaffolding stays while the conversation evolves around it.
 
-Direction is visible. `<<:` means human to AI. `>>:` means AI to human. The symbols work like arrows: `<<:` pushes instructions in, `>>:` pushes observations back out. In a markdown renderer, `>>:` directives display as blockquotes, giving you visual hierarchy for free.
+Direction is visible. Hail uses three directive channels:
+
+- `^:` for durable shared collaboration state
+- `<<:` for human-to-AI flow directives
+- `>>:` for AI-to-human flow directives
+
+The arrows still describe conversational direction. The `^:` channel is directionless shared state.
+
+Hail is advisory by default. Directives guide interpretation and coordination, but they do not create executable logic or guaranteed enforcement.
 
 ## Directives
 
-A directive is a line starting with `<<:` (human to AI) or `>>:` (AI to human). It's metadata. It tells the other side how to interpret the natural language around it.
+A directive is a line starting with `^:`, `<<:`, or `>>:`. It's metadata. It tells the other side how to interpret the natural language around it.
+
+### Shared durable directives (^:)
+
+`^:context:` sets standing background that all participants should treat as active.
+
+`^:goal:` sets the durable objective for the collaboration.
+
+`^:ownership:` assigns responsibility for an area, task, file set, or role.
+
+`^:decision:` records an accepted decision that should persist across later turns.
+
+`^:constraint:` records a standing rule or limitation.
+
+`^:status:` records the durable state of the work such as `todo`, `in_progress`, `review`, or `done`.
+
+`^:artifact:` records a durable pointer to a working document, file, branch, issue, or output.
+
+`^:blocked:` records a blocker that should remain visible until cleared.
 
 ### Human directives (<<:)
 
 `<<:context:` sets what the AI needs to know.
+
+Use `^:context:` instead when the context should remain active across participants or across multiple turns.
 
 `<<:tone:` sets how the response should feel.
 
 `<<:format:` sets the shape of the output (bullet list, prose, table, code).
@@
 `<<:avoid:` says what not to do.
 
 `<<:as:` sets a role or persona.
 
 `<<:shape:` defines the expected output structure.
+
+`<<:priority:` sets relative importance such as `low`, `medium`, `high`, or freeform text.
 
 ### AI directives (>>:)
 
 `>>:assumed:` flags what the AI filled in on its own.
@@
 `>>:suggestion:` offers something unsolicited but useful.
 
 `>>:ref:` cites a source.
 
 `>>:limit:` explains what the AI couldn't do and why.
 
 ### Named directives
@@
 A parser disambiguates names from directives by checking against the known directive list. If the segment after `<<:` is a recognized directive name, there's no speaker name. If it's not, it's a speaker name and the directive follows.
 
 Named directives follow the same scoping rules as unnamed ones. `<<:anthony:tone: formal` in the header persists for anthony across all turns. `<<:sarah:tone: casual` is independent and persists for sarah.
+
+For `^:` directives, unnamed values are shared by default. Named `^:` directives apply to the named participant.
+
+If named and unnamed directives of the same type are both present, the named value overrides the unnamed value for that participant.
 
 ### Rules
 
 Directives can appear anywhere in the document: top, inline, bottom.
 
 Multiple directives of the same type stack. `<<:tone: warm` plus `<<:tone: concise` means warm and concise.
 
 Unknown directives are ignored. This keeps the language forward-compatible. A parser from 2026 won't choke on a directive added in 2028.
 
 ## Scoping
 
 Directives have two lifetimes depending on where they appear.
 
+**Shared durable directives** using `^:` are session-level by meaning, not by position. They may appear anywhere in a document and remain active until explicitly cleared or replaced.
+
 **Header directives** appear before the first line of plain text in a document. They are session-level. They persist across all turns until explicitly cleared or replaced.
 
 **Inline directives** appear inside the body, after plain text has started. They are turn-level. They apply to the current turn only and expire at the next `---` separator.
+
+This header/inline distinction applies to `<<:` and `>>:`. Durable `^:` directives are not turn-scoped.
 
 To promote an inline directive to session-level, move it to the header or restate it in a new turn's header block (directives before that turn's first plain text line).
 
 ## Overrides and clearing
@@
 This works for any directive. `<<:avoid:` with no value removes all avoid rules. `<<:as:` with no value drops the persona.
@@
 For stacking directives like `<<:example:`, clearing removes all stacked values. To replace just one, clear and restate the ones you want to keep.
 
 ## Multi-line blocks
@@
 Blocks can contain any text including code snippets or markdown. Nesting is not supported. Keep parsing trivial.
+
+Braced block contents are preserved as text. Implementations may normalize indentation consistently, but must not reorder or reinterpret lines inside the block.
 
 ## Document structure
 
 A Hail document has two regions. The header is every `<<:` directive before the first line of plain text. The body is everything after. See the Scoping section for how these regions affect directive lifetime.
 
-For multi-turn conversations, `---` separates turns. Header directives carry forward across all turns. Inline directives expire at the next `---`.
+For multi-turn conversations, `---` separates turns. Shared directives and header directives carry forward across all turns. Inline directives expire at the next `---`.
+
+A `---` line is a turn separator only when it appears on its own line outside a braced directive block and outside fenced code.
 
 An optional `<<:hail:` version line, if present, must be the very first line of the document, before the header directives.
+
+## Parsing notes
+
+Speaker names may contain letters, numbers, `_`, and `-`.
+
+Directive names are case-sensitive and SHOULD be lowercase.
+
+Whitespace immediately after the final `:` is ignored.
+
+An empty directive value clears that directive in the current scope.
+
+Parsers SHOULD preserve directive order.
 
 ## Examples
+
+Shared state:
+
+`^:context: Celtic TV tvOS repo`
+
+`^:goal: align the implementation with the design docs`
+
+`^:ownership: {
+anthony: direction
+codex: implementation
+claude: review
+}`
+
+`^:status: in_progress`
+
+`^:blocked: waiting on API credentials`
+
+Flow:
+
+`<<:priority: high`
+
+`>>:assumed: the design docs in kivna/input are the current source of truth`
+
+`>>:suggestion: claude should critique the Match Hub interaction model next`
 
 ## What Hail is not
 
 Hail is not a programming language. There's no logic, no conditionals, no loops.
@@
 ## Status
 
 This is a draft spec. The directive set will grow based on what people actually need. The design is intentionally minimal so there's room to discover what's missing rather than guess wrong upfront.
```

## Notes On The Remaining Ambiguities

### `^:status:` vs `^:blocked:`

These are intentionally distinct.

- `^:status:` answers: what is the current durable state of the work?
- `^:blocked:` answers: what blocker is currently preventing progress?

Example:

```text
^:status: in_progress
^:blocked: waiting on API credentials
```

This is clearer than overloading `status` with both lifecycle state and blocker detail.

### `<<:context:` vs `^:context:`

These also remain intentionally distinct.

- `^:context:` is the default for persistent, shared context
- `<<:context:` is for flow-specific context that guides the current AI interaction

Rule of thumb:
- if the context should remain true for the collaboration, use `^:context:`
- if the context is just for the current ask or turn, use `<<:context:`

### `^:` Scoping

`^:` is durable by meaning, not by location.

That means:
- a `^:` directive may appear in the header
- a `^:` directive may appear mid-document
- a `^:` directive may appear later in a conversation and still update shared durable state

This avoids forcing shared-state updates into header-only positions.

## Suggested Spec-Link Convention

If a repo uses Hail, add a lightweight reference in places where Hail is actually used, or in collaboration files like `README`, `CLAUDE.md`, or `AGENTS.md`.

Recommended current spec link:

- https://github.com/anthonymaley/hail/blob/main/SPEC.md

Example comment:

```md
<!-- Collaboration metadata in this file may use Hail directives: https://github.com/anthonymaley/hail/blob/main/SPEC.md -->
```

Guidance:
- use this in files that actually contain Hail directives or explain collaboration conventions
- do not scatter it into unrelated source files that contain no Hail markup
- use `blob/main` while the spec is evolving quickly
- switch to a pinned or tagged link later when reproducibility matters

## Bottom Line

`v0.9` keeps the three-channel model, resolves the main review comments from `v0.8`, and avoids adding extra protocol machinery. It is a stronger candidate for folding back into the main Hail spec than the earlier, heavier proposal.
