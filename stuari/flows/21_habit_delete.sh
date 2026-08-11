#!/usr/bin/env bash
# Flow 21 (P0): Delete habit via card menu (destructive - cancel)
#
# Walks: Home -> habit-card "Habit settings" menu -> Delete Habit -> verifies
# confirmation dialog renders. CANCELS the dialog so we don't nuke the
# seeded habit fixtures used by every other flow.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 21: Delete habit (cancel)"

habit_delete_cancel_dialog_is_safe_to_cancel() {
  local tree="${1:-}"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -e '
    def fully_contained_by($root):
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);
    def is_safe_button($root):
      .role == "AXButton"
      and (.enabled != false)
      and fully_contained_by($root);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | [(.data.elements // [])[]? | select(.label == "Cancel")] as $cancel
    | [(.data.elements // [])[]? | select(.label == "Delete")] as $delete
    | ($cancel | length) == 1
      and ($delete | length) == 1
      and ($cancel[0] | is_safe_button($root))
      and ($delete[0] | is_safe_button($root))
  ' >/dev/null 2>&1
}

habit_delete_post_cancel_state_is_safe() {
  local tree="${1:-}" expected_card_id="${2:-}"
  [ -n "$expected_card_id" ] || return 1
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -e --arg card_id "$expected_card_id" '
    def fully_contained_by($root):
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | ([ (.data.elements // [])[]?
      | select(.role == "AXButton")
      | select(.label == "Cancel" or .label == "Delete" or .label == "Delete Habit")
    ] | length) == 0
    and ([ (.data.elements // [])[]?
      | select(.id == $card_id)
    ] | length) == 1
    and ([ (.data.elements // [])[]?
      | select(.id == $card_id)
    ][0] | fully_contained_by($root))
    and
    ([ (.data.elements // [])[]?
      | select(.role == "AXButton")
      | select(.label == "Home tab, selected" or .label == "Home tab, selected tab")
      | select(fully_contained_by($root))
    ] | length) == 1
  ' >/dev/null 2>&1
}

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: Home must be reachable"
  print_summary; exit $FAIL
fi
go_home
capture "21_home"

TARGET_CARD_ID="$(current_visible_habit_card_id 2>/dev/null || true)"
if [ -z "$TARGET_CARD_ID" ]; then
  fail "Habit delete cancel flow has no exact visible target card"
  print_summary; exit $FAIL
fi
TARGET_MENU_ID="${TARGET_CARD_ID/habit_card_/habit_card_menu_}"

if has_id "$TARGET_MENU_ID" && tap_element "$TARGET_MENU_ID" "id" "Open habit card overflow menu"; then
  sleep 1.2
else
  skip "Habit card menu" "no exact menu affordance for the visible owned habit"
  print_summary; exit $FAIL
fi

capture "21_menu_open"

if has_label "Delete Habit"; then
  if ! tap_element "Delete Habit" "label" "Tap Delete Habit"; then
    fail "Delete Habit action could not be delivered"
    print_summary; exit $FAIL
  fi
  sleep 1.2
  capture "21_confirm_dialog"
  dialog_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  if habit_delete_cancel_dialog_is_safe_to_cancel "$dialog_tree"; then
    pass "Delete Habit confirmation dialog visible"
  else
    fail "Delete Habit dialog lacks one safe Cancel button under the Stuari app root"
    print_summary; exit $FAIL
  fi
else
  skip "Delete Habit menu entry" "not visible"
  print_summary; exit $FAIL
fi

# The confirmation dialog exposes a red "Delete" destructive button and
# a "Cancel" button. We CANCEL so we don't wipe fixtures.
if ! habit_delete_cancel_dialog_is_safe_to_cancel "${dialog_tree:-}"; then
  fail "Cancel button missing or ambiguous - refusing to dismiss or confirm the destructive dialog"
  print_summary; exit $FAIL
fi

if ! tap_element "Cancel" "label" "Cancel Delete"; then
  fail "Cancel action could not be delivered - refusing to continue"
  print_summary; exit $FAIL
fi
sleep 1

# Cancellation is only safe once one fresh AX tree proves that the modal is
# gone, Home is still the prior screen, and Stuari remains foregrounded.
post_cancel_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if habit_delete_post_cancel_state_is_safe "$post_cancel_tree" "$TARGET_CARD_ID"; then
  pass "Cancelled - destructive dialog dismissed and Home fixture preserved"
else
  fail "Cancel did not restore the prior safe Home screen under the Stuari app root"
  capture "21_post_cancel_failed"
  print_summary; exit $FAIL
fi

capture "21_post_cancel"
print_summary
exit $FAIL
