# Parser Hardening: Conformance Fixtures, Validator Alignment, CLI Diagnostics

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden hail-parser by adding spec-derived conformance tests, tightening the validator to catch structural-colon and named-directive violations per SPEC.md, and improving CLI error output with error codes, line:column location, and a `--strict` flag.

**Architecture:** Three independent workstreams that share the same codebase but touch different concerns. Task 1 (conformance fixtures) adds test coverage from SPEC.md canonical examples. Tasks 2-4 (validator alignment) add new validation rules with TDD. Tasks 5-7 (CLI diagnostics) enhance ValidationIssue with codes and columns, update CLI output formatting, and add `--strict`.

**Tech Stack:** TypeScript, Vitest, zero runtime dependencies

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `tests/conformance.test.ts` | Spec-derived test cases from SPEC.md canonical examples |
| Modify | `src/types.ts` | Add `code` and `column` fields to `ValidationIssue` (move from tokenizer) |
| Modify | `src/tokenizer.ts` | Add new validation rules, error codes, column tracking |
| Modify | `src/parser.ts` | No changes expected |
| Modify | `src/cli.ts` | `--strict` flag, improved error formatting with codes and columns |
| Modify | `src/index.ts` | Re-export `ValidationIssue` from new location if moved |
| Modify | `tests/tokenizer.test.ts` | Tests for new validation rules |

---

## Task 1: Spec Conformance Fixtures

Add test cases derived directly from SPEC.md canonical examples. These test the parser end-to-end against the spec's own examples.

**Files:**
- Create: `packages/hail-parser/tests/conformance.test.ts`

- [ ] **Step 1: Write conformance tests for the simplest valid documents**

```typescript
import { describe, it, expect } from 'vitest'
import { parse } from '../src/parser.js'
import { tokenize, validate } from '../src/tokenizer.js'

describe('SPEC conformance: simplest valid documents', () => {
  it('plain text is valid Hail (SPEC line 293)', () => {
    const doc = parse("What's the capital of France?")
    expect(doc.mode).toBe('embedded')
    expect(doc.turns).toHaveLength(1)
    expect(doc.turns[0].body[0]).toEqual(
      expect.objectContaining({ type: 'text', content: "What's the capital of France?" }),
    )
    expect(validate("What's the capital of France?")).toHaveLength(0)
  })

  it('single directive with text (SPEC line 299)', () => {
    const source = `<<:context: studying for a geography exam
What's the capital of France?`
    const doc = parse(source)
    expect(doc.turns[0].header).toHaveLength(1)
    expect(doc.turns[0].header[0].name).toBe('context')
    expect(doc.turns[0].header[0].value).toBe('studying for a geography exam')
  })
})
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `cd packages/hail-parser && npx vitest run tests/conformance.test.ts`
Expected: PASS (these test existing, working behavior)

- [ ] **Step 3: Write conformance tests for the multi-party collaboration example**

```typescript
describe('SPEC conformance: multi-party collaboration (SPEC lines 306-348)', () => {
  const source = `<<:hail: 0.9

^:context: Celtic TV tvOS repo
^:goal: align the home screen with the design docs
^:ownership: {
anthony: product direction
codex: implementation
claude: review
}
^:status: in_progress

Review the current home screen and propose the next implementation slice.

<<:anthony:priority: high
<<:anthony:avoid: unnecessary churn

---

>>:codex:assumed: the design docs in kivna/input are the current source of truth
>>:codex:suggestion: fix the hero Match Hub CTA before broader IA changes

---

>>:claude:suggestion: keep Match Hub as the primary organizing concept but challenge whether the rail card should expand on focus
^:decision: Match Hub remains the primary organizing concept

---

^:blocked: waiting on API credentials for replay validation

Can the implementation proceed without live playback verification?

---

>>:codex:limit: full playback verification can't be completed until credentials are available
>>:codex:suggestion: continue with non-network UI and navigation work while blocked

---

