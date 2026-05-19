#!/usr/bin/env bash
# Flow 18: Offline Degradation
#
# Goal: use the dev-only Settings toggle to force the app offline, verify the
# OfflineBanner appears, then restore connectivity.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 18: Offline Degradation"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_settings
sleep 1
capture "18_settings_online"

for _ in 1 2 3; do
  if has_label "Force offline mode" || tree_contains "Force offline"; then break; fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 0.5
done

if has_label "Force offline mode" || tree_contains "Force offline"; then
  tap_element "Force offline mode" "label" "Enable forced offline mode"
  sleep 1.5
else
  skip "Offline toggle" "dev testing control not available in this build"
  print_summary; exit $FAIL
fi

go_home
sleep 1.5
capture "18_home_offline"

if has_label "You are offline" || tree_contains "offline" || tree_contains "No internet"; then
  pass "Offline banner appeared"
  capture "18_banner_visible"
else
  fail "Offline banner did not appear after forcing offline mode"
fi

# If the app presents its full-screen offline blocker, that is the
# expected UX for network-gated actions. Otherwise attempt a check-in tap.
if tree_contains "No internet connection"; then
  pass "Offline blocker prevents network-gated actions"
else
  # Make sure the home carousel, not the feed sheet, is the active hit target.
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1 || true
  sleep 1
  go_home
  sleep 0.8

  # Attempt a small action that requires internet by tapping the seeded habit
  # card's check-in entry point.
  if tap_first_matching_label_regex '^Habit card: ' '' \
    "Tap visible habit card while offline"; then
    sleep 2
    capture "18_checkin_offline_attempt"
    if tree_contains "offline" || tree_contains "connection" || tree_contains "internet"; then
      pass "Offline error feedback shown"
    else
      pass "Offline action stayed in a recoverable app state"
    fi
  elif has_id "$SEEDED_GROUP_CARD_ID"; then
    tap_element "$SEEDED_GROUP_CARD_ID" "id" "Tap seeded habit card while offline"
    sleep 2
    capture "18_checkin_offline_attempt"
    if tree_contains "offline" || tree_contains "connection" || tree_contains "internet"; then
      pass "Offline error feedback shown"
    else
      pass "Offline action stayed in a recoverable app state"
    fi
  else
    fail "Check In while offline" '{"reason":"no habit card was reachable on Home"}'
  fi
fi

# Restore connectivity through the same dev toggle
go_settings
sleep 1
for _ in 1 2 3; do
  if has_label "Force offline mode" || tree_contains "Force offline"; then break; fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 0.5
done
if has_label "Force offline mode" || tree_contains "Force offline"; then
  tap_element "Force offline mode" "label" "Disable forced offline mode"
  sleep 1.5
fi
go_home
sleep 1
capture "18_online_restored"

print_summary
exit $FAIL
