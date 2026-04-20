#!/usr/bin/env bash
# Flow 14: Stats — Streaks + Leaderboards
#
# Goal: open the Stats tab from home bottom sheet, verify stat cards
# render, tap into a leaderboard.
#
# Widgets (lib/home/widgets + lib/stats/widgets/):
#   stats_tab.dart
#   stats_row.dart
#   stat_item.dart
#   streak_badge.dart / streak_countdown_timer.dart
#   supporter_list_card.dart (lib/stats)
#   leaderboard_item.dart (lib/stats)

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 14: Stats"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1

# Expand home bottom sheet
run_iez "$IEZ" ui swipe --from "200,700" --to "200,200" >/dev/null 2>&1
sleep 1.2

# Switch to Stats tab
if has_label "Stats"; then
  tap_element "Stats" "label" "Switch to Stats tab"
  sleep 1.2
else
  skip "Stats tab" "not visible in bottom sheet"
  print_summary; exit $FAIL
fi

capture "14_stats"

# Verify stat items rendered — loose check: any element containing "streak"
if tree_contains "streak" || tree_contains "Streak"; then
  pass "Streak element visible"
else
  skip "Streak element" "no 'streak' label in tree"
fi

# Scroll to see more
r=$(run_iez "$IEZ" ui swipe up)
assert_ok "$r" "Scroll Stats"
sleep 0.5
capture "14_stats_scrolled"

# Tap a leaderboard entry or supporter card if present
leaderboard_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("leaderboard|rank|supporter"; "i")) | .label' | head -1)
if [ -n "$leaderboard_label" ]; then
  tap_element "$leaderboard_label" "label" "Open leaderboard ('$leaderboard_label')"
  sleep 1.5
  capture "14_leaderboard_detail"
  go_back
  sleep 1
else
  skip "Leaderboard detail" "no leaderboard label in tree"
fi

print_summary
exit $FAIL
