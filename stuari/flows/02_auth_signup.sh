#!/usr/bin/env bash
# Flow 02: Auth Sign-Up + Profile Setup
#
# Goal: take a fresh install through the Dev magic login + onboarding flow
# (welcome carousel → profile → interests → completion).
#
# A disposable, server-provisioned principal is mandatory. Cached sessions and
# already-onboarded seed users are rejected rather than counted as coverage.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/release_lifecycle.sh"
require_release_lifecycle || exit 1
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 02: Auth Sign-Up + Profile Setup"

DISPOSABLE_ONBOARDING_USER_ID="${STUARI_DISPOSABLE_ONBOARDING_USER_ID:-}"
DISPOSABLE_ONBOARDING_EMAIL="${STUARI_DISPOSABLE_ONBOARDING_EMAIL:-}"
DISPOSABLE_ONBOARDING_PASSWORD="${STUARI_DISPOSABLE_ONBOARDING_PASSWORD:-}"
DISPOSABLE_ONBOARDING_PROVISION_COMMAND="${STUARI_DISPOSABLE_ONBOARDING_PROVISION_COMMAND:-}"
DISPOSABLE_ONBOARDING_VERIFY_FRESH_COMMAND="${STUARI_DISPOSABLE_ONBOARDING_VERIFY_FRESH_COMMAND:-}"
DISPOSABLE_ONBOARDING_VERIFY_COMPLETE_COMMAND="${STUARI_DISPOSABLE_ONBOARDING_VERIFY_COMPLETE_COMMAND:-}"
DISPOSABLE_ONBOARDING_CLEANUP_COMMAND="${STUARI_DISPOSABLE_ONBOARDING_CLEANUP_COMMAND:-}"
DISPOSABLE_ONBOARDING_VERIFY_CLEAN_COMMAND="${STUARI_DISPOSABLE_ONBOARDING_VERIFY_CLEAN_COMMAND:-}"
DISPOSABLE_ONBOARDING_MUTATION_STARTED=0
DISPOSABLE_ONBOARDING_CLEANUP_COMPLETE=0

