#!/usr/bin/env bash
# Stuari — compatibility smoke entry point.
#
# Smoke uses only non-mutating/direct-safe flows. Protected onboarding remains
# available through the aggregate full runner with explicit fixture hooks.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="${STUARI_RELEASE_RUNNER:-$SCRIPT_DIR/run_release_verification.sh}"
if [ "$#" -ne 0 ]; then
  printf 'Usage: bash test_smoke.sh\n' >&2
  exit 2
fi
export FLOW_TIMEOUT=60
export RELEASE_MODE=safe
export RELEASE_FLOWS='01 03 05'
exec bash "$RUNNER"