^:blocked:
^:status: review`

  it('detects native mode from version line', () => {
    const doc = parse(source)
    expect(doc.mode).toBe('native')
    expect(doc.version).toBe('0.9')
  })

  it('splits into 6 turns', () => {
    const doc = parse(source)
    expect(doc.turns).toHaveLength(6)
  })

  it('parses durable state in turn 0', () => {
    const doc = parse(source)
    const s = doc.turns[0].state
    expect(s.durable.has('context')).toBe(true)
    expect(s.durable.has('goal')).toBe(true)
    expect(s.durable.has('status')).toBe(true)
    expect(s.durable.get('context')![0].value).toBe('Celtic TV tvOS repo')
  })

  it('parses multi-line ownership block', () => {
    const doc = parse(source)
    const ownership = doc.turns[0].state.durable.get('ownership')
    expect(ownership).toHaveLength(1)
    expect(ownership![0].value).toContain('anthony: product direction')
    expect(ownership![0].value).toContain('codex: implementation')
    expect(ownership![0].value).toContain('claude: review')
  })

  it('parses named human directives', () => {
    const doc = parse(source)
    expect(doc.turns[0].state.session.has('anthony:priority')).toBe(true)
    expect(doc.turns[0].state.session.has('anthony:avoid')).toBe(true)
    expect(doc.turns[0].state.session.get('anthony:priority')![0].value).toBe('high')
  })

  it('parses named AI directives in turn 1', () => {
    const doc = parse(source)
    const t1 = doc.turns[1]
    const assumed = t1.body.find(
      (b) => b.type === 'directive' && b.directive.name === 'assumed',
    )
    expect(assumed).toBeDefined()
    if (assumed?.type === 'directive') {
      expect(assumed.directive.speaker).toBe('codex')
      expect(assumed.directive.scope).toBe('response')
    }
  })

  it('records ^:decision: as durable from turn 2 onward', () => {
    const doc = parse(source)
    expect(doc.turns[2].state.durable.has('decision')).toBe(true)
    expect(doc.turns[2].state.durable.get('decision')![0].value).toBe(
      'Match Hub remains the primary organizing concept',
    )
  })

  it('sets and clears ^:blocked:', () => {
    const doc = parse(source)
    // Turn 3 sets blocked
    expect(doc.turns[3].state.durable.has('blocked')).toBe(true)
    expect(doc.turns[3].state.durable.get('blocked')![0].value).toContain(
      'waiting on API credentials',
    )
    // Turn 5 clears blocked
    expect(doc.turns[5].state.durable.has('blocked')).toBe(false)
  })

  it('updates ^:status: to review in final turn', () => {
    const doc = parse(source)
    const status = doc.turns[5].state.durable.get('status')
    expect(status).toHaveLength(1)
    expect(status![0].value).toBe('review')
  })

  it('validates clean with no issues', () => {
    expect(validate(source)).toHaveLength(0)
  })
})
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/hail-parser && npx vitest run tests/conformance.test.ts`
Expected: PASS

- [ ] **Step 5: Write conformance tests for scoping, overrides, and clearing (SPEC full example)**

```typescript
describe('SPEC conformance: full conversation with scoping (SPEC lines 350-433)', () => {
  const source = `<<:hail: 0.9

^:context: {
Medication reminder app for elderly users.
React Native with Expo. Passed accessibility audit Feb 2026.
Target: iOS and Android.
}
<<:audience: end users, age 65+
<<:tone: warm, encouraging
<<:avoid: medical jargon, technical error messages
<<:example: {
input: "Error 403: Authentication failure"
output: "We couldn't sign you in. Check your password and try again."
}

Write onboarding copy for the first 3 screens.

<<:length: 50 words per screen max
<<:shape: {
screen: int
heading: short phrase
body: 2-3 sentences, simple language
}

---

Here's your onboarding copy:

1. **Welcome**
   You're in the right place. SimpleHealth helps you take your
   medication on time, every time. No fuss.

>>:assumed: screens will have a "Next" button at the bottom
>>:suggestion: {
Screen 2 says "tell us" but the input form only has
medication name and time fields. Consider saying
"add your medication and pick a time" to match the UI.
}
>>:ref: Apple HIG, Accessibility Guidelines 2026

---

Good. Now write the push notification for a missed dose.

<<:tone: concerned but not alarming
<<:length: 2 sentences max

---

You missed your 2pm medication. Open SimpleHealth to
mark it as taken or skip it for today.

>>:assumed: the notification shows the specific time
>>:uncertain: {
Do you want the medication name in the notification?
Some users take multiple meds and the name helps.
}

---

<<:tone:

Yes, include the med name. And drop the tone directive,
just write it plain.

---

You missed your 2pm Metformin. Open SimpleHealth to
mark it as taken or skip it for today.

