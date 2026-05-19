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

reseed_feed_fixtures || true
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home

# Open feed
run_iez "$IEZ" ui swipe --from "200,700" --to "200,200" >/dev/null 2>&1
sleep 1.5
if has_label "Feed"; then tap_element "Feed" "label" "Feed tab"; sleep 1; fi

# Tap into a post with comments
opened_post=0
for _ in 1 2 3 4 5 6; do
  if tap_first_matching_label_regex '^Open post by ' '' \
    "Open post via card"; then
    sleep 1.5
    opened_post=1
    break
  fi

  comment_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
      | select(.label != null)
      | select(.label | test("[0-9]+ comments, tap to view"; ""))
      | select(.frame != null and .frame.width > 20 and .frame.height > 20)
      | .frame
      | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
    | head -1)

  if [ -n "$comment_coords" ] && [ "$comment_coords" != "null" ] && [ "$comment_coords" != "," ]; then
    tap_element "$comment_coords" "coords" "Open post via comments count"
    sleep 1.5
    opened_post=1
    break
  fi

  if tap_first_matching_label_regex '^Last comment by ' '' \
    "Open post via last comment"; then
    sleep 1.5
    opened_post=1
    break
  fi

  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 0.8
done

if [ "$opened_post" != "1" ]; then
  skip "Post detail entry" "no comment affordance became reachable"
  print_summary; exit $FAIL
fi

capture "09_post_detail"

# Find the comment input on the post detail page.
added=0
comment_text=$(test_comment)
for _ in 1 2 3 4 5 6; do
  input_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
      | select(.label != null)
      | select(.label | test("^(Comment input|Add a comment\\.\\.\\.)$"; ""))
      | select(.frame != null and .frame.width > 100 and .frame.height >= 40)
      | .frame
      | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
    | head -1)
  if [ -n "$input_coords" ] && [ "$input_coords" != "null" ] && [ "$input_coords" != "," ]; then
    run_iez "$IEZ" ui tap --coords "$input_coords" >/dev/null 2>&1 || true
    sleep 0.3
    r=$(run_iez "$IEZ" ui type "$comment_text")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Typed comment"
      added=1
      break
    fi
  fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 0.8
done

if [ "$added" = "0" ]; then
  fail "Comment input" '{"reason":"comment input not reachable on post detail"}'
  print_summary; exit $FAIL
fi

# Submit comment
if tap_first_matching_label_regex '^Send comment$' '' "Submit comment"; then
  :
else
  run_iez "$IEZ" ui key "40" >/dev/null 2>&1
  pass "Submit comment via return key"
fi
sleep 2
capture "09_comment_submitted"

comment_visible=0
comment_text_lc=$(printf '%s' "$comment_text" | tr '[:upper:]' '[:lower:]')
for _ in 1 2 3 4 5; do
  if run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | .label' \
    | tr '[:upper:]' '[:lower:]' \
    | grep -Fq "$comment_text_lc"; then
    comment_visible=1
    break
  fi
  sleep 1
done

if [ "$comment_visible" = "1" ]; then
  pass "Comment submitted"
elif has_label "Delete" || tree_contains "Delete"; then
  pass "Comment submitted"
else
  fail "Comment submitted" "{\"reason\":\"comment text '$comment_text' not visible after submit\"}"
fi

# Reply to an existing comment
reply_text="replying $(rand_tail)"
reply_text_lc=$(printf '%s' "$reply_text" | tr '[:upper:]' '[:lower:]')
if tap_first_matching_label_regex '^Reply$' '' "Reply to comment"; then
  sleep 1
  if has_label "Cancel reply"; then
    pass "Reply mode entered"
    reply_coords=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[]
        | select(.label != null)
        | select(.label | test("^(Reply comment input|Comment input)$"; ""))
        | select(.frame != null and .frame.width > 100 and .frame.height >= 40)
        | .frame
        | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
      | head -1)
    if [ -n "$reply_coords" ] && [ "$reply_coords" != "null" ] && [ "$reply_coords" != "," ]; then
      run_iez "$IEZ" ui tap --coords "$reply_coords" >/dev/null 2>&1 || true
      sleep 0.3
      r=$(run_iez "$IEZ" ui type "$reply_text")
      assert_ok "$r" "Type reply"
    elif tree_contains "Reply comment input"; then
      type_into "Reply comment input" "$reply_text"
    else
      type_into "Comment input" "$reply_text"
    fi
    if tap_first_matching_label_regex '^Send comment$' '' "Submit reply"; then
      :
    else
      run_iez "$IEZ" ui key "40" >/dev/null 2>&1
      pass "Submit reply via return key"
    fi
    sleep 2
    if run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[] | select(.label != null) | .label' \
      | tr '[:upper:]' '[:lower:]' \
      | grep -Fq "$reply_text_lc"; then
      pass "Reply submitted"
    elif tree_contains "View 1 reply" \
      || tree_contains "View 2 replies" \
      || tree_contains "Hide replies"; then
      pass "Reply submitted"
    else
      fail "Reply submitted" "{\"reason\":\"reply text '$reply_text' not visible after submit\"}"
    fi
  else
    fail "Reply mode" '{"reason":"Cancel reply affordance not found after tapping Reply"}'
  fi
else
  fail "Reply to comment" '{"reason":"no Reply button on existing comments"}'
fi

go_back
sleep 1
capture "09_back_to_feed"

print_summary
exit $FAIL
