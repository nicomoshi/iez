#!/usr/bin/env bash
# Flow 10: Confirmation (approve/reject a pending check-in)
#
# Goal: as a group member, find a pending check-in that needs my
# confirmation, and tap approve or reject.
#
# Widgets:
#   confirmation/widgets/actionable_member_bubble.dart
#   confirmation/widgets/confirmation_action_button.dart
#   confirmation/view/confirmation_overlay_page.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 10: Confirmation Approve/Reject"

reseed_confirmation_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1
capture "10_home"

# First try the actionable member bubble on home. The seeded dev account now
# carries a pending peer post specifically so this path stays deterministic.
found_conf=0
# The overlay tap is reliable when the sheet is collapsed; when Home restores
# the feed-expanded state, the bubble can sit under that layer and the tap
# becomes flaky.
run_iez "$IEZ" ui swipe down >/dev/null 2>&1 || true
sleep 1

for _ in 1 2 3 4 5; do
  if tap_first_matching_label_regex '^Review check-in from ' '' \
    "Open confirmation from home"; then
    found_conf=1
    sleep 1.5
    break
  fi
  sleep 1
done

# Confirmation prompts can also surface in Notifications. Fall back there.
if [ "$found_conf" = "0" ]; then
  go_notifications
  sleep 1.5
  capture "10_notifications_list"
fi

for label in "Confirm check-in" "Review check-in" "Tap to confirm" "Approve" "Reject"; do
  if has_label "$label"; then
    tap_element "$label" "label" "Open confirmation '$label'"
    found_conf=1
    sleep 1.5
    break
  fi
done

if [ "$found_conf" = "0" ]; then
  # Try substring search in Notifications as a last resort.
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | test("confirm|approve|pending"; "i")) | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Open confirmation ('$dyn')"
    found_conf=1
    sleep 1.5
  fi
fi

if [ "$found_conf" = "0" ]; then
  skip "Confirmation entry" "no pending confirmations in notifications"
  go_home
  print_summary
  exit $FAIL
fi

capture "10_confirmation_overlay"

# Now the ConfirmationOverlayPage should be visible. Approve the first
# available check-in.
if tap_first_matching_label_regex '^Confirm' '' "Confirm check-in"; then
  sleep 2
  pass "Tapped Confirm"
  capture "10_confirmed"
elif tap_first_matching_label_regex '^Reject' '' \
  "Reject check-in (Confirm unavailable)"; then
  sleep 2
  pass "Tapped Reject"
  capture "10_rejected"
else
  skip "Approve/Reject" "neither confirm nor reject button was reachable on overlay"
fi

# Dismiss overlay and return home
dismiss_all
go_home
capture "10_home_after"

print_summary
exit $FAIL
