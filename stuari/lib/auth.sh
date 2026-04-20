#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Authentication Helpers
#
# Stuari dev flavor ships a **Dev magic login** form (`Dev email`,
# `Dev password`, `Dev sign in` AX labels) that iEZ can drive without
# bouncing through the system Apple/Google OAuth webviews (which live
# outside the Flutter AX tree). These helpers prefer that form.
#
# For release/stg builds (or when `DevMagicLogin` is not rendered) we
# fall back to the OAuth buttons. The OAuth path will typically fail
# inside a simulator; tests should flag with `skip` in that case.
#
# Expected env:
#   STUARI_TEST_EMAIL    (default: alice@seed.dev)
#   STUARI_TEST_PASSWORD (default: iez-test-password-2026)
#   STUARI_TEST_NAME     (optional; used for onboarding profile step)
# ──────────────────────────────────────────────────────────────────────

if [ "${STUARI_AUTH_LOADED:-}" = "1" ]; then return 0; fi
STUARI_AUTH_LOADED=1

# Source common.sh relative to this file
_AUTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$_AUTH_DIR/common.sh"

# ── Labels ──────────────────────────────────────────────────────────
# Dev magic login form (dev flavor only)
LABEL_DEV_EMAIL="Dev email"
LABEL_DEV_PASSWORD="Dev password"
LABEL_DEV_SIGN_IN="Dev sign in"

# Fallback OAuth buttons (prod/stg)
LABEL_SIGN_IN_APPLE="Sign in with Apple"
LABEL_SIGN_IN_GOOGLE="Sign in with Google"
LABEL_PRIVACY="Privacy Policy"
LABEL_TERMS="Terms of Use"

# ── Detection ────────────────────────────────────────────────────────

on_auth_page() {
  has_label "$LABEL_DEV_SIGN_IN" \
    || has_label "$LABEL_SIGN_IN_APPLE" \
    || has_label "$LABEL_SIGN_IN_GOOGLE"
}

on_onboarding_page() {
  has_label "Get Started" || has_label "Skip" || tree_contains "Your name"
}

# Stuari's top nav exposes Home/Discover/Notifications/Profile/Settings
# tabs with labels like "Home tab" and "Home tab, selected". The home
# screen also has characteristic elements like "Create new habit" when
# the habit carousel renders. We treat any of those as "signed in".
on_home_page() {
  has_label "Home tab" \
    || has_label "Home tab, selected" \
    || has_label "Home tab, selected tab" \
    || has_label "Create new habit" \
    || has_label "Create Habit" \
    || has_label "Feed tab" \
    || tree_contains "Tab 1 of 3"
}

has_dev_magic_login() {
  has_label "$LABEL_DEV_SIGN_IN"
}

# ── Actions ──────────────────────────────────────────────────────────

# sign_in_google — tap the Google OAuth button (simulator will typically
# fail to complete the webview flow).
sign_in_google() {
  if ! has_label "$LABEL_SIGN_IN_GOOGLE"; then
    info "Google OAuth button not visible"
    return 1
  fi
  capture "auth_pre_google"
  local r
  r=$(run_iez "$IEZ" ui tap --label "$LABEL_SIGN_IN_GOOGLE")
  assert_ok "$r" "Tap Sign in with Google"
  sleep 3
  capture "auth_post_google_tap"
}

sign_in_apple() {
  if ! has_label "$LABEL_SIGN_IN_APPLE"; then
    info "Apple OAuth button not visible"
    return 1
  fi
  capture "auth_pre_apple"
  local r
  r=$(run_iez "$IEZ" ui tap --label "$LABEL_SIGN_IN_APPLE")
  assert_ok "$r" "Tap Sign in with Apple"
  sleep 3
  capture "auth_post_apple_tap"
}

