# Hail

<!-- Collaboration metadata in this file uses Hail directives: https://github.com/anthonymaley/hail/blob/main/SPEC.md -->

^:context: Hail spec repo. Defines the Human-AI Interaction Layer protocol and ships hail-parser (TypeScript). Spec at v0.9.1, parser at v0.1.0 with 44 tests. Public repo, MIT licensed. Not yet published to npm.
^:goal: dogfood Hail in real repos, publish parser to npm, plan public launch
^:ownership: {
anthony: direction and design decisions
codex: implementation and spec hardening
claude: review, writing, and skriv voice
}
^:status: in_progress
^:constraint: keep the spec minimal; add directives only when real usage proves the need
^:constraint: no runtime dependencies in hail-parser
^:artifact: SPEC.md
^:artifact: packages/hail-parser/

## Session Workflow

When wrapping up a session (`/kerd:switch out` or `/kerd:dian`):
1. Update `TODO.md`: check off completed items, add new ones.
2. Update `docs/playbook.md`: if any new steps, tools, or config were added during the session, add them to the playbook. Always update the "Current Status" section.

## Doc Impact Table

| Doc | Update When |
|-----|-------------|
| README.md | Project description, setup steps, or structure changes |
| SPEC.md | Language design changes, new directives, syntax changes |
| docs/usage-guide.md | Practical usage rules or channel guidance changes |
| docs/playbook.md | New setup steps, integrations, gotchas, tech stack changes, or status changes |
| TODO.md | Every session close-out |
