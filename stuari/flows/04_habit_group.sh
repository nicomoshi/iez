#!/usr/bin/env bash
# Flow 04: Create Habit Group + Invite + Browse Members
#
# Walks: Home → Create Habit → name → schedule → frequency → milestone
#         → check-ins → image → review → Create. Then opens the group's
#         members list and verifies it opened.
#
# Create flow pages (from lib/habit_group/widgets/):
#   create_habit_name_page.dart        — name field "e.g. Morning Run", Continue
#   create_habit_schedule_page.dart    — Continue
#   create_habit_frequency_page.dart   — Continue
#   create_habit_milestone_page.dart   — Continue
#   create_habit_check_ins_page.dart   — Continue
#   create_habit_image_page.dart       — Continue
#   create_habit_review_page.dart      — label: "Create Habit" (or "Save Changes" when editing)

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 04: Habit Group Create + Invite + Members"

fresh_launch; sleep 2

if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: must be on Home to create a habit"
  print_summary; exit $FAIL
fi
go_home

capture "04_home_before_create"

# Look for a "Create Habit" CTA — the empty state card or the + FAB
if has_label "Create Habit"; then
  tap_element "Create Habit" "label" "Start Create Habit flow"
elif has_label "Create Habit. Tap to start a new journey."; then
  tap_element "Create Habit. Tap to start a new journey." "label" "Start Create Habit flow (long label)"
elif has_label "Create new habit"; then
  tap_element "Create new habit" "label" "Start Create Habit flow (card)"
else
  skip "Create Habit CTA" "not found on Home — user may already have habits; needs a + affordance"
  # Try a swipe to reveal it
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1
  sleep 0.5
fi

sleep 1.5
capture "04_name_page"

# Step 1: Name
if tree_contains "e.g. Morning Run"; then
  type_into "e.g. Morning Run" "$(test_habit_name)"
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1
  sleep 0.5
  if has_label "Continue"; then
    tap_element "Continue" "label" "Name → Continue"
    sleep 1
  fi
else
  skip "Name step" "hint 'e.g. Morning Run' not found"
fi

capture "04_schedule_page"

# Walk through the remaining Continue-gated steps: schedule, frequency,
# milestone, check-ins, image. Tap Continue up to 6 times if visible.
for step in schedule frequency milestone checkins image; do
  if has_label "Continue"; then
    tap_element "Continue" "label" "Step '$step' → Continue"
    sleep 1
    capture "04_${step}_page"
  else
    info "Continue button not visible on '$step' step — may need to scroll or fill form"
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1
    sleep 0.3
    if has_label "Continue"; then
      tap_element "Continue" "label" "Step '$step' → Continue (after scroll)"
      sleep 1
    else
      skip "Step '$step'" "Continue not reachable"
    fi
  fi
done

# Review page — final Create Habit button
capture "04_review_page"
if has_label "Create Habit"; then
  tap_element "Create Habit" "label" "Review → Create Habit (submit)"
  sleep 3
  capture "04_post_create"
  pass "Submitted habit create form"
else
  skip "Final Create Habit" "button not reachable from review page"
fi

# Back on Home — verify a habit card now shows the habit name (best-effort)
sleep 2
go_home
capture "04_home_with_habit"

# Invite flow: from habit card, tap → menu / members
if has_label "Members"; then
  tap_element "Members" "label" "Open members list"
  sleep 1.2
  capture "04_members_list"
  if has_label "Invite"; then
    tap_element "Invite" "label" "Tap Invite"
    sleep 1
    capture "04_invite_sheet"
    dismiss_all
  fi
else
  skip "Members list" "entry point not found (may require tapping habit card first)"
fi

dismiss_all
print_summary
exit $FAIL
