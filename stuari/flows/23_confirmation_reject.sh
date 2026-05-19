#!/usr/bin/env bash
# Flow 23 (P0): Reject a check-in
#
# Flow 10 covers the approve path. This covers the reject path by finding
# a pending check-in in the feed / home pending list and tapping the
# reject (thumb-down) affordance.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 23: Confirmation — reject"

reseed_confirmation_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1
capture "23_home"

found_conf=0
run_iez "$IEZ" ui swipe down >/dev/null 2>&1 || true
sleep 1

for _ in 1 2 3 4 5; do
  if tap_first_matching_label_regex '^Review check-in from ' '' \
    "Open reject confirmation from home"; then
    found_conf=1
    sleep 1.5
    break
  fi
  sleep 1
done

if [ "$found_conf" = "0" ]; then
  go_notifications
  sleep 1.5
  capture "23_notifications_list"
fi

for label in "Reject" "Reject check-in" "Review check-in" "Confirm check-in"; do
  if has_label "$label"; then
    tap_element "$label" "label" "Open reject confirmation '$label'"
    found_conf=1
    sleep 1.5
    break
  fi
done

if [ "$found_conf" = "0" ]; then
  skip "Reject affordance" "no pending confirmation entry was reachable"
  print_summary; exit $FAIL
fi

capture "23_confirmation_overlay"

if tap_first_matching_label_regex '^Reject' '' "Tap Reject"; then
  sleep 2
  capture "23_post_reject"
  pass "Tapped reject affordance"
else
  skip "Reject affordance" "confirmation opened but Reject button was not reachable"
fi

print_summary
exit $FAIL