validate_disposable_onboarding_contract() {
  [[ "$DISPOSABLE_ONBOARDING_USER_ID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || return 1
  [ -n "$DISPOSABLE_ONBOARDING_EMAIL" ] && [ -n "$DISPOSABLE_ONBOARDING_PASSWORD" ] || return 1
  case "$(printf '%s' "$DISPOSABLE_ONBOARDING_EMAIL" | tr '[:upper:]' '[:lower:]')" in
    alice@seed.dev|bob@seed.dev) return 1 ;;
  esac
  [ "$DISPOSABLE_ONBOARDING_USER_ID" != "$STUARI_AUTH_ALICE_USER_ID" ] || return 1
  [ "$DISPOSABLE_ONBOARDING_USER_ID" != "$STUARI_AUTH_BOB_USER_ID" ] || return 1
  [ -n "$DISPOSABLE_ONBOARDING_PROVISION_COMMAND" ] \
    && [ -n "$DISPOSABLE_ONBOARDING_VERIFY_FRESH_COMMAND" ] \
    && [ -n "$DISPOSABLE_ONBOARDING_VERIFY_COMPLETE_COMMAND" ] \
    && [ -n "$DISPOSABLE_ONBOARDING_CLEANUP_COMMAND" ] \
    && [ -n "$DISPOSABLE_ONBOARDING_VERIFY_CLEAN_COMMAND" ]
}

run_disposable_onboarding_hook() {
  local command="${1:-}"
  [ -n "$command" ] || return 1
  STUARI_DISPOSABLE_ONBOARDING_USER_ID="$DISPOSABLE_ONBOARDING_USER_ID" \
    STUARI_DISPOSABLE_ONBOARDING_EMAIL="$DISPOSABLE_ONBOARDING_EMAIL" \
    STUARI_DISPOSABLE_ONBOARDING_PASSWORD="$DISPOSABLE_ONBOARDING_PASSWORD" \
    /bin/bash -c "$command"
}

cleanup_disposable_onboarding_principal() {
  local status=0
  [ "$DISPOSABLE_ONBOARDING_CLEANUP_COMPLETE" = "0" ] || return 0
  [ "$DISPOSABLE_ONBOARDING_MUTATION_STARTED" = "1" ] || {
    mark_flow_cleanup_complete
    DISPOSABLE_ONBOARDING_CLEANUP_COMPLETE=1
    return 0
  }
  run_disposable_onboarding_hook "$DISPOSABLE_ONBOARDING_CLEANUP_COMMAND" || status=1
  run_disposable_onboarding_hook "$DISPOSABLE_ONBOARDING_VERIFY_CLEAN_COMMAND" || status=1
  if [ "$status" -eq 0 ]; then
    DISPOSABLE_ONBOARDING_CLEANUP_COMPLETE=1
    mark_flow_cleanup_complete
  else
    mark_flow_cleanup_required
  fi
  return "$status"
}

onboarding_exit_cleanup() {
  local original_status=$?
  trap - EXIT INT TERM
  if ! cleanup_disposable_onboarding_principal; then exit 1; fi
  exit "$original_status"
}
trap onboarding_exit_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! validate_disposable_onboarding_contract; then
  fail "Disposable onboarding principal contract is incomplete or uses a cached seed principal"
  print_summary
  exit $FAIL
fi

export STUARI_DISPOSABLE_ONBOARDING_USER_ID="$DISPOSABLE_ONBOARDING_USER_ID"
export STUARI_DISPOSABLE_ONBOARDING_EMAIL="$DISPOSABLE_ONBOARDING_EMAIL"
DISPOSABLE_ONBOARDING_MUTATION_STARTED=1
mark_flow_cleanup_required
if ! run_disposable_onboarding_hook "$DISPOSABLE_ONBOARDING_PROVISION_COMMAND" \
  || ! run_disposable_onboarding_hook "$DISPOSABLE_ONBOARDING_VERIFY_FRESH_COMMAND"; then
  fail "Disposable onboarding principal could not be provisioned and proven fresh"
  print_summary
  exit $FAIL
fi

if ! reset_simulator_auth_tokens_to_auth_page; then
  fail "Cached simulator session could not be removed before onboarding"
  print_summary
  exit $FAIL
fi

fresh_launch
sleep 2

# Give the relaunched app time to settle on either the cached signed-in
# home state or the auth page before deciding which path this flow can
# legitimately exercise.
wait_i=0
while [ $wait_i -lt 8 ]; do
  if on_home_page || on_auth_page; then
    break
  fi
  sleep 1
  wait_i=$((wait_i + 1))
done

if on_home_page; then
  fail "Cached or already-onboarded session reached Home before disposable onboarding"
  print_summary
  exit $FAIL
fi

# Must be on auth page — assert both forms are visible.
assert_element "$LABEL_DEV_SIGN_IN"     "label" 10 "Dev magic login visible"
assert_element "$LABEL_SIGN_IN_GOOGLE"  "label" 5  "Google OAuth button"
assert_element "$LABEL_SIGN_IN_APPLE"   "label" 5  "Apple OAuth button"
capture "02_auth_landing"

# Drive the exact disposable principal; never fall through to prefilled Alice.
if ! login_with_dev_magic "$DISPOSABLE_ONBOARDING_EMAIL" "$DISPOSABLE_ONBOARDING_PASSWORD"; then
  fail "Disposable onboarding principal could not sign in"
  print_summary
  exit $FAIL
fi

sleep 2
if on_onboarding_page; then
  info "Onboarding detected — running through steps"
  export STUARI_TEST_NAME="$(test_display_name)"
  complete_onboarding
  capture "02_post_onboarding"
else
  fail "Fresh disposable principal bypassed onboarding"
  print_summary
  exit $FAIL
fi

# Verify we landed on home.
sleep 2
if on_home_page; then
  pass "Reached Home after sign-in"
  capture "02_home_after_signup"
  if run_disposable_onboarding_hook "$DISPOSABLE_ONBOARDING_VERIFY_COMPLETE_COMMAND"; then
    pass "Disposable principal onboarding completion is persisted"
  else
    fail "Disposable principal onboarding completion was not persisted"
  fi
else
  fail "Did not reach Home after sign-in"
  capture "02_post_signin_failed"
fi

if ! cleanup_disposable_onboarding_principal; then
  fail "Disposable onboarding principal cleanup proof failed"
fi
print_summary
exit $FAIL
