# How We Use Hail In Repos

Use Hail as a collaboration layer, not as a replacement for normal writing.

## Core Model

- `^:` is durable shared state
- `<<:` is human-to-AI flow guidance
- `>>:` is AI-to-human feedback

## When To Use Each Channel

Use `^:` for things that should stay true until changed:
- goals
- constraints
- ownership
- decisions
- blockers
- artifacts

Use `<<:` for what you want right now:
- tone
- format
- audience
- examples
- priority
- temporary context

Use `>>:` for what the AI needs to surface without cluttering the main answer:
- assumptions
- uncertainty
- suggestions
- references
- limits

`>>:` directives are response-level. They describe the AI turn they appear in and don't persist. To make something durable, promote it to `^:`.

## File Format

For single-turn use (repo docs, notes), `.md` works fine. Directives embed in markdown without issues.

For multi-turn conversations with `---` turn separators, use `.hail` or put `<<:hail:` on the first line. This enables native parsing where `---` means a turn boundary, not a markdown thematic break.

## Named Directives (Multi-Agent)

When multiple humans or AIs participate, add a name after the direction prefix to identify the speaker:

```text
<<:anthony:priority: high
>>:claude:suggestion: start with the value prop
>>:codex:suggestion: fix the CTA first
```

Names are optional. If absent, the directive belongs to whoever is speaking that turn. For single-human, single-AI conversations, skip the name — the syntax is unchanged.

Named directives follow the same scoping rules as unnamed ones. `<<:anthony:tone: formal` persists for anthony. `<<:sarah:tone: casual` is independent.

When to use names:
- coordination files where multiple agents write (like `INBOX.hail`)
- review threads where you want to track who suggested what
- any conversation with more than one AI or more than one human

When to skip names:
- single-human, single-AI conversations
- repo docs where only one author writes directives

## Practical Rules

- default to plain language first; add directives only when they help
- use `^:context:` by default for persistent project context
- use `<<:context:` only for turn-specific context
- keep durable state near the top when possible, but update it inline when reality changes
- put `>>:` notes after the main answer
- clear stale directives explicitly instead of letting them linger
- do not add Hail comments to files that do not use Hail
- some directives stack (`<<:example:`, `<<:avoid:`, `^:context:`, `^:constraint:`, `^:decision:`, `^:artifact:`, `>>:ref:`, `>>:suggestion:`); all others replace on restatement

## Minimal Repo Pattern

```text
^:context: tvOS app redesign repo
^:goal: align implementation with design docs
^:ownership: {
anthony: product direction
codex: implementation
claude: review
}
^:status: in_progress

Review the current home screen and propose the next slice.

<<:priority: high
<<:avoid: unnecessary churn
```

## Reference

- [Hail SPEC](https://github.com/anthonymaley/hail/blob/main/SPEC.md)
