# Hail: Human-AI Language

Version 0.1.0 (draft)

## What it is

Hail is a lightweight markup language for structured communication between humans and AI. Plain text with optional directives that make intent, context, and constraints explicit without making the conversation robotic.

A valid Hail document can be a single sentence. The structure is there when you need it.

File extension: `.hail`
MIME type: `text/hail`
Encoding: UTF-8

## Design principles

Plain text is valid Hail. Any natural language sentence works. You add structure only when freeform language isn't cutting it.

Directives are persistent. You set `^context` once and it holds across the conversation until you override it. The scaffolding stays while the conversation evolves around it.

Direction is visible. `^` means human to AI. `v` means AI to human. You can scan a conversation and instantly know who set what.

## Directives

A directive is a line starting with `^` (human to AI) or `v` (AI to human). It's metadata. It tells the other side how to interpret the natural language around it.

### Human directives (^)

`^context` sets what the AI needs to know.

`^tone` sets how the response should feel.

`^format` sets the shape of the output (bullet list, prose, table, code).

`^length` sets a size constraint.

`^audience` says who the output is for.

`^example` shows what you want by demonstration.

`^avoid` says what not to do.

`^as` sets a role or persona.

`^shape` defines the expected output structure.

### AI directives (v)

`vassumed` flags what the AI filled in on its own.

`vuncertain` flags low confidence or ambiguity.

`vsuggestion` offers something unsolicited but useful.

`vref` cites a source.

`vlimit` explains what the AI couldn't do and why.

### Rules

Directives can appear anywhere in the document: top, inline, bottom.

Multiple directives of the same type stack. `^tone warm` plus `^tone concise` means warm and concise.

Unknown directives are ignored. This keeps the language forward-compatible. A parser from 2026 won't choke on a directive added in 2028.

Directives persist across turns unless explicitly overridden.

## Multi-line blocks

For values longer than one line, use `{ }` brackets after the directive name.

```
^context {
Medication reminder app for elderly users.
React Native with Expo.
Passed accessibility audit Feb 2026.
}
```

Blocks can contain any text including code snippets or markdown. Nesting is not supported. Keep parsing trivial.

AI directives use the same syntax.

```
vsuggestion {
Screen 2 uses "tap" but elderly users sometimes
struggle with tap targets under 44px. Consider
saying "press the big green button" instead.
}
```

## Examples and output shape

The `^example` directive shows the AI what you want by demonstration.

Single line:

```
^example "red" → "warm, energetic"
```

Block:

```
^example {
input: "Your session has expired (error 401)"
output: "You've been signed out. Tap here to sign back in."
}
```

Multiple examples stack. The AI reads the pattern.

The `^shape` directive defines expected output structure without being a schema language. It's loose and human-readable.

```
^shape {
title: short phrase
body: 2-3 sentences
cta: button label, max 4 words
}
```

This is communication, not enforcement. The AI interprets `body: 2-3 sentences` with common sense.

## Document structure

Directives at the top of a document form a header. Everything after the first plain text line is the body. Directives can still appear in the body as inline overrides.

```
^context Building a CLI tool in Rust
^tone terse, technical

How should I structure the argument parser?
```

For multi-turn conversations, `---` separates turns. Header directives carry forward.

```
^context Building a CLI tool in Rust
^tone terse, technical

How should I structure the argument parser?

---

vsuggestion look at clap's derive API

Use clap with derive macros. Here's the structure...

---

Now add subcommands for init and run.

^format code only
```

The third turn inherits `^context` and `^tone` from the header. The `^format code only` applies to that turn only.

## Minimal examples

The simplest valid Hail document:

```
What's the capital of France?
```

With one directive:

```
^context studying for a geography exam
What's the capital of France?
```

A full document:

```
^context {
Medication reminder app for elderly users.
React Native with Expo. Passed accessibility audit Feb 2026.
}
^audience end users, age 65+
^tone warm, encouraging
^avoid medical jargon, technical error messages

Write onboarding copy for the first 3 screens.
Each screen gets a heading and body text.

^length 50 words per screen max

^shape {
screen_number: int
heading: short phrase
body: 2-3 sentences, simple language
}
```

A conversation with AI response:

```
^context planning a weekend trip to Melbourne
^tone casual

What should I do on Saturday?

---

Here are some ideas for Saturday:

1. Morning at Queen Victoria Market...
2. Walk along the Yarra...

vassumed you're arriving Friday night
vuncertain are you driving or flying? parking changes the plan
vsuggestion book the NGV weekend exhibition, it sells out
```

## What Hail is not

Hail is not a programming language. There's no logic, no conditionals, no loops.

Hail is not a schema language. `^shape` is a suggestion, not a contract.

Hail is not a replacement for conversation. The natural language between directives is where the real communication happens. Directives are scaffolding.

## Status

This is a draft spec. The directive set will grow based on what people actually need. The design is intentionally minimal so there's room to discover what's missing rather than guess wrong upfront.
