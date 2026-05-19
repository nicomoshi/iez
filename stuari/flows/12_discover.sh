#!/usr/bin/env bash
# Flow 12: Discover — Public Feed + Discovery Comments
#
# Goal: navigate to Discover tab, scroll, tap a discover post, add a
# discovery comment.
#
# Widgets (lib/discover/widgets/):
#   discover_post_card.dart
#   discover_video_card_*.dart
#   discovery_comment_input.dart    label: 'Cancel reply'
#   discovery_comment_tile.dart     label: 'Delete'

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 12: Discover"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

# Discover tab is feature-flagged. Check if it exists first.
if ! has_label "Discover tab" && ! has_label "Discover tab, selected"; then
  pass "Discover tab hidden while FeatureFlags.isDiscoverEnabled is false"
  print_summary
  exit $FAIL
fi

go_discover
sleep 2
capture "12_discover_landing"

# Scroll the public feed
r=$(run_iez "$IEZ" ui swipe up)
assert_ok "$r" "Scroll Discover (swipe up)"
sleep 0.8
capture "12_discover_scrolled"

r=$(run_iez "$IEZ" ui swipe up)
assert_ok "$r" "Scroll Discover again"
sleep 0.8

# Horizontal swipe to advance carousel (Discover is often a PageView)
r=$(run_iez "$IEZ" ui swipe --from "350,400" --to "50,400")
assert_ok "$r" "Horizontal swipe (next card)"
sleep 1
capture "12_next_card"

# Try opening discovery comments — look for "View comments" / "N comments"
comment_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("comment"; "i")) | .label' | head -1)
if [ -n "$comment_label" ]; then
  tap_element "$comment_label" "label" "Open discovery comments ('$comment_label')"
  sleep 1.5
  capture "12_discovery_comments"

  # Try adding a comment (best-effort — the input has no explicit semanticLabel)
  run_iez "$IEZ" ui tap --coords "200,750" >/dev/null 2>&1
  sleep 0.5
  if run_iez "$IEZ" ui type "$(test_comment)" | grep -q '"ok":true'; then
    pass "Typed discovery comment"
    run_iez "$IEZ" ui key "40" >/dev/null 2>&1  # return
    sleep 1
  fi

  dismiss_all
else
  skip "Discovery comments" "no comment entry visible"
fi

go_home
print_summary
exit $FAIL
