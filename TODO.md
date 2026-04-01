# TODO

## Current Session

Session complete. Nothing in progress.

### What was done (2026-04-01)

- [x] Audited README.md and docs for multi-agent / named directive coverage
- [x] Added "Multi-agent" section to README with named directive syntax
- [x] Added "Named Directives (Multi-Agent)" section to usage guide
- [x] Removed duplicate "Hail Collaboration" section from README
- [x] Added `--summary` to README CLI examples
- [x] Fixed premature `npm install` in README (package not published yet)
- [x] Added 38 spec conformance test fixtures from SPEC.md canonical examples
- [x] Added speaker name validation tests
- [x] Added specific "Too many segments" error for >2 segment named directives (E002)
- [x] Added validation warnings: uppercase names (W002), misplaced version line (W003)
- [x] Added error codes (E001-E003, W001-W004) and column numbers to ValidationIssue
- [x] Updated CLI `--validate` output to `ERROR E001 at line:column: message` format
- [x] Added `--strict` flag to treat warnings as errors
- [x] Updated all docs with new test count (58 → 113), error codes, --strict

## Next

- Publish `hail-parser` to npm
- Start using Hail in real repos and capture friction from actual usage
- Plan launch: blog post, social, community outreach
- VS Code syntax highlighting extension

## Backlog

- `^:clear:` bulk reset directive (defer until real usage proves the need)
- Parser compatibility matrix: parser version vs supported spec version
- Editor tooling beyond syntax highlighting: linting, format awareness, preview