>>:assumed: "Metformin" is a placeholder, the app fills in the real name`

  it('parses multi-line ^:context: block', () => {
    const doc = parse(source)
    const ctx = doc.turns[0].state.durable.get('context')
    expect(ctx).toHaveLength(1)
    expect(ctx![0].value).toContain('Medication reminder app')
    expect(ctx![0].value).toContain('React Native with Expo')
    expect(ctx![0].value).toContain('Target: iOS and Android')
  })

  it('persists <<:audience: across all turns', () => {
    const doc = parse(source)
    for (let i = 0; i < doc.turns.length; i++) {
      expect(doc.turns[i].state.session.has('audience')).toBe(true)
    }
  })

  it('overrides <<:tone: in turn 2 (concerned) then clears in turn 4', () => {
    const doc = parse(source)
    // Turn 0: warm, encouraging
    expect(doc.turns[0].state.session.get('tone')![0].value).toBe('warm, encouraging')
    // Turn 2: overridden
    expect(doc.turns[2].state.session.get('tone')![0].value).toBe('concerned but not alarming')
    // Turn 4: cleared
    expect(doc.turns[4].state.session.has('tone')).toBe(false)
  })

  it('inline <<:length: in turn 0 does not persist to turn 1', () => {
    const doc = parse(source)
    // length is inline (after text) in turn 0
    const inlineLength = doc.turns[0].body.find(
      (b) => b.type === 'directive' && b.directive.name === 'length',
    )
    expect(inlineLength).toBeDefined()
    if (inlineLength?.type === 'directive') {
      expect(inlineLength.directive.scope).toBe('turn')
    }
    // turn 1 should not have length in session state
    expect(doc.turns[1].state.session.has('length')).toBe(false)
  })

  it('<<:length: in turn 2 header persists to turn 3', () => {
    const doc = parse(source)
    // turn 2 header sets length
    expect(doc.turns[2].state.session.has('length')).toBe(true)
    expect(doc.turns[2].state.session.get('length')![0].value).toBe('2 sentences max')
    // persists to turn 3
    expect(doc.turns[3].state.session.has('length')).toBe(true)
  })

  it('stacks <<:avoid: values', () => {
    const doc = parse(source)
    const avoids = doc.turns[0].state.session.get('avoid')
    // Only 1 because the header has only one <<:avoid: directive
    expect(avoids).toHaveLength(1)
    expect(avoids![0].value).toBe('medical jargon, technical error messages')
  })

  it('>>:ref: appears in turn 1 response, not in turn 2', () => {
    const doc = parse(source)
    expect(doc.turns[1].state.response.has('ref')).toBe(true)
    expect(doc.turns[2].state.response.has('ref')).toBe(false)
  })

  it('>>:uncertain: block value parsed correctly', () => {
    const doc = parse(source)
    const uncertain = doc.turns[3].body.find(
      (b) => b.type === 'directive' && b.directive.name === 'uncertain',
    )
    expect(uncertain).toBeDefined()
    if (uncertain?.type === 'directive') {
      expect(uncertain.directive.value).toContain('medication name in the notification')
    }
  })

  it('validates clean with no issues', () => {
    expect(validate(source)).toHaveLength(0)
  })
})
```

- [ ] **Step 6: Run all conformance tests**

Run: `cd packages/hail-parser && npx vitest run tests/conformance.test.ts`
Expected: PASS

- [ ] **Step 7: Write conformance tests for named directive disambiguation**

```typescript
describe('SPEC conformance: named directive structural disambiguation', () => {
  it('one segment = unnamed (SPEC line 117)', () => {
    const tokens = tokenize('<<:context: value')
    const d = tokens[0] as any
    expect(d.speaker).toBeUndefined()
    expect(d.name).toBe('context')
    expect(d.value).toBe('value')
  })

  it('two segments = named (SPEC line 117)', () => {
    const tokens = tokenize('<<:anthony:context: value')
    const d = tokens[0] as any
    expect(d.speaker).toBe('anthony')
    expect(d.name).toBe('context')
    expect(d.value).toBe('value')
  })

  it('colons after final structural colon belong to value (SPEC line 117)', () => {
    const tokens = tokenize('<<:context: time is 3:30pm')
    const d = tokens[0] as any
    expect(d.name).toBe('context')
    expect(d.value).toBe('time is 3:30pm')
  })

  it('colons after final structural colon in named directive belong to value', () => {
    const tokens = tokenize('<<:anthony:context: meeting at 10:00am')
    const d = tokens[0] as any
    expect(d.speaker).toBe('anthony')
    expect(d.name).toBe('context')
    expect(d.value).toBe('meeting at 10:00am')
  })

  it('more than two segments before final structural colon is invalid (SPEC line 117)', () => {
    // <<:a:b:c: value has three segments — should not parse as a valid directive
    const issues = validate('<<:a:b:c: value')
    expect(issues.length).toBeGreaterThan(0)
    expect(issues[0].severity).toBe('error')
  })

  it('speaker name allows letters, numbers, underscore, hyphen (SPEC line 279)', () => {
    const tokens = tokenize('<<:agent_1:tone: warm')
    const d = tokens[0] as any
    expect(d.speaker).toBe('agent_1')

    const tokens2 = tokenize('<<:my-bot:tone: warm')
    const d2 = tokens2[0] as any
    expect(d2.speaker).toBe('my-bot')
  })

  it('named and unnamed of same type coexist independently (SPEC line 119)', () => {
    const source = `<<:hail: 0.9

