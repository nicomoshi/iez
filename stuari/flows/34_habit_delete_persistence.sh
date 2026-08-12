#!/usr/bin/env bash
# Flow 34: Delete Habit Persistence
#
# Covers Rudy's beta feedback directly:
#   create a unique habit -> delete that exact habit -> pull refresh ->
#   terminate/relaunch -> verify the deleted habit does not reappear.
#
# This flow intentionally does NOT delete shared seeded fixtures. It creates
# its own unique habit first by reusing Flow 04, then performs the destructive
# action on that per-run habit.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/release_lifecycle.sh"
require_release_lifecycle || exit 1
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 34: Delete habit persists across refresh/relaunch"

HABIT_DELETE_FIXTURE_TOKEN="$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-' || true)"
if ! [[ "$HABIT_DELETE_FIXTURE_TOKEN" =~ ^[0-9a-f]{32}$ ]]; then
  fail "Collision-safe disposable habit fixture identity available"
  print_summary
  exit $FAIL
fi
HABIT_NAME="Del Me $HABIT_DELETE_FIXTURE_TOKEN"
export STUARI_FLOW04_HABIT_NAME="$HABIT_NAME"
export STUARI_FLOW04_HABIT_TOKEN="$HABIT_DELETE_FIXTURE_TOKEN"
HABIT_DELETE_FIXTURE_CREATED=0
HABIT_DELETE_FIXTURE_DELETED=0
HABIT_DELETE_CLEANUP_RAN=0
HABIT_DELETE_DURABILITY_PROVEN=1
TARGET_CARD_ID=""
HANDOFF_TARGET_CARD_ID=""
HABIT_DELETE_HANDOFF_FILE="$(mktemp "${TMPDIR:-/tmp}/stuari-flow34-handoff.XXXXXX")" || exit 1
chmod 600 "$HABIT_DELETE_HANDOFF_FILE" || exit 1

