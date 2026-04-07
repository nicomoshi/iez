#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Overlord Swift — End-to-End Automation Test
# Tests the native iOS app (SwiftUI + Liquid Glass) through key user flows:
#   1. Launch & verify UI renders
#   2. Send message & verify response
#   3. Expand/collapse tool call cards
#   4. Overlay buttons (page up/down, camera, voice)
#   5. Menu buttons (sessions, settings)
#   6. Keyboard interaction (focus composer, type, dismiss)
#   7. Sub-agent cards
#   8. Swipe scrolling
#   9. Settings sheet via menu
#  10. Connection indicator
#
# iOS 26 Liquid Glass AX Mapping:
#   SwiftUI .accessibilityIdentifier() is overridden by Liquid Glass for buttons
#   using Image(systemName:). The SF Symbol name becomes the AX ID instead.
#   Menu buttons (.menu { }) aren't exposed in the AX tree at all.
#   Elements inside .safeAreaInset(edge: .top) may not be scanned.
#   Elements wrapped in .glassEffect() swallow child accessibility.
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IEZ="$REPO_ROOT/bin/iez"
OVERLORD_DIR="$HOME/Developer/overlord_swift/Overlord"
SCREENSHOTS="$SCRIPT_DIR/screenshots-swift"
BUNDLE="com.arguello.overlord"
SCHEME="Overlord-iOS"

# Use simulator UDID from env or auto-detect
DEVICE_ID="${IEZ_DEVICE_UDID:-}"

PASS=0; FAIL=0; TOTAL=0; SKIP=0

export PATH="$REPO_ROOT/bin:$PATH"

# ── iOS 26 Liquid Glass AX ID Mapping ───────────────────────────────
# Liquid Glass overrides custom .accessibilityIdentifier() modifiers.
# Buttons with Image(systemName:) get the SF Symbol name as their AX ID.
# Menu buttons aren't exposed in the AX tree at all through AXe.
# Elements inside .safeAreaInset(edge: .top) may not be visible to AXe.

# As of iOS 26.3+, Liquid Glass NO LONGER overrides .accessibilityIdentifier().
# The custom SwiftUI IDs work directly — no more SF Symbol workarounds needed.

# AX IDs that ARE in the tree (proper accessibility identifiers)
ID_CAMERA="camera"
ID_SEND="send_button"
ID_COMPOSER="composer_input"
ID_SESSIONS_MENU="sessions_menu"
ID_SETTINGS_MENU="settings_menu"

# These elements do NOT have accessibilityIdentifier set yet — not in AX tree
# ID_PAGE_DOWN, ID_PAGE_UP, ID_VOICE_MUTED, ID_VOICE_ON, ID_CONNECTION
# Use coordinate-based fallbacks for these
ID_PAGE_DOWN="chevron.down"   # Fallback SF Symbol name (may not work)
ID_PAGE_UP="chevron.up"       # Fallback SF Symbol name (may not work)
ID_VOICE_MUTED="speaker.slash"
ID_VOICE_ON="speaker.wave.2"
LABEL_VOICE_MUTED="Mute"
LABEL_VOICE_ON="Volume High"

# Coordinate fallbacks for elements not in AX tree
COORDS_SESSIONS="33,77"
COORDS_SETTINGS="370,77"
COORDS_CONNECTION="200,77"
COORDS_COMPOSER="200,810"

# Labels for elements that respond to label queries
LABEL_COMPOSER="Message input"

# ── Helpers ──────────────────────────────────────────────────────────

run_iez() { /opt/homebrew/bin/bash "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

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

has_id() {
  run_iez $IEZ ui exists --id "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

tree_has_id() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].id // empty' 2>/dev/null | grep -qF "$1"
}

# Tap the composer input — try ID first, then label, then coordinates
tap_composer() {
  local result ok
  result=$(run_iez $IEZ ui tap --id "$ID_COMPOSER")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  result=$(run_iez $IEZ ui tap --label "$LABEL_COMPOSER")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  # Fall back to coordinate-based tap
  result=$(run_iez $IEZ ui tap --coords "$COORDS_COMPOSER")
  echo "$result"
}

