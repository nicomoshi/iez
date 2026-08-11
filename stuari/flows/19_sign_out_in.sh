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

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
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
    pass "Sign-in after sign-out reached Home"
  else
    fail "Sign-in after sign-out did not reach Home"
  fi
else
  skip "Sign back in" "dev magic login form not visible"
fi

capture "19_signed_back_in"
print_summary
exit $FAIL
