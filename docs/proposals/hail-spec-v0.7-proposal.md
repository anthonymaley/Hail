# Hail v0.7 Proposal For Multi-Agent Repo Work

Date: 2026-03-20

Purpose:
- capture a concrete spec diff proposal for `Hail`
- make it easier to coordinate work between Anthony, Codex, and Claude Code
- give Claude a clear review target instead of a loose discussion

## Summary

The current `Hail` draft is already strong as a human/AI communication language. The main gap is not syntax. The main gap is operational semantics for multi-party, long-running, repo-oriented collaboration.

This proposal keeps `Hail` lightweight and plain-text first, but adds enough structure to make it useful for:
- durable shared context across a team
- task ownership
- handoff between agents
- active-state clarity
- blocker reporting
- decision logging
- later stripping directives from publishable content

The key structural change is to split Hail into three directive channels:
- `^:` for durable shared collaboration state
- `<<:` for request-side flow directives
- `>>:` for response-side flow directives

The main additions are:
- `^:context:`
- `^:goal:`
- `^:ownership:`
- `^:decision:`
- `^:constraint:`
- `^:status:`
- `^:artifact:`
- `<<:priority:`
- `>>:blocked:`
- `>>:next:`

It also tightens:
- precedence rules
- named vs unnamed directive semantics
- stacking behavior
- turn separator behavior
- minimal parser expectations

## Model

The proposed mental model is:

- `^:` = durable shared state
- `<<:` = request-side flow
- `>>:` = response-side flow

This is intended to support:
- multiple humans on the same team
- multiple agents working in parallel
- different people using different model combinations
- clean separation between collaboration metadata and publishable content

## Proposed Spec Diff

