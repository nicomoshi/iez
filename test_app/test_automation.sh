#!/bin/bash
# Test automation for Apps 98-100: CountdownTimer/ColorMixer/QuoteBook
set -uo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p' || true; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null || echo "false")
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

TREE_CACHE=""
refresh_tree() {
  TREE_CACHE=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label' 2>/dev/null || true)
}

tree_has() {
  echo "$TREE_CACHE" | grep -qF -- "$1" 2>/dev/null
}

assert_tree_has() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if tree_has "$substr"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc ('$substr' not in tree)"
  fi
}

# Nuke all Runner processes and uninstall all test apps
nuke_all() {
  set +e
  for bid in com.test.countdownTimer com.test.colorMixer com.test.quoteBook; do
    xcrun simctl terminate "$DEVICE_ID" "$bid" 2>/dev/null
  done
  sleep 1
  # Force kill lingering Runners
  local attempt pids
  for attempt in 1 2 3; do
    pids=$(ps aux | grep "CoreSimulator/Devices.*Runner.app/Runner" | grep -v grep | awk '{print $2}')
    [ -z "$pids" ] && break
    echo "$pids" | xargs kill -9 2>/dev/null
    sleep 1
  done
  # Uninstall all test apps
  for bid in com.test.countdownTimer com.test.colorMixer com.test.quoteBook; do
    xcrun simctl uninstall "$DEVICE_ID" "$bid" 2>/dev/null
  done
  sleep 1
  set -e
}

# Install and launch a single app (after nuking all others)
fresh_launch() {
  local bid="$1" app_path="$2" expected="$3"
  nuke_all
  xcrun simctl install "$DEVICE_ID" "$app_path" 2>/dev/null
  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$bid" 2>/dev/null || true
  sleep 5
  # Verify correct app
  local app_name
  app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || true)
  if [ "$app_name" = "$expected" ]; then
    echo "  ✔ $expected is in foreground"
  else
    echo "  ⚠ Expected '$expected' but saw '$app_name', retrying..."
    nuke_all
    xcrun simctl install "$DEVICE_ID" "$app_path" 2>/dev/null
    sleep 1
    xcrun simctl launch "$DEVICE_ID" "$bid" 2>/dev/null || true
    sleep 5
  fi
}

# ============================================================
echo "=== App 98: CountdownTimer ==="
# ============================================================

fresh_launch "com.test.countdownTimer" \
  "$SCRIPT_DIR/countdown_timer/build/ios/iphonesimulator/Runner.app" \
  "Countdown Timer"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Countdown Timer"
assert_tree_has "Time display" "Time remaining"
assert_tree_has "Duration label" "Duration: 60s"
assert_tree_has "Start button" "Start"
assert_tree_has "Pause button" "Pause"
assert_tree_has "Reset button" "Reset"
assert_tree_has "History button" "History"
assert_tree_has "Settings button" "Settings"

echo "--- Start Timer ---"
R=$(run_iez "$IEZ" ui tap --label "Start")
assert_ok "Tap Start" "$R"
sleep 2

echo "--- Pause Timer ---"
R=$(run_iez "$IEZ" ui tap --label "Pause")
assert_ok "Tap Pause" "$R"
sleep 0.5

echo "--- Reset Timer ---"
R=$(run_iez "$IEZ" ui tap --label "Reset")
assert_ok "Tap Reset" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Duration restored" "Duration: 60s"

echo "--- Navigate to Settings ---"
R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Tap Settings" "$R"
sleep 2

refresh_tree
assert_tree_has "Settings heading" "Timer Settings"
assert_tree_has "Duration text" "Duration: 60 seconds"
assert_tree_has "Quick Presets" "Quick Presets"
assert_tree_has "30s preset" "30s"
assert_tree_has "120s preset" "120s"
assert_tree_has "300s preset" "300s"
assert_tree_has "600s preset" "600s"
assert_tree_has "Apply button" "Apply"

echo "--- Select Preset ---"
R=$(run_iez "$IEZ" ui tap --label "30s")
assert_ok "Tap 30s preset" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Duration updated to 30" "Duration: 30 seconds"

echo "--- Apply and return ---"
R=$(run_iez "$IEZ" ui tap --label "Apply")
assert_ok "Tap Apply" "$R"
sleep 2

refresh_tree
assert_tree_has "Back on home" "Countdown Timer"
assert_tree_has "Duration now 30s" "Duration: 30s"

echo "--- Navigate to History ---"
R=$(run_iez "$IEZ" ui tap --label "History")
assert_ok "Tap History" "$R"
sleep 2

refresh_tree
assert_tree_has "History heading" "Timer History"
assert_tree_has "Empty history" "No completed timers yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from History" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app98_countdown.png)
assert_ok "Screenshot CountdownTimer" "$R"

# ============================================================
echo ""
echo "=== App 99: ColorMixer ==="
# ============================================================

fresh_launch "com.test.colorMixer" \
  "$SCRIPT_DIR/color_mixer/build/ios/iphonesimulator/Runner.app" \
  "Color Mixer"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Color Mixer"