# login_with_dev_magic — drive the dev-flavor email+password form.
# Returns 0 on reaching home/onboarding, 1 otherwise.
login_with_dev_magic() {
  local email="${STUARI_TEST_EMAIL:-alice@seed.dev}"
  local password="${STUARI_TEST_PASSWORD:-iez-test-password-2026}"

  info "Dev magic login as $email"
  capture "auth_pre_dev_magic"

  # The form ships with pre-filled default values, but we set them
  # explicitly for safety (e.g., when using a non-Alice account).
  # The DevMagicLogin form initialises the controllers with the default
  # alice@seed.dev credentials. For the common case (STUARI_TEST_EMAIL
  # unset OR == alice@seed.dev) we can skip typing entirely — just tap
  # Dev sign in. For any other account, overwrite the fields.
  local default_email="alice@seed.dev"
  local default_password="iez-test-password-2026"
  local need_email_type=1
  local need_password_type=1
  [ "$email" = "$default_email" ] && need_email_type=0
  [ "$password" = "$default_password" ] && need_password_type=0

  local r
  # Clear a focused field by sending backspace 40x (HID keycode 42).
  _clear_field() {
    for _ in $(seq 1 40); do
      run_iez "$IEZ" ui key 42 >/dev/null 2>&1
    done
  }

  if [ "$need_email_type" = "1" ]; then
    r=$(run_iez "$IEZ" ui tap --label "$LABEL_DEV_EMAIL")
    assert_ok "$r" "Focus Dev email"
    sleep 0.3
    _clear_field
    r=$(run_iez "$IEZ" ui type "$email")
    assert_ok "$r" "Type Dev email"
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
  fi

  if [ "$need_password_type" = "1" ]; then
    r=$(run_iez "$IEZ" ui tap --label "$LABEL_DEV_PASSWORD")
    assert_ok "$r" "Focus Dev password"
    sleep 0.3
    _clear_field
    r=$(run_iez "$IEZ" ui type "$password")
    assert_ok "$r" "Type Dev password"
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
  fi

  r=$(run_iez "$IEZ" ui tap --label "$LABEL_DEV_SIGN_IN")
  assert_ok "$r" "Tap Dev sign in"

  # Wait up to 20s for post-auth state (home or onboarding). The iOS
  # push-notification permission alert ("Would Like to Send You
  # Notifications") steals focus immediately after sign-in — dismiss
  # with "Allow" as soon as it appears so the AX tree can settle on
  # the app again.
  local i=0
  while [ $i -lt 20 ]; do
    if has_label "Allow" && has_label "Don't Allow"; then
      run_iez "$IEZ" ui tap --label "Allow" >/dev/null 2>&1
      sleep 1
    fi
    # Some iOS builds use a curly apostrophe in "Don't" (U+2019); guard
    # against the permission alert being mid-animation.
    if has_label "Allow" && tree_contains "Allow"; then
      run_iez "$IEZ" ui tap --label "Allow" >/dev/null 2>&1
      sleep 1
    fi
    if on_home_page || on_onboarding_page; then
      pass "Dev magic login reached Home or Onboarding (t=${i}s)"
      capture "auth_post_dev_magic"
      return 0
    fi
    sleep 1; i=$((i + 1))
  done
  fail "Dev magic login did not reach Home/Onboarding within 20s"
  capture "auth_dev_magic_timeout"
  return 1
}

# login_with_test_user — unified entry point used by every flow.
# 1) If already on Home → return.
# 2) Else if Dev magic login form is visible → drive it.
# 3) Else fall back to Google OAuth (best-effort; usually fails in sim).
login_with_test_user() {
  if on_home_page; then
    pass "Already signed in (Home tab visible)"
    return 0
  fi

  # If we're not on auth page, try to get there (cold launch may still
  # be on splash screen).
  local wait_i=0
  while [ $wait_i -lt 6 ]; do
    if on_auth_page; then break; fi
    sleep 1; wait_i=$((wait_i + 1))
  done
  if ! on_auth_page; then
    fail "Expected auth page but it was not visible"
    return 1
  fi

  if has_dev_magic_login; then
    login_with_dev_magic
    return $?
  fi

  info "Dev magic login not visible — falling back to Google OAuth"
  sign_in_google
  local i=0
  while [ $i -lt 20 ]; do
    if on_home_page || on_onboarding_page; then
      pass "OAuth sign-in reached Home or Onboarding"
      return 0
    fi
    sleep 1; i=$((i + 1))
  done
  fail "OAuth sign-in did not reach Home within 20s"
  return 1
}

