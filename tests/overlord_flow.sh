#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# iez Overlord Flutter — End-to-End UI Flow Test
# Exercises: launch, chat, tool call cards, model sheet, scroll, nav
# ──────────────────────────────────────────────────────────────────────
# Optimized for speed: minimal sleeps, batched assertions, cached trees
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IEZ="$REPO_ROOT/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
BUNDLE="com.arguello.overlordFlutter"
OVERLORD_DIR="$HOME/Developer/overlord_flutter"
SCREENSHOTS="$SCRIPT_DIR/overlord_screenshots"
PASS=0; FAIL=0; TOTAL=0
START_TIME=$(date +%s)

# ── Helpers (optimized — single jq parse, no redundant pipes) ────────

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p' || true; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  if echo "$result" | jq -e '.ok == true' &>/dev/null; then
    PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$desc"
  else
    FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m %s\n' "$desc"
  fi
}

# Cached tree — avoids re-fetching for multiple assertions on same screen
TREE_JSON=""
TREE_LABELS=""

refresh_tree() {
  TREE_JSON=$(run_iez "$IEZ" ui tree --compact)
  TREE_LABELS=$(echo "$TREE_JSON" | jq -r '.data.elements[].label // empty' 2>/dev/null || true)
}

tree_has() { echo "$TREE_LABELS" | grep -qF -- "$1" 2>/dev/null; }

assert_tree_has() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if tree_has "$substr"; then
    PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$desc"
  else
    FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m %s (\047%s\047 not in tree)\n' "$desc" "$substr"
  fi
}

assert_tree_missing() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if ! tree_has "$substr"; then
    PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m %s\n' "$desc"
  else
    FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m %s (\047%s\047 still in tree)\n' "$desc" "$substr"
  fi
}

# Get element center coords from cached tree
elem_coords() {
  echo "$TREE_JSON" | jq -r --arg lbl "$1" \
    '.data.elements[] | select(.label | test($lbl)) | "\(.frame.x + .frame.width/2 | floor),\(.frame.y + .frame.height/2 | floor)"' \
    2>/dev/null | head -1
}

tap_coords() {
  local coords="$1"
  run_iez "$IEZ" ui tap --coords "$coords"
}

screenshot() {
  run_iez "$IEZ" ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# Check if app is in foreground (from cached tree)
app_in_foreground() {
  echo "$TREE_JSON" | jq -e '.data.elements[] | select(.role=="AXApplication" and (.label | test("Overlord")))' &>/dev/null
}

# ── Setup ────────────────────────────────────────────────────────────

mkdir -p "$SCREENSHOTS"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Overlord Flutter — iez UI Flow Test             ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. Build & Launch ────────────────────────────────────────────────

echo "── Phase 1: Launch ──"

# Build simulator binary (skip if recent build exists)
APP_PATH="$OVERLORD_DIR/build/ios/iphonesimulator/Runner.app"
if [[ -d "$APP_PATH" ]]; then
  APP_AGE=$(( $(date +%s) - $(stat -f %m "$APP_PATH") ))
  if (( APP_AGE > 3600 )); then
    echo "  ⏳ Rebuilding (build is ${APP_AGE}s old)..."
    (cd "$OVERLORD_DIR" && flutter build ios --simulator --no-codesign 2>&1 | tail -3)
  else
    echo "  ⚡ Using existing build (${APP_AGE}s old)"
  fi
else
  echo "  ⏳ Building for simulator..."
  (cd "$OVERLORD_DIR" && flutter build ios --simulator --no-codesign 2>&1 | tail -3)
fi

# Ensure simulator is booted
BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "$DEVICE_ID" || true)
if [[ "$BOOTED" = "0" ]]; then
  R=$(run_iez "$IEZ" sim boot --udid "$DEVICE_ID")
  assert_ok "1.01 Boot simulator" "$R"
  sleep 3
else
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1))
  printf '  \033[32m✓\033[0m 1.01 Simulator already booted\n'
fi

# Terminate + reinstall + launch (clean slate)
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
sleep 0.5
xcrun simctl install "$DEVICE_ID" "$APP_PATH" 2>/dev/null
xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null

# Wait for app to settle — poll for foreground, max 10s
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  refresh_tree
  # Handle permission dialogs (speech recognition, microphone)
  if tree_has "Allow"; then
    run_iez "$IEZ" ui tap --label "Allow" >/dev/null
    sleep 1
    refresh_tree
  fi
  if app_in_foreground; then break; fi
done

assert_ok "1.02 App in foreground" "$(echo "$TREE_JSON" | jq -c '{ok: (.data.elements[] | select(.role=="AXApplication" and (.label | test("Overlord"))) | true) // false}')" 2>/dev/null || true
# Simpler check
TOTAL=$((TOTAL + 1))
if app_in_foreground; then
  PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m 1.02 Overlord in foreground\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m 1.02 Overlord NOT in foreground\n'
  echo "Tree labels: $(echo "$TREE_LABELS" | head -5)"
  # Attempt recovery
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 3
  refresh_tree
