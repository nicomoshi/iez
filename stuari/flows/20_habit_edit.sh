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
source "$SCRIPT_DIR/../lib/release_lifecycle.sh"
require_release_lifecycle || exit 1
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"
source "$SCRIPT_DIR/../lib/disposable_habit.sh"

section "Flow 20: Edit habit rules"
HABIT_TOKEN="${STUARI_FLOW20_HABIT_TOKEN:-$(disposable_habit_uuid)}"
ORIGINAL_NAME="${STUARI_FLOW20_ORIGINAL_NAME:-IEZ Edit $HABIT_TOKEN}"
UPDATED_NAME="${STUARI_FLOW20_UPDATED_NAME:-IEZ Edited $HABIT_TOKEN}"
if ! disposable_habit_name_is_owned "$ORIGINAL_NAME" "$HABIT_TOKEN" \
  || ! disposable_habit_name_is_owned "$UPDATED_NAME" "$HABIT_TOKEN"; then
  fail "Flow 20 requires UUID-owned original and updated disposable names"
  print_summary
  exit $FAIL
fi

DISPOSABLE_HABIT_TOKEN="$HABIT_TOKEN"
FLOW20_TARGET_CARD_ID=""
FLOW20_CURRENT_NAME="$ORIGINAL_NAME"
FLOW20_OWNERSHIP_CLAIMED=0
FLOW20_CLEANUP_COMPLETE=0
FLOW20_HANDOFF_FILE="$(mktemp "${TMPDIR:-/tmp}/stuari-flow20-handoff.XXXXXX")" || exit 1
chmod 600 "$FLOW20_HANDOFF_FILE" || exit 1

cleanup_flow20_disposable_fixture() {
  [ "$FLOW20_CLEANUP_COMPLETE" = "0" ] || return 0
  rm -f "$FLOW20_HANDOFF_FILE" 2>/dev/null || true
  if [ "$FLOW20_OWNERSHIP_CLAIMED" != "1" ]; then
    mark_flow_cleanup_required
    return 1
  fi
  if disposable_habit_delete_and_prove_cleanup "$FLOW20_CURRENT_NAME" "$FLOW20_TARGET_CARD_ID" \
    || { [ "$FLOW20_CURRENT_NAME" != "$ORIGINAL_NAME" ] \
      && disposable_habit_delete_and_prove_cleanup "$ORIGINAL_NAME" "$FLOW20_TARGET_CARD_ID"; }; then
    FLOW20_CLEANUP_COMPLETE=1
    mark_flow_cleanup_complete
    info "Flow 20 proved edited disposable habit cleanup after refresh and relaunch"
    return 0
  fi
  mark_flow_cleanup_required
  return 1
}

flow20_exit_cleanup() {
  local original_status=$?
  trap - EXIT INT TERM
  if ! cleanup_flow20_disposable_fixture; then exit 1; fi
  exit "$original_status"
}
trap flow20_exit_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

section "Flow 20 setup: create owned habit"
mark_flow_cleanup_required
STUARI_FLOW04_HABIT_NAME="$ORIGINAL_NAME" \
  STUARI_FLOW04_HABIT_TOKEN="$HABIT_TOKEN" \
  STUARI_FLOW04_OWNERSHIP_HANDOFF_FILE="$FLOW20_HANDOFF_FILE" \
  SCREENSHOTS="$SCREENSHOTS" \
  bash "$SCRIPT_DIR/04_habit_group.sh"
create_rc=$?
if disposable_habit_read_handoff "$FLOW20_HANDOFF_FILE" "$HABIT_TOKEN"; then
  FLOW20_TARGET_CARD_ID="$(jq -r '.card_id' "$FLOW20_HANDOFF_FILE")"
  FLOW20_OWNERSHIP_CLAIMED=1
  rm -f "$FLOW20_HANDOFF_FILE"
fi
if [ "$create_rc" -eq 0 ] && [ "$FLOW20_OWNERSHIP_CLAIMED" = "1" ]; then
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
# Continue buttons — we provide input where needed. Stop as soon as either
# exact review submit label appears, or after 10 iterations.
for step in $(seq 1 10); do
  if [ -n "$(first_coords_matching_exact_labels \
      "Save Changes" "Save Changes: habit review")" ]; then
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

  if tap_first_matching_exact_labels \
      "Continue" "Continue: habit name" \
      "Edit wizard step $step Continue habit name" || \
    tap_first_matching_exact_labels \
      "Continue" "Continue: habit image" \
      "Edit wizard step $step Continue habit image" || \
    tap_first_matching_exact_labels \
      "Continue" "Continue: habit frequency" \
      "Edit wizard step $step Continue habit frequency" || \
    tap_first_matching_exact_labels \
      "Continue" "Continue: check-in times" \
      "Edit wizard step $step Continue check-in times" || \
    tap_first_matching_exact_labels \
      "Continue" "Continue: habit milestone" \
      "Edit wizard step $step Continue habit milestone"; then
    sleep 1
  elif tap_first_matching_exact_labels \
      "Skip" "Skip: habit image" "Skip step $step"; then
    sleep 1
  else
    info "No Continue/Skip on step $step"
    break
  fi
done

# Final save
FLOW20_CURRENT_NAME="$UPDATED_NAME"
if tap_first_matching_exact_labels \
    "Save Changes" "Save Changes: habit review" \
    "Save Changes"; then
  sleep 2
  pass "Submitted edit habit form"
else
  fail "Save Changes button not found on the edit review page"
fi

capture "20_after_save"
go_home
# Immediate optimistic assertion: this bounded helper only reads compact AX
# trees. Refresh/relaunch are deliberately below this gate.
if wait_for_immediate_habit_card_name "$UPDATED_NAME" 8; then
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

if ! cleanup_flow20_disposable_fixture; then
  fail "Flow 20 could not prove cleanup of its exact disposable habit"
fi
print_summary
exit $FAIL
