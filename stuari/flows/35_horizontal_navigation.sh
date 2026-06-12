#!/usr/bin/env bash
# Flow 35: Horizontal Shell Navigation
#
# Goal: verify page-level horizontal swipes move across shell branches while
# local horizontal gesture areas, like the home habit carousel, keep ownership.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 35: Horizontal Navigation"

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
    pass "Swipe landed on: $desc"
    return 0
  fi
  fail "Swipe did not land on expected tab: $desc"
  return 1
}

swipe_left_body() {
  local desc="$1"
  local r
  r=$(run_iez "$IEZ" ui swipe --from "365,92" --to "35,92")
  assert_ok "$r" "Swipe left: $desc"
  sleep 1.3
}

swipe_right_body() {
  local desc="$1"
  local r
  r=$(run_iez "$IEZ" ui swipe --from "35,92" --to "365,92")
  assert_ok "$r" "Swipe right: $desc"
  sleep 1.3
}

go_home
sleep 1.2
capture "35_home_start"
assert_selected_tab "$TAB_HOME" "Home"

swipe_left_body "Home to Notifications"
capture "35_notifications_swiped"
assert_selected_tab "$TAB_NOTIFICATIONS" "Notifications"

swipe_left_body "Notifications to Profile"
capture "35_profile_swiped"
assert_selected_tab "$TAB_PROFILE" "Profile"

swipe_left_body "Profile to Settings"
capture "35_settings_swiped"
assert_selected_tab "$TAB_SETTINGS" "Settings"

swipe_left_body "Settings edge"
capture "35_settings_edge"
assert_selected_tab "$TAB_SETTINGS" "Settings edge remains"

swipe_right_body "Settings to Profile"
capture "35_profile_return"
assert_selected_tab "$TAB_PROFILE" "Profile return"

swipe_right_body "Profile to Notifications"
capture "35_notifications_return"
assert_selected_tab "$TAB_NOTIFICATIONS" "Notifications return"

swipe_right_body "Notifications to Home"
capture "35_home_return"
assert_selected_tab "$TAB_HOME" "Home return"

# Local gesture ownership check: a horizontal swipe over the home carousel
# should stay on Home. The carousel may move to another habit card, but the
# shell should not jump to Notifications from this gesture-rich area.
if wait_for_visible_habit_card 4; then
  before_card="$(current_visible_habit_card_id)"
  r=$(run_iez "$IEZ" ui swipe --from "345,280" --to "45,280")
  assert_ok "$r" "Swipe over habit carousel area"
  sleep 1.5
  capture "35_home_carousel_override"
  after_card="$(current_visible_habit_card_id)"
  if selected_tab_matches "$TAB_HOME"; then
    pass "Home carousel swipe kept shell on Home"
    if [ -n "$before_card" ] && [ -n "$after_card" ] && [ "$before_card" != "$after_card" ]; then
      info "Carousel moved from $before_card to $after_card"
    fi
  else
    fail "Home carousel swipe incorrectly changed shell branch"
  fi
else
  skip "Home carousel gesture ownership" "no visible habit card"
fi

print_summary
exit $FAIL