fi
# (the assert_ok above was a bad approach - undo its count)
TOTAL=$((TOTAL - 1))

screenshot "01_launch"

echo ""

# ── 2. Chat Screen Basics ───────────────────────────────────────────

echo "── Phase 2: Chat Screen ──"

refresh_tree

# The chat screen should have the message input field
assert_tree_has "2.01 Message input field" "Message…"

# Check for existing chat content (tool call cards, text blocks)
# The app connects to a real gateway so there should be existing messages
TOTAL=$((TOTAL + 1))
ELEM_COUNT=$(echo "$TREE_JSON" | jq '.data.elements | length' 2>/dev/null || echo "0")
if (( ELEM_COUNT > 5 )); then
  PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m 2.02 Chat has content (%d elements)\n' "$ELEM_COUNT"
else
  FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m 2.02 Chat content sparse (%d elements)\n' "$ELEM_COUNT"
fi

screenshot "02_chat"

echo ""

# ── 3. Scroll Up/Down ───────────────────────────────────────────────

echo "── Phase 3: Scroll ──"

# Scroll up to see older messages
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "3.01 Swipe up" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui swipe up)
assert_ok "3.02 Swipe up again" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui swipe up)
assert_ok "3.03 Swipe up third" "$R"
sleep 0.3

refresh_tree
screenshot "03_scrolled_up"

# Scroll back down
R=$(run_iez "$IEZ" ui swipe down)
assert_ok "3.04 Swipe down" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui swipe down)
assert_ok "3.05 Swipe down again" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui swipe down)
assert_ok "3.06 Swipe down third" "$R"
sleep 0.3

refresh_tree
screenshot "03_scrolled_down"

echo ""

# ── 4. Tool Call Cards (Expand/Collapse) ─────────────────────────────

echo "── Phase 4: Tool Call Cards ──"

# Tool call cards in Overlord show exec commands, read, edit, etc.
# They appear as elements with AXStaticText containing command text,
# with caret icons. We look for typical tool-call content.

# Find a tool call card element (exec/read/edit commands in the tree)
# These appear as clickable rows with command text
TOOL_CARD_COORDS=""
# Look for elements that look like exec commands (contain "cd " or shell commands)
TOOL_CARD_COORDS=$(echo "$TREE_JSON" | jq -r \
  '.data.elements[] | select(
    (.label | test("cd |grep |cat |flutter |git "; "s")) and
    .frame.width > 100 and .frame.height > 0 and .frame.y > 60 and .frame.y < 760
  ) | "\(.frame.x + .frame.width/2 | floor),\(.frame.y + .frame.height/2 | floor)"' \
  2>/dev/null | head -1)

if [[ -n "$TOOL_CARD_COORDS" ]]; then
  # Tap to expand
  R=$(tap_coords "$TOOL_CARD_COORDS")
  assert_ok "4.01 Tap tool call card (expand)" "$R"
  sleep 0.5

  refresh_tree
  screenshot "04_tool_expanded"

  # Tap again to collapse
  R=$(tap_coords "$TOOL_CARD_COORDS")
  assert_ok "4.02 Tap tool call card (collapse)" "$R"
  sleep 0.3

  refresh_tree
  screenshot "04_tool_collapsed"
else
  # If no exec-style cards visible, try finding any tappable card-like element
  # (mid-screen, not the input or title bar)
  TOOL_CARD_COORDS=$(echo "$TREE_JSON" | jq -r \
    '.data.elements[] | select(
      .frame.y > 100 and .frame.y < 700 and
      .frame.width > 200 and .frame.height > 15 and .frame.height < 60 and
      (.label | length) > 10
    ) | "\(.frame.x + .frame.width/2 | floor),\(.frame.y + .frame.height/2 | floor)"' \
    2>/dev/null | head -1)

  if [[ -n "$TOOL_CARD_COORDS" ]]; then
    R=$(tap_coords "$TOOL_CARD_COORDS")
    assert_ok "4.01 Tap content card" "$R"
    sleep 0.5
    refresh_tree
    screenshot "04_card_tapped"

    R=$(tap_coords "$TOOL_CARD_COORDS")
    assert_ok "4.02 Tap content card again" "$R"
    sleep 0.3
  else
    TOTAL=$((TOTAL + 2)); FAIL=$((FAIL + 2))
    printf '  \033[31m✗\033[0m 4.01 No tool call cards found to tap\n'
    printf '  \033[31m✗\033[0m 4.02 Skipped\n'
  fi
fi

echo ""

# ── 5. Model Selection Sheet ────────────────────────────────────────

echo "── Phase 5: Model Selection Sheet ──"

# The connection dot is at top-left (~33, ~78 from title_bar.dart layout)
# TitleBar is 36px high, starts after SafeArea top (~59px on iPhone 17 Pro)
# Connection dot is a 32x32 circle at left:17 + 16 padding
# Approximate center: x=33, y=59+18=77

