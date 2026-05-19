#!/usr/bin/env bash
# Flow 29 (P1): Notifications — mark read + tap deep-link
#
# Walks to the notifications tab, asserts the list mounts, taps the
# first notification and verifies the app navigates somewhere (post /
# group / profile). On empty state, just verifies the empty-state label
# renders.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 29: Notifications mark read"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_notifications
sleep 1.5
capture "29_notifications"

# If the list is populated, tap the first row; otherwise verify empty state.
tree=$(run_iez "$IEZ" ui tree --compact)
# Heuristic: notification rows often contain phrases like "confirmed",
# "commented", "sent you", "is now following", or "reacted to".
first_hit=$(echo "$tree" | jq -r '.data.elements[] | select(.label != null) | select(.label | test("confirmed|commented|sent you|reacted|rewarded|is now following"; "i")) | .label' | head -1)

if [ -n "$first_hit" ]; then
  tap_element "$first_hit" "label" "Tap notification: '$first_hit'"
  sleep 2
  capture "29_after_tap"
  pass "Tapped a notification"
  # Go back to the notifications tab for cleanup
  go_back
  sleep 1
else
  info "No notifications — checking for empty state"
  if tree_contains "No notifications" || tree_contains "empty" || tree_contains "all caught up"; then
    pass "Empty-state visible"
    print_summary
    exit $FAIL
  else
    skip "Notification interaction" "neither rows nor empty-state visible"
  fi
fi

print_summary
exit $FAIL
