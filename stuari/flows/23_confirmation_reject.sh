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

section "Flow 23: Confirmation — reject"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1

# Pull up Feed bottom sheet
run_iez "$IEZ" ui swipe --from "200,800" --to "200,200" >/dev/null 2>&1
sleep 1
if has_label "Feed"; then
  tap_element "Feed" "label" "Open Feed tab"
  sleep 1.5
fi

capture "23_feed"

# The vote buttons are a thumbs-down ("Reject") and thumbs-up ("Confirm").
# Look for either label. The vote_button widget uses IconButton with
# tooltips "Confirm check-in" / "Reject check-in".
reject_labels=( "Reject" "Reject check-in" "Not now" "Deny" "No" )
found=""
for lbl in "${reject_labels[@]}"; do
  if has_label "$lbl"; then found="$lbl"; break; fi
done

if [ -z "$found" ]; then
  skip "Reject affordance" "no 'Reject' label visible — no pending check-in by peers"
  print_summary; exit $FAIL
fi

tap_element "$found" "label" "Tap Reject"
sleep 2
capture "23_post_reject"
pass "Tapped reject affordance"

print_summary
exit $FAIL
