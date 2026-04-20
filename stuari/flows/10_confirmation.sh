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

section "Flow 10: Confirmation Approve/Reject"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1
capture "10_home"

# Confirmation prompts surface in Notifications (tab badge) or directly
# as an overlay over the home screen. Check Notifications first.
go_notifications
sleep 1.5
capture "10_notifications_list"

# Look for a "Confirm", "Approve", or pending-review notification
found_conf=0
for label in "Confirm check-in" "Review check-in" "Tap to confirm" "Approve" "Reject"; do
  if has_label "$label"; then
    tap_element "$label" "label" "Open confirmation '$label'"
    found_conf=1
    sleep 1.5
    break
  fi
done

if [ "$found_conf" = "0" ]; then
  # Try substring search
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
if has_label "Approve"; then
  tap_element "Approve" "label" "Approve check-in"
  sleep 2
  pass "Tapped Approve"
  capture "10_approved"
elif has_label "Reject"; then
  tap_element "Reject" "label" "Reject check-in (Approve unavailable)"
  sleep 2
  pass "Tapped Reject"
  capture "10_rejected"
else
  skip "Approve/Reject" "neither button found on overlay"
fi

# Dismiss overlay and return home
dismiss_all
go_home
capture "10_home_after"

print_summary
exit $FAIL