```diff
--- a/SPEC.md
+++ b/SPEC.md
@@
-# Hail: Human-AI Language
+# Hail: Human-AI Language
 
-Version 0.5.0 (draft)
+Version 0.7.0 (draft)
 
@@
 ## Design principles
 
 Plain text is valid Hail. Any natural language sentence works. You add structure only when freeform language isn't cutting it.
 
 Directives are persistent. You set context once and it holds across the conversation until you override it. The scaffolding stays while the conversation evolves around it.
 
-Direction is visible. `<<:` means human to AI. `>>:` means AI to human. The symbols work like arrows: `<<:` pushes instructions in, `>>:` pushes observations back out. In a markdown renderer, `>>:` directives display as blockquotes, giving you visual hierarchy for free.
+Direction is visible. Directives are grouped into three channels:
+
+- `^:` for durable shared collaboration state
+- `<<:` for request-side flow directives
+- `>>:` for response-side flow directives
+
+These markers are not restricted to humans or AIs. Any participant may use any form when appropriate.
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
+`^:status:` records the durable state of the work such as `todo`, `in_progress`, `blocked`, or `done`.
+
+`^:artifact:` records a durable pointer to a working document, file, branch, issue, or output.
 
 ### Human directives (<<:)
 
-`<<:context:` sets what the AI needs to know.
 `<<:tone:` sets how the response should feel.
 
 `<<:format:` sets the shape of the output (bullet list, prose, table, code).
 
@@
 `<<:avoid:` says what not to do.
 
 `<<:as:` sets a role or persona.
 
 `<<:shape:` defines the expected output structure.
+
+`<<:priority:` sets relative importance such as `low`, `medium`, `high`, or freeform text.
+
+`<<:status:` sets the temporary task state for the current flow or turn.
 
 ### AI directives (>>:)
 
 `>>:assumed:` flags what the AI filled in on its own.
 
 `>>:uncertain:` flags low confidence or ambiguity.
@@
 `>>:suggestion:` offers something unsolicited but useful.
 
 `>>:ref:` cites a source.
 
 `>>:limit:` explains what the AI couldn't do and why.
+
+`>>:blocked:` states a concrete blocker preventing progress.
+
+`>>:next:` states the next recommended actor and action.
 
 ### Named directives
@@
-Named directives follow the same scoping rules as unnamed ones. `<<:anthony:tone: formal` in the header persists for anthony across all turns. `<<:sarah:tone: casual` is independent and persists for sarah.
+Named directives follow the same scoping rules as unnamed ones. `^:anthony:goal: ship v1` persists for anthony until changed. `<<:sarah:tone: formal` applies only in the relevant flow scope.
+
+When named and unnamed directives coexist in the same conversation, unnamed directives are global by default. Named directives apply only to the named speaker.
+
+If a named directive and an unnamed directive of the same type are both active, the named directive takes precedence for that speaker.
 
 ### Rules
 
 Directives can appear anywhere in the document: top, inline, bottom.
 
-Multiple directives of the same type stack. `<<:tone: warm` plus `<<:tone: concise` means warm and concise.
+Multiple directives of the same type stack unless documented otherwise. `<<:tone: warm` plus `<<:tone: concise` means warm and concise.
+
+When stacked directives are interpreted, order of appearance is preserved.
+
+For directives that normally take a single value, a later value replaces the earlier value in the same scope unless the directive is explicitly documented as stackable.
+
+The following directives are stackable by default:
+- `context`
+- `avoid`
+- `example`
+- `ref`
+- `suggestion`
+
+All other directives replace earlier values in the same scope unless an implementation explicitly chooses to preserve history.
 
 Unknown directives are ignored. This keeps the language forward-compatible. A parser from 2026 won't choke on a directive added in 2028.
 
 ## Scoping
 
 Directives have two lifetimes depending on where they appear.
 
-**Header directives** appear before the first line of plain text in a document. They are session-level. They persist across all turns until explicitly cleared or replaced.
+**Shared directives** using `^:` are session-level by default. They persist across all turns until explicitly cleared or replaced.
+
+**Header directives** using `<<:` or `>>:` appear before the first line of plain text in a document. They are session-level for that flow channel. They persist across all turns until explicitly cleared or replaced.
 
 **Inline directives** appear inside the body, after plain text has started. They are turn-level. They apply to the current turn only and expire at the next `---` separator.
+
+In multi-turn conversations, each speaker has an active state made of session-level directives currently in force for that speaker plus any active global session-level directives.
+
+Turn-level directives temporarily override active session-level directives for the current turn only.
+
+Durable shared directives `^:` are not turn-scoped. They remain active until restated or cleared.
 
 ## Overrides and clearing
 
-To replace a header directive, restate it with a new value. The old value is gone.
+To replace a directive, restate it with a new value in the same scope. The old value is gone unless the directive is stackable.
@@
-This works for any directive. `<<:avoid:` with no value removes all avoid rules. `<<:as:` with no value drops the persona.
+This works for any directive. `<<:avoid:` with no value removes all avoid rules. `^:goal:` with no value clears the durable goal.
@@
-For stacking directives like `<<:example:`, clearing removes all stacked values. To replace just one, clear and restate the ones you want to keep.
+For stacking directives like `<<:example:`, clearing removes all stacked values. To replace just one, clear and restate the ones you want to keep.
+
+Precedence order, highest to lowest:
+1. turn-level named flow directive
+2. turn-level unnamed flow directive
+3. session-level named flow directive
+4. session-level unnamed flow directive
+5. named shared durable directive
+6. unnamed shared durable directive
+7. plain text only
+
+If two directives conflict at the same precedence level, the later one wins unless the directive is stackable.
 
 ## Multi-line blocks
@@
 Blocks can contain any text including code snippets or markdown. Nesting is not supported. Keep parsing trivial.
+
+Braced block contents are preserved as text. Implementations may normalize leading indentation consistently, but must not reorder or reinterpret lines inside the block.
 
 ## Document structure
@@
-For multi-turn conversations, `---` separates turns. Header directives carry forward across all turns. Inline directives expire at the next `---`.
+For multi-turn conversations, `---` separates turns. Shared directives carry forward across all turns. Flow header directives carry forward across all turns. Inline flow directives expire at the next `---`.
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
+Parsers SHOULD preserve original directive order.
+
+Parsers SHOULD expose the active directive state for debugging or inspection when used in long-running conversations.
+
+## References
+
+`>>:ref:` is intentionally lightweight, but implementations SHOULD support at least these common forms:
+
+Single-line:
+
+`>>:ref: https://example.com/spec`
+
+`>>:ref: /repo/path/file.swift`
+
+`>>:ref: commit abc1234`
+
+Block:
+
+`>>:ref: { type: file, value: /repo/path/file.swift }`
+
+`>>:ref: { type: url, value: https://example.com/spec }`
+
+Hail does not require a strict reference schema, but implementations SHOULD preserve enough structure for humans and tools to identify the source.
+
+## Durable state promotion
+
+Some response-side flow directives may later be promoted into durable shared state.
+
+For example:
+- `>>:decision:` may be promoted to `^:decision:` once accepted
+- `>>:ref:` may be promoted to `^:artifact:` if it becomes a standing working reference
+
+Hail does not require automatic promotion. Promotion is explicit by restating the accepted state using `^:`.
 
 ## Examples
+
+Example shared state:
+
+`^:context: Celtic TV tvOS repo`
+
+`^:goal: align the implementation with the design docs`
+
+`^:ownership: anthony=direction, codex=implementation, claude=review`
+
+Example flow:
+
+`<<:priority: high`
+
+`>>:assumed: the design docs in kivna/input are the current source of truth`
+
+`>>:next: claude should critique the Match Hub interaction model`
 
 ## Versioning
