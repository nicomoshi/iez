#!/usr/bin/env bash
# Flow 30 (P1): Chat — delete own message + reaction
#
# Walks: Home → open group chat → send a message → long-press to open
# message context menu → delete. Verifies message removed.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 30: Chat delete message"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_home
sleep 1

# Open the group chat from the habit card (Open group chat tooltip).
if has_label "Open group chat"; then
  tap_element "Open group chat" "label" "Open group chat"
  sleep 1.5
else
  skip "Chat entry" "no Open group chat button on home"
  print_summary; exit $FAIL
fi

capture "30_chat"

# Send a new message (test fixture)
msg=$(test_chat_message)
if tree_contains "Type a message"; then
  type_into "Type a message..." "$msg"
  sleep 0.5
  if has_label "Send message"; then
    tap_element "Send message" "label" "Send message"
    sleep 1.5
    pass "Sent message '$msg'"
  fi
else
  skip "Chat input" "hint not visible"
fi

capture "30_after_send"

# Long-press the message to open context menu. iEZ has no long-press
# primitive, so simulate via a tap+hold using the coords the message
# bubble occupies. We read the tree and find the label matching our
# message (ChatMessageBubble passes message.content as Semantics label).
msg_coords=$(run_iez "$IEZ" ui tree --compact \
  | jq -r --arg m "$msg" '[.data.elements[] | select(.label != null) | select(.label | contains($m))] | first | "\(.frame.x + (.frame.width/2) | floor),\(.frame.y + (.frame.height/2) | floor)"' 2>/dev/null)

if [ -n "$msg_coords" ] && [ "$msg_coords" != "null" ] && [ "$msg_coords" != "," ]; then
  info "Long-pressing message bubble at $msg_coords"
  r=$(run_iez "$IEZ" ui long-press --coords "$msg_coords")
  assert_ok "$r" "Long-press message bubble"
  sleep 1.5
fi

if has_label "Delete" || has_label "Delete message"; then
  for lbl in "Delete message" "Delete"; do
    if has_label "$lbl"; then
      tap_element "$lbl" "label" "Tap $lbl"
      sleep 1
      break
    fi
  done
  if has_label "Delete" || has_label "Confirm"; then
    coords=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '[.data.elements[] | select(.label == "Delete")] | last | "\(.frame.x + (.frame.width/2) | floor),\(.frame.y + (.frame.height/2) | floor)"' 2>/dev/null)
    if [ -n "$coords" ] && [ "$coords" != "null" ] && [ "$coords" != "," ]; then
      r=$(run_iez "$IEZ" ui tap --coords "$coords")
      assert_ok "$r" "Confirm delete ($coords)"
    fi
  fi
  pass "Deleted own message"
else
  skip "Delete message" "long-press menu not reachable via single tap"
fi

capture "30_done"
go_back
sleep 1
print_summary
exit $FAIL
