#!/usr/bin/env bash

# Ownership and cleanup helpers for habits created by release flows. Callers
# must source common.sh, auth.sh, and navigation.sh before invoking UI helpers.

disposable_habit_uuid() {
  local token=""
  token="$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  [[ "$token" =~ ^([0-9a-f]{32}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$ ]] || return 1
  printf '%s\n' "$token"
}

disposable_habit_name_is_owned() {
  local name="${1:-}" token="${2:-}"
  [[ "$token" =~ ^([0-9a-f]{32}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$ ]] || return 1
  case "$name" in
    *" $token") return 0 ;;
    *) return 1 ;;
  esac
}

disposable_habit_target_is_exact() {
  local name="${1:-}" expected_id="${2:-}" tree="" observed_id="" label=""
  [ -n "$name" ] && [[ "$expected_id" == habit_card_* ]] || return 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1
  observed_id="$(stuari_centered_habit_card_id_from_tree "$tree" 2>/dev/null || true)"
  [ "$observed_id" = "$expected_id" ] || return 1
  label="$(printf '%s\n' "$tree" | jq -er --arg id "$expected_id" '
    [(.data.elements // [])[]?
      | select(.role == "AXButton" and .enabled != false and .id == $id)
      | (.label // empty)] as $labels
    | select(($labels | length) == 1)
    | $labels[0]
  ' 2>/dev/null || true)"
  habit_card_label_matches_name "$label" "$name"
}

disposable_habit_absence_is_proven() {
  local name="${1:-}" expected_id="${2:-}" tree=""
  [ -n "$name" ] && [ -n "$expected_id" ] || return 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1
  printf '%s\n' "$tree" | jq -e --arg name "$name" --arg id "$expected_id" '
    ([.data.elements[]?
      | select(.id == $id)
    ] | length) == 0
    and
    ([.data.elements[]?
      | select(((.id // "") | startswith("habit_card_")))
      | select((((.id // "") | startswith("habit_card_menu_")) | not))
      | select((.label // "") | contains($name))
    ] | length) == 0
  ' >/dev/null 2>&1
}

disposable_habit_delete_and_prove_cleanup() {
  local name="${1:-}" expected_id="${2:-}" menu_id="" tree=""
  disposable_habit_name_is_owned "$name" "${DISPOSABLE_HABIT_TOKEN:-}" || return 1
  [ -n "$expected_id" ] || return 1

  fresh_launch || return 1
  sleep 2
  if on_auth_page; then login_with_test_user || return 1; fi
  if on_onboarding_page; then complete_onboarding || return 1; fi
  go_home || return 1
  select_habit_card_by_id "$expected_id" 100 || return 1
  disposable_habit_target_is_exact "$name" "$expected_id" || return 1

  menu_id="${expected_id/habit_card_/habit_card_menu_}"
  tap_element "$menu_id" "id" "Open exact disposable habit menu" "AXButton" || return 1
  sleep 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  stuari_ax_tree_has_actionable_target "$tree" "" "Delete Habit" "AXButton" || return 1
  tap_element "Delete Habit" "label" "Delete exact disposable habit" "AXButton" || return 1
  sleep 1
  tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
  stuari_ax_tree_has_actionable_target "$tree" "" "Cancel" "AXButton" || return 1
  stuari_ax_tree_has_actionable_target "$tree" "" "Delete" "AXButton" || return 1
  tap_element "Delete" "label" "Confirm exact disposable habit deletion" "AXButton" || return 1
  sleep 3

  go_home || return 1
  wait_for_immediate_habit_card_absent "$name" 8 || return 1
  disposable_habit_absence_is_proven "$name" "$expected_id" || return 1
  pull_to_refresh_home || return 1
  disposable_habit_absence_is_proven "$name" "$expected_id" || return 1

  terminate_app || return 1
  fresh_launch || return 1
  sleep 2
  if on_auth_page; then login_with_test_user || return 1; fi
  if on_onboarding_page; then complete_onboarding || return 1; fi
  go_home || return 1
  disposable_habit_absence_is_proven "$name" "$expected_id"
}

disposable_habit_handoff_file_is_safe() {
  local file="${1:-}" mode="" owner=""
  [ -n "$file" ] && [ -f "$file" ] && [ ! -L "$file" ] || return 1
  mode="$(/usr/bin/stat -f '%Lp' "$file" 2>/dev/null \
    || stat -c '%a' "$file" 2>/dev/null || true)"
  owner="$(/usr/bin/stat -f '%u' "$file" 2>/dev/null \
    || stat -c '%u' "$file" 2>/dev/null || true)"
  [ "$mode" = "600" ] && [ "$owner" = "$(id -u)" ]
}

disposable_habit_write_handoff() {
  local file="${1:-}" name="${2:-}" card_id="${3:-}" token="${4:-}" tmp=""
  disposable_habit_handoff_file_is_safe "$file" || return 1
  disposable_habit_name_is_owned "$name" "$token" || return 1
  [[ "$card_id" == habit_card_* ]] || return 1
  [ -n "${STUARI_RELEASE_LIFECYCLE_TOKEN:-}" ] || return 1
  tmp="$file.tmp.$$"
  (umask 077 && jq -n \
    --arg name "$name" \
    --arg card_id "$card_id" \
    --arg fixture_token "$token" \
    --arg lifecycle_token "$STUARI_RELEASE_LIFECYCLE_TOKEN" \
    '{name:$name,card_id:$card_id,fixture_token:$fixture_token,lifecycle_token:$lifecycle_token}' \
    >"$tmp") || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$file"
}

disposable_habit_read_handoff() {
  local file="${1:-}" expected_token="${2:-}"
  disposable_habit_handoff_file_is_safe "$file" || return 1
  jq -e --arg lifecycle "${STUARI_RELEASE_LIFECYCLE_TOKEN:-}" --arg token "$expected_token" '
    type == "object"
    and .lifecycle_token == $lifecycle
    and .fixture_token == $token
    and (.name | type == "string" and endswith(" " + $token))
    and (.card_id | type == "string" and startswith("habit_card_"))
  ' "$file" >/dev/null 2>&1
}