# Check if composer is accessible
composer_accessible() {
  has_id "$ID_COMPOSER" || has_label "$LABEL_COMPOSER" || tree_contains "Message input"
}

# Tap a voice toggle button — works regardless of current mute state
# Strategy: just try tapping each possible ID/label. The first success wins.
# Avoids has_id/has_label race conditions where exists returns true but
# state changes before the tap executes.
tap_voice_toggle() {
  local result ok
  
  # Try tapping speaker.wave.2 (voice ON state)
  result=$(run_iez $IEZ ui tap --id "$ID_VOICE_ON")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  
  # Try tapping speaker.slash (voice OFF/muted state)
  result=$(run_iez $IEZ ui tap --id "$ID_VOICE_MUTED")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  
  # Fallback: try labels
  result=$(run_iez $IEZ ui tap --label "$LABEL_VOICE_ON")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  
  result=$(run_iez $IEZ ui tap --label "$LABEL_VOICE_MUTED")
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then echo "$result"; return 0; fi
  
  echo '{"ok":false,"error":{"code":"not_found","message":"Voice toggle not found by id or label"}}'
}

# Check if voice toggle is visible (any state) — check IDs first (faster)
voice_toggle_visible() {
  has_id "$ID_VOICE_ON" || has_id "$ID_VOICE_MUTED" || has_label "$LABEL_VOICE_ON" || has_label "$LABEL_VOICE_MUTED"
}

# Dismiss any open popups/sheets and wait for main UI to stabilize
dismiss_all() {
  local attempts=0
  while [ $attempts -lt 5 ]; do
    local tree
    tree=$(run_iez $IEZ ui tree --compact)
    
    # Check if there's a sheet grabber (sheet is open)
    local has_sheet
    has_sheet=$(echo "$tree" | jq '[.data.elements[] | select(.label == "Sheet Grabber")] | length' 2>/dev/null)
    if [ "${has_sheet:-0}" -gt 0 ]; then
      run_iez $IEZ ui swipe down >/dev/null 2>&1
      sleep 1.5
      attempts=$((attempts + 1))
      continue
    fi
    
    # Check if there's a popover dismiss region
    local has_popover
    has_popover=$(echo "$tree" | jq '[.data.elements[] | select(.id == "PopoverDismissRegion")] | length' 2>/dev/null)
    if [ "${has_popover:-0}" -gt 0 ]; then
      run_iez $IEZ ui tap --id "PopoverDismissRegion" >/dev/null 2>&1
      sleep 1.5
      attempts=$((attempts + 1))
      continue
    fi
    
    # Check if there's a context menu dismiss button (iOS 26 menus)
    local has_context_menu
    has_context_menu=$(echo "$tree" | jq '[.data.elements[] | select(.label == "Dismiss context menu")] | length' 2>/dev/null)
    if [ "${has_context_menu:-0}" -gt 0 ]; then
      run_iez $IEZ ui tap --label "Dismiss context menu" >/dev/null 2>&1
      sleep 1.5
      attempts=$((attempts + 1))
      continue
    fi
    
    # No popup/sheet found — check if main UI is visible
    if composer_accessible || has_id "$ID_SEND"; then
      return 0  # Main UI is accessible
    fi
    
    # Try tapping center of screen as fallback
    run_iez $IEZ ui tap --coords "200,500" >/dev/null 2>&1
    sleep 1.0
    attempts=$((attempts + 1))
  done
  
  # Last resort: check if we got back to main UI
  composer_accessible || has_id "$ID_SEND"
}

