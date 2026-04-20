#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Authentication Helpers
#
# Stuari auth is OAuth-only: "Sign in with Apple" and "Sign in with Google".
# There is no email/password form. Sign-up and sign-in are the same flow;
# the onboarding step only runs for users who haven't completed it.
#
# For automated testing we tap the Google OAuth button and assume one of:
#   a) A test Google account is already signed in on the simulator, OR
#   b) The USE_MOCK_DATA=true flavor bypasses real OAuth (check .env.dev).
# If neither, the flow will fail at the ASWebAuthenticationSession stage
# (system webview, outside Flutter AX tree) and the test skips gracefully.
# ──────────────────────────────────────────────────────────────────────

if [ "${STUARI_AUTH_LOADED:-}" = "1" ]; then return 0; fi
STUARI_AUTH_LOADED=1

# Source common.sh relative to this file
_AUTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$_AUTH_DIR/common.sh"

# Labels on the authentication page
LABEL_SIGN_IN_APPLE="Sign in with Apple"
LABEL_SIGN_IN_GOOGLE="Sign in with Google"
LABEL_PRIVACY="Privacy Policy"
LABEL_TERMS="Terms of Use"

# ── Detection ────────────────────────────────────────────────────────

on_auth_page() {
  has_label "$LABEL_SIGN_IN_APPLE" || has_label "$LABEL_SIGN_IN_GOOGLE"
}

on_onboarding_page() {
  has_label "Get Started" || has_label "Skip" || tree_contains "Your name"
}

on_home_page() {
  has_label "Home tab" || has_label "Home tab, selected"
}

# ── Actions ──────────────────────────────────────────────────────────

# sign_in_google — tap the Google OAuth button.
# Returns 0 if tap succeeded (OAuth sheet may still fail in system webview).
sign_in_google() {
  if ! on_auth_page; then
    info "Not on auth page — skipping sign-in"
    return 1
  fi
  capture "auth_pre_google"
  local r
  r=$(run_iez "$IEZ" ui tap --label "$LABEL_SIGN_IN_GOOGLE")
  assert_ok "$r" "Tap Sign in with Google"
  sleep 3  # System webview takes a moment to appear
  capture "auth_post_google_tap"
}

# sign_in_apple — tap the Apple OAuth button.
sign_in_apple() {
  if ! on_auth_page; then
    info "Not on auth page — skipping sign-in"
    return 1
  fi
  capture "auth_pre_apple"
  local r
  r=$(run_iez "$IEZ" ui tap --label "$LABEL_SIGN_IN_APPLE")
  assert_ok "$r" "Tap Sign in with Apple"
  sleep 3
  capture "auth_post_apple_tap"
}

# login_with_test_user — tap Google OAuth, assume test creds are handled either
# by a pre-signed-in sim account or by the USE_MOCK_DATA flavor.
# Env vars (optional, reserved for future mock-bridge integration):
#   STUARI_TEST_EMAIL, STUARI_TEST_PASSWORD
login_with_test_user() {
  local email="${STUARI_TEST_EMAIL:-}"
  if [ -z "$email" ]; then
    info "STUARI_TEST_EMAIL not set — relying on existing sim account or mock flavor"
  else
    info "Using test account: $email"
  fi

  # Already signed in?
  if on_home_page; then
    pass "Already signed in (Home tab visible)"
    return 0
  fi

  # On auth page?
  if ! on_auth_page; then
    fail "Expected auth page but it was not visible"
    return 1
  fi

  sign_in_google

  # Give the OAuth flow up to 20s to complete
  local i=0
  while [ $i -lt 20 ]; do
    if on_home_page || on_onboarding_page; then
      pass "Sign-in completed (reached Home or Onboarding)"
      return 0
    fi
    sleep 1; i=$((i + 1))
  done

  fail "Sign-in did not reach Home within 20s (OAuth webview likely blocked)"
  return 1
}

# complete_onboarding — walk through the onboarding steps if present.
# Welcome → Profile (name, username) → Interests → Completion → Home.
complete_onboarding() {
  if ! on_onboarding_page; then
    info "Not on onboarding page — skipping"
    return 0
  fi
  capture "onboarding_welcome"

  # Welcome: skip to final slide then tap Get Started (or tap Skip)
  if has_label "Skip"; then
    tap_element "Skip" "label" "Skip welcome carousel"
    sleep 1
  fi
  if has_label "Get Started"; then
    tap_element "Get Started" "label" "Get Started"
    sleep 1.5
  fi
  capture "onboarding_profile"

  # Profile step: display name + username
  if tree_contains "Your name"; then
    type_into "Your name" "${STUARI_TEST_NAME:-Stu Ari}"
    # Try to dismiss keyboard before the username field
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.5
    type_into "username" "stuari_test_$(date +%s)"
    sleep 0.5
    # Continue button
    if has_label "Continue"; then
      tap_element "Continue" "label" "Profile → Continue"
      sleep 1.5
    fi
  fi
  capture "onboarding_interests"

  # Interests step: pick any and continue
  if has_label "Continue"; then
    tap_element "Continue" "label" "Interests → Continue"
    sleep 1.5
  fi

  # Completion: Create Habit
  if has_label "Create Habit"; then
    tap_element "Create Habit" "label" "Completion → Create Habit"
    sleep 2
  fi
  capture "onboarding_done"
}

# sign_out — navigate Settings → Sign out. Best-effort.
sign_out() {
  # Navigate to Settings tab
  if has_label "Settings tab"; then
    tap_element "Settings tab" "label" "Open Settings tab"
    sleep 1.2
  elif has_label "Settings tab, selected"; then
    pass "Settings tab already selected"
  else
    fail "Settings tab not visible — can't sign out"
    return 1
  fi
  capture "settings_page"

  # Scroll to find Sign Out (settings pages are long)
  local tries=0
  while [ $tries -lt 4 ]; do
    if has_label "Sign Out" || has_label "Sign out" || has_label "Log Out"; then
      break
    fi
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1
    sleep 0.6
    tries=$((tries + 1))
  done

  if has_label "Sign Out"; then
    tap_element "Sign Out" "label" "Tap Sign Out"
  elif has_label "Sign out"; then
    tap_element "Sign out" "label" "Tap Sign out"
  elif has_label "Log Out"; then
    tap_element "Log Out" "label" "Tap Log Out"
  else
    skip "Sign Out button" "not found in settings page"
    return 1
  fi
  sleep 1.5

  # Confirm dialog (if any): "Sign out" / "Confirm"
  if has_label "Confirm"; then
    tap_element "Confirm" "label" "Confirm sign out"
  elif has_label "Sign out"; then
    tap_element "Sign out" "label" "Confirm sign out"
  fi

  sleep 3  # Give auth state time to clear
  capture "post_sign_out"

  # Verify we're back on auth page
  if on_auth_page; then
    pass "Signed out (auth page visible)"
  else
    fail "Sign-out did not return to auth page"
  fi
}
