#!/usr/bin/env bash
# Stuari occurrence release visual/E2E verification on the selected simulator.

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IEZ_REPO_DIR="${IEZ_REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
EVIDENCE_ROOT="${EVIDENCE_ROOT:-$SCRIPT_DIR/artifacts/release-$(date +%Y%m%d_%H%M%S)-$$}"
SCREENSHOTS="$EVIDENCE_ROOT/screenshots"
AX_TREES="$EVIDENCE_ROOT/ax"
LOG_DIR="$EVIDENCE_ROOT/logs"
RESULTS_FILE="$EVIDENCE_ROOT/flow_results.tsv"
VISUAL_STATE_MANIFEST="$EVIDENCE_ROOT/visual-state-declarations.json"
EVIDENCE_EVENT_FILE="$EVIDENCE_ROOT/evidence-events.jsonl"
EVIDENCE_MANIFEST="$EVIDENCE_ROOT/evidence-manifest.json"
FLOW_TIMEOUT="${FLOW_TIMEOUT:-300}"
FLOW_TIMEOUT_GRACE="${FLOW_TIMEOUT_GRACE:-20}"
RELEASE_LOCK_DIR="${RELEASE_LOCK_DIR:-$SCRIPT_DIR/artifacts/.release-verification.lock}"
RELEASE_MODE="${RELEASE_MODE:-safe}"

# shellcheck source=lib/release_lifecycle.sh
source "$SCRIPT_DIR/lib/release_lifecycle.sh"
# shellcheck source=lib/evidence_validator.sh
source "$SCRIPT_DIR/lib/evidence_validator.sh"

safe_flows=(01 03 05 06 32 33 35 36)
protected_flows=(02 04 15 18 20 34)

release_flow_is_protected() {
  case "$1" in 02|04|15|18|20|34) return 0 ;; *) return 1 ;; esac
}

release_flow_numbers() {
  local raw="${RELEASE_FLOWS:-}" number="" seen=" "
  case "$RELEASE_MODE" in safe|protected|full) ;; *)
    printf 'Invalid RELEASE_MODE: %s (expected safe, protected, or full).\n' "$RELEASE_MODE" >&2
    return 1
  esac
  if [ -z "$raw" ]; then
    case "$RELEASE_MODE" in
      safe) printf '%s\n' "${safe_flows[@]}" ;;
      protected) printf '%s\n' "${protected_flows[@]}" ;;
      full)
        number=1
        while [ "$number" -le 36 ]; do printf '%02d\n' "$number"; number=$((number + 1)); done
        ;;
    esac
    return 0
  fi
  for number in $(printf '%s\n' "$raw" | tr ',' ' '); do
    [[ "$number" =~ ^[0-9][0-9]$ ]] || return 1
    case "$seen" in *" $number "*) return 1 ;; esac
    seen="$seen$number "
    case "$RELEASE_MODE" in
      safe) release_flow_is_protected "$number" && return 1 ;;
      protected) release_flow_is_protected "$number" || return 1 ;;
    esac
    printf '%s\n' "$number"
  done
}

flow_requires_cleanup() {
  case "$1" in
    02|04|05|06|15|18|19|20|34|36) return 0 ;;
    *) return 1 ;;
  esac
}

release_simulator_inventory_json() {
  if [ -n "${STUARI_SIMULATOR_INVENTORY_FILE:-}" ]; then
    cat "$STUARI_SIMULATOR_INVENTORY_FILE"
  elif [ -n "${STUARI_SIMULATOR_INVENTORY_COMMAND:-}" ]; then
    /bin/bash -c "$STUARI_SIMULATOR_INVENTORY_COMMAND"
  else
    xcrun simctl list devices available -j
  fi
}

validate_release_device() {
  local inventory=""
  if [ -z "${IEZ_DEVICE_UDID:-}" ]; then
    printf 'IEZ_DEVICE_UDID is required for release verification.\n' >&2
    return 1
  fi
  inventory="$(release_simulator_inventory_json 2>/dev/null)" || return 1
  printf '%s\n' "$inventory" | jq -e --arg udid "$IEZ_DEVICE_UDID" '
    [.devices[][]?
      | select(.udid == $udid and .name == "iPhone 17" and .isAvailable == true)
    ] | length == 1
  ' >/dev/null 2>&1
}

discover_disabled_is_explicit_na() {
  local number="$1" log="$2"
  case "$number" in
    12)
      grep -Fq 'Discover tab hidden while FeatureFlags.isDiscoverEnabled is false' "$log"
      ;;
    25)
      grep -Fq 'Discover comments unavailable while FeatureFlags.isDiscoverEnabled is false' "$log"
      ;;
    *)
      return 1
      ;;
  esac
}

