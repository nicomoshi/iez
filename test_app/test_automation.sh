#!/bin/bash
# Test Automation: Interactive Widgets
# Widgets: AnimatedSwitcher, AnimatedScale, AnimatedOpacity, FilledButton.tonalIcon,
#          Badge, Tooltip, CircleAvatar, ListWheelScrollView, ListView.separated,
#          Dismissible, SnackBar, Divider
set -euo pipefail
cd "$(dirname "$0")/.."

PASS=0; FAIL=0; TOTAL=0
run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $2"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $2"
  fi
}

has_label() {
  run_iez ./bin/iez ui exists --label "$1" | jq -r '.ok' | grep -q true
}

assert_label() {
  TOTAL=$((TOTAL + 1))
  if has_label "$1"; then
    PASS=$((PASS + 1)); echo "  ✓ Label: $1"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ Label: $1"
  fi
}

assert_no_label() {
  TOTAL=$((TOTAL + 1))
  if ! has_label "$1"; then
    PASS=$((PASS + 1)); echo "  ✓ No label: $1"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ Expected no label: $1"
  fi
}

assert_label_contains() {
  TOTAL=$((TOTAL + 1))
  local tree; tree=$(run_iez ./bin/iez ui tree --compact)
  if echo "$tree" | jq -r '.data.elements[].label // ""' | grep -q "$1"; then
    PASS=$((PASS + 1)); echo "  ✓ Contains: $1"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ Missing: $1"
  fi
}

START_TIME=$(date +%s)
echo "=== Interactive Widgets Test ==="
echo ""

# --- Screen 1: Counter Animations ---
echo "--- Screen 1: Counter Animations ---"
assert_label "Counter Animations"
assert_label "0"
assert_label "Decrease"
assert_label "Increase"
assert_label "Fade Out"
assert_label "Scale Up"
assert_label "Count: 0"
assert_label "Visible: true"
assert_label "Scale: 1.0x"

# Tap Increase 3 times
R=$(run_iez ./bin/iez ui tap --label "Increase")
assert_ok "$R" "Tap Increase (1)"

R=$(run_iez ./bin/iez ui tap --label "Increase")
assert_ok "$R" "Tap Increase (2)"

R=$(run_iez ./bin/iez ui tap --label "Increase")
assert_ok "$R" "Tap Increase (3)"


assert_label "Count: 3"

# Decrease once
R=$(run_iez ./bin/iez ui tap --label "Decrease")
assert_ok "$R" "Tap Decrease"


assert_label "Count: 2"

# Toggle fade
R=$(run_iez ./bin/iez ui tap --label "Fade Out")
assert_ok "$R" "Tap Fade Out"


assert_label "Visible: false"
assert_label "Fade In"

# Toggle scale
R=$(run_iez ./bin/iez ui tap --label "Scale Up")
assert_ok "$R" "Tap Scale Up"


assert_label "Scale: 2.0x"
assert_label "Scale Down"

# Toggle back
R=$(run_iez ./bin/iez ui tap --label "Fade In")
assert_ok "$R" "Tap Fade In"


assert_label "Visible: true"

R=$(run_iez ./bin/iez ui tap --label "Scale Down")
assert_ok "$R" "Tap Scale Down"


assert_label "Scale: 1.0x"

# --- Screen 2: Badges & Tooltips ---
echo ""
echo "--- Screen 2: Badges & Tooltips ---"
R=$(run_iez ./bin/iez ui tap --coords 201,800)
assert_ok "$R" "Tap Badges tab"


assert_label "Badges & Tooltips"
assert_label "Tooltips"
assert_label "Home"
assert_label "Settings"
assert_label "Profile"
assert_label "Badges"
assert_label "Notification count: 3"
assert_label "Notifications"
assert_label "Circle Avatars"
assert_label "AB"
assert_label "CD"
assert_label "EF"
assert_label "Color Picker (Wheel)"
assert_label "Selected: Red"

# Clear notifications
R=$(run_iez ./bin/iez ui tap --label "Notifications")
assert_ok "$R" "Tap Notifications (clear badge)"


assert_label "Notification count: 0"

# --- Screen 3: Swipe to Dismiss ---
echo ""
echo "--- Screen 3: Swipe to Dismiss (ListView.separated + Dismissible) ---"
R=$(run_iez ./bin/iez ui tap --coords 335,800)
assert_ok "$R" "Tap List tab"


assert_label "Swipe to Dismiss"
assert_label "Items: 10"
assert_label "Last dismissed: None"
assert_label "Reset"

# Swipe first item to dismiss
R=$(run_iez ./bin/iez ui swipe --from 350,206 --to 50,206)
assert_ok "$R" "Swipe Item 1 to dismiss"
sleep 0.15

assert_label "Items: 9"
assert_label_contains "Last dismissed: Item 1"

# Swipe another item
R=$(run_iez ./bin/iez ui swipe --from 350,206 --to 50,206)
assert_ok "$R" "Swipe Item 2 to dismiss"
sleep 0.15

assert_label "Items: 8"
assert_label_contains "Last dismissed: Item 2"

# Reset list
R=$(run_iez ./bin/iez ui tap --label "Reset")
assert_ok "$R" "Tap Reset"


assert_label "Items: 10"
assert_label "Last dismissed: None"

# Return to Counter to verify state preserved
echo ""
echo "--- Verify state preserved ---"
R=$(run_iez ./bin/iez ui tap --coords 67,800)
assert_ok "$R" "Tap Counter tab"


assert_label "Count: 2"
assert_label "Visible: true"
assert_label "Scale: 1.0x"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo ""
echo "=== Results: $PASS/$TOTAL passed ($FAIL failed) in ${ELAPSED}s ==="
[ "$FAIL" -eq 0 ] && echo "🎉 ALL TESTS PASSED" || echo "❌ SOME TESTS FAILED"
exit "$FAIL"
