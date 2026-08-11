#!/usr/bin/env bash
# Flow 19 (P0): Sign out → Sign back in
#
# Exercises the full auth cycle, ensuring the authentication listener
# flips the state.user cleanly and the dev magic-login form re-mounts.
# Regression guard for previous crash modes where a Supabase Realtime
# disconnect hung the auth stream.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 19: Sign out + sign back in"

AUTH_CYCLE_RESTORE_REQUIRED=0
AUTH_CYCLE_CLEANUP_RAN=0
cleanup_auth_cycle() {
  if [ "$AUTH_CYCLE_CLEANUP_RAN" = "1" ]; then
    return 0
  fi
  AUTH_CYCLE_CLEANUP_RAN=1
  if [ "$AUTH_CYCLE_RESTORE_REQUIRED" != "1" ]; then
    mark_flow_cleanup_complete
    return 0
  fi
  if ensure_verified_alice_session; then
    AUTH_CYCLE_RESTORE_REQUIRED=0
    mark_flow_cleanup_complete
    return 0
  fi
  mark_flow_cleanup_required
  return 1
}

auth_cycle_exit_cleanup() {
  local original_status=$?
  trap - EXIT
  if ! cleanup_auth_cycle; then
    exit 1
  fi
  exit "$original_status"
}

trap auth_cycle_exit_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if ! ensure_verified_alice_session; then
  fail "Verified Alice principal required before auth-cycle mutation"
  print_summary
  exit $FAIL
fi
AUTH_CYCLE_RESTORE_REQUIRED=1

fresh_launch; sleep 2
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: must be on Home before sign-out"
  print_summary; exit $FAIL
fi

capture "19_before_sign_out"
sign_out
sleep 1

if on_auth_page; then
  pass "Auth page reached after sign-out"
else
  fail "Auth page not reached after sign-out"
fi

capture "19_after_sign_out"

# Exercise the persisted auth boundary independently of the in-process
# sign-out transition. The explicit terminate keeps this checkpoint visible
# in the flow and makes the ordering contract testable.
terminate_app
fresh_launch; sleep 2

if on_auth_page && ! on_home_page; then
  pass "Auth page survives terminate/relaunch with Home absent"
else
  fail "Terminate/relaunch did not preserve the signed-out auth page with Home absent"
fi

capture "19_after_terminate_relaunch"

# Sign back in with same credentials only after the post-relaunch auth
# checkpoint has passed.
if has_dev_magic_login; then
  login_with_dev_magic
  sleep 2
  if on_onboarding_page; then
    complete_onboarding
    sleep 2
  fi
  if on_home_page; then
    if persisted_session_is_verified_alice; then
      pass "Sign-in after sign-out restored verified Alice on Home"
      AUTH_CYCLE_RESTORE_REQUIRED=0
      mark_flow_cleanup_complete
    else
      fail "Sign-in after sign-out reached Home under the wrong principal"
    fi
  else
    fail "Sign-in after sign-out did not reach Home"
  fi
else
  fail "Sign back in — dev magic login controls missing after sign-out"
  capture "19_dev_login_controls_missing"
fi

capture "19_signed_back_in"
print_summary
exit $FAIL
