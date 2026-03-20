# Review: Hail v0.8 Proposal

Date: 2026-03-20
Reviewer: Claude (spec review, not cheerleading)

## Overall Judgment

This is a good proposal. The cuts from v0.7 were the right calls. The `^:` channel is well-motivated and the boundaries between the three channels are now coherent. The remaining problems are smaller: some overlap between directives, a few ambiguities in scoping, and one structural question about where `^:` lives in a document. None of these are blockers. This is close to mergeable.

## Findings by Severity

### 1. HIGH: `^:status:` and `^:blocked:` overlap

`^:status:` accepts freeform values including `blocked`. `^:blocked:` records a blocker. If someone writes `^:status: blocked` and also `^:blocked: waiting on API keys`, what's the canonical source of truth for "is this blocked?" They're expressing the same fact in two places with two directives.

The proposal's own open question #2 asks about this. The answer is: pick one pattern. Either `^:blocked:` exists as its own directive (in which case `^:status:` should not accept `blocked` as a value, or the spec should say `^:blocked:` is the authoritative signal), or blockers are expressed through `^:status: blocked` plus a `^:context:` line explaining what the blocker is.

Recommendation: keep `^:blocked:` as its own directive. It's more expressive than `^:status: blocked` because it carries the reason inline. But add one sentence to the spec: "When `^:blocked:` is set, the work is considered blocked regardless of `^:status:` value." That eliminates the ambiguity. And remove `blocked` from the example values for `^:status:`. Make the status values `todo`, `in_progress`, `done`.

### 2. HIGH: `<<:context:` and `^:context:` are now confusingly similar

The proposal adds a note: "A durable context that should remain active across participants belongs in `^:context:` instead." This is helpful but insufficient. A new user reads the spec, sees two context directives, and has to decide which one to use. The guidance is buried in a one-liner under `<<:context:`.

The real distinction is: `<<:context:` is what one human is telling one AI in this conversation. `^:context:` is what everyone should know, durably. But in practice, most context that someone writes at the top of a `.hail` file is intended to be durable. The single-party case (`<<:context:`) is the minority use case once `^:context:` exists.

Recommendation: make the distinction sharper in the spec. Add a short paragraph after the `^:context:` definition:

"Use `^:context:` for standing facts that all participants need. Use `<<:context:` for context that is specific to one human's request in one turn. If in doubt, use `^:context:`. It's the safer default because it persists and is visible to everyone."

This steers people toward the right choice without deprecating `<<:context:`.

### 3. MEDIUM: `^:` scoping is underspecified for position

The current v0.5 spec has a clean rule: header directives (before first plain text) are session-level, inline directives (after plain text) are turn-level. The v0.8 proposal says `^:` directives are "session-level by default" and "not turn-scoped." But it doesn't say what happens when a `^:` directive appears inline.

If someone writes:

```
^:context: Building an app

What should I do first?

^:decision: we're using React Native
```

Is that `^:decision:` session-level because it's `^:`? Or turn-level because it appeared inline? The proposal says `^:` is not turn-scoped, which implies it's always session-level regardless of position. But this contradicts the header/inline model that `<<:` and `>>:` follow, and it means `^:` behaves differently from `<<:` depending on position.

Recommendation: state it explicitly. "`^:` directives are always session-level regardless of where they appear in the document. Unlike `<<:` and `>>:`, position does not affect their lifetime. A `^:decision:` written in the middle of turn 5 persists just like one written in the header."

This is the right rule because shared state is shared state. It doesn't make sense for a decision to expire at the end of a turn just because someone wrote it after a sentence.

### 4. MEDIUM: The `^:` caret symbol was previously rejected

In v0.3 we moved away from `^:` as the human directive prefix, eventually landing on `<<:` and `>>:`. Now `^:` is being reintroduced for a different purpose (durable shared state). This is fine conceptually, but someone reading the git history might be confused about why `^:` was removed and then brought back with different semantics.

Not a spec problem, but worth a line in the proposal's commentary or in a changelog: "The `^:` prefix was previously used for human-to-AI directives (v0.1 through v0.3) and was replaced by `<<:`. In v0.8, `^:` is reintroduced with new semantics as a directionless shared-state channel. The caret now represents 'elevated' or 'pinned' state rather than directional intent."

### 5. MEDIUM: `^:artifact:` naming (open question #3)

The proposal asks whether `^:artifact:` is the right name. The alternatives are `^:ref:` and `^:work:`.

`^:ref:` collides with `>>:ref:` (AI citations). Different channel, same name. That's the same problem as the `<<:status:` / `^:status:` collision from v0.7, which was rightly flagged. Avoid it.

`^:work:` is vague. "Work" could mean the task, the output, the process.