flow35_flutter_threshold_evidence_is_valid_for_release() {
  local evidence="${STUARI_FLOW35_FLUTTER_EVIDENCE_FILE:-}"
  [ -n "$evidence" ] && [ -f "$evidence" ] && [ -s "$evidence" ] || return 1
  grep -Fq 'Given a 47 px horizontal drag starts over the habit carousel' "$evidence" || return 1
  grep -Fq 'Given a 48 px intentional horizontal drag starts over the habit carousel' "$evidence" || return 1
  grep -Fq 'All tests passed!' "$evidence" || return 1
  ! grep -Eq 'Some tests failed|[1-9][0-9]* tests? failed' "$evidence"
}

flow35_exact_threshold_is_explicit_na() {
  local number="$1" log="$2"
  [ "$number" = "35" ] || return 1
  grep -Fq 'Exact 48 pt simulator boundary (not applicable: Axe quantizes sub-50 pt swipes; focused 47/48 px Flutter widget evidence passed)' "$log" || return 1
  flow35_flutter_threshold_evidence_is_valid_for_release
}

run_flow_with_timeout() {
  local flow="$1" log="$2" cleanup_status="$3"
  local pid watchdog code timed_out_file
  timed_out_file="$log.timed-out"
  : >"$cleanup_status"
  rm -f "$timed_out_file"

  IEZ_REPO_DIR="$IEZ_REPO_DIR" \
    IEZ="$IEZ_REPO_DIR/bin/iez" \
    IEZ_DEVICE_UDID="${IEZ_DEVICE_UDID:-}" \
    STUARI_BUNDLE_ID="${STUARI_BUNDLE_ID:-com.stuari.stuari.dev}" \
    STUARI_CLEANUP_STATUS_FILE="$cleanup_status" \
    STUARI_DUE_NOW_CLEANUP_TIMEOUT_SECONDS="${STUARI_DUE_NOW_CLEANUP_TIMEOUT_SECONDS:-15}" \
    STUARI_RELEASE_LIFECYCLE_TOKEN="${STUARI_RELEASE_LIFECYCLE_TOKEN:-}" \
    STUARI_RELEASE_LIFECYCLE_LOCK_DIR="${STUARI_RELEASE_LIFECYCLE_LOCK_DIR:-}" \
    STUARI_FLOW35_FLUTTER_EVIDENCE_FILE="${STUARI_FLOW35_FLUTTER_EVIDENCE_FILE:-}" \
    STUARI_EVIDENCE_RUN_ID="${STUARI_EVIDENCE_RUN_ID:-}" \
    STUARI_EVIDENCE_EVENT_FILE="${STUARI_EVIDENCE_EVENT_FILE:-}" \
    SCREENSHOTS="$SCREENSHOTS" \
    AX_TREES="$AX_TREES" \
    /bin/bash "$flow" >"$log" 2>&1 &
  pid=$!

  (
    trap 'exit 0' TERM INT
    sleep "$FLOW_TIMEOUT"
    if kill -0 "$pid" 2>/dev/null; then
      printf '1\n' >"$timed_out_file"
      kill -TERM "$pid" 2>/dev/null || true
      # Let the flow's signal trap publish CLEANUP_REQUIRED/CLEAN first. A
      # plain shell waiting on a long-running child may need that child
      # interrupted to dispatch its trap, but once cleanup has started its
      # direct child is the bounded cleanup command and must be left alive.
      sleep 0.2
      if kill -0 "$pid" 2>/dev/null && [ ! -s "$cleanup_status" ]; then
        /usr/bin/pkill -TERM -P "$pid" 2>/dev/null || true
      fi
      sleep "$FLOW_TIMEOUT_GRACE"
      kill -KILL "$pid" 2>/dev/null || true
      /usr/bin/pkill -KILL -P "$pid" 2>/dev/null || true
    fi
  ) 2>/dev/null &
  watchdog=$!

  wait "$pid"
  code=$?
  # The watchdog may be blocked in its foreground sleep; stop our private
  # child immediately so a fast flow does not wait for the timeout duration.
  /usr/bin/pkill -KILL -P "$watchdog" 2>/dev/null || true
  kill -KILL "$watchdog" 2>/dev/null || true
  wait "$watchdog" 2>/dev/null || true

  if [ -s "$timed_out_file" ]; then
    return 124
  fi
  return "$code"
}