R=$(tap_coords "33,77")
assert_ok "5.01 Tap connection dot (open model sheet)" "$R"
sleep 0.8

refresh_tree
screenshot "05_model_sheet"

# The model sheet should show "Models" heading and selector cards
assert_tree_has "5.02 Models heading" "Models"

# Check for model selector elements
TOTAL=$((TOTAL + 1))
if tree_has "Main session model" || tree_has "Sub-agent model" || tree_has "session model"; then
  PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m 5.03 Model selectors visible\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m 5.03 Model selectors not visible\n'
fi

# Dismiss the sheet by tapping outside (tap above the sheet, in the barrier area)
R=$(tap_coords "201,100")
assert_ok "5.04 Dismiss model sheet" "$R"
sleep 0.5

refresh_tree
# After dismiss, should be back on chat — no "Models" heading
assert_tree_missing "5.05 Model sheet dismissed" "Models"

screenshot "05_after_dismiss"

echo ""

# ── 6. Send a Message ───────────────────────────────────────────────

echo "── Phase 6: Send Message ──"

# Type in the message field
R=$(run_iez "$IEZ" ui type "hello from iez test" --label "Message…")
assert_ok "6.01 Type message" "$R"
sleep 0.3

screenshot "06_typed"

# The send button appears when text is present — it's at the right of input area
# Input area is at bottom: camera(left), textfield(center), send(right)
# Send button center approximately x=392, y=808 (from chat_screen layout)
# Actually: right side of input, SafeArea bottom + offset
# From code: Padding 10px, Row with camera(36px)+gap(6)+textfield+gap(6)+send(36px)
# Send button: x≈402-10-18=374, y≈874-safeBottom(34)-8-18=814
R=$(tap_coords "380,808")
assert_ok "6.02 Tap send button" "$R"
sleep 1

refresh_tree
screenshot "06_sent"

# The message should appear in the chat
# User messages show as MessageBubble with the text
TOTAL=$((TOTAL + 1))
if tree_has "hello from iez test"; then
  PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m 6.03 Sent message visible in chat\n'
else
  # The message might have scrolled; check anyway
  FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m 6.03 Sent message not visible (may have scrolled)\n'
fi

echo ""

# ── 7. Log Viewer Navigation ────────────────────────────────────────

echo "── Phase 7: Log Viewer ──"

# Terminal icon is at top-right of title bar
# From title_bar.dart: right:14, 32x32 circle
# Approximate center: x=402-14-16=372, y=77
R=$(tap_coords "372,77")
assert_ok "7.01 Tap terminal icon (open log viewer)" "$R"
sleep 0.8

refresh_tree
screenshot "07_log_viewer"

# Log viewer should show different content — check for log-related elements
# LogViewerScreen likely has its own content
TOTAL=$((TOTAL + 1))
if ! tree_has "Message…"; then
  PASS=$((PASS + 1)); printf '  \033[32m✓\033[0m 7.02 Navigated away from chat (no input field)\n'
else
  FAIL=$((FAIL + 1)); printf '  \033[31m✗\033[0m 7.02 Still on chat screen\n'
fi

# Go back to chat
R=$(run_iez "$IEZ" ui tap --label "Back")
if ! echo "$R" | jq -e '.ok == true' &>/dev/null; then
  # Try swipe right to go back (iOS gesture)
  R=$(run_iez "$IEZ" ui swipe --from "10,400" --to "300,400")
fi
assert_ok "7.03 Navigate back to chat" "$R"
sleep 0.5

refresh_tree
assert_tree_has "7.04 Back on chat screen" "Message…"

screenshot "07_back_to_chat"

echo ""

# ── 8. Keyboard Interactions ─────────────────────────────────────────

echo "── Phase 8: Keyboard ──"

# Tap the text field to bring up keyboard
R=$(run_iez "$IEZ" ui tap --label "Message…")
assert_ok "8.01 Tap message field (keyboard up)" "$R"
sleep 0.5

refresh_tree
screenshot "08_keyboard_up"

# Dismiss keyboard by tapping outside the text field (tap on chat area)
R=$(tap_coords "201,400")
assert_ok "8.02 Tap chat area (dismiss keyboard)" "$R"
sleep 0.3

screenshot "08_keyboard_down"

echo ""

# ── 9. Final Screenshot & Summary ───────────────────────────────────

echo "── Phase 9: Final ──"

# Scroll to bottom to see latest content
R=$(run_iez "$IEZ" ui swipe down)
assert_ok "9.01 Final scroll to bottom" "$R"
sleep 0.3

refresh_tree
screenshot "09_final"

# ── Summary ──────────────────────────────────────────────────────────

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "╔══════════════════════════════════════════════════╗"
printf "║  RESULTS: %d/%d passed, %d failed  (%ds)        ║\n" "$PASS" "$TOTAL" "$FAIL" "$DURATION"
echo "╚══════════════════════════════════════════════════╝"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