`^:artifact:` is the right name. It's specific: it points to a thing that exists (a file, a branch, an issue, a URL). It doesn't collide with anything. Keep it.

### 6. LOW: Parsing notes use SHOULD without RFC context

The parsing notes say "Directive names are case-sensitive and SHOULD be lowercase" and "Parsers SHOULD preserve directive order." The v0.7 review flagged RFC 2119 language as premature. This version uses less of it, but it's still there.

Recommendation: either commit to RFC 2119 (add a note saying "key words are used per RFC 2119") or drop the caps. Rewrite as: "Directive names are case-sensitive. Use lowercase." and "Parsers should preserve directive order." Lowercase "should" reads as guidance. Uppercase "SHOULD" reads as a conformance requirement, which implies a testing and compliance framework that doesn't exist.

### 7. LOW: The new examples are isolated fragments

The v0.5 spec has a full multi-turn conversation example that demonstrates scoping, overrides, clearing, and AI directives all working together. The v0.8 proposal adds new examples for `^:` directives but they're isolated single-line fragments. There's no example showing `^:` and `<<:` and `>>:` interacting in a real multi-turn, multi-party conversation.

Recommendation: add one complete example showing all three channels in a real scenario. Something like two humans and two agents working on a feature, where `^:` sets the shared context and ownership, `<<:` carries individual instructions, and `>>:` carries individual responses. This is the proposal's primary use case. It should have a worked example.

### 8. LOW: Block text preservation rule may be too strict

"Implementations may normalize indentation consistently, but must not reorder or reinterpret lines inside the block." The "must not reinterpret" clause could be read as prohibiting syntax highlighting, markdown rendering inside blocks, or any transformation. It probably means "don't parse Hail directives inside blocks," but it says more than that.

Recommendation: tighten the wording. "Lines inside a braced block are not parsed for directives. The block content is treated as opaque text."

## Answers to the Proposal's Open Questions

**1. Should `^:` directives appear anywhere in a document, or only in header-style positions?**

Anywhere. `^:` is shared state. Decisions happen mid-conversation. Blockers appear mid-turn. Restricting `^:` to headers would force people to scroll up and edit the top of the document to record a decision they just made in turn 12. That's friction in exactly the wrong place. Let `^:` appear anywhere, and make it always session-level regardless of position.

**2. Should `^:blocked:` be a first-class directive?**

Yes. See finding #1 above. `^:blocked:` carries the reason inline. `^:status: blocked` doesn't. A dedicated blocker directive is more expressive and removes the overlap with `^:status:`.

**3. Is `^:artifact:` the right name?**

Yes. See finding #5 above. `^:ref:` collides with `>>:ref:`. `^:work:` is vague. `^:artifact:` is specific and unambiguous.

**4. Should `<<:context:` remain once `^:context:` exists?**

Yes, but with clearer guidance. See finding #2 above. `<<:context:` is for turn-level or single-party context. `^:context:` is the default for anything durable. The spec should steer users toward `^:context:` as the normal choice.

## Recommended Edits Summary

Accept as-is:
- `^:` as a third channel for durable shared state
- `^:context:`, `^:goal:`, `^:decision:`, `^:constraint:`, `^:ownership:`, `^:artifact:`
- `^:blocked:` as its own directive
- `<<:priority:`
- `<<:` stays human-side, `>>:` stays AI-side
- Turn separator clarification (outside code fences and blocks)
- Spec-link convention (scoped to collaboration files, not scattered)
- Speaker name charset rule
- Directive order preservation

Modify:
- Remove `blocked` from `^:status:` example values; add a line saying `^:blocked:` is authoritative for blocker state
- Add sharper guidance distinguishing `<<:context:` from `^:context:`
- State explicitly that `^:` is always session-level regardless of position
- Tighten block preservation wording to "not parsed for directives" rather than "must not reinterpret"
- Drop uppercase SHOULD or add an RFC 2119 reference
- Add a complete multi-turn, multi-party example showing all three channels

Defer:
- Nothing. This proposal is scoped correctly.

Reject:
- Nothing. The v0.7 cuts were sufficient.

## Final Take

This is a solid v0.8 direction. The three-channel model (`^:` / `<<:` / `>>:`) is coherent and adds real value for the Anthony + Codex + Claude use case. The cuts from v0.7 were correct: no precedence matrix, no stackable lists, no workflow-ish `>>:next:`, no premature conformance language. What remains is a clean addition of shared state to a language that needed it.

The main work left is clarifying the edges: `^:status:` vs `^:blocked:` overlap, `<<:context:` vs `^:context:` guidance, and explicit scoping rules for `^:` regardless of position. These are small fixes. The architecture is right.

Ship it after those edits.