@@
 A parser that encounters a version it doesn't support should warn but still attempt to parse the document. Unknown directives are already ignored by design, so a newer document will mostly work with an older parser. The version line is a hint, not a gate.
+
+## Minimal conformance
+
+A minimal Hail implementation:
+- MUST accept plain text as valid Hail
+- MUST parse unnamed directives in all supported channels
+- MUST distinguish session-level and turn-level directives
+- MUST preserve `^:` durable shared directives if supported
+- MUST ignore unknown directives without failing
+- SHOULD preserve directive order
+- SHOULD warn, not fail, on unsupported `<<:hail:` versions
+- MAY ignore named directives if multi-party support is not implemented, but SHOULD preserve them in parsed output
 
 ## What Hail is not
 
 Hail is not a programming language. There's no logic, no conditionals, no loops.
@@
 ## Status
 
 This is a draft spec. The directive set will grow based on what people actually need. The design is intentionally minimal so there's room to discover what's missing rather than guess wrong upfront.
```

## Why These Changes

### Keep

- plain text remains valid Hail
- directives remain optional
- unknown directives stay ignored
- `shape` stays advisory, not schema enforcement
- no logic, conditions, or loops

### Improve

- teams need a durable shared layer that survives across turns and participants
- long-running sessions need clearer active-state semantics
- multiple agents need clearer ownership and handoff markers
- named and unnamed directives need explicit precedence
- lightweight parsing still needs deterministic behavior
- references need enough structure to be tool-friendly

## Main Review Questions For Claude

Please review this proposal with emphasis on:

1. Whether introducing `^:` for durable shared state is the right architectural move.
2. Whether the split between `^:`, `<<:`, and `>>:` is coherent and worth the added complexity.
3. Whether the precedence and scoping rules are coherent and easy to implement.
4. Whether `unnamed directives are global by default` is the right rule when named directives are present.
5. Whether the stacking rules are too complicated or not explicit enough.
6. Whether `>>:ref:` should stay loose or become more structured.
7. Whether this still feels like Hail, or whether it starts to overfit coordination use cases.

## Suggested Claude Prompt

```text
Review this Hail v0.7 proposal as a spec reviewer, not as a cheerleader.

File:
/Users/anthonymaley/leru/docs/hail-spec-v0.7-proposal.md

Context:
- The current source spec is at /Users/anthonymaley/hail/SPEC.md
- The goal is to make Hail more usable for multi-agent repo work between Anthony, Codex, and Claude Code
- The intended use case includes multiple humans and multiple agents working at the same time
- The main new idea is `^:` as durable shared state, with `<<:` and `>>:` reserved for flow-state interaction metadata
- I want a rigorous review of the proposal, especially where it may be underspecified, overcomplicated, or violating the original design philosophy

Please do three things:

1. Review the proposed diff critically.
Focus on ambiguity, parsing hazards, scope/precedence issues, and places where the design may become too heavy.

2. Say which proposed additions you agree with, which you disagree with, and which you would modify.
Be concrete. If something should change, propose better wording or a better rule.

3. Propose a tighter version of the spec changes if needed.
If you think this should be v0.7, say so. If you think some changes should be deferred, say which ones.

Output format:
- Brief overall judgment
- Findings ordered by severity
- Recommended edits
- Final take on whether this is a good base for Anthony + Codex + Claude collaboration

Be blunt and precise.
```

## Working Assumption

The best near-term use of Hail is as a human-readable coordination layer, not as a fully normative protocol runtime. This proposal is meant to strengthen that use case without turning Hail into a workflow DSL.

## Spec Link Convention

To make Hail easier for collaborators to discover across repos and documents, files may include a short comment pointing to the canonical spec.

Recommended current link:

- `https://github.com/anthonymaley/hail/blob/main/SPEC.md`

Recommended comment forms:

Markdown:

```md
<!-- Collaboration metadata in this file may use Hail directives: https://github.com/anthonymaley/hail/blob/main/SPEC.md -->
```

Short Markdown variant:

```md
<!-- Hail directives reference: https://github.com/anthonymaley/hail/blob/main/SPEC.md -->
```

Swift or source-code comment:

```swift
// Hail directives reference: https://github.com/anthonymaley/hail/blob/main/SPEC.md
```

Guidance:

- use `blob/main` while the spec is evolving quickly and you want people to see the latest version
- use a versioned tag or commit-pinned URL when reproducibility matters
- keep the comment neutral and minimal; it should point to the spec, not explain the entire protocol inline
- if a file is meant for final publishing, strip Hail comments unless the protocol reference is intentionally part of the published artifact
