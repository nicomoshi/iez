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
FLOW_TIMEOUT="${FLOW_TIMEOUT:-300}"
FLOW_TIMEOUT_GRACE="${FLOW_TIMEOUT_GRACE:-20}"
RELEASE_LOCK_DIR="${RELEASE_LOCK_DIR:-$SCRIPT_DIR/artifacts/.release-verification.lock}"
RELEASE_LOCK_OWNED=0
RELEASE_LOCK_TOKEN=""

default_flows=(05 06 15 18 32 33 34 35 36)

acquire_release_lock() {
  local token=""
  mkdir -p "$(dirname "$RELEASE_LOCK_DIR")" || return 1
  token="$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$token" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] || return 1
  if ! mkdir "$RELEASE_LOCK_DIR" 2>/dev/null; then
    return 1
  fi
  if ! printf '%s\n' "$token" >"$RELEASE_LOCK_DIR/owner"; then
    rmdir "$RELEASE_LOCK_DIR" 2>/dev/null || true
    return 1
  fi
  RELEASE_LOCK_TOKEN="$token"
  RELEASE_LOCK_OWNED=1
}

release_release_lock() {
  local owner=""
  [ "$RELEASE_LOCK_OWNED" = "1" ] || return 0
  owner="$(cat "$RELEASE_LOCK_DIR/owner" 2>/dev/null)"
  if [ -z "$RELEASE_LOCK_TOKEN" ] || [ "$owner" != "$RELEASE_LOCK_TOKEN" ]; then
    return 1
  fi
  rm -f "$RELEASE_LOCK_DIR/owner" || return 1
  rmdir "$RELEASE_LOCK_DIR" || return 1
  RELEASE_LOCK_OWNED=0
  RELEASE_LOCK_TOKEN=""
}

release_flow_numbers() {
  local raw="${RELEASE_FLOWS:-}"
  if [ -z "$raw" ]; then
    printf '%s\n' "${default_flows[@]}"
    return 0
  fi
  printf '%s\n' "$raw" | tr ',' ' ' | tr ' ' '\n' | sed '/^$/d'
}

flow_requires_cleanup() {
  case "$1" in
    04|05|06|15|18|19|20|34|36) return 0 ;;
    *) return 1 ;;
  esac
}

flow_is_blocked_unsafe_mutation() {
  case "$1" in
    04|15|18|20) return 0 ;;
    *) return 1 ;;
  esac
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
    STUARI_FLOW35_FLUTTER_EVIDENCE_FILE="${STUARI_FLOW35_FLUTTER_EVIDENCE_FILE:-}" \
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
      /usr/bin/pkill -TERM -P "$pid" 2>/dev/null || true
      sleep "$FLOW_TIMEOUT_GRACE"
      kill -KILL "$pid" 2>/dev/null || true
      /usr/bin/pkill -KILL -P "$pid" 2>/dev/null || true
    fi
  ) 2>/dev/null &
  watchdog=$!

  wait "$pid"
  code=$?
  kill "$watchdog" 2>/dev/null || true
  /usr/bin/pkill -TERM -P "$watchdog" 2>/dev/null || true
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
  if flow_is_blocked_unsafe_mutation "$number"; then
    printf '%s\tBLOCKED_UNSAFE_MUTATION\t126\t0\t1\t0\t0\t1\t0\tNOT_RUN\n' \
      "$name" >>"$RESULTS_FILE"
    printf '%-36s %-28s %4ss\n' "$name" "BLOCKED_UNSAFE_MUTATION" "0"
    return 0
  fi

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

main() {
  local number not_green main_status=0
  [[ "$FLOW_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || FLOW_TIMEOUT=300
  [[ "$FLOW_TIMEOUT_GRACE" =~ ^[1-9][0-9]*$ ]] || FLOW_TIMEOUT_GRACE=20

  if ! acquire_release_lock; then
    printf 'Release verification blocked: another run owns %s or lock ownership is unavailable.\n' \
      "$RELEASE_LOCK_DIR" >&2
    return 1
  fi
  trap release_release_lock EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  mkdir -p "$SCREENSHOTS" "$AX_TREES" "$LOG_DIR"
  printf 'flow\tresult\texit\tpass\tfail\tskip\tna\ttotal\tduration_seconds\tcleanup\n' >"$RESULTS_FILE"

  printf 'Stuari release verification\n'
  printf 'Evidence: %s\n' "$EVIDENCE_ROOT"
  printf 'Device: %s\n' "${IEZ_DEVICE_UDID:-auto}"

  while IFS= read -r number; do
    run_flow "$number"
  done < <(release_flow_numbers)

  printf '\nResults: %s\n' "$RESULTS_FILE"
  not_green="$(awk -F'\t' 'NR > 1 && $2 != "PASS" && $2 != "PASS_WITH_NA" && $2 != "N/A"' \
    "$RESULTS_FILE" | wc -l | tr -d ' ')"
  [ "$not_green" -eq 0 ] || main_status=1

  trap - EXIT INT TERM
  if ! release_release_lock; then
    printf 'Release verification failed to release its exact owned lock: %s\n' \
      "$RELEASE_LOCK_DIR" >&2
    return 1
  fi
  return "$main_status"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
