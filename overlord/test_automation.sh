#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Overlord Flutter — End-to-End Automation Test
# Tests the OpenClaw mobile command center app through key user flows:
#   1. Launch & gateway connection
#   2. Send message & verify response
#   3. Expand/collapse tool call cards
#   4. Model selection bottom sheet
#   5. Chat scroll (up/down)
#   6. Sub-agent overlay
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IEZ="$REPO_ROOT/bin/iez"
OVERLORD_DIR="$HOME/Developer/overlord_flutter"
SCREENSHOTS="$SCRIPT_DIR/screenshots"
BUNDLE="com.arguello.overlordFlutter"

# Use simulator UDID from env or auto-detect
DEVICE_ID="${IEZ_DEVICE_UDID:-}"

PASS=0; FAIL=0; TOTAL=0; SKIP=0

export PATH="$REPO_ROOT/bin:$PATH"

# ── Helpers ──────────────────────────────────────────────────────────

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m %s\n' "$2"
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m %s\n' "$2"
    [ "${VERBOSE:-}" = "1" ] && echo "$1" | jq . >&2
  fi
}

assert_fail() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" != "true" ]; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m %s (expected fail)\n' "$2"
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m %s (should have failed)\n' "$2"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

tree_has_role() {
  local label="$1" role="$2"
  run_iez $IEZ ui tree --compact | jq -r --arg l "$label" --arg r "$role" \
    '.data.elements[] | select(.label == $l and .role == $r) | .label' 2>/dev/null | grep -q .
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.2
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 2.0
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

skip_test() {
  TOTAL=$((TOTAL + 1)); SKIP=$((SKIP + 1))
  printf '  \033[1;33m⊘\033[0m %s (skipped: %s)\n' "$1" "$2"
}

# ── Setup ────────────────────────────────────────────────────────────

mkdir -p "$SCREENSHOTS"

# Auto-detect UDID if not set
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID=$(xcrun simctl list devices booted -j 2>/dev/null | jq -r '.devices[][] | select(.state == "Booted") | .udid' | head -1)
  if [ -z "$DEVICE_ID" ]; then
    echo "ERROR: No booted simulator found. Boot one first: iez sim boot"
    exit 1
  fi
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║   Overlord Flutter — E2E Automation Suite        ║"
echo "║   Bundle: $BUNDLE          ║"
echo "║   Device: ${DEVICE_ID:0:20}...                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ═════════════════════════════════════════════════════════════════════
# FLOW 1: Launch App & Verify Gateway Connection
# ═════════════════════════════════════════════════════════════════════
echo "━━━ Flow 1: Launch & Gateway Connection ━━━"

fresh_launch

# Wait for the app to fully render — look for the text input field
R=$(run_iez $IEZ ui wait --label "Message…" --timeout 8)
assert_ok "$R" "App launched — message input visible"

screenshot "01_launch"

# Check title bar is rendered (connection dot area)
# The TitleBar has a connection dot + model menu. The terminal icon button
# navigates to LogViewerScreen. We verify basic UI structure.
TOTAL=$((TOTAL + 1))
# Look for any evidence of the title bar — the log viewer icon (terminal)
# is rendered by PhosphorIconsBold.terminal — check for tappable elements at top
TREE=$(run_iez $IEZ ui tree --compact)
TOP_ELEMENTS=$(echo "$TREE" | jq '[.data.elements[] | select(.frame != null)] | length' 2>/dev/null)
if [ "${TOP_ELEMENTS:-0}" -gt 2 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m UI tree has interactive elements (%s found)\n' "$TOP_ELEMENTS"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m UI tree too sparse (%s elements)\n' "${TOP_ELEMENTS:-0}"
fi

# The connection status is shown as a colored dot (green/amber/red).
# We can't directly read the dot color via AX, but we can verify
# the app didn't crash and the input field is responsive.
R=$(run_iez $IEZ ui exists --label "Message…")
assert_ok "$R" "Input field accessible after launch"

screenshot "02_connection_state"

# ═════════════════════════════════════════════════════════════════════
# FLOW 2: Send a Message & Verify Response
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 2: Send Message & Verify Response ━━━"

# Type a test message into the input field
R=$(run_iez $IEZ ui type "hello" --label "Message…")
assert_ok "$R" "Type test message into input"

screenshot "03_typed_message"

# Check for send button — Overlord uses a GestureDetector with an arrow icon
# The send button appears when there's text in the input. It's a CircleAvatar
# with PhosphorIconsBold.arrowUp. AX may show it as a generic button.
# We look for tappable elements near the input area.
sleep 0.3

# Try to find and tap the send button
# In Overlord, send is a GestureDetector wrapping an icon — it may not have an AX label
# We'll tap by coordinates (send button is bottom-right of input bar)
# Typical iPhone 16 Pro: input bar at bottom, send button ~right side
R=$(run_iez $IEZ ui tap --coords "370,810")
assert_ok "$R" "Tap send button area"

# Wait for a response — the agent should reply, creating message bubbles
# Overlord shows a TypingIndicator while waiting, then MessageBubble for response
sleep 3

screenshot "04_after_send"

# Check if any new content appeared (message bubbles)
TREE_AFTER=$(run_iez $IEZ ui tree --compact)
ELEMENT_COUNT=$(echo "$TREE_AFTER" | jq '[.data.elements[]] | length' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "${ELEMENT_COUNT:-0}" -gt 3 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Chat has content after send (%s elements)\n' "$ELEMENT_COUNT"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Chat appears empty after send (%s elements)\n' "${ELEMENT_COUNT:-0}"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 3: Expand/Collapse Tool Call Card
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 3: Expand/Collapse Tool Call Card ━━━"

# Tool call cards are rendered by ToolCallCard — they have a header row
# with the tool name (e.g. "exec", "read") that's tappable to expand.
# If the agent response included tool calls, we should see them.
# Look for any tool-call-like labels in the tree.

TOOL_LABELS=("exec" "read" "edit" "write" "web_search" "web_fetch")
FOUND_TOOL=""
for tool in "${TOOL_LABELS[@]}"; do
  if tree_contains "$tool"; then
    FOUND_TOOL="$tool"
    break
  fi
done

if [ -n "$FOUND_TOOL" ]; then
  # Tap to expand
  R=$(run_iez $IEZ ui tap --label "$FOUND_TOOL")
  assert_ok "$R" "Tap tool card '$FOUND_TOOL' to expand"
  sleep 0.3

  screenshot "05_tool_expanded"

  # Tap again to collapse
  R=$(run_iez $IEZ ui tap --label "$FOUND_TOOL")
  assert_ok "$R" "Tap tool card '$FOUND_TOOL' to collapse"
  sleep 0.2

  screenshot "06_tool_collapsed"
else
  # No tool call cards visible — this is normal if the agent didn't use tools
  skip_test "Expand tool card" "no tool call cards in current response"
  skip_test "Collapse tool card" "no tool call cards in current response"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 4: Open Model Selection Bottom Sheet
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 4: Model Selection Bottom Sheet ━━━"

# The model menu is triggered by tapping the connection dot (top-left circle).
# TitleBar renders it as a GestureDetector wrapping a 32x32 ClipOval at left.
# On iPhone 16 Pro, the safe area top is ~59px, so the dot is roughly at (33, 77).
R=$(run_iez $IEZ ui tap --coords "33,77")
assert_ok "$R" "Tap connection dot (model menu trigger)"

sleep 0.8

screenshot "07_model_sheet"

# The _ModelMenuSheet should now be visible with "Models" title
R=$(run_iez $IEZ ui wait --label "Models" --timeout 5)
assert_ok "$R" "Model sheet visible — 'Models' title found"

# Check for model selector cards
TOTAL=$((TOTAL + 1))
if tree_contains "Main session model"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Main session model selector visible\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Main session model selector not found\n'
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Sub-agent model"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Sub-agent model selector visible\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Sub-agent model selector not found\n'
fi

screenshot "08_model_sheet_detail"

# Dismiss the sheet by tapping outside (above the sheet) or swiping down
R=$(run_iez $IEZ ui swipe down)
assert_ok "$R" "Dismiss model sheet (swipe down)"

sleep 0.3

# Verify sheet dismissed — "Models" should no longer be visible
TOTAL=$((TOTAL + 1))
if ! tree_contains "Models"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Model sheet dismissed\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Model sheet still visible after dismiss\n'
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 5: Scroll Up/Down in Chat
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 5: Chat Scroll (Up/Down) ━━━"

# Overlord's chat is a ListView inside a CustomScrollView.
# We use swipe gestures (not scroll — Flutter ignores AXe scroll presets).

# First, ensure we have enough content to scroll (send another message if needed)
R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Swipe up (scroll down in chat)"

sleep 0.3
screenshot "09_scrolled_down"

R=$(run_iez $IEZ ui swipe down)
assert_ok "$R" "Swipe down (scroll up in chat)"

sleep 0.3
screenshot "10_scrolled_up"

# Check scroll indicators — Overlord shows floating scroll buttons
# _showScrollToBottom and _showScrollToTop are conditional
# We can verify the UI didn't crash after scrolling
R=$(run_iez $IEZ ui exists --label "Message…")
assert_ok "$R" "Input field still accessible after scrolling"

# ═════════════════════════════════════════════════════════════════════
# FLOW 6: View Sub-Agent Overlay
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 6: Sub-Agent Overlay ━━━"

# Sub-agent overlays appear when the agent spawns sub-agents. The overlay
# is triggered via showAgentOverlay() in chat_screen.dart. It's shown
# when tapping on a SessionEventCard or specific agent stream items.
#
# If there are active/completed sub-agents, there will be:
# - An _AgentBadge in the TitleBar (robot icon + count)
# - Tappable session event cards in the chat
#
# Check for agent badge in title bar area
TREE=$(run_iez $IEZ ui tree --compact)

# Look for sub-agent related labels
HAS_AGENT_BADGE=$(echo "$TREE" | jq '[.data.elements[] | select(.label != null) | select(.label | test("agent|sub-agent|Sub-agent"; "i"))] | length' 2>/dev/null)

if [ "${HAS_AGENT_BADGE:-0}" -gt 0 ]; then
  # Try to tap the agent badge to open overlay
  R=$(run_iez $IEZ ui tap --label "Sub-agent")
  assert_ok "$R" "Tap sub-agent card to open overlay"
  sleep 0.5

  screenshot "11_agent_overlay"

  # Check overlay content
  TOTAL=$((TOTAL + 1))
  if tree_contains "Sub-agent"; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Sub-agent overlay visible\n'
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Sub-agent overlay content not found\n'
  fi

  # Dismiss overlay
  R=$(run_iez $IEZ ui swipe down)
  assert_ok "$R" "Dismiss agent overlay"
else
  # No active sub-agents — test the agent badge area (top-right)
  # The badge is only shown when agentCount > 0
  skip_test "Open sub-agent overlay" "no active sub-agents in current session"
  skip_test "Verify overlay content" "no active sub-agents in current session"
  skip_test "Dismiss agent overlay" "no active sub-agents in current session"

  # Still verify the badge area doesn't crash when tapped
  # Agent badge position is top-right, roughly at (350, 77) on iPhone 16 Pro
  R=$(run_iez $IEZ ui tap --coords "350,77")
  assert_ok "$R" "Tap log viewer button (top-right, no agent badge)"
  sleep 0.5

  screenshot "11_log_viewer"

  # If we opened the log viewer, go back
  R=$(run_iez $IEZ ui key "escape")
  # Don't assert — escape may not work if no navigation happened
  sleep 0.3
fi

# ═════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════╗"
printf "║  Results: \033[1;32m%d passed\033[0m / \033[1;31m%d failed\033[0m / \033[1;33m%d skipped\033[0m / %d total  ║\n" "$PASS" "$FAIL" "$SKIP" "$TOTAL"
echo "╚══════════════════════════════════════════════════╝"
echo "Screenshots: $SCREENSHOTS/"

exit $FAIL