<<:tone: formal
<<:anthony:tone: casual

Hello`
    const doc = parse(source)
    expect(doc.turns[0].state.session.has('tone')).toBe(true)
    expect(doc.turns[0].state.session.has('anthony:tone')).toBe(true)
    expect(doc.turns[0].state.session.get('tone')![0].value).toBe('formal')
    expect(doc.turns[0].state.session.get('anthony:tone')![0].value).toBe('casual')
  })
})
```

- [ ] **Step 8: Run tests — the "more than two segments" test should FAIL**

Run: `cd packages/hail-parser && npx vitest run tests/conformance.test.ts`
Expected: The "more than two segments" test fails because the current regex doesn't match `<<:a:b:c: value` at all, so it falls through to `startsWithChannelPrefix` returning true but `parseDirectiveLine` returning null — which actually DOES produce a malformed directive error. Verify this.

If it passes: great, the tokenizer already correctly rejects three-segment directives as malformed.
If it fails: we'll fix it in Task 2.

- [ ] **Step 9: Write conformance tests for embedded vs native mode**

```typescript
describe('SPEC conformance: document structure and parsing modes', () => {
  it('embedded mode: --- keeps host-format meaning (SPEC line 271)', () => {
    const source = `<<:tone: warm

Some text

---

More text`
    const doc = parse(source)
    expect(doc.mode).toBe('embedded')
    expect(doc.turns).toHaveLength(1)
  })

  it('native mode from .hail filename (SPEC line 269)', () => {
    const doc = parse('Hello', { filename: 'chat.hail' })
    expect(doc.mode).toBe('native')
  })

  it('native mode from <<:hail: on first line (SPEC line 269)', () => {
    const doc = parse('<<:hail: 0.9\n\nHello')
    expect(doc.mode).toBe('native')
  })

  it('<<:hail: version line must be first line (SPEC line 275)', () => {
    const source = `some text
<<:hail: 0.9`
    const doc = parse(source)
    // version line not on first line, so embedded mode
    expect(doc.mode).toBe('embedded')
  })

  it('unknown directives should not cause parse failure (SPEC line 143)', () => {
    const source = '<<:banana: yellow'
    const issues = validate(source)
    // No errors — unknown directives are valid
    expect(issues.filter((i) => i.severity === 'error')).toHaveLength(0)
  })

  it('directive names are case-sensitive, lowercase required (SPEC line 281)', () => {
    const tokens = tokenize('<<:Tone: warm')
    // Currently parses — spec says "use lowercase" but doesn't say reject
    const d = tokens[0] as any
    expect(d.name).toBe('Tone')
  })
})
```

- [ ] **Step 10: Run all conformance tests**

Run: `cd packages/hail-parser && npx vitest run tests/conformance.test.ts`
Expected: PASS