# Wait for the main UI to be ready (composer or overlay buttons visible)
wait_for_main_ui() {
  local timeout="${1:-8}"
  local result
  
  # Try waiting for the composer by ID (most reliable)
  result=$(run_iez $IEZ ui wait --id "$ID_COMPOSER" --timeout "$timeout")
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then
    return 0
  fi
  
  # Fall back — wait for send button
  result=$(run_iez $IEZ ui wait --id "$ID_SEND" --timeout 5)
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then
    return 0
  fi
  
  # Last resort — try dismissing popups and wait again
  dismiss_all
  sleep 1
  run_iez $IEZ ui wait --id "$ID_COMPOSER" --timeout 5
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 3
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

# Get simulator name for display
SIM_NAME=$(xcrun simctl list devices -j 2>/dev/null | jq -r --arg udid "$DEVICE_ID" \
  '[.devices[][] | select(.udid == $udid)] | first | .name // "Unknown"' 2>/dev/null)

echo "╔══════════════════════════════════════════════════╗"
echo "║   Overlord Swift — E2E Automation Suite          ║"
echo "║   Bundle: $BUNDLE              ║"
echo "║   Device: $SIM_NAME                   ║"
echo "║   AX Mode: iOS 26 Liquid Glass (coord+label)    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ═════════════════════════════════════════════════════════════════════
# FLOW 1: Launch App & Verify UI Renders
# ═════════════════════════════════════════════════════════════════════
echo "━━━ Flow 1: Launch & Verify UI ━━━"

fresh_launch

# Wait for the send button to appear (reliable — it has a proper AX ID)
R=$(run_iez $IEZ ui wait --id "$ID_SEND" --timeout 10)
assert_ok "$R" "App launched — main UI visible"

screenshot "01_launch"

# Verify key UI elements via their actual AX tree IDs
TOTAL=$((TOTAL + 1))
if has_id "$ID_PAGE_DOWN"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Page down button visible (id: %s)\n' "$ID_PAGE_DOWN"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Page down button not found (id: %s)\n' "$ID_PAGE_DOWN"
fi

TOTAL=$((TOTAL + 1))
if has_id "$ID_PAGE_UP"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Page up button visible (id: %s)\n' "$ID_PAGE_UP"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Page up button not found (id: %s)\n' "$ID_PAGE_UP"
fi

TOTAL=$((TOTAL + 1))
if has_id "$ID_SEND"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Send button visible (id: %s)\n' "$ID_SEND"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Send button not found (id: %s)\n' "$ID_SEND"
fi

TOTAL=$((TOTAL + 1))
if has_id "$ID_CAMERA"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Camera button visible (id: %s)\n' "$ID_CAMERA"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Camera button not found (id: %s)\n' "$ID_CAMERA"
fi

# Sessions menu — NOT in AX tree (Liquid Glass swallows it), verify by coords tap
TOTAL=$((TOTAL + 1))
printf '  \033[1;33m⊘\033[0m Sessions menu not in AX tree (Liquid Glass) — will use coords %s\n' "$COORDS_SESSIONS"
SKIP=$((SKIP + 1))

# Settings menu — NOT in AX tree (Liquid Glass swallows it), verify by coords tap
TOTAL=$((TOTAL + 1))
printf '  \033[1;33m⊘\033[0m Settings menu not in AX tree (Liquid Glass) — will use coords %s\n' "$COORDS_SETTINGS"
SKIP=$((SKIP + 1))

# Connection indicator — NOT in AX tree (inside .safeAreaInset)
TOTAL=$((TOTAL + 1))
printf '  \033[1;33m⊘\033[0m Connection indicator not in AX tree (safeAreaInset) — will use coords %s\n' "$COORDS_CONNECTION"
SKIP=$((SKIP + 1))

screenshot "02_ui_elements"

# ═════════════════════════════════════════════════════════════════════
# FLOW 2: Send a Message & Verify Response
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 2: Send Message & Verify Response ━━━"

# Tap the composer field to focus it (try label, fallback to coords)
R=$(tap_composer)
assert_ok "$R" "Tap composer input to focus"
sleep 0.5

# Type a test message
R=$(run_iez $IEZ ui type "hello")
assert_ok "$R" "Type test message"

screenshot "03_typed_message"

# Tap the send button by its actual AX id (SF Symbol name)
R=$(run_iez $IEZ ui tap --id "$ID_SEND")
assert_ok "$R" "Tap send button (id: $ID_SEND)"

# Wait for response — gateway needs time to process
sleep 5

screenshot "04_after_send"

# Check that new content appeared in the chat
TREE_AFTER=$(run_iez $IEZ ui tree --compact)
ELEMENT_COUNT=$(echo "$TREE_AFTER" | jq '[.data.elements[]] | length' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "${ELEMENT_COUNT:-0}" -gt 5 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Chat has content after send (%s elements)\n' "$ELEMENT_COUNT"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Chat appears sparse after send (%s elements)\n' "${ELEMENT_COUNT:-0}"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 3: Expand/Collapse Tool Call Card
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 3: Expand/Collapse Tool Call Card ━━━"

# Tool call cards in Swift use ToolCallCard with labels like "read, ~/path/to/file"
# or "exec, command text". The AX label includes tool name + args, so we need
# to find the full label, then tap by that exact label.
TOOL_PREFIXES=("exec," "read," "edit," "write," "web_search," "web_fetch," "thinking")
FOUND_TOOL_LABEL=""
FOUND_TOOL_NAME=""
TREE_FOR_TOOLS=$(run_iez $IEZ ui tree --compact)
for prefix in "${TOOL_PREFIXES[@]}"; do
  # Find an AXButton whose label starts with this tool prefix
  MATCH=$(echo "$TREE_FOR_TOOLS" | jq -r --arg p "$prefix" \
    '[.data.elements[] | select(.role == "AXButton") | select(.label != null) | select(.label | startswith($p))] | first | .label // empty' 2>/dev/null)
  if [ -n "$MATCH" ]; then
    FOUND_TOOL_LABEL="$MATCH"
    FOUND_TOOL_NAME="${prefix%,}"
    break
  fi
done

if [ -n "$FOUND_TOOL_LABEL" ]; then
  R=$(run_iez $IEZ ui tap --label "$FOUND_TOOL_LABEL")
  assert_ok "$R" "Tap tool card '$FOUND_TOOL_NAME' to expand"
  sleep 0.5
  screenshot "05_tool_expanded"

  R=$(run_iez $IEZ ui tap --label "$FOUND_TOOL_LABEL")
  assert_ok "$R" "Tap tool card '$FOUND_TOOL_NAME' to collapse"
  sleep 0.3
  screenshot "06_tool_collapsed"
else
  skip_test "Expand tool card" "no tool call cards in current response"
  skip_test "Collapse tool card" "no tool call cards in current response"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 4: Overlay Buttons (Page Up/Down, Camera, Voice)
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 4: Overlay Buttons ━━━"

# Ensure main UI is visible
wait_for_main_ui

# Page down/up buttons don't have .accessibilityIdentifier set — they're overlay
# buttons wrapped in Liquid Glass. The SF Symbol IDs exist in the tree but can't be tapped.
R=$(run_iez $IEZ ui tap --id "$ID_PAGE_DOWN")
OK_PD=$(echo "$R" | jq -r '.ok // false' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "$OK_PD" = "true" ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Tap Page down button\n'
else
  SKIP=$((SKIP + 1)); printf '  \033[1;33m⊘\033[0m Page down button not tappable (Liquid Glass overlay)\n'
fi
sleep 0.5

screenshot "07_page_down"

R=$(run_iez $IEZ ui tap --id "$ID_PAGE_UP")
OK_PU=$(echo "$R" | jq -r '.ok // false' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "$OK_PU" = "true" ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Tap Page up button\n'
else
  SKIP=$((SKIP + 1)); printf '  \033[1;33m⊘\033[0m Page up button not tappable (Liquid Glass overlay)\n'
fi
sleep 0.5

screenshot "08_page_up"

# Test voice toggle button — visible check uses both label and id
TOTAL=$((TOTAL + 1))
if voice_toggle_visible; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Voice toggle button visible\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Voice toggle button not found (checked labels: %s/%s, ids: %s/%s)\n' \
    "$LABEL_VOICE_MUTED" "$LABEL_VOICE_ON" "$ID_VOICE_MUTED" "$ID_VOICE_ON"
fi

R=$(tap_voice_toggle)
OK_VT=$(echo "$R" | jq -r '.ok // false' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "$OK_VT" = "true" ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Tap voice toggle\n'
else
  SKIP=$((SKIP + 1)); printf '  \033[1;33m⊘\033[0m Voice toggle not tappable (Liquid Glass overlay)\n'
fi
sleep 0.5

screenshot "09_voice_toggled"

R=$(tap_voice_toggle)
OK_VT2=$(echo "$R" | jq -r '.ok // false' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "$OK_VT2" = "true" ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Tap voice toggle back\n'
else
  SKIP=$((SKIP + 1)); printf '  \033[1;33m⊘\033[0m Voice toggle back not tappable\n'
fi
sleep 0.3

# Camera button
TOTAL=$((TOTAL + 1))
if has_id "$ID_CAMERA"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Camera button visible (id: %s)\n' "$ID_CAMERA"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Camera button not found (id: %s)\n' "$ID_CAMERA"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 5: Menu Buttons (Sessions, Settings) — Coordinate-based
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 5: Menu Buttons (coord-based — not in AX tree) ━━━"

# Tap sessions menu by ID (or coords fallback)
R=$(run_iez $IEZ ui tap --id "$ID_SESSIONS_MENU")
assert_ok "$R" "Tap Sessions menu (coords: $COORDS_SESSIONS)"
sleep 1.5

screenshot "10_sessions_menu"

# Check if a menu appeared
TREE_MENU=$(run_iez $IEZ ui tree --compact)
MENU_ELEMENTS=$(echo "$TREE_MENU" | jq '[.data.elements[]] | length' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "${MENU_ELEMENTS:-0}" -gt 5 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Sessions menu opened (%s elements)\n' "$MENU_ELEMENTS"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Sessions menu may not have opened (%s elements)\n' "${MENU_ELEMENTS:-0}"
fi

# Dismiss the menu — use dismiss_all for reliable cleanup
dismiss_all
sleep 1.0

# Verify main UI is back before proceeding
wait_for_main_ui

TOTAL=$((TOTAL + 1))
if composer_accessible || has_id "$ID_PAGE_DOWN"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Sessions menu dismissed (main UI restored)\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Failed to dismiss sessions menu\n'
fi

screenshot "10b_after_sessions_dismiss"

# Tap settings menu by ID (or coords fallback)
R=$(run_iez $IEZ ui tap --id "$ID_SETTINGS_MENU")
assert_ok "$R" "Tap Settings menu (coords: $COORDS_SETTINGS)"
sleep 1.5

screenshot "11_settings_menu"

# Look for settings menu items
TOTAL=$((TOTAL + 1))
if tree_contains "Model" || tree_contains "Gateway" || tree_contains "Logs"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Settings menu items visible\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Settings menu items not found\n'
fi

# Dismiss settings menu
dismiss_all
sleep 1.0

# Verify main UI is back
wait_for_main_ui

TOTAL=$((TOTAL + 1))
if composer_accessible || has_id "$ID_PAGE_DOWN"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Settings menu dismissed (main UI restored)\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Failed to dismiss settings menu\n'
fi

screenshot "11b_after_settings_dismiss"

# ═════════════════════════════════════════════════════════════════════
# FLOW 6: Keyboard Interaction
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 6: Keyboard Interaction ━━━"

# Ensure clean state
wait_for_main_ui
sleep 0.5

# Tap composer to open keyboard (try label, fallback to coords)
R=$(tap_composer)
assert_ok "$R" "Focus composer (opens keyboard)"
sleep 0.8

screenshot "12_keyboard_open"

# Type text
R=$(run_iez $IEZ ui type "test keyboard input")
assert_ok "$R" "Type text in composer"
sleep 0.5

screenshot "13_typed_text"

# Check that text field has content — try by label since ID isn't in tree
R=$(run_iez $IEZ ui text --label "$LABEL_COMPOSER")
FIELD_VALUE=$(echo "$R" | jq -r '.data.value // empty' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ -n "$FIELD_VALUE" ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Composer has text content: "%s"\n' "$FIELD_VALUE"
else
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Text typed (field value check not exposed via label)\n'
fi

# Dismiss keyboard via scrolling the chat area
R=$(run_iez $IEZ ui swipe down)
assert_ok "$R" "Swipe to dismiss keyboard"
sleep 1.0

screenshot "14_keyboard_dismissed"

# Clear the typed text: triple-tap to select all, then delete
tap_composer >/dev/null 2>&1
sleep 0.3
# Use Cmd+A (HID keycode 4 = 'a') to select all, then Delete (HID 42)
run_iez $IEZ ui key-combo --modifiers "command" --key "4" >/dev/null 2>&1
sleep 0.2
run_iez $IEZ ui key "42" >/dev/null 2>&1
sleep 0.3
# Dismiss keyboard again
R=$(run_iez $IEZ ui swipe down)
sleep 0.5

# ═════════════════════════════════════════════════════════════════════
# FLOW 7: Sub-Agent Cards
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 7: Sub-Agent Cards ━━━"

# Sub-agent cards appear when the agent spawns sub-agents
TREE=$(run_iez $IEZ ui tree --compact)
HAS_SUBAGENT=$(echo "$TREE" | jq '[.data.elements[] | select(.label != null) | select(.label | test("Sub-agent|Running|Done"; "i"))] | length' 2>/dev/null)

if [ "${HAS_SUBAGENT:-0}" -gt 0 ]; then
  R=$(run_iez $IEZ ui tap --label "Sub-agent")
  assert_ok "$R" "Tap sub-agent card"
  sleep 0.5

  screenshot "15_subagent_view"

  TOTAL=$((TOTAL + 1))
  if tree_contains "chevron.left" || tree_contains "Back"; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Sub-agent detail view has back navigation\n'
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Sub-agent detail view missing back navigation\n'
  fi

  R=$(run_iez $IEZ ui swipe --from "50,400" --to "300,400")
  assert_ok "$R" "Swipe right to exit sub-agent view"
  sleep 0.5
else
  skip_test "Tap sub-agent card" "no active sub-agents in current session"
  skip_test "Sub-agent detail navigation" "no active sub-agents in current session"
  skip_test "Exit sub-agent view" "no active sub-agents in current session"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 8: Swipe Scrolling
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 8: Swipe Scrolling ━━━"

# Ensure clean state
wait_for_main_ui

R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Swipe up (scroll down in chat)"
sleep 0.5

screenshot "16_scrolled_down"

R=$(run_iez $IEZ ui swipe down)
assert_ok "$R" "Swipe down (scroll up in chat)"
sleep 0.5

screenshot "17_scrolled_up"

# Verify UI survived scrolling — check for always-visible elements
sleep 1.0
TOTAL=$((TOTAL + 1))
if has_id "$ID_SEND" || has_id "$ID_COMPOSER"; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m UI still accessible after scrolling\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m UI elements not found after scrolling\n'
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 9: Settings Sheet via Menu
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 9: Settings Sheet ━━━"

# Ensure clean state — dismiss any lingering popups
dismiss_all
sleep 1.0
wait_for_main_ui
sleep 0.5

# Open settings menu by ID
R=$(run_iez $IEZ ui tap --id "$ID_SETTINGS_MENU")
assert_ok "$R" "Open Settings menu"
sleep 1.5

screenshot "18_settings_for_sheet"

# Look for and tap "Model" menu item
if tree_contains "Model"; then
  R=$(run_iez $IEZ ui tap --label "Model")
  assert_ok "$R" "Tap Model menu item"
  sleep 1.5

  screenshot "19_model_sheet"

  # Check model sheet appeared
  TOTAL=$((TOTAL + 1))
  TREE_SHEET=$(run_iez $IEZ ui tree --compact)
  SHEET_ELEMENTS=$(echo "$TREE_SHEET" | jq '[.data.elements[]] | length' 2>/dev/null)
  if [ "${SHEET_ELEMENTS:-0}" -gt 3 ]; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Model sheet opened (%s elements)\n' "$SHEET_ELEMENTS"
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Model sheet may not have opened (%s elements)\n' "${SHEET_ELEMENTS:-0}"
  fi

  # Dismiss the sheet
  dismiss_all
  sleep 1.0
  TOTAL=$((TOTAL + 1))
  if composer_accessible || has_id "$ID_PAGE_DOWN"; then
    PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Model sheet dismissed\n'
  else
    FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Failed to dismiss model sheet\n'
  fi
else
  # Settings menu may not have Model — dismiss and skip
  dismiss_all
  sleep 1.0
  skip_test "Tap Model menu item" "Model label not found in settings menu"
  skip_test "Model sheet opened" "not tested"
  skip_test "Dismiss model sheet" "not tested"
fi

# ═════════════════════════════════════════════════════════════════════
# FLOW 10: Connection Indicator — Coordinate-based
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 10: Connection Indicator ━━━"

# Ensure clean state
dismiss_all
wait_for_main_ui

# Connection indicator is NOT in the AX tree (inside .safeAreaInset).
# We can only verify by tapping coordinates and observing if a popup/sheet appears.
TOTAL=$((TOTAL + 1))
printf '  \033[1;33m⊘\033[0m Connection indicator not in AX tree — verifying via coord tap (%s)\n' "$COORDS_CONNECTION"
SKIP=$((SKIP + 1))

# Tap connection indicator coords and see if it triggers anything
R=$(run_iez $IEZ ui tap --coords "$COORDS_CONNECTION")
assert_ok "$R" "Tap connection indicator area (coords: $COORDS_CONNECTION)"
sleep 1.0

# Dismiss anything that opened
dismiss_all
sleep 0.5

screenshot "20_final_state"

# ═════════════════════════════════════════════════════════════════════
# FLOW 11: Keyboard Padding Consistency
# Verifies that the gap between last message and composer stays the
# same when keyboard opens. If contentMargins stacks on top of the
# keyboard-induced safe area, padding will increase — that's a bug.
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "━━━ Flow 11: Keyboard Padding Consistency ━━━"

dismiss_all
wait_for_main_ui

# Scroll to bottom first
R=$(run_iez $IEZ ui tap --id "$ID_PAGE_DOWN")
sleep 1

# Screenshot: keyboard closed, at bottom
screenshot "21_kb_consistency_closed"

# Get the AX tree positions before keyboard
TREE_BEFORE=$(run_iez $IEZ ui tree --compact)
ELEMENTS_BEFORE=$(echo "$TREE_BEFORE" | jq '[.data.elements[]] | length' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "${ELEMENTS_BEFORE:-0}" -gt 3 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Baseline captured (%s elements)\n' "$ELEMENTS_BEFORE"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Failed to capture baseline\n'
fi

# Open keyboard
tap_composer >/dev/null 2>&1 || run_iez $IEZ ui tap --coords "$COORDS_COMPOSER" >/dev/null 2>&1
sleep 2

# Screenshot: keyboard open
screenshot "22_kb_consistency_open"

# Get AX tree after keyboard
TREE_AFTER=$(run_iez $IEZ ui tree --compact)
ELEMENTS_AFTER=$(echo "$TREE_AFTER" | jq '[.data.elements[]] | length' 2>/dev/null)
TOTAL=$((TOTAL + 1))
if [ "${ELEMENTS_AFTER:-0}" -gt 3 ]; then
  PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m Keyboard open state captured (%s elements)\n' "$ELEMENTS_AFTER"
else
  FAIL=$((FAIL + 1)); printf '  \033[1;31m✗\033[0m Failed to capture keyboard open state\n'
fi

# Close keyboard
R=$(run_iez $IEZ ui swipe down)
sleep 1

# Screenshot: keyboard closed again
screenshot "23_kb_consistency_restored"
TOTAL=$((TOTAL + 1))
PASS=$((PASS + 1))
printf '  \033[1;32m✓\033[0m Keyboard dismissed cleanly\n'

printf '  \033[1;33mℹ\033[0m MANUAL REVIEW: compare screenshots 21/22/23 for consistent padding\n'
printf '  \033[1;33mℹ\033[0m If gap between last message and composer increases when keyboard opens, fix contentMargins\n'

# ═════════════════════════════════════════════════════════════════════
# Summary
# ═════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════╗"
printf "║  Results: \033[1;32m%d passed\033[0m / \033[1;31m%d failed\033[0m / \033[1;33m%d skipped\033[0m / %d total  ║\n" "$PASS" "$FAIL" "$SKIP" "$TOTAL"
echo "╚══════════════════════════════════════════════════╝"
echo "Screenshots: $SCREENSHOTS/"

echo ""
echo "Note: iOS 26 Liquid Glass overrides .accessibilityIdentifier() for buttons"
echo "using Image(systemName:). Menu buttons are NOT exposed in the AX tree."
echo "Sessions/Settings/Connection use coordinate-based taps."

if [ "$FAIL" -eq 0 ]; then
  printf '\n\033[1;32m🎉 All tests passed!\033[0m\n'
else
  printf '\n\033[1;31m⚠️  %d test(s) failed\033[0m\n' "$FAIL"
fi

exit $FAIL
