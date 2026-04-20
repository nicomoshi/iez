#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — E2E Orchestrator
#
# Runs every flow in numeric order. Each flow is a self-contained script
# that sources lib/common.sh and reports its own pass/fail counters.
# The orchestrator collects per-flow results into an aggregate summary.
#
# Usage:
#   bash test_e2e.sh              # run all flows
#   VERBOSE=1 bash test_e2e.sh    # show JSON on failures
#   bash test_e2e.sh 05 06        # run only specific flow numbers
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLOWS_DIR="$SCRIPT_DIR/flows"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"

# Per-flow timeout (seconds)
FLOW_TIMEOUT="${FLOW_TIMEOUT:-180}"

# Determine flows to run
if [ $# -gt 0 ]; then
  # User passed specific flow numbers (e.g., 05 06)
  FLOWS=()
  for n in "$@"; do
    padded=$(printf '%02d' "$((10#$n))")
    for f in "$FLOWS_DIR/${padded}_"*.sh; do
      [ -f "$f" ] && FLOWS+=("$f")
    done
  done
else
  # Run everything
  FLOWS=( "$FLOWS_DIR"/*.sh )
fi

if [ ${#FLOWS[@]} -eq 0 ]; then
  echo "ERROR: No flow scripts found in $FLOWS_DIR" >&2
  exit 1
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║   Stuari — E2E Orchestrator                      ║"
echo "║   Bundle: $BUNDLE_ID"
echo "║   Device: ${DEVICE_ID:-auto}"
echo "║   Flows: ${#FLOWS[@]} scheduled"
echo "╚══════════════════════════════════════════════════╝"

# Per-flow results
declare -a RESULTS_NAME
declare -a RESULTS_CODE
declare -a RESULTS_DURATION

TOTAL_FLOW_PASS=0
TOTAL_FLOW_FAIL=0
START_TS=$(date +%s)

for flow in "${FLOWS[@]}"; do
  name=$(basename "$flow" .sh)
  echo ""
  echo "========================================================"
  echo " Running: $name"
  echo "========================================================"

  start=$(date +%s)

  # Run with timeout. gtimeout (coreutils) is preferred on macOS.
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$FLOW_TIMEOUT" bash "$flow"
  elif command -v timeout >/dev/null 2>&1; then
    timeout "$FLOW_TIMEOUT" bash "$flow"
  else
    bash "$flow"
  fi
  code=$?

  end=$(date +%s)
  dur=$((end - start))

  RESULTS_NAME+=("$name")
  RESULTS_CODE+=("$code")
  RESULTS_DURATION+=("$dur")

  if [ "$code" -eq 0 ]; then
    TOTAL_FLOW_PASS=$((TOTAL_FLOW_PASS + 1))
    printf '\n \033[1;32m▶ %s passed in %ss\033[0m\n' "$name" "$dur"
  elif [ "$code" -eq 124 ]; then
    TOTAL_FLOW_FAIL=$((TOTAL_FLOW_FAIL + 1))
    printf '\n \033[1;31m▶ %s TIMED OUT (%ss)\033[0m\n' "$name" "$dur"
  else
    TOTAL_FLOW_FAIL=$((TOTAL_FLOW_FAIL + 1))
    printf '\n \033[1;31m▶ %s failed (exit=%s) in %ss\033[0m\n' "$name" "$code" "$dur"
  fi
done

END_TS=$(date +%s)
TOTAL_TIME=$((END_TS - START_TS))

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Stuari E2E — Aggregate Results                 ║"
echo "╚══════════════════════════════════════════════════╝"
printf '%-32s %-8s %s\n' "FLOW" "RESULT" "TIME"
printf '%-32s %-8s %s\n' "--------------------------------" "--------" "------"
for i in "${!RESULTS_NAME[@]}"; do
  code="${RESULTS_CODE[$i]}"
  name="${RESULTS_NAME[$i]}"
  dur="${RESULTS_DURATION[$i]}"
  if [ "$code" -eq 0 ]; then
    printf '%-32s \033[1;32m%-8s\033[0m %ss\n' "$name" "PASS" "$dur"
  elif [ "$code" -eq 124 ]; then
    printf '%-32s \033[1;31m%-8s\033[0m %ss\n' "$name" "TIMEOUT" "$dur"
  else
    printf '%-32s \033[1;31m%-8s\033[0m %ss\n' "$name" "FAIL($code)" "$dur"
  fi
done
printf '\n \033[1;32m%d flows passed\033[0m, \033[1;31m%d flows failed\033[0m in %ss total\n' \
  "$TOTAL_FLOW_PASS" "$TOTAL_FLOW_FAIL" "$TOTAL_TIME"
echo ""
echo "Screenshots: $SCREENSHOTS/"

exit "$TOTAL_FLOW_FAIL"
