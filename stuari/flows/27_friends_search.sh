#!/usr/bin/env bash
# Flow 27 (P1): Members sheet → friend search
#
# Opens the overflow members sheet from Home and verifies the "Add Member"
# CTA routes into the existing FriendSearchPage.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 27: Members sheet smoke"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_home
sleep 1

# Look for a member bubble overflow "+N" label first, then for "Members".
members_label=""
for lbl in "Members" "+1" "+2" "+3" "+4"; do
  if has_label "$lbl"; then members_label="$lbl"; break; fi
done

# Also try a startswith match for member bubble counts.
if [ -z "$members_label" ]; then
  members_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '[.data.elements[] | select(.label != null) | select(.label | test("^member|^\\+[0-9]+ more|Group members"; "i")) | .label][0]')
fi

if [ -n "$members_label" ] && [ "$members_label" != "null" ]; then
  tap_element "$members_label" "label" "Open members sheet ('$members_label')"
  sleep 1.2
  capture "27_members_sheet"

  if has_label "Add Member"; then
    tap_element "Add Member" "label" "Tap Add Member"
    sleep 1.5
    capture "27_friend_search"
    if tree_contains "Invite to Group" || tree_contains "Inviting to" || has_label "Invite via SMS"; then
      pass "Friend search page opened from members sheet"
    else
      fail "Friend search page did not open from members sheet"
    fi
  else
    info "No Add Member CTA — members sheet may be read-only"
  fi
elif has_label "Add friend to group"; then
  tap_element "Add friend to group" "label" "Open friend search from home shortcut"
  sleep 1.5
  capture "27_friend_search"
  if tree_contains "Invite to Group" || tree_contains "Inviting to" || has_label "Invite via SMS"; then
    pass "Friend search page opened from direct add-friend button"
  else
    fail "Friend search page did not open from direct add-friend button"
  fi
else
  skip "Friend search entry" "no member overflow or add-friend affordance visible on home"
fi

dismiss_all
print_summary
exit $FAIL
