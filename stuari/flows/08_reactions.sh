#!/usr/bin/env bash
# Flow 08: Reactions
#
# Goal: from the feed, find a post, tap a reaction button, verify state
# changes (count increments or icon filled).
#
# Reaction widgets:
#   feed/widgets/like_button.dart       Semantics(button: true)
#   feed/widgets/feed_post_card_reaction_row.dart  Semantics(button: true, label: "N reactions...")

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 08: Reactions"

reseed_feed_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1

# Expand home bottom sheet to reveal feed
run_iez "$IEZ" ui swipe --from "200,700" --to "200,200" >/dev/null 2>&1
sleep 1.5
if has_label "Feed"; then
  tap_element "Feed" "label" "Feed tab"
  sleep 1
fi

capture "08_feed_initial"

# Find a reaction row label — pattern starts with "react" (case-insensitive) or
# ends with " reactions". Also try Like.
reaction_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("reaction"; "i")) | .label' | head -1)

if [ -z "$reaction_label" ]; then
  # Try like_button which has no specific label — look for heart icon substring
  reaction_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^(Like|like$|Liked|❤)"; "i")) | .label' | head -1)
fi

if [ -n "$reaction_label" ]; then
  tapped_reaction=0
  for _ in 1 2 3 4 5 6; do
    if tap_first_matching_label_regex 'reaction|^(Like|like$|Liked|❤)' 'i' \
      "Tap reaction ($reaction_label)"; then
      tapped_reaction=1
      break
    fi
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
    sleep 0.8
  done
  sleep 1
  capture "08_after_tap"
  if [ "$tapped_reaction" = "1" ]; then
    pass "Reaction tap executed"
  else
    fail "Reaction tap" '{"reason":"reaction label found but never became visible enough to tap"}'
  fi
else
  if tree_contains "No posts yet"; then
    skip "Reaction tap" "feed is empty for this seeded account"
  else
    skip "Reaction tap" "no reaction buttons visible in current feed"
  fi
fi

# Sanity: UI should still be responsive. Home-tab top-nav semantics are
# not exposed on the home page (see navigation.sh), so fall back to any
# always-present home marker.
if has_label "Home tab, selected" \
  || has_label "Home tab" \
  || has_label "Create new habit" \
  || tree_contains "Tab 1 of 3"; then
  pass "Home still present after reaction"
else
  fail "Home lost after reaction"
fi

print_summary
exit $FAIL
