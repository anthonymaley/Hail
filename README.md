# Hail

Human-AI Language. A markup language for human-AI communication.

## What it is

Plain text with three optional directive channels:

- `^:` durable shared state (goals, decisions, ownership, blockers)
- `<<:` human-to-AI flow guidance (tone, format, priority)
- `>>:` AI-to-human feedback (assumptions, uncertainty, suggestions)

A valid Hail document is any plain text. Directives are optional scaffolding you add when freeform language isn't cutting it.

## Quick example

```
^:context: Mobile app for elderly users
^:goal: write onboarding copy
^:ownership: {
anthony: direction
claude: writing
}

Write the first 3 screens.

<<:tone: warm, encouraging
<<:length: 50 words per screen

---

Here's your onboarding copy:

1. Welcome to SimpleHealth...

>>:assumed: screens have a Next button
>>:suggestion: say "press the big green button" instead of "tap"
```

## Docs

- [SPEC.md](SPEC.md) — the full language specification
- [Usage Guide](docs/usage-guide.md) — when to use each channel, practical rules
- [README Template](docs/readme-template.md) — snippet to paste into repos that use Hail