assert_tree_has "Hex code" "#808080"
assert_tree_has "Red slider" "Red: 128"
assert_tree_has "Green slider" "Green: 128"
assert_tree_has "Blue slider" "Blue: 128"
assert_tree_has "Save Color button" "Save Color"
assert_tree_has "Reset button" "Reset"
assert_tree_has "Quick Colors heading" "Quick Colors"
assert_tree_has "Pure Red chip" "Pure Red"
assert_tree_has "Pure Green chip" "Pure Green"
assert_tree_has "Pure Blue chip" "Pure Blue"
assert_tree_has "Yellow chip" "Yellow"
assert_tree_has "Cyan chip" "Cyan"
assert_tree_has "White chip" "White"
assert_tree_has "Saved Colors button" "Saved Colors"
assert_tree_has "About button" "About"

echo "--- Tap Pure Red ---"
R=$(run_iez "$IEZ" ui tap --label "Pure Red")
assert_ok "Tap Pure Red" "$R"
sleep 1

refresh_tree
assert_tree_has "Hex is red" "#FF0000"
assert_tree_has "Red is 255" "Red: 255"

echo "--- Save Color ---"
R=$(run_iez "$IEZ" ui tap --label "Save Color")
assert_ok "Tap Save Color" "$R"
sleep 5  # Wait for SnackBar to auto-dismiss (Flutter default 4s)

echo "--- Tap Yellow ---"
R=$(run_iez "$IEZ" ui tap --label "Yellow")
assert_ok "Tap Yellow" "$R"
sleep 1

refresh_tree
assert_tree_has "Hex is yellow" "#FFFF00"

echo "--- Save second color ---"
R=$(run_iez "$IEZ" ui tap --label "Save Color")
assert_ok "Save Yellow" "$R"
sleep 5  # Wait for SnackBar

echo "--- View Saved Colors ---"
R=$(run_iez "$IEZ" ui tap --label "Saved Colors")
assert_ok "Tap Saved Colors" "$R"
sleep 1

refresh_tree
assert_tree_has "Saved Colors heading" "Saved Colors"
assert_tree_has "Red saved" "#FF0000"
assert_tree_has "Yellow saved" "#FFFF00"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Saved Colors" "$R"
sleep 1

echo "--- About Dialog ---"
R=$(run_iez "$IEZ" ui tap --label "About")
assert_ok "Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "About title" "About Color Mixer"
assert_tree_has "About content" "Mix colors using RGB sliders"
assert_tree_has "OK button" "OK"

R=$(run_iez "$IEZ" ui tap --label "OK")
assert_ok "Dismiss About dialog" "$R"
sleep 0.5

echo "--- Reset Color ---"
R=$(run_iez "$IEZ" ui tap --label "Reset")
assert_ok "Tap Reset" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Reset to grey" "#808080"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app99_colormixer.png)
assert_ok "Screenshot ColorMixer" "$R"

# ============================================================
echo ""
echo "=== App 100: QuoteBook ==="
# ============================================================

fresh_launch "com.test.quoteBook" \
  "$SCRIPT_DIR/quote_book/build/ios/iphonesimulator/Runner.app" \
  "Quote Book"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Quote Book"
assert_tree_has "All filter" "All"
assert_tree_has "Motivation filter" "Motivation"
assert_tree_has "Innovation filter" "Innovation"
assert_tree_has "Life filter" "Life"
assert_tree_has "Wisdom filter" "Wisdom"
assert_tree_has "Steve Jobs quote" "The only way to do great work"
assert_tree_has "John Lennon quote" "John Lennon"
assert_tree_has "Aristotle quote" "Aristotle"
assert_tree_has "Favorites button" "Favorites"
assert_tree_has "Add Quote FAB" "Add Quote"

echo "--- Filter by Innovation ---"
R=$(run_iez "$IEZ" ui tap --label "Innovation")
assert_ok "Tap Innovation filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Innovation quote visible" "Innovation distinguishes"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 0.5

echo "--- Navigate to Favorites ---"
R=$(run_iez "$IEZ" ui tap --label "Favorites")
assert_ok "Tap Favorites" "$R"
sleep 1

refresh_tree
assert_tree_has "Favorites heading" "Favorites"
assert_tree_has "No favorites" "No favorites yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Favorites" "$R"
sleep 1

echo "--- Navigate to Add Quote ---"
R=$(run_iez "$IEZ" ui tap --label "Add Quote")
assert_ok "Tap Add Quote" "$R"
sleep 1

refresh_tree
assert_tree_has "Add Quote heading" "Add Quote"
assert_tree_has "Quote text field" "Quote text"
assert_tree_has "Author field" "Author"
assert_tree_has "Category dropdown" "Category"
assert_tree_has "Save Quote button" "Save Quote"

echo "--- Fill in new quote ---"
R=$(run_iez "$IEZ" ui type "Knowledge is power" --label "Quote text")
assert_ok "Type quote text" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Francis Bacon" --label "Author")
assert_ok "Type author" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Quote")
assert_ok "Tap Save Quote" "$R"
sleep 1

echo "--- Verify new quote ---"
refresh_tree
assert_tree_has "Back on home" "Quote Book"
assert_tree_has "New quote visible" "Knowledge is power"

echo "--- Scroll quotes ---"
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "Swipe up" "$R"
sleep 0.5

refresh_tree
assert_tree_has "App still showing" "Quote Book"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app100_quotebook.png)
assert_ok "Screenshot QuoteBook" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
