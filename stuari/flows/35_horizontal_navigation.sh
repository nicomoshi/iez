#!/usr/bin/env bash
# Flow 35: Tap-Only Shell Navigation + Carousel Swipe Boundary
#
# Goal: verify horizontal body swipes never switch shell destinations, top-nav
# taps still do, and bracket the habit-carousel boundary with a 47 pt stay and
# a 50 pt move. The exact 48 pt contract belongs to the Flutter widget test
# because Axe quantizes sub-50 pt simulator swipes on this runtime.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 35: Tap-Only Navigation + Carousel Boundary"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

selected_tab_matches() {
  local base="$1"
  run_iez "$IEZ" ui tree --compact \
    | jq -e --arg base "$base" '.data.elements[]
      | select(.label != null)
      | select((.label | startswith($base)) and (.label | contains("selected")))' \
      >/dev/null 2>&1
}

assert_selected_tab() {
  local base="$1" desc="$2"
  if selected_tab_matches "$base"; then
    pass "Selected shell destination: $desc"
    return 0
  fi
  fail "Unexpected shell destination; expected: $desc"
  return 1
}

assert_body_swipe_stays() {
  local from="$1" to="$2" expected="$3" desc="$4"
  local r
  r=$(run_iez "$IEZ" ui swipe --from "$from" --to "$to")
  assert_ok "$r" "Horizontal body swipe delivered: $desc"
  sleep 1.3
  assert_selected_tab "$expected" "$desc remains selected"
}

carousel_neighbor_direction() {
  local current_id="$1" current_x tree
  tree=$(run_iez "$IEZ" ui tree --compact)
  current_x=$(printf '%s\n' "$tree" | jq -r --arg id "$current_id" '
    [.data.elements[]
      | select(.id == $id)
      | select(.frame != null and .frame.width > 40 and .frame.height > 40)
      | (.frame.x + (.frame.width / 2))] | first // empty')
  [ -z "$current_x" ] && return 1

  if printf '%s\n' "$tree" | jq -e --arg id "$current_id" --argjson x "$current_x" '
    [.data.elements[]
      | select(.id != null and (.id | startswith("habit_card_")))
      | select(.id | startswith("habit_card_menu_") | not)
      | select(.id != $id)
      | select(.frame != null and .frame.width > 40 and .frame.height > 40)
      | select((.frame.x + (.frame.width / 2)) > ($x + 20))] | length > 0' \
      >/dev/null 2>&1; then
    printf 'left\n'
    return 0
  fi

  if printf '%s\n' "$tree" | jq -e --arg id "$current_id" --argjson x "$current_x" '
    [.data.elements[]
      | select(.id != null and (.id | startswith("habit_card_")))
      | select(.id | startswith("habit_card_menu_") | not)
      | select(.id != $id)
      | select(.frame != null and .frame.width > 40 and .frame.height > 40)
      | select((.frame.x + (.frame.width / 2)) < ($x - 20))] | length > 0' \
      >/dev/null 2>&1; then
    printf 'right\n'
    return 0
  fi

  return 1
}

go_home
sleep 1.2
capture "35_home_start"
assert_selected_tab "$TAB_HOME" "Home"

assert_body_swipe_stays "365,420" "35,420" "$TAB_HOME" "Home"
capture "35_home_shell_swipe_ignored"

# Bracket the app's fixed threshold without overclaiming Axe precision. Run only
# when AX exposes a real adjacent habit card.
if wait_for_visible_habit_card 5; then
  before_card="$(current_visible_habit_card_id)"
  direction="$(carousel_neighbor_direction "$before_card" 2>/dev/null || true)"
  if [ "$direction" = "left" ]; then
    drag_from="250,340"
    drag_47_to="203,340"
    drag_50_to="200,340"
  elif [ "$direction" = "right" ]; then
    drag_from="150,340"
    drag_47_to="197,340"
    drag_50_to="200,340"
  else
    drag_from=""
  fi

  if [ -n "$drag_from" ]; then
    r=$(run_iez "$IEZ" ui swipe --from "$drag_from" --to "$drag_47_to")
    assert_ok "$r" "47 pt habit-carousel drag delivered"
    sleep 1
    capture "35_carousel_47pt_stays"
    after_47="$(current_visible_habit_card_id)"
    if [ "$after_47" = "$before_card" ]; then
      pass "47 pt drag stays on the selected habit"
    else
      fail "47 pt drag changed habit ($before_card -> $after_47)"
    fi
    assert_selected_tab "$TAB_HOME" "Home after 47 pt carousel drag"

    skip "Exact 48 pt simulator boundary" "Axe quantizes sub-50 pt swipes; exact 48 is covered by Flutter widget tests"

    r=$(run_iez "$IEZ" ui swipe --from "$drag_from" --to "$drag_50_to")
    assert_ok "$r" "50 pt fallback carousel drag delivered"
    sleep 1
    capture "35_carousel_50pt_fallback_moves"
    after_50="$(current_visible_habit_card_id)"
    if [ -n "$after_50" ] && [ "$after_50" != "$before_card" ]; then
      pass "50 pt simulator fallback selects exactly one adjacent habit"
      info "Carousel moved from $before_card to $after_50"
    else
      fail "Carousel did not select an adjacent habit at the 50 pt tooling boundary"
    fi
    assert_selected_tab "$TAB_HOME" "Home after carousel boundary probe"
  else
    skip "47/48 pt carousel boundary" "AX exposed no adjacent habit card"
  fi
else
  skip "47/48 pt carousel boundary" "no visible habit card"
fi

# Shell destinations now change only through explicit nav taps.
go_notifications
assert_selected_tab "$TAB_NOTIFICATIONS" "Notifications after nav tap"
capture "35_notifications_tapped"
assert_body_swipe_stays "35,420" "365,420" "$TAB_NOTIFICATIONS" "Notifications"
capture "35_notifications_shell_swipe_ignored"

go_profile
assert_selected_tab "$TAB_PROFILE" "Profile after nav tap"
capture "35_profile_tapped"
assert_body_swipe_stays "365,420" "35,420" "$TAB_PROFILE" "Profile"
capture "35_profile_shell_swipe_ignored"

go_settings
assert_selected_tab "$TAB_SETTINGS" "Settings after nav tap"
capture "35_settings_tapped"
assert_body_swipe_stays "35,420" "365,420" "$TAB_SETTINGS" "Settings"
capture "35_settings_shell_swipe_ignored"

go_home
assert_selected_tab "$TAB_HOME" "Home after nav tap"
capture "35_home_tapped_return"

print_summary
exit $FAIL
