#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_destructive_flow_safety.XXXXXX")"
FLOW21_FILE="$ROOT_DIR/stuari/flows/21_habit_delete.sh"
FLOW24_FILE="$ROOT_DIR/stuari/flows/24_account_delete.sh"
FLOW34_FILE="$ROOT_DIR/stuari/flows/34_habit_delete_persistence.sh"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail_test() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass_test() {
  printf 'PASS: %s\n' "$1"
}

assert_accepts() {
  local description="$1"
  shift
  "$@" || fail_test "$description"
  pass_test "$description"
}

assert_rejects() {
  local description="$1"
  shift
  if "$@"; then
    fail_test "$description"
  fi
  pass_test "$description"
}

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  grep -Fq -- "$needle" "$file" || fail_test "$description"
}

extract_function() {
  local function_name="$1" file="$2"
  awk -v fn="$function_name" '
    $0 ~ "^" fn "\\(\\) \\{$" { in_fn=1 }
    in_fn { print }
    in_fn && $0 == "}" { exit }
  ' "$file"
}

export SKIP_DEVICE_DETECT=1
export STUARI_SUITE_DIR="$TMP_DIR"
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
source "$ROOT_DIR/stuari/lib/common.sh"

for function_name in \
  habit_delete_cancel_dialog_is_safe_to_cancel \
  habit_delete_post_cancel_state_is_safe; do
  eval "$(extract_function "$function_name" "$FLOW21_FILE")"
done

for function_name in \
  account_delete_cancel_dialog_is_safe_to_cancel \
  account_delete_tile_label_from_tree \
  account_delete_post_cancel_state_is_safe; do
  eval "$(extract_function "$function_name" "$FLOW24_FILE")"
done

for function_name in \
  habit_delete_centered_card_id_from_tree \
  habit_delete_target_matches_expected_id_from_tree \
  habit_delete_target_menu_is_safe_from_tree \
  habit_delete_menu_action_is_safe_from_tree \
  habit_delete_confirm_dialog_is_safe_from_tree \
  habit_delete_cleanup_ownership_is_provable \
  habit_delete_report_cleanup_required \
  cleanup_habit_delete_fixture; do
  eval "$(extract_function "$function_name" "$FLOW34_FILE")"
done

root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
cancel='{"role":"AXButton","label":"Cancel","enabled":true,"frame":{"x":20,"y":760,"width":160,"height":48}}'
habit_delete='{"role":"AXButton","label":"Delete","enabled":true,"frame":{"x":222,"y":760,"width":160,"height":48}}'
account_delete='{"role":"AXButton","label":"Delete Account","enabled":true,"frame":{"x":202,"y":760,"width":180,"height":48}}'

habit_dialog="{\"ok\":true,\"data\":{\"elements\":[$root,$cancel,$habit_delete]}}"
assert_accepts "Flow 21 accepts one actionable in-root Cancel and Delete pair" \
  habit_delete_cancel_dialog_is_safe_to_cancel "$habit_dialog"

for invalid_case in missing duplicate disabled zero_size off_root wrong_app; do
  case "$invalid_case" in
    missing)
      tree="{\"ok\":true,\"data\":{\"elements\":[$root,$habit_delete]}}"
      ;;
    duplicate)
      tree="{\"ok\":true,\"data\":{\"elements\":[$root,$cancel,$cancel,$habit_delete]}}"
      ;;
    disabled)
      tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":false,\"frame\":{\"x\":20,\"y\":760,\"width\":160,\"height\":48}},$habit_delete]}}"
      ;;
    zero_size)
      tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":760,\"width\":0,\"height\":48}},$habit_delete]}}"
      ;;
    off_root)
      tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":450,\"y\":760,\"width\":160,\"height\":48}},$habit_delete]}}"
      ;;
    wrong_app)
      tree="{\"ok\":true,\"data\":{\"elements\":[{\"role\":\"AXApplication\",\"label\":\"Cluster\",\"frame\":{\"x\":0,\"y\":0,\"width\":402,\"height\":874}},$cancel,$habit_delete]}}"
      ;;
  esac
  assert_rejects "Flow 21 rejects $invalid_case Cancel state" \
    habit_delete_cancel_dialog_is_safe_to_cancel "$tree"