# Return the only normalized exact-name habit card when it is fully contained
# by the Stuari root and is the unique mounted card nearest the app center.
# Partially visible adjacent cards still participate in collision and nearest
# card checks, but they can never become the destructive target.
habit_delete_centered_card_id_from_tree() {
  local tree="${1:-}" name="${2:-}"
  [ -n "$tree" ] && [ -n "$name" ] || return 1
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -er --arg name "$name" '
    def normalized:
      ascii_downcase
      | gsub("[[:space:]]+"; " ")
      | sub("^ "; "")
      | sub(" $"; "");
    def exact_name:
      try (
        (.label | capture("^Habit card: (?<name>.+) habit, .+$") | .name | normalized)
        == ($name | normalized)
      ) catch false;
    def has_positive_frame:
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0;
    def intersects($root):
      has_positive_frame
      and .frame.x < ($root.x + $root.width)
      and (.frame.x + .frame.width) > $root.x
      and .frame.y < ($root.y + $root.height)
      and (.frame.y + .frame.height) > $root.y;
    def fully_contained_by($root):
      has_positive_frame
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);

    [(.data.elements // [])[]? | select(.role == "AXApplication")] as $apps
    | $apps[0].frame as $root
    | [
        (.data.elements // [])[]?
        | select((.id | type) == "string")
        | select(.id | startswith("habit_card_"))
        | select((.id | startswith("habit_card_menu_")) | not)
        | select((.label | type) == "string")
        | select(intersects($root))
        | {
            id: .id,
            label: .label,
            fully_contained: fully_contained_by($root),
            distance: (((.frame.x + (.frame.width / 2))
              - ($root.x + ($root.width / 2))) | abs),
            area: (.frame.width * .frame.height)
          }
      ] as $cards
    | [ $cards[] | select(exact_name) ] as $matches
    | select(($matches | length) == 1)
    | select($matches[0].fully_contained)
    | ($cards | sort_by(.distance, (-.area))) as $ordered
    | select(($ordered | length) > 0)
    | ($ordered[0].distance) as $minimum_distance
    | select(([ $ordered[] | select(.distance == $minimum_distance) ] | length) == 1)
    | select($ordered[0].id == $matches[0].id)
    | $matches[0].id
  ' 2>/dev/null
}

habit_delete_target_matches_expected_id_from_tree() {
  local tree="${1:-}" name="${2:-}" expected_id="${3:-}" observed_id=""
  [ -n "$expected_id" ] || return 1
  observed_id="$(habit_delete_centered_card_id_from_tree "$tree" "$name" 2>/dev/null || true)"
  [ -n "$observed_id" ] && [ "$observed_id" = "$expected_id" ]
}

habit_delete_target_menu_is_safe_from_tree() {
  local tree="${1:-}" name="${2:-}" expected_id="${3:-}" menu_id=""
  habit_delete_target_matches_expected_id_from_tree "$tree" "$name" "$expected_id" || return 1
  menu_id="${expected_id/habit_card_/habit_card_menu_}"

  printf '%s\n' "$tree" | jq -e --arg menu_id "$menu_id" '
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
    | [(.data.elements // [])[]? | select(.id == $menu_id)] as $menus
    | ($menus | length) == 1
      and ($menus[0].role == "AXButton")
      and ($menus[0].enabled != false)
      and ($menus[0] | fully_contained_by($root))
  ' >/dev/null 2>&1
}

habit_delete_menu_action_is_safe_from_tree() {
  local tree="${1:-}" name="${2:-}" expected_id="${3:-}"
  habit_delete_target_menu_is_safe_from_tree "$tree" "$name" "$expected_id" || return 1

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

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | [(.data.elements // [])[]? | select(.label == "Delete Habit")] as $actions
    | ($actions | length) == 1
      and ($actions[0].role == "AXButton")
      and ($actions[0].enabled != false)
      and ($actions[0] | fully_contained_by($root))
  ' >/dev/null 2>&1
}

habit_delete_confirm_dialog_is_safe_from_tree() {
  local tree="${1:-}" name="${2:-}" expected_id="${3:-}"
  habit_delete_target_menu_is_safe_from_tree "$tree" "$name" "$expected_id" || return 1

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
    def safe_button($root):
      .role == "AXButton"
      and (.enabled != false)
      and fully_contained_by($root);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | [(.data.elements // [])[]? | select(.label == "Cancel")] as $cancel
    | [(.data.elements // [])[]? | select(.label == "Delete")] as $delete
    | ($cancel | length) == 1
      and ($delete | length) == 1
      and ($cancel[0] | safe_button($root))
      and ($delete[0] | safe_button($root))
  ' >/dev/null 2>&1
}

habit_delete_current_centered_card_id() {
  local name="$1" tree=""
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  habit_delete_centered_card_id_from_tree "$tree" "$name"
}

habit_delete_cleanup_ownership_is_provable() {
  local observed_id="${1:-}" expected_id="${2:-}"
  [ -n "$observed_id" ] && [ -n "$expected_id" ] && [ "$observed_id" = "$expected_id" ]
}

habit_delete_report_cleanup_required() {
  STUARI_HABIT_DELETE_CLEANUP_REQUIRED=1
  export STUARI_HABIT_DELETE_CLEANUP_REQUIRED
  mark_flow_cleanup_required
  info "Cleanup required: preserving '$HABIT_NAME' because exact fixture ownership is not provable"
}

habit_delete_cleanup_tap_id() {
  tap_element "$1" "id" "Cleanup exact disposable habit menu" "AXButton"
}

habit_delete_cleanup_tap_label() {
  tap_element "$1" "label" "Cleanup disposable habit action: $1" "AXButton"
}

cleanup_habit_delete_fixture() {
  local tree="" observed_id="" cleanup_menu_id=""

  if [ "${HABIT_DELETE_CLEANUP_RAN:-0}" = "1" ]; then
    return 0
  fi
  HABIT_DELETE_CLEANUP_RAN=1

  if [ "${HABIT_DELETE_FIXTURE_CREATED:-0}" != "1" ]; then
    rm -f "$HABIT_DELETE_HANDOFF_FILE" 2>/dev/null || true
    mark_flow_cleanup_complete
    return 0
  fi
  if [ "${HABIT_DELETE_FIXTURE_DELETED:-0}" = "1" ]; then
    rm -f "$HABIT_DELETE_HANDOFF_FILE" 2>/dev/null || true
    mark_flow_cleanup_complete
    return 0
  fi

  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  observed_id="$(habit_delete_centered_card_id_from_tree "$tree" "$HABIT_NAME" 2>/dev/null || true)"
  if ! habit_delete_cleanup_ownership_is_provable "$observed_id" "${TARGET_CARD_ID:-}" \
    || ! habit_delete_target_menu_is_safe_from_tree "$tree" "$HABIT_NAME" "${TARGET_CARD_ID:-}"; then
    habit_delete_report_cleanup_required
    return 1
  fi

  cleanup_menu_id="${TARGET_CARD_ID/habit_card_/habit_card_menu_}"
  if ! habit_delete_cleanup_tap_id "$cleanup_menu_id"; then
    habit_delete_report_cleanup_required
    return 1
  fi
  sleep 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  if ! habit_delete_menu_action_is_safe_from_tree "$tree" "$HABIT_NAME" "$TARGET_CARD_ID" \
    || ! habit_delete_cleanup_tap_label "Delete Habit"; then
    habit_delete_report_cleanup_required
    return 1
  fi
  sleep 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  if ! habit_delete_confirm_dialog_is_safe_from_tree "$tree" "$HABIT_NAME" "$TARGET_CARD_ID"; then
    habit_delete_report_cleanup_required
    return 1
  fi
  if ! habit_delete_cleanup_tap_label "Delete"; then
    habit_delete_report_cleanup_required
    return 1
  fi
  sleep 4
  if ! wait_for_immediate_habit_card_absent "$HABIT_NAME" 8; then
    habit_delete_report_cleanup_required
    return 1
  fi

  HABIT_DELETE_FIXTURE_DELETED=1
  mark_flow_cleanup_complete
  info "Cleaned up disposable habit fixture: $HABIT_NAME"
  return 0
}

habit_delete_exit_cleanup() {
  local original_status=$?
  trap - EXIT
  if ! cleanup_habit_delete_fixture; then
    exit 1
  fi
  exit "$original_status"
}

trap habit_delete_exit_cleanup EXIT

if ! ensure_verified_alice_session; then
  fail "Verified Alice principal required before disposable habit creation"
  print_summary
  exit $FAIL
fi

info "Creating disposable habit: $HABIT_NAME"
# Flow 04 can fail after the server accepted its submit. Assume the reserved
# UUID-named habit may exist before entering the child so every exit path either
# deletes that exact card or reports cleanup required without touching others.
HABIT_DELETE_FIXTURE_CREATED=1
mark_flow_cleanup_required
STUARI_FLOW04_OWNERSHIP_HANDOFF_FILE="$HABIT_DELETE_HANDOFF_FILE" \
  SCREENSHOTS="$SCREENSHOTS" bash "$SCRIPT_DIR/04_habit_group.sh"
create_rc=$?
if [ -s "$HABIT_DELETE_HANDOFF_FILE" ]; then
  HANDOFF_TARGET_CARD_ID="$(jq -r \
    --arg lifecycle "${STUARI_RELEASE_LIFECYCLE_TOKEN:-}" \
    --arg token "$HABIT_DELETE_FIXTURE_TOKEN" \
    'select(.lifecycle_token == $lifecycle and .fixture_token == $token) | .card_id // empty' \
    "$HABIT_DELETE_HANDOFF_FILE" 2>/dev/null || true)"
  TARGET_CARD_ID="$HANDOFF_TARGET_CARD_ID"
fi
rm -f "$HABIT_DELETE_HANDOFF_FILE"
if [ "$create_rc" -ne 0 ]; then
  fail "Disposable habit created before delete flow"
  print_summary
  exit $FAIL
fi
pass "Disposable habit created: $HABIT_NAME"

fresh_launch
sleep 2
if on_onboarding_page; then complete_onboarding; fi
if ! persisted_session_is_verified_alice; then
  fail "Verified Alice principal preserved before destructive habit mutation"
  print_summary
  exit $FAIL
fi
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

target_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
observed_target_card_id="$(habit_delete_centered_card_id_from_tree "$target_tree" "$HABIT_NAME" 2>/dev/null || true)"
if [ -n "$HANDOFF_TARGET_CARD_ID" ] && [ "$observed_target_card_id" = "$HANDOFF_TARGET_CARD_ID" ]; then
  TARGET_CARD_ID="$HANDOFF_TARGET_CARD_ID"
  pass "Disposable habit is the single centered positive-width card: $TARGET_CARD_ID"
else
  fail "Disposable habit does not match the exact child ownership handoff"
  capture "34_target_card_precondition_failed"
  print_summary
  exit $FAIL
fi

TARGET_MENU_ID="${TARGET_CARD_ID/habit_card_/habit_card_menu_}"
pre_menu_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if habit_delete_target_menu_is_safe_from_tree "$pre_menu_tree" "$HABIT_NAME" "$TARGET_CARD_ID" \
  && tap_element "$TARGET_MENU_ID" "id" "Open habit settings for disposable habit"; then
  sleep 1.2
else
  fail "Exact habit settings menu is not visible for disposable habit card $TARGET_CARD_ID"
  capture "34_no_habit_settings"
  print_summary
  exit $FAIL
fi

capture "34_delete_menu"

menu_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if habit_delete_menu_action_is_safe_from_tree "$menu_tree" "$HABIT_NAME" "$TARGET_CARD_ID"; then
  if ! tap_element "Delete Habit" "label" "Choose Delete Habit"; then
    fail "Delete Habit action could not be delivered"
    print_summary
    exit $FAIL
  fi
  sleep 1.2
else
  fail "Exact target card/menu pair changed before Delete Habit action"
  capture "34_no_delete_entry"
  print_summary
  exit $FAIL
fi

capture "34_delete_confirm"

confirm_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if habit_delete_confirm_dialog_is_safe_from_tree "$confirm_tree" "$HABIT_NAME" "$TARGET_CARD_ID"; then
  if tap_element "Delete" "label" "Confirm destructive delete"; then
    sleep 4
  else
    fail "Destructive delete action could not be delivered"
    print_summary
    exit $FAIL
  fi
else
  fail "Refusing destructive delete: exact target card/menu pair or dialog changed"
  capture "34_no_confirm_delete"
  print_summary
  exit $FAIL
fi

go_home
sleep 1.5
capture "34_after_delete"
# Immediate optimistic assertion: this bounded helper only reads compact AX
# trees and cannot refresh, relaunch, or mutate product state. Durability
# assertions remain below the refresh and relaunch boundaries.
if wait_for_immediate_habit_card_absent "$HABIT_NAME" 8; then
  pass "Deleted habit removed immediately from Home"
else
  fail "Deleted habit removed immediately from Home"
  HABIT_DELETE_DURABILITY_PROVEN=0
  capture "34_still_visible_after_delete"
fi

pull_to_refresh_home
capture "34_after_pull_to_refresh"
if tree_contains "$HABIT_NAME"; then
  fail "Deleted habit stays deleted after pull-to-refresh"
  HABIT_DELETE_DURABILITY_PROVEN=0
  capture "34_reappeared_after_refresh"
else
  pass "Deleted habit stays deleted after pull-to-refresh"
fi

terminate_app
fresh_launch
sleep 2
if on_onboarding_page; then complete_onboarding; fi
if ! persisted_session_is_verified_alice; then
  fail "Verified Alice principal preserved after destructive habit mutation"
  print_summary
  exit $FAIL
fi
go_home
wait_for_visible_habit_card 10 || true
capture "34_after_relaunch"

if tree_contains "$HABIT_NAME"; then
  fail "Deleted habit stays deleted after app relaunch"
  HABIT_DELETE_DURABILITY_PROVEN=0
  capture "34_reappeared_after_relaunch"
else
  pass "Deleted habit stays deleted after app relaunch"
fi

if [ "$HABIT_DELETE_DURABILITY_PROVEN" = "1" ]; then
  HABIT_DELETE_FIXTURE_DELETED=1
fi

print_summary
exit $FAIL