- [ ] **Step 11: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/tests/conformance.test.ts
git commit -m "Add spec conformance test fixtures from SPEC.md canonical examples"
```

---

## Task 2: Validator — Speaker Name Format Validation

The spec says speaker names may contain `[a-zA-Z0-9_-]` (SPEC line 279). The current validator doesn't check this.

**Files:**
- Modify: `packages/hail-parser/tests/tokenizer.test.ts`
- Modify: `packages/hail-parser/src/tokenizer.ts`

- [ ] **Step 1: Write failing test for invalid speaker name characters**

Add to `tests/tokenizer.test.ts` inside the `validate` describe block:

```typescript
  it('warns on speaker names with invalid characters', () => {
    const issues = validate('<<:anthony!:tone: warm')
    // The `!` makes the regex not match, so it's already a malformed directive
    expect(issues.length).toBeGreaterThan(0)
    expect(issues[0].severity).toBe('error')
  })

  it('accepts valid speaker name characters', () => {
    const issues = validate('<<:agent_1:tone: warm')
    expect(issues).toHaveLength(0)
  })

  it('accepts hyphenated speaker names', () => {
    const issues = validate('<<:my-bot:tone: warm')
    expect(issues).toHaveLength(0)
  })
```

- [ ] **Step 2: Run tests to check which pass/fail**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: These likely all pass already because the tokenizer regex `[a-zA-Z0-9_-]+` enforces the character set. Verify.

- [ ] **Step 3: Commit if tests pass, or fix and commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/tests/tokenizer.test.ts
git commit -m "Add speaker name validation tests"
```

---

## Task 3: Validator — Three-Segment Named Directive Rejection

SPEC line 117: "More than two segments before [the final structural colon] is invalid." The tokenizer regex already won't match three segments, so `startsWithChannelPrefix` returns true but `parseDirectiveLine` returns null — producing a "malformed directive" error. We should give a more specific error message.

**Files:**
- Modify: `packages/hail-parser/src/tokenizer.ts`
- Modify: `packages/hail-parser/tests/tokenizer.test.ts`

- [ ] **Step 1: Write failing test for specific three-segment error message**

Add to `tests/tokenizer.test.ts` in the `validate` block:

```typescript
  it('rejects three-segment directive with specific message', () => {
    const issues = validate('<<:a:b:c: value')
    expect(issues).toHaveLength(1)
    expect(issues[0].severity).toBe('error')
    expect(issues[0].message).toContain('Too many segments')
  })

  it('rejects four-segment directive with specific message', () => {
    const issues = validate('>>:a:b:c:d: value')
    expect(issues).toHaveLength(1)
    expect(issues[0].severity).toBe('error')
    expect(issues[0].message).toContain('Too many segments')
  })
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: FAIL — message currently says "Malformed directive" not "Too many segments"

- [ ] **Step 3: Add three-segment detection to validate()**

In `packages/hail-parser/src/tokenizer.ts`, add a regex for over-segmented directives. Replace the malformed directive check block (lines 206-217) with:

```typescript
    // Check for malformed directives: starts with channel prefix but doesn't parse
    if (startsWithChannelPrefix(raw)) {
      const parsed = parseDirectiveLine(raw, lineNum)
      if (!parsed) {
        // Check if it's a three-or-more segment directive
        const afterPrefix = raw.replace(/^(\^:|<<:|>>:)/, '')
        const segmentMatch = afterPrefix.match(
          /^([a-zA-Z0-9_-]+:){2,}(?=\s|{|$)/,
        )
        if (segmentMatch) {
          issues.push({
            line: lineNum,
            message: `Too many segments in directive header: ${raw}. Named directives use channel:speaker:name: format (max two segments after prefix).`,
            severity: 'error',
          })
        } else {
          issues.push({
            line: lineNum,
            message: `Malformed directive: ${raw}`,
            severity: 'error',
          })
        }
      } else if (parsed.type === 'block_start') {
        inBlock = true
      }
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/src/tokenizer.ts packages/hail-parser/tests/tokenizer.test.ts
git commit -m "Add specific error for three-or-more segment directives"
```

---

## Task 4: Validator — Strict Mode Warnings

Add warnings (not errors) for patterns the spec discourages but doesn't forbid: uppercase directive names (SPEC says "use lowercase"), and `<<:hail:` not on line 1.

**Files:**
- Modify: `packages/hail-parser/src/tokenizer.ts`
- Modify: `packages/hail-parser/tests/tokenizer.test.ts`

- [ ] **Step 1: Write failing tests for strict-mode warnings**

Add to `tests/tokenizer.test.ts`:

```typescript
  it('warns on uppercase directive names', () => {
    const issues = validate('<<:Tone: warm')
    const warnings = issues.filter((i) => i.severity === 'warning')
    expect(warnings).toHaveLength(1)
    expect(warnings[0].message).toContain('lowercase')
  })

  it('warns on <<:hail: not on first line', () => {
    const issues = validate('some text\n<<:hail: 0.9')
    const warnings = issues.filter((i) => i.severity === 'warning')
    expect(warnings.length).toBeGreaterThan(0)
    expect(warnings.some((w) => w.message.includes('first line'))).toBe(true)
  })

  it('does not warn on <<:hail: on first line', () => {
    const issues = validate('<<:hail: 0.9\n\nHello')
    const warnings = issues.filter((i) => i.message.includes('first line'))
    expect(warnings).toHaveLength(0)
  })
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: FAIL — no warnings currently emitted for these patterns

- [ ] **Step 3: Add the warnings to validate()**

In `packages/hail-parser/src/tokenizer.ts`, inside the `validate()` function, add these checks after the existing `if (startsWithChannelPrefix(raw))` block:

```typescript
    // Check for uppercase directive names (spec says "use lowercase")
    if (startsWithChannelPrefix(raw)) {
      const parsed = parseDirectiveLine(raw, lineNum)
      // ... existing malformed check ...

      // Warn on uppercase in directive or speaker names
      if (parsed && parsed.type !== 'version') {
        const dt = parsed as DirectiveToken
        if (dt.name !== dt.name.toLowerCase()) {
          issues.push({
            line: lineNum,
            message: `Directive name "${dt.name}" should be lowercase`,
            severity: 'warning',
          })
        }
        if (dt.speaker && dt.speaker !== dt.speaker.toLowerCase()) {
          issues.push({
            line: lineNum,
            message: `Speaker name "${dt.speaker}" should be lowercase`,
            severity: 'warning',
          })
        }
      }
    }

    // Check for <<:hail: not on first line
    if (lineNum > 1 && raw.match(VERSION_RE)) {
      issues.push({
        line: lineNum,
        message: '<<:hail: version line should be on the first line of the document',
        severity: 'warning',
      })
    }
```

Note: The existing `if (startsWithChannelPrefix(raw))` block needs to be restructured so the `parsed` variable is available for both the malformed check and the uppercase check. Merge them into a single block:

```typescript
    if (startsWithChannelPrefix(raw)) {
      const parsed = parseDirectiveLine(raw, lineNum)
      if (!parsed) {
        const afterPrefix = raw.replace(/^(\^:|<<:|>>:)/, '')
        const segmentMatch = afterPrefix.match(
          /^([a-zA-Z0-9_-]+:){2,}(?=\s|{|$)/,
        )
        if (segmentMatch) {
          issues.push({
            line: lineNum,
            message: `Too many segments in directive header: ${raw}. Named directives use channel:speaker:name: format (max two segments after prefix).`,
            severity: 'error',
          })
        } else {
          issues.push({
            line: lineNum,
            message: `Malformed directive: ${raw}`,
            severity: 'error',
          })
        }
      } else if (parsed.type === 'block_start') {
        inBlock = true
      }

      if (parsed && parsed.type !== 'version') {
        const dt = parsed as DirectiveToken
        if (dt.name !== dt.name.toLowerCase()) {
          issues.push({
            line: lineNum,
            message: `Directive name "${dt.name}" should be lowercase`,
            severity: 'warning',
          })
        }
        if (dt.speaker && dt.speaker !== dt.speaker.toLowerCase()) {
          issues.push({
            line: lineNum,
            message: `Speaker name "${dt.speaker}" should be lowercase`,
            severity: 'warning',
          })
        }
      }
    }

    // <<:hail: not on first line
    if (lineNum > 1 && raw.match(VERSION_RE)) {
      issues.push({
        line: lineNum,
        message: '<<:hail: version line should be on the first line of the document',
        severity: 'warning',
      })
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass (conformance tests for uppercase names should still pass since they test tokenizer output, not validation)

- [ ] **Step 6: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/src/tokenizer.ts packages/hail-parser/tests/tokenizer.test.ts
git commit -m "Add validation warnings for uppercase names and misplaced version line"
```

---

## Task 5: CLI Diagnostics — Error Codes and Column Numbers

Add `code` and `column` fields to `ValidationIssue`. Every validation rule gets a stable error code. Column tracking pinpoints where in the line the issue starts.

**Files:**
- Modify: `packages/hail-parser/src/tokenizer.ts` (ValidationIssue type and all issue pushes)
- Modify: `packages/hail-parser/tests/tokenizer.test.ts`

- [ ] **Step 1: Write failing tests for error codes and columns**

Add to `tests/tokenizer.test.ts`:

```typescript
describe('error codes and columns', () => {
  it('malformed directive has code E001', () => {
    const issues = validate('<<:')
    expect(issues[0].code).toBe('E001')
  })

  it('too many segments has code E002', () => {
    const issues = validate('<<:a:b:c: value')
    expect(issues[0].code).toBe('E002')
  })

  it('unclosed block has code E003', () => {
    const issues = validate('^:context: {\nsome content')
    expect(issues[0].code).toBe('E003')
  })

  it('separator spacing has code W001', () => {
    const issues = validate('text\n---\nmore')
    expect(issues[0].code).toBe('W001')
  })

  it('uppercase name has code W002', () => {
    const issues = validate('<<:Tone: warm')
    expect(issues[0].code).toBe('W002')
  })

  it('misplaced version has code W003', () => {
    const issues = validate('text\n<<:hail: 0.9')
    const w = issues.find((i) => i.code === 'W003')
    expect(w).toBeDefined()
  })

  it('unclosed fence has code W004', () => {
    const issues = validate('```\nsome code')
    expect(issues[0].code).toBe('W004')
  })

  it('malformed directive column points to start of line', () => {
    const issues = validate('<<:')
    expect(issues[0].column).toBe(1)
  })

  it('issues have column field', () => {
    const issues = validate('<<:Tone: warm')
    expect(typeof issues[0].column).toBe('number')
  })
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: FAIL — `code` and `column` properties don't exist on ValidationIssue

