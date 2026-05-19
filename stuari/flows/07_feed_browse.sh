#!/usr/bin/env bash
# Flow 07: Feed Browse + Post Detail
#
# Goal: scroll the feed, verify posts render (image/video thumbnails),
# tap into a post detail page, verify detail renders, navigate back.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 07: Feed Browse"

reseed_feed_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

# The "feed" is part of Home — it's the bottom sheet that expands from the
# home screen. Drag it up or use the Feed tab within the bottom sheet tabs.
go_home
sleep 1
capture "07_home_initial"

# Drag the home bottom sheet up to reveal the feed
# The sheet grabber is near the bottom; swipe up from ~y=700 to y=200
r=$(run_iez "$IEZ" ui swipe --from "200,700" --to "200,200")
if [ "$(json_ok "$r")" = "true" ]; then
  pass "Expanded home bottom sheet"
  sleep 1.5
else
  skip "Expand feed sheet" "swipe failed"
fi
capture "07_feed_expanded"

# Tap Feed tab within the bottom sheet if present
if has_label "Feed"; then
  tap_element "Feed" "label" "Switch to Feed tab"
  sleep 1
fi

capture "07_feed_list"

# Scroll the feed — expect more posts to load
r=$(run_iez "$IEZ" ui swipe up)
assert_ok "$r" "Scroll feed down (swipe up)"
sleep 0.8
capture "07_feed_scrolled"
r=$(run_iez "$IEZ" ui swipe up)
assert_ok "$r" "Scroll feed further"
sleep 0.8

# Tap the first post with a "comments" label (feed_post_card_last_comment).
# These labels are rendered inside a scrolling ListView so the element
# may have frame={{0,0},{0,0}} and the tap-by-label can silently fail
# even when a subsequent tree inspection shows the detail page. Tap
# tolerantly and verify by post-tap state instead of the tap return.
comment_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^\\d+ comments")) | .label' | head -1)
if [ -z "$comment_label" ]; then
  comment_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^Last comment by ")) | .label' | head -1)
fi
if [ -n "$comment_label" ]; then
  r=$(run_iez "$IEZ" ui tap --label "$comment_label")
  sleep 1.5
  capture "07_post_detail"
  # Verify post detail opened (authoritative)
  if tree_contains "Post image" || tree_contains "Post video" || has_label "Post"; then
    pass "Post detail loaded via '$comment_label'"
  else
    fail "Post detail did not load after tapping '$comment_label'"
  fi
  # Back
  go_back
  sleep 1
else
  if tree_contains "No posts yet"; then
    skip "Post detail" "feed is empty for this seeded account"
  else
    skip "Post detail" "no posts with comments in feed"
  fi
fi

capture "07_back_to_feed"

# Scroll back up
r=$(run_iez "$IEZ" ui swipe down)
assert_ok "$r" "Scroll feed back to top"
sleep 0.5

print_summary
exit $FAIL
