# Hail v0.8 Proposal

Date: 2026-03-20

Purpose:
- define a simpler next draft of `Hail`
- preserve Hail's plain-text-first design
- add the minimum needed for multi-human, multi-agent collaboration

This proposal is intentionally narrower than the previous `v0.7` draft. It keeps the architectural change that matters, removes the heavy mechanism that made the proposal harder to reason about, and stays closer to the original design philosophy.

## Executive Summary

The main change in `v0.8` is the addition of a third directive channel:

- `^:` for durable shared collaboration state
- `<<:` for human-to-AI flow directives
- `>>:` for AI-to-human flow directives

This gives Hail a clean way to represent:
- standing team context
- durable goals and decisions
- shared blockers and ownership
- live conversational flow that can still be stripped from final output

The design goal is not to turn Hail into a workflow engine. The design goal is to let several humans and several agents work in the same thread or document without losing shared state.

## What Changed From The v0.7 Proposal

Removed:
- seven-level precedence hierarchy
- stackable vs non-stackable directive list
- `>>:next:`
- structured `>>:ref:` schema form
- minimal conformance section
- formal durable-state-promotion section
- "any participant may use any channel"

Changed:
- `>>:blocked:` becomes `^:blocked:`
- `<<:` stays human/request-side
- `>>:` stays AI/response-side
- `^:` is the only directionless shared-state channel
- `^:ownership:` is treated as plain text or block text, not inline key-value syntax

## Proposed Spec Diff

```diff
--- a/SPEC.md
+++ b/SPEC.md
@@
-# Hail: Human-AI Language
+# Hail: Human-AI Language
 
-Version 0.5.0 (draft)
+Version 0.8.0 (draft)
 
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
+`^:status:` records the durable state of the work such as `todo`, `in_progress`, `blocked`, or `done`.
+
+`^:artifact:` records a durable pointer to a working document, file, branch, issue, or output.
+
+`^:blocked:` records a blocker that should remain visible until cleared.
 
 ### Human directives (<<:)
 
 `<<:context:` sets what the AI needs to know.
+
+A durable context that should remain active across participants belongs in `^:context:` instead.
 
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
 
+**Shared durable directives** using `^:` are session-level by default. They persist across all turns until explicitly cleared or replaced.
+
 **Header directives** appear before the first line of plain text in a document. They are session-level. They persist across all turns until explicitly cleared or replaced.
 
 **Inline directives** appear inside the body, after plain text has started. They are turn-level. They apply to the current turn only and expire at the next `---` separator.
+
+This header/inline distinction applies to `<<:` and `>>:`. Durable `^:` directives are not turn-scoped.
 
 To promote an inline directive to session-level, move it to the header or restate it in a new turn's header block (directives before that turn's first plain text line).
 
 ## Overrides and clearing
 
 To replace a header directive, restate it with a new value. The old value is gone.
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

## Commentary

### Why `^:` Stays

`^:` solves the real coordination problem:
- several humans need to see the same direction
- several agents may be working at once
- some information must persist beyond one turn
- that information should still be separate from publishable content

Without `^:`, Hail has no clean way to separate:
- standing shared state
from
- ordinary turn instructions and responses

### Why The Mechanism Was Cut Back

The previous proposal started moving toward protocol machinery instead of communication design. This version avoids that.

Specifically:
- no long precedence matrix
- no directive classification table
- no mini-schema for references
- no workflow-ish `>>:next:`
- no premature conformance language

### Suggested Spec-Link Convention

If a repo uses Hail, add a lightweight comment or reference in places where Hail is actually in use, or in repo-level collaboration files like `README`, `CLAUDE.md`, or `AGENTS.md`.

Recommended current spec link:

- [Hail SPEC](https://github.com/anthonymaley/hail/blob/main/SPEC.md)

Example comment:

```md
<!-- Collaboration metadata in this file may use Hail directives: https://github.com/anthonymaley/hail/blob/main/SPEC.md -->
```

Guidance:
- use this in files that actually contain Hail directives or explain collaboration conventions
- do not scatter it into unrelated source files that contain no Hail markup
- use `blob/main` while the spec is evolving quickly
- switch to a pinned or tagged link later when reproducibility matters

## Questions To Resolve

1. Should `^:` directives appear anywhere in a document, or only in header-style positions?
2. Should `^:blocked:` be a first-class directive, or should blockers just be represented through `^:status:` plus freeform context?
3. Is `^:artifact:` the right name, or would `^:ref:` or `^:work:` be clearer for durable pointers?
4. Should `<<:context:` remain as-is once `^:context:` exists, or should the spec steer users more strongly toward `^:` for any persistent context?

## Bottom Line

`v0.8` keeps the right change and cuts the wrong complexity. If Hail is going to support real team collaboration across multiple humans and multiple agents, `^:` is the important addition. Everything else should stay as simple as possible.
