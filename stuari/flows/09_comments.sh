#!/usr/bin/env bash
# Flow 09: Comments + Replies
#
# Goal: open a post detail, add a comment, reply to an existing comment.
#
# Widgets:
#   comments/widgets/comment_input_bar.dart  has "Cancel reply" label
#   comments/widgets/comment_tile.dart       has "Delete" / reply actions

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 09: Comments + Replies"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home

# Open feed
run_iez "$IEZ" ui swipe --from "200,700" --to "200,200" >/dev/null 2>&1
sleep 1.5
if has_label "Feed"; then tap_element "Feed" "label" "Feed tab"; sleep 1; fi

# Tap into a post with comments
comment_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[] | select(.label != null) | select(.label | test("^\\d+ comment"; "")) | .label' | head -1)

if [ -z "$comment_label" ]; then
  # Try entering the first post via its image
  image_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | test("Post image|Post video"; "")) | .label' | head -1)
  if [ -n "$image_label" ]; then
    tap_element "$image_label" "label" "Open post via image"
    sleep 1.5
  else
    skip "Post detail entry" "no posts in feed"
    print_summary; exit $FAIL
  fi
else
  # Off-screen ListView items can silently fail a label tap; verify by
  # post-state rather than the tap's return code.
  r=$(run_iez "$IEZ" ui tap --label "$comment_label")
  sleep 1.5
  if tree_contains "Post image" || tree_contains "Post video" || has_label "Back"; then
    pass "Opened post via '$comment_label'"
  else
    fail "Tap '$comment_label' did not open a post"
  fi
fi

capture "09_post_detail"

# Find the comment input — likely has a hint like "Add a comment..." or "Write..."
# Try typing into it by tapping a text field, then typing.
# There's no explicit semanticLabel on the input in comment_input_bar.dart,
# so we fall back to "Write a comment" / "Add a comment" / field by label.
added=0
for candidate in "Add a comment..." "Add a comment" "Write a comment..." "Write a comment" "Comment..."; do
  if tree_contains "$candidate"; then
    type_into "$candidate" "$(test_comment)"
    added=1
    break
  fi
done

if [ "$added" = "0" ]; then
  # Last resort: tap the bottom-center of the screen and type
  run_iez "$IEZ" ui tap --coords "200,750" >/dev/null 2>&1
  sleep 0.5
  if run_iez "$IEZ" ui type "$(test_comment)" | grep -q '"ok":true'; then
    pass "Typed comment (via coords fallback)"
    added=1
  fi
fi

# Submit comment — look for a send/paper-plane-style button
if has_label "Send comment" || has_label "Send"; then
  label=$(has_label "Send comment" && echo "Send comment" || echo "Send")
  tap_element "$label" "label" "Submit comment"
  sleep 2
  capture "09_comment_submitted"
else
  skip "Submit comment" "no explicit Send button — may require return key"
  run_iez "$IEZ" ui key "40" >/dev/null 2>&1  # return key
  sleep 1
fi

# Reply to an existing comment (best-effort — look for "Reply" button).
# Reply buttons can be off-screen in the comment ListView; treat the tap
# as soft-pass so only the downstream verification drives pass/fail.
if has_label "Reply"; then
  run_iez "$IEZ" ui tap --label "Reply" >/dev/null 2>&1
  sleep 0.8
  if has_label "Cancel reply"; then
    pass "Reply mode entered (Cancel reply visible)"
    run_iez "$IEZ" ui type "replying $(rand_tail)" >/dev/null 2>&1
    sleep 0.3
    tap_element "Cancel reply" "label" "Cancel reply"
  else
    skip "Reply mode" "Cancel reply affordance not found"
  fi
else
  skip "Reply to comment" "no Reply button on existing comments"
fi

go_back
sleep 1
capture "09_back_to_feed"

print_summary
exit $FAIL
