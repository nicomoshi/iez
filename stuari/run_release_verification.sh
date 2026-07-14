#!/usr/bin/env bash
# Stuari occurrence release visual/E2E verification on the selected simulator.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IEZ_REPO_DIR="${IEZ_REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
EVIDENCE_ROOT="${EVIDENCE_ROOT:-$SCRIPT_DIR/artifacts/release-$(date +%Y%m%d_%H%M%S)-$$}"
SCREENSHOTS="$EVIDENCE_ROOT/screenshots"
AX_TREES="$EVIDENCE_ROOT/ax"
LOG_DIR="$EVIDENCE_ROOT/logs"
RESULTS_FILE="$EVIDENCE_ROOT/flow_results.tsv"
FLOW_TIMEOUT="${FLOW_TIMEOUT:-300}"

mkdir -p "$SCREENSHOTS" "$AX_TREES" "$LOG_DIR"
printf 'flow\tresult\texit\tpass\tfail\tskip\ttotal\tduration_seconds\n' >"$RESULTS_FILE"

flows=(04 05 06 15 18 20 32 33 34 35 36)

run_flow() {
  local number="$1" flow name log start end duration code summary clean
  local passed failed skipped total result

  flow=$(find "$SCRIPT_DIR/flows" -maxdepth 1 -type f -name "${number}_*.sh" -print | head -1)
  if [ -z "$flow" ]; then
    printf '%s\tMISSING\t127\t0\t1\t0\t1\t0\n' "$number" >>"$RESULTS_FILE"
    return 0
  fi

  name=$(basename "$flow" .sh)
  log="$LOG_DIR/$name.log"
  start=$(date +%s)

  if command -v gtimeout >/dev/null 2>&1; then
    IEZ_REPO_DIR="$IEZ_REPO_DIR" \
      IEZ="$IEZ_REPO_DIR/bin/iez" \
      IEZ_DEVICE_UDID="$IEZ_DEVICE_UDID" \
      STUARI_BUNDLE_ID="${STUARI_BUNDLE_ID:-com.stuari.stuari.dev}" \
      SCREENSHOTS="$SCREENSHOTS" \
      AX_TREES="$AX_TREES" \
      gtimeout "$FLOW_TIMEOUT" /bin/bash "$flow" >"$log" 2>&1
  else
    IEZ_REPO_DIR="$IEZ_REPO_DIR" \
      IEZ="$IEZ_REPO_DIR/bin/iez" \
      IEZ_DEVICE_UDID="$IEZ_DEVICE_UDID" \
      STUARI_BUNDLE_ID="${STUARI_BUNDLE_ID:-com.stuari.stuari.dev}" \
      SCREENSHOTS="$SCREENSHOTS" \
      AX_TREES="$AX_TREES" \
      /bin/bash "$flow" >"$log" 2>&1
  fi
  code=$?

  end=$(date +%s)
  duration=$((end - start))
  summary=$(grep -a 'Results:' "$log" | tail -1)
  clean=$(printf '%s\n' "$summary" | sed $'s/\033\\[[0-9;]*m//g')
  passed=$(printf '%s\n' "$clean" | sed -E 's/.*Results: ([0-9]+) passed.*/\1/')
  failed=$(printf '%s\n' "$clean" | sed -E 's/.*\/ ([0-9]+) failed.*/\1/')
  skipped=$(printf '%s\n' "$clean" | sed -E 's/.*\/ ([0-9]+) skipped.*/\1/')
  total=$(printf '%s\n' "$clean" | sed -E 's/.*\/ ([0-9]+) total.*/\1/')

  case "$passed:$failed:$skipped:$total" in
    *[!0-9:]*|:::)
      passed=0
      failed=1
      skipped=0
      total=1
      ;;
  esac

  if [ "$code" -eq 124 ]; then
    result="TIMEOUT"
  elif [ "$failed" -gt 0 ] || [ "$code" -ne 0 ]; then
    result="FAIL"
  elif [ "$skipped" -gt 0 ]; then
    result="PASS_WITH_SKIP"
  else
    result="PASS"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$result" "$code" "$passed" "$failed" "$skipped" "$total" "$duration" \
    >>"$RESULTS_FILE"
  printf '%-36s %-15s %4ss\n' "$name" "$result" "$duration"
}

printf 'Stuari release verification\n'
printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
printf 'Device: %s\n' "${IEZ_DEVICE_UDID:-auto}"

for number in "${flows[@]}"; do
  run_flow "$number"
done

printf '\nResults: %s\n' "$RESULTS_FILE"

# Exit nonzero when any flow did not fully pass. Predeploy runs are expected
# to report fail-closed backend blocks; classification happens in the report,
# not by softening this exit code.
not_green=$(awk -F'\t' 'NR > 1 && $2 != "PASS" && $2 != "PASS_WITH_SKIP"' "$RESULTS_FILE" | wc -l | tr -d ' ')
[ "$not_green" -eq 0 ]
