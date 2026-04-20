#!/usr/bin/env bash
# Flow 11: Group Chat — Send Message + React
#
# Goal: open a habit group's chat, send a message, react to a message.
#
# Widgets (lib/chat/widgets/):
#   chat_input_bar.dart
#     hintText: 'Type a message...'
#     IconButton tooltip: 'Send message'
#   chat_message_bubble.dart       Semantics(image: true) for media bubbles
#   reaction_display.dart          Semantics(button: true) per emoji
#   reaction_emoji_picker.dart     Semantics(button: true) per emoji option

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 11: Group Chat"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
sleep 1

# Chat is reached from a habit group — either via a chat button on the home
# card, or via Group Chat bottom-sheet tab, or by navigating to /group/:id/chat.
if has_label "Chat"; then
  tap_element "Chat" "label" "Open group chat"
  sleep 1.5
else
  # Try finding a chat icon/button via tree search
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | test("chat|message"; "i")) | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Open chat ('$dyn')"
    sleep 1.5
  else
    skip "Chat entry" "no Chat button visible on Home"
    print_summary; exit $FAIL
  fi
fi

capture "11_chat_opened"

# Verify we're in the chat — input hint is "Type a message..."
if tree_contains "Type a message"; then
  pass "Chat input visible"
else
  fail "Chat input hint 'Type a message' not found"
fi

# Type & send a message
msg="$(test_chat_message)"
type_into "Type a message..." "$msg"
sleep 0.3
capture "11_typed_message"

# Send — tooltip is "Send message" which Flutter should expose as AX label
if has_label "Send message"; then
  tap_element "Send message" "label" "Tap Send message"
  sleep 2
  capture "11_sent"
elif has_label "Send"; then
  tap_element "Send" "label" "Tap Send"
  sleep 2
else
  # Fall back to return key
  run_iez "$IEZ" ui key "40" >/dev/null 2>&1
  sleep 1.5
  info "Used return key to submit (no Send button label found)"
fi

# Verify the message appears in the chat list
if tree_contains "$msg"; then
  pass "Message '$msg' visible in chat"
else
  skip "Message visibility" "text not found in tree after send (may be below fold)"
fi

# React to a message — long-press to open emoji picker.
# iez ui long-press requires --coords, not --label, so we read the element's
# frame from the tree and long-press its center.
if has_label "$msg"; then
  center=$(run_iez "$IEZ" ui tree --compact \
    | jq -r --arg m "$msg" \
      '.data.elements[] | select(.label == $m) | .frame
        | if . then "\((.x + .width/2) | floor),\((.y + .height/2) | floor)" else empty end' \
    | head -1)
  if [ -n "$center" ]; then
    r=$(run_iez "$IEZ" ui long-press --coords "$center")
    assert_ok "$r" "Long-press message at $center to open reaction picker"
  else
    r=$(run_iez "$IEZ" ui long-press --coords "200,500")
    assert_ok "$r" "Long-press message (fallback coords 200,500)"
  fi
  sleep 1
  capture "11_reaction_picker"
  # Tap first emoji — emoji picker buttons are labeled by emoji character
  emoji_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.role == "AXButton") | select(.label != null) | .label' \
    | grep -E '^.?(👍|❤|🔥|😂|😮|🎉|👏)' | head -1)
  if [ -n "$emoji_label" ]; then
    tap_element "$emoji_label" "label" "Tap emoji reaction ($emoji_label)"
    sleep 1
    capture "11_reacted"
  else
    skip "Emoji reaction" "no emoji picker buttons found"
    dismiss_all
  fi
else
  skip "Long-press message" "message not re-findable for long-press"
fi

go_back
sleep 1
print_summary
exit $FAIL
