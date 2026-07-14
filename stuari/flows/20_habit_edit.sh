#!/usr/bin/env bash
# Flow 20 (P0): Edit habit rules
#
# Walks: create an owned disposable habit -> Home -> open that habit's
# overflow menu -> Edit Habit -> replace name -> Save Changes -> verify Home,
# refresh, and relaunch all show the edited name.
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
ORIGINAL_NAME="${STUARI_FLOW20_ORIGINAL_NAME:-Edit Me $(rand_tail)}"
UPDATED_NAME="${STUARI_FLOW20_UPDATED_NAME:-Edited $(rand_tail)}"

section "Flow 20 setup: create owned habit"
if STUARI_FLOW04_HABIT_NAME="$ORIGINAL_NAME" \
  SCREENSHOTS="$SCREENSHOTS" \
  bash "$SCRIPT_DIR/04_habit_group.sh"; then
  pass "Created owned habit for edit flow: $ORIGINAL_NAME"
else
  fail "Could not create owned habit for edit flow: $ORIGINAL_NAME"
  print_summary; exit $FAIL
fi

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: Home must be reachable"
  print_summary; exit $FAIL
fi
go_home
capture "20_home"

if wait_for_visible_habit_card_name "$ORIGINAL_NAME" 10; then
  pass "Owned habit visible before edit: $ORIGINAL_NAME"
else
  fail "Owned habit not visible before edit: $ORIGINAL_NAME"
fi

# Open the three-dot menu on the currently-selected habit card.
if tap_visible_habit_menu "Open habit card overflow menu"; then
  sleep 1.2
  capture "20_menu_open"
else
  fail "Habit card menu missing for the owned disposable habit"
  print_summary; exit $FAIL
fi

# Tap "Edit Habit"
if has_label "Edit Habit"; then
  tap_element "Edit Habit" "label" "Tap Edit Habit"
  sleep 1.5
  capture "20_edit_page"
else
  fail "Edit Habit menu entry missing for the owned disposable habit"
  print_summary; exit $FAIL
fi

# On the edit page: replace the pre-filled name with a unique value.
# Flutter does not expose this TextField as a stable AX text field on iOS
# simulator, so use the measured center of the visible input.
if tree_contains "What habit do you" || tree_contains "$ORIGINAL_NAME" || tree_contains "e.g. Morning Run"; then
  replace_text_at_coords "205,390" "$UPDATED_NAME" "Habit name"
else
  fail "Habit name field not found on the edit page"
fi
capture "20_name_replaced"
run_iez "$IEZ" ui swipe down >/dev/null 2>&1
sleep 0.5

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
  fail "Save Changes button not found on the edit review page"
fi

capture "20_after_save"
go_home
if wait_for_visible_habit_card_name "$UPDATED_NAME" 12; then
  pass "Edited habit is visible on Home: $UPDATED_NAME"
else
  fail "Edited habit not visible on Home: $UPDATED_NAME"
fi

pull_to_refresh_home
capture "20_after_refresh"
if wait_for_visible_habit_card_name "$UPDATED_NAME" 10; then
  pass "Edited habit survives pull-to-refresh: $UPDATED_NAME"
else
  fail "Edited habit missing after pull-to-refresh: $UPDATED_NAME"
fi

terminate_app
fresh_launch
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
capture "20_after_relaunch"
if wait_for_visible_habit_card_name "$UPDATED_NAME" 12; then
  pass "Edited habit survives relaunch: $UPDATED_NAME"
else
  fail "Edited habit missing after relaunch: $UPDATED_NAME"
fi

print_summary
exit $FAIL