- [ ] **Step 3: Add code and column to ValidationIssue and all issue pushes**

In `packages/hail-parser/src/tokenizer.ts`, update the interface:

```typescript
export interface ValidationIssue {
  line: number
  column: number
  code: string
  message: string
  severity: 'error' | 'warning'
}
```

Then update every `issues.push()` call with the appropriate code and column:

| Code | Severity | Rule |
|------|----------|------|
| `E001` | error | Malformed directive |
| `E002` | error | Too many segments |
| `E003` | error | Unclosed block |
| `W001` | warning | Separator spacing |
| `W002` | warning | Uppercase directive/speaker name |
| `W003` | warning | Version line not on first line |
| `W004` | warning | Unclosed fenced code block |

For column: all directives start at column 1 (line start). Set `column: 1` for all current rules.

Here are the updated push calls:

Malformed directive:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'E001',
  message: `Malformed directive: ${raw}`,
  severity: 'error',
})
```

Too many segments:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'E002',
  message: `Too many segments in directive header: ${raw}. Named directives use channel:speaker:name: format (max two segments after prefix).`,
  severity: 'error',
})
```

Unclosed block:
```typescript
issues.push({
  line: lines.length,
  column: 1,
  code: 'E003',
  message: 'Unclosed block: missing closing }',
  severity: 'error',
})
```

Separator spacing:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'W001',
  message: 'Turn separator missing blank lines before/after',
  severity: 'warning',
})
```

Uppercase directive name:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'W002',
  message: `Directive name "${dt.name}" should be lowercase`,
  severity: 'warning',
})
```

Uppercase speaker name:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'W002',
  message: `Speaker name "${dt.speaker}" should be lowercase`,
  severity: 'warning',
})
```

Misplaced version:
```typescript
issues.push({
  line: lineNum,
  column: 1,
  code: 'W003',
  message: '<<:hail: version line should be on the first line of the document',
  severity: 'warning',
})
```

Unclosed fence:
```typescript
issues.push({
  line: lines.length,
  column: 1,
  code: 'W004',
  message: 'Unclosed fenced code block',
  severity: 'warning',
})
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/hail-parser && npx vitest run tests/tokenizer.test.ts`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/src/tokenizer.ts packages/hail-parser/tests/tokenizer.test.ts
git commit -m "Add error codes and column numbers to validation issues"
```

---

## Task 6: CLI Diagnostics — Improved Output Format

Update CLI `--validate` output to show error codes and column numbers. Format: `ERROR E001 at line:column: message`

**Files:**
- Modify: `packages/hail-parser/src/cli.ts`
- Modify: `packages/hail-parser/tests/tokenizer.test.ts` (or a new CLI test, but keeping it simple)

- [ ] **Step 1: Update the --validate output format in cli.ts**

In `packages/hail-parser/src/cli.ts`, replace the validate output block (lines 85-88):