# complete_onboarding — walk through the onboarding steps if present.
# Welcome → Profile (name, username) → Interests → Completion → Home.
#
# Each step is guarded so that running the helper on a page that is
# NOT onboarding becomes a no-op instead of emitting a cascade of
# spurious `fail` lines. `complete_onboarding` returns 0 if we walked
# the flow, 0 if we never needed to, and only reports failures for
# steps that started (the page was present) but didn't succeed.
complete_onboarding() {
  if ! on_onboarding_page; then
    info "Not on onboarding page — skipping"
    return 0
  fi
  capture "onboarding_welcome"

  # Welcome carousel: Skip → Get Started (either may be absent depending
  # on the carousel index).
  if has_label "Skip"; then
    tap_element "Skip" "label" "Skip welcome carousel"
    sleep 1
  fi
  if has_label "Get Started"; then
    tap_element "Get Started" "label" "Get Started"
    sleep 1.5
  fi
  capture "onboarding_profile"

  # Profile step: display name + username. The Display Name field has
  # no AX label (Flutter TextField without hint + with a section header
  # above); we tap by coordinates. Username field has hint="username".
  if tree_contains "Display Name" || tree_contains "Set up your profile"; then
    # Both TextFields lack stable AX labels once populated; tap by coords.
    # On iPhone 17 the Display Name field frame.y≈455, Username y≈563.
    # Tap middle, clear, type.
    run_iez "$IEZ" ui tap --coords "200,485" >/dev/null 2>&1
    sleep 0.3
    for _ in $(seq 1 30); do run_iez "$IEZ" ui key 42 >/dev/null 2>&1; done
    run_iez "$IEZ" ui type "${STUARI_TEST_NAME:-Stu Ari}" >/dev/null 2>&1
    sleep 0.3
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
    # Username field
    run_iez "$IEZ" ui tap --coords "200,595" >/dev/null 2>&1
    sleep 0.3
    for _ in $(seq 1 30); do run_iez "$IEZ" ui key 42 >/dev/null 2>&1; done
    # Username must be ≤ 20 chars. Use short prefix + 6-digit tail.
    run_iez "$IEZ" ui type "stu_$(date +%s | tail -c 7)" >/dev/null 2>&1
    sleep 0.5
    run_iez "$IEZ" ui swipe down >/dev/null 2>&1
    sleep 0.3
    if has_label "Continue"; then
      tap_element "Continue" "label" "Profile → Continue"
      sleep 1.5
    fi
    capture "onboarding_interests"

    # Interests step — pick one to enable Continue, then tap.
    for pick in "Fitness" "Productivity" "Social" "Creativity" "Learning"; do
      if has_label "$pick"; then
        tap_element "$pick" "label" "Select interest: $pick"
        sleep 0.3
        break
      fi
    done
    if has_label "Continue"; then
      tap_element "Continue" "label" "Interests → Continue"
      sleep 1.5
    fi
  fi

  # Completion step: only tap "Create Habit" if it exists. Suppress for
  # users whose onboarding short-circuits (e.g., pre-seeded profile).
  if has_label "Create Habit"; then
    tap_element "Create Habit" "label" "Completion → Create Habit"
    sleep 2
  fi
  capture "onboarding_done"
}

# sign_out — navigate Settings → Sign out. Best-effort.
#
# Implementation notes:
#  • The top nav "Settings tab" label is not exposed on the home tab (see
#    navigation.sh). Use the `go_settings` helper, which has a coordinate
#    fallback baked in.
#  • The Sign-Out confirm dialog produces TWO "Sign Out" labels (the
#    dialog title + the confirm button). We disambiguate by tapping the
#    last one — the button is laid out lower on the screen.
sign_out() {
  # Load navigation helper lazily (don't force at sourcing time).
  if ! declare -F go_settings >/dev/null 2>&1; then
    # shellcheck source=navigation.sh
    source "$_AUTH_DIR/navigation.sh"
  fi

  go_settings || {
    fail "Could not open Settings tab — can't sign out"
    return 1
  }
  sleep 1.2
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

  # Confirm dialog shows "Sign Out" twice: once as the title text, once as
  # the red confirm button. Read the tree and pick the button (highest y).
  local confirm_coords
  confirm_coords=$(run_iez "$IEZ" ui tree \
    | jq -r '[.data.tree[].children[]? | select(.role == "AXButton" and (.AXLabel == "Sign Out" or .AXLabel == "Sign out" or .AXLabel == "Confirm"))] | sort_by(.frame.y) | last | "\(.frame.x + (.frame.width / 2) | floor),\(.frame.y + (.frame.height / 2) | floor)"' 2>/dev/null)
  if [ -n "$confirm_coords" ] && [ "$confirm_coords" != "null" ] && [ "$confirm_coords" != "," ]; then
    local r
    r=$(run_iez "$IEZ" ui tap --coords "$confirm_coords")
    assert_ok "$r" "Confirm sign out ($confirm_coords)"
  elif has_label "Confirm"; then
    tap_element "Confirm" "label" "Confirm sign out"
  fi

  # Give auth state time to clear. The auth page re-renders the dev
  # magic login form + the privacy footer — on a signed-out simulator
  # this can take 5–7s under Impeller.
  local wait_i=0
  while [ $wait_i -lt 10 ]; do
    if on_auth_page; then
      pass "Signed out (auth page visible)"
      capture "post_sign_out"
      return 0
    fi
    sleep 1; wait_i=$((wait_i + 1))
  done
  capture "post_sign_out"
  fail "Sign-out did not return to auth page"
  return 1
}

# reset_auth_state — ensure the app starts each flow at the login screen.
# Used at the top of flows that need a clean slate.
reset_auth_state() {
  # Close the app if running
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1
  sleep 5
  if on_auth_page; then
    pass "Auth state reset (already on auth page)"
    return 0
  fi
  # Signed in from a previous run — sign out first.
  if on_home_page; then
    info "Previous session active — signing out"
    sign_out && return 0
    return 1
  fi
  skip "reset_auth_state" "neither auth nor home visible"
  return 1
}
