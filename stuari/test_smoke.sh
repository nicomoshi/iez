#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Smoke Test (≤ 3 minutes)
#
# Runs the minimum-viable set: cold start + sign-in + one photo check-in.
# Use this as the fast inner-loop while developing; use test_e2e.sh for
# the full regression pass.
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run three flows with a 60s budget each
export FLOW_TIMEOUT=60

exec bash "$SCRIPT_DIR/test_e2e.sh" 01 02 05
