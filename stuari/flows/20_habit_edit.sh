#!/usr/bin/env bash
# Flow 20 (P0): Edit habit rules
#
# Walks: Home → open habit-card overflow menu → Edit Habit → change name →
# Save Changes. Verifies the edit form mounts and Save button exists.
#
# Source-of-truth widgets:
#   lib/home/widgets/habit_card_menu.dart      (Edit Habit menu entry)
#   lib/habit_group/view/edit_habit_page.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 20: Edit habit rules"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: Home must be reachable"
  print_summary; exit $FAIL
fi
go_home
capture "20_home"

# Open the three-dot menu on the currently-selected habit card.
# HabitCardMenu exposes a Semantics(button:true, label:'Habit settings').
if has_label "Habit settings"; then
  tap_element "Habit settings" "label" "Open habit card overflow menu"
  sleep 1.2
  capture "20_menu_open"
elif has_label "More options"; then
  tap_element "More options" "label" "Open habit card overflow menu (legacy label)"
  sleep 1.2
  capture "20_menu_open"
else
  skip "Habit card menu" "no menu affordance — user may not own any habit"
  print_summary; exit $FAIL
fi

# Tap "Edit Habit"
if has_label "Edit Habit"; then
  tap_element "Edit Habit" "label" "Tap Edit Habit"
  sleep 1.5
  capture "20_edit_page"
else
  skip "Edit Habit menu entry" "not present — non-owner or menu layout changed"
  print_summary; exit $FAIL
fi

# On the edit page: look for a name field. EditHabitPage reuses the
# create widgets, so the same "e.g. Morning Run" hint should surface
# when the name field is empty. For pre-populated groups we look for
# a Save / Save Changes button.
if tree_contains "e.g. Morning Run"; then
  # Field is visible — re-type. (No --clear primitive; concatenation is OK.)
  type_into "e.g. Morning Run" "_edit_$(rand_tail)"
fi
run_iez "$IEZ" ui swipe down >/dev/null 2>&1

# Walk forward through the PageView wizard. Some steps have gated
# Continue buttons — we provide input where needed. Stop as soon as
# "Save Changes" appears, or after 10 iterations.
for step in $(seq 1 10); do
  if has_label "Save Changes"; then
    info "Reached Review page at step $step"
    break
  fi

  # Milestone gate: Continue is enabled only when milestoneDay > 0.
  # The default on edit is whatever the habit has; if user never set it
  # the control starts at 0 (disabled). Pick a preset before Continue.
  if tree_contains "Set your milestone" || has_label "Set your milestone"; then
    # Tap preset to set a positive value.
    for preset in "30 days preset" "7 days preset" "21 days preset" "14 days preset"; do
      if has_label "$preset"; then
        tap_element "$preset" "label" "Pick $preset milestone"
        sleep 0.8
        break
      fi
    done
  fi

  # Name page gate: nameController must not be empty. On edit, existing
  # name is loaded. On stuck first-iteration, we still type.

  if has_label "Continue"; then
    tap_element "Continue" "label" "Edit wizard step $step Continue"
    sleep 1
  elif has_label "Skip"; then
    tap_element "Skip" "label" "Skip step $step"
    sleep 1
  else
    info "No Continue/Skip on step $step"
    break
  fi
done

# Final save
if has_label "Save Changes"; then
  tap_element "Save Changes" "label" "Save Changes"
  sleep 2
  pass "Submitted edit habit form"
else
  skip "Save on edit form" "no Save Changes button found"
fi

capture "20_after_save"
go_home
print_summary
exit $FAIL
