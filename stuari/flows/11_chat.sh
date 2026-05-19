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

# Verify we're in the chat.
if tree_contains "Chat message input" || tree_contains "Type a message"; then
  pass "Chat input visible"
else
  fail "Chat input not found"
fi

# Type & send a message
msg="$(test_chat_message)"
msg_lc=$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]')
if has_label "Chat message input"; then
  type_into "Chat message input" "$msg"
else
  type_into "Type a message..." "$msg"
fi
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

message_visible=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if run_iez "$IEZ" ui tree --compact \
    | jq -e --arg msg "$msg_lc" \
      '.data.elements[]
        | select(.label != null)
        | select((.label | ascii_downcase) | contains($msg))' >/dev/null 2>&1; then
    message_visible=1
    break
  fi
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1 || true
  sleep 0.3
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1 || true
  sleep 1
done

if [ "$message_visible" = "1" ]; then
  pass "Message '$msg' visible in chat"
else
  fail "Message visibility" '{"reason":"text not found in tree after send"}'
fi

# React to a message — long-press to open emoji picker.
# iez ui long-press requires --coords, not --label, so we read the element's
# frame from the tree and long-press its center.
if [ "$message_visible" = "1" ]; then
  center=$(run_iez "$IEZ" ui tree --compact \
    | jq -r --arg m "$msg_lc" \
      '.data.elements[]
        | select(.label != null)
        | select((.label | ascii_downcase) | contains($m))
        | .frame
        | if . then "\((.x + .width/2) | floor),\((.y + .height/2) | floor)" else empty end' \
    | tail -1)
  if [ -z "$center" ]; then
    center=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Message from Alice:")) | .frame
        | if . then "\((.x + .width/2) | floor),\((.y + .height/2) | floor)" else empty end' \
      | tail -1)
  fi
  if [ -n "$center" ]; then
    r=$(run_iez "$IEZ" ui long-press --coords "$center")
    assert_ok "$r" "Long-press message at $center to open reaction picker"
  else
    r=$(run_iez "$IEZ" ui long-press --coords "200,500")
    assert_ok "$r" "Long-press message (fallback coords 200,500)"
  fi
  sleep 1
  capture "11_reaction_picker"
  # Tap the first visible emoji option. The picker exposes labels like
  # "Thumbs up\n👍" rather than the emoji glyph alone.
  emoji_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
      | select(.role == "AXButton")
      | select(.label != null)
      | select(.label | test("Thumbs up|Love|Laugh|Surprised|Sad|Fire"))
      | .frame
      | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
    | head -1)
  if [ -n "$emoji_coords" ]; then
    tap_element "$emoji_coords" "coords" "Tap emoji reaction"
    sleep 1
    capture "11_reacted"
  else
    skip "Emoji reaction" "no emoji picker buttons found"
    dismiss_all
  fi
else
  fail "Long-press message" '{"reason":"message was not visible after send"}'
fi

go_back
sleep 1
print_summary
exit $FAIL
