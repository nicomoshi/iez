#!/usr/bin/env bash
# Flow 32 (P1): Open Habit Detail from habit card menu
#
# Walks: Home → three-dot habit card menu → "View Details" → asserts
# HabitDetailPage shell (cover image, name, members, go-back) → back → Home.
#
# The HabitDetailPage is reached via HabitCardMenu's "View Details" action
# (see lib/home/widgets/habit_card_menu.dart). The action is always shown
# (owner + non-owner), so this flow is safe for any seeded habit regardless
# of the current user's role.
#
# Source-of-truth widgets:
#   lib/habit_detail/view/habit_detail_page.dart
#   lib/habit_detail/widgets/habit_header.dart     (back button, cover image)
#   lib/habit_detail/widgets/members_section.dart  ("Members" heading)
#   lib/habit_detail/widgets/habit_stats_row.dart  ("Streak", "Check-ins")

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 32: Habit Detail (card menu → View Details)"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: Home must be reachable"
  print_summary; exit $FAIL
fi
go_home
capture "32_home_before"

# Open the three-dot menu on the currently-selected habit card.
# HabitCardMenu exposes a Semantics(button:true, label:'Habit settings')
# for every habit (owner and non-owner) as of feat/wire-habit-detail.
if has_label "Habit settings"; then
  tap_element "Habit settings" "label" "Open habit card overflow menu"
  sleep 1.2
  capture "32_menu_open"
else
  skip "Habit card menu" "no menu affordance — user may not have any habits"
  print_summary; exit $FAIL
fi

# Tap "View Details" — new menu entry (always present, not owner-gated).
if has_label "View Details"; then
  tap_element "View Details" "label" "Tap View Details"
  sleep 2
  capture "32_detail_page"
  pass "Tapped View Details — entering HabitDetailPage"
else
  fail "View Details entry missing from habit card menu"
  print_summary; exit $FAIL
fi

# Assert HabitDetailPage is visible by checking for its distinctive labels.
# The page always renders:
#   - "Go back"       (IconButton in HabitHeader)
#   - "Open group chat" (IconButton in HabitHeader)
#   - "Members"       (heading in MembersSection)
#   - Stat labels: "Streak", "Avg Streak", "Check-ins" (HabitStatsRow)
# For seeded habits with a cover image, "<Name> group cover image" is also
# present via Semantics on the Image.network widget.

assert_element "Go back"         "label" 8  "HabitDetailPage back button"
assert_element "Open group chat" "label" 4  "HabitDetailPage chat button"
assert_element "Members"         "label" 4  "HabitDetailPage Members heading"
assert_element "Streak"          "label" 4  "HabitDetailPage Streak stat"
assert_element "Check-ins"       "label" 4  "HabitDetailPage Check-ins stat"

# Best-effort: the seeded Morning Runs habit has a cover image, so check
# for its semantic label. Non-seeded builds may lack cover images — skip
# rather than fail.
if has_label "Morning Runs group cover image"; then
  pass "Morning Runs cover image rendered"
elif tree_contains " group cover image"; then
  pass "Group cover image rendered (dynamic name)"
else
  skip "Group cover image" "no image label found — habit may lack a cover"
fi

# Tap back → verify we return to Home.
tap_element "Go back" "label" "Tap HabitDetailPage back button"
sleep 1.5
capture "32_after_back"

if on_home_page; then
  pass "Returned to Home after back"
else
  fail "Back from HabitDetailPage did not return to Home"
fi

dismiss_all
print_summary
exit $FAIL