done

home_selected='{"role":"AXButton","label":"Home tab, selected","frame":{"x":10,"y":820,"width":70,"height":44}}'
target_card='{"role":"AXButton","id":"habit_card_target","label":"Habit card: Seed habit, On track","frame":{"x":78,"y":118,"width":246,"height":382}}'
post_habit_cancel="{\"ok\":true,\"data\":{\"elements\":[$root,$home_selected,$target_card]}}"
assert_accepts "Flow 21 post-cancel proof retains Home and the exact target card" \
  habit_delete_post_cancel_state_is_safe "$post_habit_cancel" "habit_card_target"
assert_rejects "Flow 21 post-cancel proof rejects a removed target card" \
  habit_delete_post_cancel_state_is_safe "{\"ok\":true,\"data\":{\"elements\":[$root,$home_selected]}}" "habit_card_target"
assert_rejects "Flow 21 post-cancel proof rejects a still-open destructive dialog" \
  habit_delete_post_cancel_state_is_safe "{\"ok\":true,\"data\":{\"elements\":[$root,$home_selected,$target_card,$cancel,$habit_delete]}}" "habit_card_target"

account_dialog="{\"ok\":true,\"data\":{\"elements\":[$root,$cancel,$account_delete]}}"
assert_accepts "Flow 24 accepts one actionable in-root Cancel and Delete Account pair" \
  account_delete_cancel_dialog_is_safe_to_cancel "$account_dialog"
assert_rejects "Flow 24 rejects duplicate Cancel controls" \
  account_delete_cancel_dialog_is_safe_to_cancel "{\"ok\":true,\"data\":{\"elements\":[$root,$cancel,$cancel,$account_delete]}}"
assert_rejects "Flow 24 rejects a missing Cancel control" \
  account_delete_cancel_dialog_is_safe_to_cancel "{\"ok\":true,\"data\":{\"elements\":[$root,$account_delete]}}"
assert_rejects "Flow 24 rejects an off-root Cancel control" \
  account_delete_cancel_dialog_is_safe_to_cancel "{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"frame\":{\"x\":500,\"y\":760,\"width\":100,\"height\":48}},$account_delete]}}"
assert_rejects "Flow 24 rejects a disabled Cancel control" \
  account_delete_cancel_dialog_is_safe_to_cancel "{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":false,\"frame\":{\"x\":20,\"y\":760,\"width\":160,\"height\":48}},$account_delete]}}"
assert_rejects "Flow 24 rejects a zero-size Cancel control" \
  account_delete_cancel_dialog_is_safe_to_cancel "{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"frame\":{\"x\":20,\"y\":760,\"width\":0,\"height\":48}},$account_delete]}}"

account_tile='{"role":"AXButton","label":"Danger Zone\nDelete Account","frame":{"x":20,"y":420,"width":362,"height":64}}'
account_page="{\"ok\":true,\"data\":{\"elements\":[$root,$account_tile]}}"
tile_label="$(account_delete_tile_label_from_tree "$account_page")" || fail_test "Flow 24 finds one safe Account tile"
[ "$tile_label" = $'Danger Zone\nDelete Account' ] || fail_test "Flow 24 returns the exact Account tile label"
pass_test "Flow 24 records the exact safe Account tile marker"
assert_accepts "Flow 24 post-cancel proof restores the exact Account tile" \
  account_delete_post_cancel_state_is_safe "$account_page" "$tile_label"
assert_rejects "Flow 24 post-cancel proof rejects a still-open dialog" \
  account_delete_post_cancel_state_is_safe "{\"ok\":true,\"data\":{\"elements\":[$root,$account_tile,$cancel,$account_delete]}}" "$tile_label"
