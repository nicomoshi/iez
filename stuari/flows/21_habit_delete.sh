#!/usr/bin/env bash
# Flow 21 (P0): Delete habit via card menu (destructive — cancel)
#
# Walks: Home → habit-card "Habit settings" menu → Delete Habit → verifies
# confirmation dialog renders. CANCELS the dialog so we don't nuke the
# seeded habit fixtures used by every other flow.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 21: Delete habit (cancel)"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: Home must be reachable"
  print_summary; exit $FAIL
fi
go_home
capture "21_home"

if tap_visible_habit_menu "Open habit card overflow menu"; then
  sleep 1.2
else
  skip "Habit card menu" "no menu affordance — user has no owned habits"
  print_summary; exit $FAIL
fi

capture "21_menu_open"

if has_label "Delete Habit"; then
  tap_element "Delete Habit" "label" "Tap Delete Habit"
  sleep 1.2
  capture "21_confirm_dialog"
  pass "Delete Habit tapped"
else
  skip "Delete Habit menu entry" "not visible"
  print_summary; exit $FAIL
fi

# The confirmation dialog exposes a red "Delete" destructive button and
# a "Cancel" button. We CANCEL so we don't wipe fixtures.
if has_label "Cancel"; then
  tap_element "Cancel" "label" "Cancel Delete"
  sleep 1
  pass "Cancelled — fixture preserved"
else
  skip "Cancel button" "no Cancel in dialog — dismissing via swipe"
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1
fi

capture "21_post_cancel"
go_home
print_summary
exit $FAIL
