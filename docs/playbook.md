# Playbook: Hail

How to rebuild this project from scratch.

## Tech Stack

Pure spec project for now. No code dependencies yet. The spec lives in `SPEC.md` at the repo root.

## Setup

Clone the repo. Read `SPEC.md`.

## Architecture

Hail is a markup language spec. The core artifact is `SPEC.md` which defines syntax, directives, and document structure. Tooling (parsers, editors, CLI) will live alongside the spec as the project matures.

## Integrations

None yet.

## Deployment

Not applicable yet. The spec is the deliverable.

## Gotchas

Nothing yet.

## Current Status

Spec at v0.2.0 (draft). Covers the `^`/`v` directive system, scoping (header vs inline lifetimes), overrides and clearing, multi-line blocks, examples, output shape, document structure, and versioning. Full multi-turn example conversation in the spec. No tooling, no parser, no formal grammar yet.
