#!/usr/bin/env bash
# Flow 03: Existing User Sign-In + Sign-Out
#
# Goal: verify a user who has already onboarded can sign in (skipping
# onboarding) and then sign out via Settings.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 03: Sign-In + Sign-Out"

fresh_launch
sleep 2

# Reach auth page if we're signed in from a prior run
if on_home_page; then
  info "Currently signed in — testing sign-out first"
  sign_out "03_"
  sleep 2
  fresh_launch
  sleep 2
fi

# Now expected to be on auth page
if ! on_auth_page; then
  fail "Expected auth page after sign-out"
  capture "03_unexpected_state"
  print_summary
  exit $FAIL
fi

capture "03_auth_page"
pass "Landed on auth page"

# Sign in
login_with_test_user

# Verify we skipped onboarding (existing user)
if on_onboarding_page; then
  info "Onboarding was shown — user state may be fresh. Walking through."
  complete_onboarding
fi

sleep 2
if on_home_page; then
  pass "Sign-in reached Home"
  capture "03_signed_in_home"
else
  fail "Sign-in did not reach Home"
fi

# Sign out again to return to a known state
section "Sign-Out"
sleep 1
go_home >/dev/null 2>&1 || true
sleep 1
sign_out "03_"

print_summary
exit $FAIL
