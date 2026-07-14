#!/usr/bin/env bash
# Flow 34: Delete Habit Persistence
#
# Covers Rudy's beta feedback directly:
#   create a unique habit → delete that exact habit → pull refresh →
#   terminate/relaunch → verify the deleted habit does not reappear.
#
# This flow intentionally does NOT delete shared seeded fixtures. It creates
# its own unique habit first by reusing Flow 04, then performs the destructive
# action on that per-run habit.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 34: Delete habit persists across refresh/relaunch"

HABIT_NAME="${STUARI_DELETE_HABIT_NAME:-Delete Me $(rand_tail)}"
export STUARI_FLOW04_HABIT_NAME="$HABIT_NAME"

info "Creating disposable habit: $HABIT_NAME"
SCREENSHOTS="$SCREENSHOTS" bash "$SCRIPT_DIR/04_habit_group.sh"
create_rc=$?
if [ "$create_rc" -ne 0 ]; then
  fail "Disposable habit created before delete flow"
  print_summary
  exit $FAIL
fi
pass "Disposable habit created: $HABIT_NAME"

fresh_launch
sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
wait_for_visible_habit_card 15 || true
capture "34_home_before_delete"

if wait_for_habit_name "$HABIT_NAME" 12; then
  pass "Disposable habit visible before delete"
else
  fail "Disposable habit not visible before delete: $HABIT_NAME"
  capture "34_missing_before_delete"
  print_summary
  exit $FAIL
fi

if tap_visible_habit_menu "Open habit settings for disposable habit"; then
  sleep 1.2
else
  fail "Habit settings menu visible for disposable habit"
  capture "34_no_habit_settings"
  print_summary
  exit $FAIL
fi

capture "34_delete_menu"

if has_label "Delete Habit"; then
  tap_element "Delete Habit" "label" "Choose Delete Habit"
  sleep 1.2
else
  fail "Delete Habit menu entry visible"
  capture "34_no_delete_entry"
  print_summary
  exit $FAIL
fi

capture "34_delete_confirm"

if has_label "Delete"; then
  tap_element "Delete" "label" "Confirm destructive delete"
  sleep 4
else
  fail "Delete confirmation button visible"
  capture "34_no_confirm_delete"
  print_summary
  exit $FAIL
fi

go_home
sleep 1.5
capture "34_after_delete"
if tree_contains "$HABIT_NAME"; then
  fail "Deleted habit removed immediately from Home"
  capture "34_still_visible_after_delete"
else
  pass "Deleted habit removed immediately from Home"
fi

pull_to_refresh_home
capture "34_after_pull_to_refresh"
if tree_contains "$HABIT_NAME"; then
  fail "Deleted habit stays deleted after pull-to-refresh"
  capture "34_reappeared_after_refresh"
else
  pass "Deleted habit stays deleted after pull-to-refresh"
fi

terminate_app
fresh_launch
sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
wait_for_visible_habit_card 10 || true
capture "34_after_relaunch"

if tree_contains "$HABIT_NAME"; then
  fail "Deleted habit stays deleted after app relaunch"
  capture "34_reappeared_after_relaunch"
else
  pass "Deleted habit stays deleted after app relaunch"
fi

print_summary
exit $FAIL
