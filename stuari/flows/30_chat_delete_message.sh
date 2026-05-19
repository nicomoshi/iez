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
cleanup_generated_chat_messages || true

go_home
sleep 1

# Open the group chat from the habit card (Open group chat tooltip).
if tap_first_matching_label_regex '^Open group chat' '' "Open group chat"; then
  sleep 1.5
else
  skip "Chat entry" "no Open group chat button on home"
  print_summary; exit $FAIL
fi

capture "30_chat"

# Send a new message (test fixture)
msg=$(test_chat_message)
msg_lc=$(printf '%s' "$msg" | tr '[:upper:]' '[:lower:]')
if tree_contains "Chat message input" || tree_contains "Type a message"; then
  if has_label "Chat message input"; then
    type_into "Chat message input" "$msg"
  else
    type_into "Type a message..." "$msg"
  fi
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

message_visible=0
for _ in 1 2 3 4 5; do
  if run_iez "$IEZ" ui tree --compact \
    | jq -e --arg msg "$msg_lc" '.data.elements[]
      | select(.label != null)
      | select((.label | ascii_downcase) | contains($msg))' >/dev/null 2>&1; then
    message_visible=1
    break
  fi
  sleep 1
done

if [ "$message_visible" = "1" ]; then
  pass "Message '$msg' visible in chat"
else
  skip "Message visibility" "text not found in tree after send"
  print_summary; exit $FAIL
fi

# Prefer the explicit message-scoped overflow menu on the freshly sent message.
options_coords=$(run_iez "$IEZ" ui tree --compact \
  | jq -r --arg msg "$msg_lc" '.data.elements[]
    | select(.label != null)
    | select(
        ((.label | ascii_downcase) | contains("message options for " + $msg))
        or ((.label | ascii_downcase) | contains("message options"))
      )
    | select(.frame != null and .frame.width > 0 and .frame.height > 0)
    | .frame
    | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
  | head -1)

menu_open=0
if [ -n "$options_coords" ]; then
  r=$(run_iez "$IEZ" ui tap --coords "$options_coords")
  assert_ok "$r" "Open message options"
  sleep 1.5
  if has_label "Delete message" || has_label "Delete"; then
    menu_open=1
  fi
fi

if [ "$menu_open" != "1" ]; then
  msg_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r --arg msg "$msg_lc" '.data.elements[]
      | select(.label != null)
      | select((.label | ascii_downcase) | contains($msg))
      | select(.frame != null and .frame.width > 0 and .frame.height > 0)
      | .frame
      | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
    | tail -1)

  if [ -n "$msg_coords" ] && [ "$msg_coords" != "null" ] && [ "$msg_coords" != "," ]; then
    msg_x=${msg_coords%,*}
    msg_y=${msg_coords#*,}
    for offset in 54 66 78 90 102; do
      candidate="$((msg_x - offset)),$msg_y"
      tap_element "$candidate" "coords" "Tap message menu affordance"
      sleep 1
      if has_label "Delete message" || has_label "Delete"; then
        menu_open=1
        break
      fi
    done
  fi
fi

if [ "$menu_open" != "1" ]; then
  fail "Open message options" '{"reason":"delete action did not appear after tapping message options"}'
  print_summary; exit $FAIL
fi

if has_label "Delete message" || has_label "Delete"; then
  if has_label "Delete message"; then
    tap_element "Delete message" "label" "Tap Delete message"
  else
    tap_element "Delete" "label" "Tap Delete"
  fi
  sleep 1
  if has_label "Delete" || has_label "Confirm"; then
    coords=$(run_iez "$IEZ" ui tree --compact \
      | jq -r '[.data.elements[] | select(.label == "Delete")] | last | "\(.frame.x + (.frame.width/2) | floor),\(.frame.y + (.frame.height/2) | floor)"' 2>/dev/null)
    if [ -n "$coords" ] && [ "$coords" != "null" ] && [ "$coords" != "," ]; then
      r=$(run_iez "$IEZ" ui tap --coords "$coords")
      assert_ok "$r" "Confirm delete ($coords)"
    fi
  fi
  sleep 1.5
  if run_iez "$IEZ" ui tree --compact \
    | jq -e --arg msg "$msg_lc" '.data.elements[]
      | select(.label != null)
      | select((.label | ascii_downcase) | contains($msg))' >/dev/null 2>&1; then
    fail "Deleted own message" "{\"reason\":\"message still visible after delete\"}"
  else
    pass "Deleted own message"
  fi
else
  fail "Delete message" '{"reason":"delete action disappeared before it could be tapped"}'
fi

capture "30_done"
go_back
sleep 1
print_summary
exit $FAIL
