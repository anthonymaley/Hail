# hail-parser

TypeScript parser and CLI for Hail.

## What it does

- tokenizes Hail source into a raw token stream
- parses tokens into turns, directives, and resolved state
- supports native mode (`.hail` or first-line `<<:hail:`) and embedded mode (`.md` and other host formats)
- validates common document issues

## Install

```bash
npm install hail-parser
```

## API

```typescript
import { parse, tokenize, validate, stateAt } from 'hail-parser'

const doc = parse(source, { filename: 'example.hail' })
const tokens = tokenize(source)
const issues = validate(source)
const turnState = stateAt(doc, 0)
```

### `parse(source, options?)`

Parses a Hail document into:

- `mode`: `native` or `embedded`
- `version`: optional `<<:hail:` version
- `turns`: parsed turns with headers, body elements, and accumulated state
- `finalState`: durable/session/response directive state after the last turn

### `tokenize(source)`

Returns the raw token stream. Useful for debugging parser behavior.

### `validate(source)`

Returns a list of validation issues, each with `line`, `column`, `code`, `message`, and `severity`:

| Code | Severity | Rule |
|------|----------|------|
| E001 | error | Malformed directive |
| E002 | error | Too many segments in named directive |
| E003 | error | Unclosed braced block |
| W001 | warning | Separator missing surrounding blank lines |
| W002 | warning | Uppercase directive or speaker name |
| W003 | warning | `<<:hail:` version line not on first line |
| W004 | warning | Unclosed fenced code block |

### `stateAt(doc, turnIndex)`

Returns the directive state active after a specific turn.

## CLI

```bash
npx hail-parser document.md
npx hail-parser document.hail --tokens
npx hail-parser document.hail --state
npx hail-parser document.hail --turn 1 --state
npx hail-parser document.hail --summary
npx hail-parser document.hail --validate
npx hail-parser document.hail --validate --strict
```

`--strict` treats warnings as errors (exit 1 if any warnings present).

## Parsing Modes

Native mode:

- applies to `.hail` files
- also applies when the first line is `<<:hail: ...`
- treats `---` as a turn separator

Embedded mode:

- applies to `.md` and other host formats without first-line `<<:hail:`
- parses the document as a single turn
- leaves host-format `---` semantics alone

## Development

```bash
npm test
npm run build
```

## Status

Parser is implemented and tested locally. The package is not yet published to npm.
