# Review: Hail v0.9 Proposal

Date: 2026-03-20
Reviewer: Claude (spec review)

## Overall Judgment

v0.9 is tighter than v0.8 and addresses the main review findings. The three issues I flagged as high severity in v0.8 are all resolved or improved. The remaining problems are smaller, mostly wording. This is close to merge-ready. A few edits and it's done.

## Did v0.9 Resolve the v0.8 Issues?

**`^:status:` vs `^:blocked:` (was HIGH):** Resolved. The example values for `^:status:` are now `todo`, `in_progress`, `review`, `done`. No `blocked` in the list. `^:blocked:` carries the reason. The commentary section explains the distinction clearly. The only remaining gap: the spec diff itself doesn't include the sentence I recommended ("When `^:blocked:` is set, the work is considered blocked regardless of `^:status:` value"). The commentary explains it but the spec text doesn't. Minor fix.

**`<<:context:` vs `^:context:` (was HIGH):** Improved. The guidance under `<<:context:` now reads "Use `^:context:` instead when the context should remain active across participants or across multiple turns." This is better than v0.8's one-liner. The commentary section adds a clear rule of thumb. I'd still push the guidance one step further in the spec itself (see findings below), but the confusion risk is much lower now.

**`^:` scoping by position (was MEDIUM):** Resolved. The scoping section now says "`^:` are session-level by meaning, not by position. They may appear anywhere in a document and remain active until explicitly cleared or replaced." This is exactly the right rule, stated explicitly. The follow-up line "Durable `^:` directives are not turn-scoped" reinforces it. Clear.

## Findings by Severity

### 1. MEDIUM: Block preservation wording is still too broad

v0.8 review flagged this. v0.9 keeps the same wording: "must not reorder or reinterpret lines inside the block." This still reads as prohibiting any transformation, including syntax highlighting or display formatting.

Recommendation (same as v0.8 review): replace with "Lines inside a braced block are not parsed for directives. The block content is treated as opaque text." This says what you mean without overreaching.

### 2. MEDIUM: The `<<:context:` guidance could be one sentence stronger

The current wording steers people toward `^:context:` but doesn't state a default. Someone skimming the spec will still see two context directives and hesitate.

Recommendation: after the line "Use `^:context:` instead when the context should remain active across participants or across multiple turns," add: "If in doubt, use `^:context:`. It is the safer default." Seven words. Eliminates the hesitation.

### 3. MEDIUM: No complete multi-party example

The v0.8 review flagged this as LOW. Bumping it to MEDIUM for v0.9 because this proposal's entire motivation is multi-human, multi-agent work, and the examples section still only shows isolated fragments. There's no worked conversation showing Anthony setting `^:` state, Claude responding with `>>:` directives, and Codex picking up the thread.

Recommendation: add one complete example. Doesn't need to be long. Five or six turns showing `^:ownership:` set at the top, two agents responding to the same `^:goal:`, a `^:blocked:` appearing mid-conversation, and a `^:decision:` recorded after discussion. This is the proposal's pitch. Show it working.

### 4. LOW: SHOULD still appears without RFC 2119 context

"Directive names are case-sensitive and SHOULD be lowercase" and "Parsers SHOULD preserve directive order." Same finding as v0.8. Either add an RFC 2119 reference or use lowercase "should."

Recommendation: lowercase. This isn't an internet standard yet. "Directive names are case-sensitive. Use lowercase." is cleaner.

### 5. LOW: `^:blocked:` authoritativeness not stated in spec text

The commentary section explains the `^:status:` / `^:blocked:` distinction well. But the spec diff itself just lists both directives without saying how they interact. If someone reads only the spec (not the proposal commentary), they could still write `^:status: in_progress` alongside `^:blocked: waiting on keys` and wonder which one is telling the truth about whether work can proceed.

Recommendation: add one sentence after the `^:blocked:` definition in the spec: "When `^:blocked:` is active, the work is considered blocked regardless of `^:status:` value. Clear `^:blocked:` when the blocker is resolved."

### 6. LOW: The `^:` caret reintroduction goes unmentioned

Same note from v0.8 review. `^:` was the original human directive prefix in v0.1 through v0.3, removed in v0.4, now returning with different semantics. Not a spec problem, but worth a note in the changelog or commentary so someone reading the git history doesn't think it's a regression.

### 7. INFORMATIONAL: Spec-link convention is well-scoped

The guidance is now correct: use it in files that contain Hail directives or in repo-level collaboration files, not scattered into unrelated source files. Nothing to change.

## Recommended Edits

Accept as-is:
- The entire three-channel model
- All `^:` directives (`context`, `goal`, `ownership`, `decision`, `constraint`, `status`, `artifact`, `blocked`)
- `<<:priority:`
- `^:` scoping rule (session-level by meaning, not position)
- `^:status:` example values without `blocked`
- `<<:context:` / `^:context:` guidance
- Turn separator clarification
- Speaker name charset
- Directive order preservation
- Spec-link convention

Modify (all small):
- Block preservation: "Lines inside a braced block are not parsed for directives. The block content is treated as opaque text."
- `<<:context:` guidance: add "If in doubt, use `^:context:`. It is the safer default."
- `^:blocked:` definition: add "When `^:blocked:` is active, the work is considered blocked regardless of `^:status:` value. Clear `^:blocked:` when the blocker is resolved."
- Parsing notes: lowercase "should" instead of "SHOULD"
- Add a complete multi-turn, multi-party example

Reject: nothing.
Defer: nothing.

## Final Take on Readiness

This is ready to merge into the main spec after the five modifications listed above. None of them change the architecture. They're all wording tightening and one example addition. The three-channel model is coherent, the scoping rules are clear, the directive set is well-chosen, and the cuts from v0.7 held.

v0.9 is the right next version of Hail.
