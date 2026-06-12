#!/usr/bin/env bash
# Flow 15: Notifications — Inbox + Deep Link
#
# Goal: open Notifications tab, verify list renders, tap a notification
# to deep-link into a post/group.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 15: Notifications"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

# Note the badge count (if any) on the Notifications tab
badge_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Notifications tab")) | .label' | head -1)
if [ -n "$badge_label" ]; then
  info "Notifications tab label: '$badge_label'"
fi

go_notifications
sleep 1.5
capture "15_notifications_list"

# Verify the list area has SOME content. An empty-state stub (no
# notifications yet) is a legitimate state for a freshly-seeded user
# and should not flag as a fail — treat it as skip instead. We
# consider the page "loaded" if we can see either notification items
# OR an empty-state message.
tree=$(run_iez "$IEZ" ui tree --compact)
count=$(echo "$tree" | jq '[.data.elements[]] | length' 2>/dev/null)
has_empty_marker="false"
if echo "$tree" | jq -e '.data.elements[] | select(.label and (.label | test("no notifications|nothing here|all caught up|empty"; "i")))' >/dev/null 2>&1; then
  has_empty_marker="true"
fi
TOTAL=$((TOTAL + 1))
if [ "$has_empty_marker" = "true" ]; then
  pass "Notifications empty-state visible"
  info "Deep-link path not exercised because inbox is empty"
  go_home
  print_summary
  exit $FAIL
elif [ "${count:-0}" -gt 5 ]; then
  pass "Notifications list has $count elements"
else
  fail "Notifications list looks empty ($count elements)"
fi

# Scroll the list
run_iez "$IEZ" ui swipe up >/dev/null 2>&1
sleep 0.5
capture "15_notifications_scrolled"

# Tap the first notification row. Prefer stable Semantics identifiers; fall
# back to the older label matching path for builds that do not expose them.
first_notif_id=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
      | select(.id != null)
      | select(.id | startswith("notification_tile_"))
      | .id' | head -1)

first_notif=""
if [ -z "$first_notif_id" ]; then
  first_notif=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
        | select(.label != null)
        | select(.label | test("liked|commented|followed|confirm|posted|check in"; "i"))
        | .label' | head -1)
fi

tapped_notification="false"
if [ -n "$first_notif_id" ]; then
  coords=$(coords_for_id "$first_notif_id")
  if [ -n "$coords" ]; then
    r=$(run_iez "$IEZ" ui tap --coords "$coords")
    assert_ok "$r" "Tap first notification row ($first_notif_id)"
  else
    tap_element "$first_notif_id" "id" "Tap first notification row ($first_notif_id)"
  fi
  sleep 2
  capture "15_notif_target"
  tapped_notification="true"
elif [ -n "$first_notif" ]; then
  tap_element "$first_notif" "label" "Tap first notification ('$first_notif')"
  sleep 2
  capture "15_notif_target"
  tapped_notification="true"
fi

if [ "$tapped_notification" = "true" ]; then
  # Verify we navigated somewhere — we should not be on the notifications list anymore
  # (best-effort: Home tab selected state flipped)
  if has_label "Notifications tab, selected"; then
    fail "Tap did not navigate — still on Notifications"
  else
    pass "Notification deep-link opened a target screen"
  fi

  # Return to notifications
  go_back
  sleep 1
else
  info "No tappable notification rows found"
fi

go_home
print_summary
exit $FAIL
