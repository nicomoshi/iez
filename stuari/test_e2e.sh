#!/usr/bin/env bash
# Stuari — compatibility E2E entry point.
#
# This wrapper delegates every run to run_release_verification.sh. It never
# executes a flow script directly; aggregate lock, lifecycle, timeout, result,
# and evidence policy stay in one runner.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="${STUARI_RELEASE_RUNNER:-$SCRIPT_DIR/run_release_verification.sh}"
selection=""
requires_lifecycle=0
seen=" "
for raw in "$@"; do
  case "$raw" in
    [1-9]) number="0$raw" ;;
    0[1-9]|1[0-9]|2[0-9]|3[0-6]) number="$raw" ;;
    *) printf 'Invalid flow selection: %s (expected 1-36).\n' "$raw" >&2; exit 2 ;;
  esac
  case "$seen" in *" $number "*) printf 'Duplicate flow selection: %s.\n' "$number" >&2; exit 2 ;; esac
  seen="$seen$number "
  case "$number" in 02|04|15|18|20|34) requires_lifecycle=1 ;; esac
  if [ -n "$selection" ]; then selection="$selection "; fi
  selection="$selection$number"
done

if [ -n "$selection" ]; then
  if [ "$requires_lifecycle" -eq 1 ]; then
    export RELEASE_MODE=full
  else
    export RELEASE_MODE=safe
  fi
  export RELEASE_FLOWS="$selection"
else
  direct_mode="${STUARI_DIRECT_RUN_MODE:-safe}"
  case "$direct_mode" in
    safe|protected|full) export RELEASE_MODE="$direct_mode" ;;
    *) printf 'Invalid STUARI_DIRECT_RUN_MODE: %s.\n' "$direct_mode" >&2; exit 2 ;;
  esac
  unset RELEASE_FLOWS
fi
exec bash "$RUNNER"
