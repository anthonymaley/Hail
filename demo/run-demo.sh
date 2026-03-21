#!/bin/bash
# Demo script for Hail terminal recording
# Run from the hail repo root

PARSER="node packages/hail-parser/dist/cli.js"
DEMO="demo"

clear

echo "═══════════════════════════════════════════════════"
echo "  Hail: Human-AI Interaction Layer"
echo "  Terminal Demo"
echo "═══════════════════════════════════════════════════"
echo ""
sleep 2

# ─────────────────────────────────────
# ACT 1: Writing Hail
# ─────────────────────────────────────

echo "━━━ Act 1: Writing Hail ━━━"
echo ""
sleep 1

# Stage 1: Human writes initial directives
echo "┌ Human sets up the collaboration:"
echo ""
sleep 1
cat "$DEMO/stage-1.hail"
echo ""
sleep 3

echo ""
echo "┌ Parser: --summary"
echo ""
sleep 1
$PARSER "$DEMO/stage-1.hail" --summary
sleep 3

# Stage 2: Claude responds
echo ""
echo ""
echo "┌ Claude responds with content + feedback:"
echo ""
sleep 1
echo "---"
echo ""
tail -n 12 "$DEMO/stage-2.hail"
echo ""
sleep 3

echo ""
echo "┌ Parser: --summary (after Claude's turn)"
echo ""
sleep 1
$PARSER "$DEMO/stage-2.hail" --summary
sleep 3

# Stage 3: Codex reviews + decision
echo ""
echo ""
echo "┌ Codex reviews + team records a decision:"
echo ""
sleep 1
tail -n 7 "$DEMO/stage-3.hail"
echo ""
sleep 3

echo ""
echo "┌ Parser: --summary (decision is now durable)"
echo ""
sleep 1
$PARSER "$DEMO/stage-3.hail" --summary
sleep 3

# Stage 4: Blocker
echo ""
echo ""
echo "┌ Blocker appears, status changes:"
echo ""
sleep 1
tail -n 4 "$DEMO/stage-4.hail"
echo ""
sleep 3

# Validation
echo ""
echo ""
echo "┌ Validation: catching malformed directives"
echo ""
sleep 1
cat "$DEMO/bad-example.hail"
echo ""
sleep 1
$PARSER "$DEMO/bad-example.hail" --validate 2>&1
echo ""
sleep 3

# ─────────────────────────────────────
# ACT 2: The Inbox
# ─────────────────────────────────────

echo ""
echo "━━━ Act 2: The Inbox ━━━"
echo ""
echo "Multiple agents write to INBOX.hail."
echo "Decisions, insights, and open questions accumulate."
echo "One command shows you what matters."
echo ""
sleep 3

echo "┌ hail-parser INBOX.hail --summary"
echo ""
sleep 1
$PARSER "$DEMO/demo-inbox.hail" --summary
sleep 5

echo ""
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Three prefixes. No tooling required."
echo "  github.com/anthonymaley/hail"
echo "═══════════════════════════════════════════════════"
echo ""
