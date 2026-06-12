#!/usr/bin/env bash
# Flow 33: Pull-to-refresh preserves selected habit
#
# Reproduces the bad UX Rudy reported: select a non-initial habit card,
# pull down to refresh while still on Home, and assert the visible selected
# habit remains the same after data resubscription/reordering.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 33: Habit Refresh Selection"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
wait_for_visible_habit_card 15 || true
capture "33_home_initial"
sleep 0.7

initial_id="$(current_visible_habit_card_id)"
initial_label="$(current_visible_habit_card_label)"
if [ -z "$initial_id" ] || [ -z "$initial_label" ]; then
  fail "Visible habit card detected before refresh"
  capture "33_no_visible_habit"
  print_summary
  exit $FAIL
fi
pass "Visible habit before carousel move: $initial_label"

selected_id="$initial_id"
selected_label="$initial_label"
for attempt in 1 2 3; do
  r=$(run_iez "$IEZ" ui swipe --from "360,340" --to "35,340")
  assert_ok "$r" "Attempt carousel move to another habit ($attempt)"
  sleep 1.5
  if ! wait_for_visible_habit_card 8; then
    info "Carousel move did not leave a visible app card; relaunching and using current selection"
    fresh_launch; sleep 2
    go_home
    wait_for_visible_habit_card 15 || true
  fi
  selected_id="$(current_visible_habit_card_id)"
  selected_label="$(current_visible_habit_card_label)"
  if [ -n "$selected_id" ] && [ "$selected_id" != "$initial_id" ]; then
    break
  fi
done

if [ "$selected_id" = "$initial_id" ]; then
  for attempt in 1 2 3; do
    r=$(run_iez "$IEZ" ui swipe --from "35,340" --to "360,340")
    assert_ok "$r" "Attempt carousel move opposite direction ($attempt)"
    sleep 1.5
    if ! wait_for_visible_habit_card 8; then
      info "Opposite carousel move did not leave a visible app card; relaunching and using current selection"
      fresh_launch; sleep 2
      go_home
      wait_for_visible_habit_card 15 || true
    fi
    selected_id="$(current_visible_habit_card_id)"
    selected_label="$(current_visible_habit_card_label)"
    if [ -n "$selected_id" ] && [ "$selected_id" != "$initial_id" ]; then
      break
    fi
  done
fi
capture "33_after_carousel_move"
sleep 0.7
wait_for_visible_habit_card 5 || true
selected_id="$(current_visible_habit_card_id)"
selected_label="$(current_visible_habit_card_label)"

if [ -z "$selected_id" ] || [ -z "$selected_label" ]; then
  fail "Visible habit card detected after carousel move"
  capture "33_no_habit_after_move"
  print_summary
  exit $FAIL
fi

if [ "$selected_id" = "$initial_id" ]; then
  fail "Carousel moved to a different habit before refresh"
  capture "33_carousel_did_not_move"
else
  pass "Selected non-initial habit: $selected_label"
fi

pull_to_refresh_home
capture "33_after_pull_to_refresh"
sleep 0.7
wait_for_visible_habit_card 5 || true

after_id="$(current_visible_habit_card_id)"
after_label="$(current_visible_habit_card_label)"
if [ "$after_id" = "$selected_id" ] || [ "$after_label" = "$selected_label" ]; then
  pass "Pull-to-refresh preserved selected habit"
else
  fail "Pull-to-refresh changed selected habit from '$selected_label' to '$after_label'"
  capture "33_selected_habit_changed"
fi

print_summary
exit $FAIL