parse_flow_summary() {
  local log="$1" summary clean passed failed skipped na total
  summary="$(grep -a 'Results:' "$log" | tail -1)"
  clean="$(printf '%s\n' "$summary" | sed $'s/\033\\[[0-9;]*m//g')"
  passed="$(printf '%s\n' "$clean" | sed -nE 's/.*Results: ([0-9]+) passed.*/\1/p')"
  failed="$(printf '%s\n' "$clean" | sed -nE 's/.*\/ ([0-9]+) failed.*/\1/p')"
  skipped="$(printf '%s\n' "$clean" | sed -nE 's/.*\/ ([0-9]+) skipped.*/\1/p')"
  na="$(printf '%s\n' "$clean" | sed -nE 's/.*\/ ([0-9]+) n\/a.*/\1/p')"
  total="$(printf '%s\n' "$clean" | sed -nE 's/.*\/ ([0-9]+) total.*/\1/p')"

  if ! [[ "$passed" =~ ^[0-9]+$ ]] \
    || ! [[ "$failed" =~ ^[0-9]+$ ]] \
    || ! [[ "$skipped" =~ ^[0-9]+$ ]] \
    || ! [[ "$na" =~ ^[0-9]+$ ]] \
    || ! [[ "$total" =~ ^[0-9]+$ ]]; then
    printf '0\t1\t0\t0\t1\n'
    return 1
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$passed" "$failed" "$skipped" "$na" "$total"
}

classify_flow_result() {
  local number="$1" code="$2" failed="$3" skipped="$4" na="$5"
  local log="$6" cleanup_status="$7"

  if [ "$code" -eq 124 ]; then
    if flow_requires_cleanup "$number"; then
      if [ "$(cat "$cleanup_status" 2>/dev/null)" = "CLEAN" ]; then
        printf 'TIMEOUT_CLEANED\n'
      else
        printf 'TIMEOUT_CLEANUP_REQUIRED\n'
      fi
    else
      printf 'TIMEOUT\n'
    fi
  elif [ "$failed" -gt 0 ] || [ "$code" -ne 0 ]; then
    printf 'FAIL\n'
  elif discover_disabled_is_explicit_na "$number" "$log"; then
    printf 'N/A\n'
  elif [ "$skipped" -gt 0 ]; then
    printf 'BLOCKED_SKIP\n'
  elif [ "$na" -gt 0 ]; then
    if [ "$na" -eq 1 ] && flow35_exact_threshold_is_explicit_na "$number" "$log"; then
      printf 'PASS_WITH_NA\n'
    else
      printf 'BLOCKED_NA\n'
    fi
  else
    printf 'PASS\n'
  fi
}

run_flow() {
  local number="$1" flow="" candidate flow_count=0 name log cleanup_status start end duration code
  local counts passed failed skipped na total result cleanup_result

  if ! [[ "$number" =~ ^[0-9][0-9]$ ]]; then
    printf '%s\tINVALID_FLOW_NUMBER\t127\t0\t1\t0\t0\t1\t0\tN/A\n' "$number" >>"$RESULTS_FILE"
    return 0
  fi
  for candidate in "$SCRIPT_DIR"/flows/"${number}_"*.sh; do
    [ -f "$candidate" ] || continue
    flow="$candidate"
    flow_count=$((flow_count + 1))
  done
  if [ "$flow_count" -eq 0 ]; then
    printf '%s\tMISSING\t127\t0\t1\t0\t0\t1\t0\tN/A\n' "$number" >>"$RESULTS_FILE"
    return 0
  fi
  if [ "$flow_count" -ne 1 ]; then
    printf '%s\tAMBIGUOUS_FLOW\t127\t0\t1\t0\t0\t1\t0\tN/A\n' "$number" >>"$RESULTS_FILE"
    return 0
  fi

  name="$(basename "$flow" .sh)"
  log="$LOG_DIR/$name.log"
  cleanup_status="$LOG_DIR/$name.cleanup"

  start="$(date +%s)"
  run_flow_with_timeout "$flow" "$log" "$cleanup_status"
  code=$?
  end="$(date +%s)"
  duration=$((end - start))

  counts="$(parse_flow_summary "$log")"
  IFS=$'\t' read -r passed failed skipped na total <<<"$counts"
  result="$(classify_flow_result \
    "$number" "$code" "$failed" "$skipped" "$na" "$log" "$cleanup_status")"
  cleanup_result="$(cat "$cleanup_status" 2>/dev/null)"
  [ -n "$cleanup_result" ] || cleanup_result="N/A"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$name" "$result" "$code" "$passed" "$failed" "$skipped" "$na" "$total" "$duration" \
    "$cleanup_result" >>"$RESULTS_FILE"
  printf '%-36s %-28s %4ss\n' "$name" "$result" "$duration"
}

