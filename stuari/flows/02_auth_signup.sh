#!/usr/bin/env bash
# Flow 02: Auth Sign-Up + Profile Setup
#
# Goal: take a fresh install through the Dev magic login + onboarding flow
# (welcome carousel → profile → interests → completion).
#
# If we start with a prior session cached (`on_home_page`), the sign-up
# path is skipped and marked `skip` — the flow does not masquerade as
# passing when it couldn't exercise the onboarding path.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 02: Auth Sign-Up + Profile Setup"

fresh_launch
sleep 2

# If a prior run left us signed in, skip the whole flow rather than force
# a brittle sign-out→sign-in sequence — flow 03 covers that path.
if on_home_page; then
  info "Already signed in — skipping sign-up (this flow tests a fresh user)"
  skip "Dev magic login" "prior session still active"
  skip "Onboarding carousel"       "prior session still active"
  skip "Profile page"              "prior session still active"
  skip "Interests page"            "prior session still active"
  skip "Completion → Home"         "prior session still active"
  print_summary
  exit 0
fi

# Must be on auth page — assert both forms are visible.
assert_element "$LABEL_DEV_SIGN_IN"     "label" 10 "Dev magic login visible"
assert_element "$LABEL_SIGN_IN_GOOGLE"  "label" 5  "Google OAuth button"
assert_element "$LABEL_SIGN_IN_APPLE"   "label" 5  "Apple OAuth button"
capture "02_auth_landing"

# Drive the dev magic login.
login_with_test_user

# If we reached onboarding, walk through it using fixtures.
sleep 2
if on_onboarding_page; then
  info "Onboarding detected — running through steps"
  export STUARI_TEST_NAME="$(test_display_name)"
  complete_onboarding
  capture "02_post_onboarding"
fi

# Verify we landed on home.
sleep 2
if on_home_page; then
  pass "Reached Home after sign-in"
  capture "02_home_after_signup"
else
  fail "Did not reach Home after sign-in"
  capture "02_post_signin_failed"
fi

print_summary
exit $FAIL