```typescript
      for (const issue of issues) {
        const prefix = issue.severity === 'error' ? 'ERROR' : 'WARN'
        console.error(`${prefix} line ${issue.line}: ${issue.message}`)
      }
```

With:

```typescript
      for (const issue of issues) {
        const prefix = issue.severity === 'error' ? 'ERROR' : 'WARN'
        console.error(
          `${prefix} ${issue.code} at ${issue.line}:${issue.column}: ${issue.message}`,
        )
      }
```

- [ ] **Step 2: Update the --help text to document --strict**

In the `usage()` function, add `--strict` to the help text (will be implemented in next task):

```typescript
function usage(): void {
  console.error(`Usage: hail-parser <file> [options]

Options:
  --tokens     Output raw token stream
  --state      Output active directive state
  --turn N     Select a specific turn (used with --state)
  --summary    Show current state, insights, and items needing input
  --validate   Check for parse issues, exit 0 if clean
  --strict     Treat warnings as errors (used with --validate)
  --help       Show this message`)
}
```

- [ ] **Step 3: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass (no tests directly test CLI output format)

- [ ] **Step 4: Manual smoke test**

Run: `cd packages/hail-parser && npx tsx src/cli.ts ../../INBOX.hail --validate`
Expected: Output like `WARN W001 at 9:1: Turn separator missing blank lines before/after` (or clean)

- [ ] **Step 5: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/src/cli.ts
git commit -m "Improve --validate output with error codes and line:column format"
```

---

## Task 7: CLI Diagnostics — --strict Flag

Add `--strict` flag that treats warnings as errors (exit 1 if any warnings).

**Files:**
- Modify: `packages/hail-parser/src/cli.ts`

- [ ] **Step 1: Add --strict logic to the --validate block**

In `packages/hail-parser/src/cli.ts`, replace the validate exit logic:

```typescript
  if (flags.has('--validate')) {
    const issues = validate(source)

    if (issues.length === 0) {
      console.error('Valid.')
      process.exit(0)
    } else {
      for (const issue of issues) {
        const prefix = issue.severity === 'error' ? 'ERROR' : 'WARN'
        console.error(
          `${prefix} ${issue.code} at ${issue.line}:${issue.column}: ${issue.message}`,
        )
      }
      const strict = flags.has('--strict')
      const hasErrors = issues.some((i) => i.severity === 'error')
      const hasWarnings = issues.some((i) => i.severity === 'warning')
      process.exit(hasErrors || (strict && hasWarnings) ? 1 : 0)
    }
  }
```

- [ ] **Step 2: Manual smoke test without --strict**

Run: `cd packages/hail-parser && echo '<<:Tone: warm\n\nHello' | npx tsx src/cli.ts /dev/stdin --validate`
Expected: Prints warning, exits 0

- [ ] **Step 3: Manual smoke test with --strict**

Run: `cd packages/hail-parser && echo '<<:Tone: warm' > /tmp/test.hail && npx tsx src/cli.ts /tmp/test.hail --validate --strict; echo "exit: $?"`
Expected: Prints warning, exits 1

- [ ] **Step 4: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd /Users/anthonymaley/hail
git add packages/hail-parser/src/cli.ts
git commit -m "Add --strict flag to treat warnings as errors in --validate"
```

---

## Task 8: Final Verification and Doc Updates

**Files:**
- Modify: `packages/hail-parser/README.md`
- Modify: `docs/playbook.md`

- [ ] **Step 1: Run full test suite**

Run: `cd packages/hail-parser && npx vitest run`
Expected: All tests pass. Count should be notably higher than 58.

- [ ] **Step 2: Run build**

Run: `cd packages/hail-parser && npm run build`
Expected: Clean compile, no errors

- [ ] **Step 3: Update test count in playbook**

Update `docs/playbook.md` line 43 with the actual new test count.

- [ ] **Step 4: Update parser README with new CLI features**

In `packages/hail-parser/README.md`, add `--strict` to the CLI docs and mention error codes in the validate output.

- [ ] **Step 5: Update README.md CLI section**

In the root `README.md`, add `--strict` to the CLI examples:

```bash
npx hail-parser document.hail --validate         # check for issues
npx hail-parser document.hail --validate --strict # treat warnings as errors
```

- [ ] **Step 6: Commit**

```bash
cd /Users/anthonymaley/hail
git add docs/playbook.md packages/hail-parser/README.md README.md
git commit -m "Update docs with new test count, --strict flag, and error codes"
```