resolve_selected_flow_names() {
  local numbers="$1" names="$2" number="" candidate="" count=0 flow=""
  : >"$names"
  while IFS= read -r number; do
    count=0
    flow=""
    for candidate in "$SCRIPT_DIR"/flows/"${number}_"*.sh; do
      [ -f "$candidate" ] || continue
      flow="$candidate"
      count=$((count + 1))
    done
    [ "$count" -eq 1 ] || return 1
    basename "$flow" .sh >>"$names"
  done <"$numbers"
  [ -s "$names" ]
}

selected_flows_require_fixture_lifecycle() {
  local numbers="$1" number=""
  while IFS= read -r number; do
    release_flow_is_protected "$number" && return 0
  done <"$numbers"
  return 1
}

release_runner_exit_cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if ! release_lifecycle_restore_fixtures; then status=1; fi
  if ! release_release_lock; then status=1; fi
  exit "$status"
}

main() {
  local number not_green main_status=0 selected_numbers selected_names expected_label
  [[ "$FLOW_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || FLOW_TIMEOUT=300
  [[ "$FLOW_TIMEOUT_GRACE" =~ ^[1-9][0-9]*$ ]] || FLOW_TIMEOUT_GRACE=20

  if ! validate_release_device; then
    printf 'Release verification requires one available simulator named exactly iPhone 17 for IEZ_DEVICE_UDID.\n' >&2
    return 1
  fi
  if ! acquire_release_lock; then
    printf 'Release verification blocked: another run owns %s or lock ownership is unavailable.\n' \
      "$RELEASE_LOCK_DIR" >&2
    return 1
  fi
  trap release_runner_exit_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  mkdir -p "$SCREENSHOTS" "$AX_TREES" "$LOG_DIR"
  STUARI_EVIDENCE_RUN_ID="$RELEASE_LOCK_TOKEN"
  STUARI_EVIDENCE_EVENT_FILE="$EVIDENCE_EVENT_FILE"
  export STUARI_EVIDENCE_RUN_ID STUARI_EVIDENCE_EVENT_FILE
  : >"$EVIDENCE_EVENT_FILE"
  if ! STUARI_VISUAL_MANIFEST_OUTPUT="$VISUAL_STATE_MANIFEST" \
    bash "$SCRIPT_DIR/generate_visual_state_manifest.sh"; then
    printf 'Visual-state declaration generation failed closed.\n' >&2
    return 1
  fi
  selected_numbers="$EVIDENCE_ROOT/selected_flows.txt"
  selected_names="$EVIDENCE_ROOT/selected_flow_names.txt"
  if ! release_flow_numbers >"$selected_numbers" || [ ! -s "$selected_numbers" ]; then
    printf 'Release flow selection is invalid for RELEASE_MODE=%s.\n' "$RELEASE_MODE" >&2
    return 1
  fi
  if ! resolve_selected_flow_names "$selected_numbers" "$selected_names"; then
    printf 'Release flow selection contains a missing or ambiguous flow.\n' >&2
    return 1
  fi
  printf 'flow\tresult\texit\tpass\tfail\tskip\tna\ttotal\tduration_seconds\tcleanup\n' >"$RESULTS_FILE"

  if selected_flows_require_fixture_lifecycle "$selected_numbers"; then
    if ! release_lifecycle_setup_fixtures; then
      printf 'Protected release fixture setup failed; no protected flow was started.\n' >&2
      return 1
    fi
  fi

  printf 'Stuari release verification\n'
  printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
  printf 'Mode: %s\n' "$RELEASE_MODE"
  printf 'Device: %s (iPhone 17)\n' "$IEZ_DEVICE_UDID"

  while IFS= read -r number; do
    run_flow "$number"
  done <"$selected_numbers"

  printf '\nResults: %s\n' "$RESULTS_FILE"
  not_green="$(awk -F'\t' 'NR > 1 && $2 != "PASS" && $2 != "PASS_WITH_NA" && $2 != "N/A"' \
    "$RESULTS_FILE" | wc -l | tr -d ' ')"
  [ "$not_green" -eq 0 ] || main_status=1

  expected_label="${STUARI_EXPECTED_AX_APPLICATION_LABEL:-${STUARI_AX_APPLICATION_LABEL:-stuari-dev}}"
  if ! validate_release_evidence \
    "$expected_label" "$selected_names" "$VISUAL_STATE_MANIFEST"; then
    printf 'Release evidence validation or contact-sheet generation failed.\n' >&2
    main_status=1
  fi
  if ! release_lifecycle_restore_fixtures; then
    printf 'Release fixture cleanup or restoration proof failed.\n' >&2
    main_status=1
  fi
  if ! release_release_lock; then
    printf 'Release verification failed to release its exact owned lock: %s\n' \
      "$RELEASE_LOCK_DIR" >&2
    main_status=1
  fi
  trap - EXIT INT TERM
  return "$main_status"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