assert_rejects "Flow 24 rejects duplicate Account tile markers" \
  account_delete_post_cancel_state_is_safe "{\"ok\":true,\"data\":{\"elements\":[$root,$account_tile,$account_tile]}}" "$tile_label"

assert_file_contains 'if ! tap_element "Cancel"' "$FLOW21_FILE" \
  "Flow 21 must fail when the Cancel tap is not delivered"
assert_file_contains 'if ! tap_element "Cancel"' "$FLOW24_FILE" \
  "Flow 24 must fail when the Cancel tap is not delivered"
pass_test "Both cancel flows fail closed on tap-delivery failure"

target='{"role":"AXButton","id":"habit_card_target","label":"Habit card: Delete   Me 1234 habit, On track","frame":{"x":78,"y":118,"width":246,"height":382}}'
adjacent='{"role":"AXButton","id":"habit_card_adjacent","label":"Habit card: Other habit, On track","frame":{"x":330,"y":118,"width":180,"height":382}}'
target_menu='{"role":"AXButton","id":"habit_card_menu_target","label":"Habit settings","enabled":true,"frame":{"x":282,"y":130,"width":40,"height":40}}'
delete_action='{"role":"AXButton","label":"Delete Habit","enabled":true,"frame":{"x":90,"y":560,"width":222,"height":48}}'
target_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$target_menu]}}"

selected_id="$(habit_delete_centered_card_id_from_tree "$target_tree" " delete me 1234 ")" || \
  fail_test "Flow 34 selects the normalized exact centered target"
[ "$selected_id" = "habit_card_target" ] || fail_test "Flow 34 returned an adjacent card ID"
pass_test "Flow 34 selects only the normalized exact centered target"
assert_accepts "Flow 34 proves the exact target ID and matching menu together" \
  habit_delete_target_menu_is_safe_from_tree "$target_tree" "Delete Me 1234" "habit_card_target"
assert_rejects "Flow 34 rejects a swapped expected target ID" \
  habit_delete_target_menu_is_safe_from_tree "$target_tree" "Delete Me 1234" "habit_card_adjacent"

collision='{"role":"AXButton","id":"habit_card_collision","label":"Habit card: delete me 1234 habit, On track","frame":{"x":330,"y":118,"width":180,"height":382}}'
assert_rejects "Flow 34 rejects an adjacent normalized-name collision" \
  habit_delete_centered_card_id_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$collision,$target_menu]}}" "Delete Me 1234"
closer='{"role":"AXButton","id":"habit_card_closer","label":"Habit card: Other habit, On track","frame":{"x":78,"y":118,"width":246,"height":382}}'
assert_rejects "Flow 34 rejects the target when another mounted card ties for nearest center" \
  habit_delete_centered_card_id_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$closer,$target_menu]}}" "Delete Me 1234"
zero_target='{"role":"AXButton","id":"habit_card_target","label":"Habit card: Delete Me 1234 habit, On track","frame":{"x":78,"y":118,"width":0,"height":382}}'
assert_rejects "Flow 34 rejects a zero-size target card" \
  habit_delete_centered_card_id_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$zero_target,$adjacent,$target_menu]}}" "Delete Me 1234"
off_root_target='{"role":"AXButton","id":"habit_card_target","label":"Habit card: Delete Me 1234 habit, On track","frame":{"x":500,"y":118,"width":246,"height":382}}'
assert_rejects "Flow 34 rejects an off-root target card" \
  habit_delete_centered_card_id_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$off_root_target,$adjacent,$target_menu]}}" "Delete Me 1234"

wrong_menu='{"role":"AXButton","id":"habit_card_menu_adjacent","label":"Habit settings","enabled":true,"frame":{"x":282,"y":130,"width":40,"height":40}}'
assert_rejects "Flow 34 rejects a menu ID that does not match the target card" \
  habit_delete_target_menu_is_safe_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$wrong_menu]}}" "Delete Me 1234" "habit_card_target"
