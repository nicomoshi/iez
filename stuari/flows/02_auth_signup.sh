#!/usr/bin/env bash
# Flow 02: Auth Sign-Up + Profile Setup
#
# Goal: take a fresh install through OAuth sign-in and the onboarding flow
# (welcome carousel → profile → interests → completion).
#
# NOTE: Stuari uses OAuth only (Apple/Google). There is NO email/password
# signup. This flow assumes either:
#   - USE_MOCK_DATA=true is set in .env.dev (bypasses real OAuth), OR
#   - The simulator already has a Google account ready to auto-accept.
#
# If OAuth pops a system webview that iez can't interact with, the test
# will log "skip" on auth steps and still verify UI elements it can see.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 02: Auth Sign-Up + Profile Setup"

fresh_launch

# Ensure we start unauthed
if on_home_page; then
  info "Already signed in — skipping sign-up path"
  skip "OAuth sign-in" "user already authenticated"
else
  assert_element "$LABEL_SIGN_IN_GOOGLE" "label" 10 "Google OAuth button"
  assert_element "$LABEL_SIGN_IN_APPLE" "label" 5 "Apple OAuth button"
  capture "02_auth_landing"

  # Tap Google — the mock-data flavor should short-circuit OAuth
  login_with_test_user
fi

# If we reached onboarding, walk through it using fixtures
if on_onboarding_page; then
  info "Onboarding detected — running through steps"
  # Override the helper's default name with a unique fixture
  export STUARI_TEST_NAME="$(test_display_name)"
  complete_onboarding
  capture "02_post_onboarding"
fi

# Verify we landed on home
sleep 2
if on_home_page; then
  pass "Reached Home after onboarding"
  capture "02_home_after_signup"
else
  fail "Did not reach Home after onboarding"
fi

print_summary
exit $FAIL