zero_menu='{"role":"AXButton","id":"habit_card_menu_target","label":"Habit settings","enabled":true,"frame":{"x":282,"y":130,"width":0,"height":40}}'
assert_rejects "Flow 34 rejects a zero-size exact target menu" \
  habit_delete_target_menu_is_safe_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$zero_menu]}}" "Delete Me 1234" "habit_card_target"

menu_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$target_menu,$delete_action]}}"
assert_accepts "Flow 34 re-proves target, menu, and Delete Habit action before tapping" \
  habit_delete_menu_action_is_safe_from_tree "$menu_tree" "Delete Me 1234" "habit_card_target"
assert_rejects "Flow 34 rejects duplicate Delete Habit actions" \
  habit_delete_menu_action_is_safe_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$target_menu,$delete_action,$delete_action]}}" "Delete Me 1234" "habit_card_target"

confirm_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$target_menu,$cancel,$habit_delete]}}"
assert_accepts "Flow 34 re-proves target, menu, and exact confirm dialog before deletion" \
  habit_delete_confirm_dialog_is_safe_from_tree "$confirm_tree" "Delete Me 1234" "habit_card_target"
assert_rejects "Flow 34 rejects a target swap at destructive confirmation" \
  habit_delete_confirm_dialog_is_safe_from_tree "$confirm_tree" "Delete Me 1234" "habit_card_adjacent"
assert_rejects "Flow 34 rejects duplicate Cancel controls at destructive confirmation" \
  habit_delete_confirm_dialog_is_safe_from_tree "{\"ok\":true,\"data\":{\"elements\":[$root,$target,$adjacent,$target_menu,$cancel,$cancel,$habit_delete]}}" "Delete Me 1234" "habit_card_target"

assert_rejects "Cleanup ownership rejects an adjacent-card ID" \
  habit_delete_cleanup_ownership_is_provable "habit_card_adjacent" "habit_card_target"
assert_accepts "Cleanup ownership accepts only the previously proven target ID" \
  habit_delete_cleanup_ownership_is_provable "habit_card_target" "habit_card_target"

swapped_target='{"role":"AXButton","id":"habit_card_swapped","label":"Habit card: Delete Me 1234 habit, On track","frame":{"x":78,"y":118,"width":246,"height":382}}'
swapped_menu='{"role":"AXButton","id":"habit_card_menu_swapped","label":"Habit settings","enabled":true,"frame":{"x":282,"y":130,"width":40,"height":40}}'
cleanup_mismatch_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$swapped_target,$adjacent,$swapped_menu]}}"
run_iez() { printf '%s\n' "$cleanup_mismatch_tree"; }
cleanup_mutation_attempted=0
habit_delete_cleanup_tap_id() { cleanup_mutation_attempted=1; return 0; }
habit_delete_cleanup_tap_label() { cleanup_mutation_attempted=1; return 0; }
HABIT_NAME="Delete Me 1234"
TARGET_CARD_ID="habit_card_target"
HABIT_DELETE_CLEANUP_RAN=0
HABIT_DELETE_FIXTURE_CREATED=1
HABIT_DELETE_FIXTURE_DELETED=0
STUARI_HABIT_DELETE_CLEANUP_REQUIRED=0
assert_rejects "Cleanup fails when live fixture ownership no longer matches" cleanup_habit_delete_fixture
[ "$cleanup_mutation_attempted" = "0" ] || fail_test "Cleanup ownership mismatch attempted a destructive tap"
[ "$STUARI_HABIT_DELETE_CLEANUP_REQUIRED" = "1" ] || fail_test "Cleanup ownership mismatch did not flag manual cleanup"
pass_test "Cleanup ownership mismatch preserves the fixture without any destructive tap"
assert_file_contains 'if ! cleanup_habit_delete_fixture; then' "$FLOW34_FILE" \
  "Flow 34 exit trap must convert unprovable cleanup into failure"
pass_test "Flow 34 cleanup preserves unowned fixtures and reports failure"

printf 'All destructive-flow safety checks passed.\n'
