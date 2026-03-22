#!/usr/bin/env bash
# test_automation.sh — GardenPlanner (App 162)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.gardenPlanner"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

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
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.3
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 1.5
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# =========================================
echo "=== GardenPlanner Test Suite ==="
# =========================================

fresh_launch

echo "--- Home Screen ---"
R=$(run_iez $IEZ ui wait --label "Garden Planner" --timeout 5)
assert_ok "$R" "App title visible"

R=$(run_iez $IEZ ui exists --label "Add Plant")
assert_ok "$R" "Add Plant FAB"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"

R=$(run_iez $IEZ ui exists --label "Vegetables")
assert_ok "$R" "Vegetables filter chip"

R=$(run_iez $IEZ ui exists --label "Fruits")
assert_ok "$R" "Fruits filter chip"

R=$(run_iez $IEZ ui exists --label "Herbs")
assert_ok "$R" "Herbs filter chip"

TOTAL=$((TOTAL + 1))
if tree_contains "Tomato"; then
  PASS=$((PASS + 1)); echo "  ✓ Tomato in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tomato in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Strawberry"; then
  PASS=$((PASS + 1)); echo "  ✓ Strawberry in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Strawberry in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Basil"; then
  PASS=$((PASS + 1)); echo "  ✓ Basil in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Basil in list"
fi

screenshot "01_home"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Vegetables")
assert_ok "$R" "Tap Vegetables filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Tomato"; then
  PASS=$((PASS + 1)); echo "  ✓ Tomato visible after Vegetables filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tomato visible after Vegetables filter"
fi

TOTAL=$((TOTAL + 1))
if ! tree_contains "Strawberry"; then
  PASS=$((PASS + 1)); echo "  ✓ Strawberry hidden after Vegetables filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Strawberry hidden after Vegetables filter"
fi

R=$(run_iez $IEZ ui tap --label "Fruits")
assert_ok "$R" "Tap Fruits filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Strawberry"; then
  PASS=$((PASS + 1)); echo "  ✓ Strawberry visible after Fruits filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Strawberry visible after Fruits filter"
fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Reset to All filter"
sleep 0.3

screenshot "02_filters"

echo "--- Detail Screen ---"
# Tap Tomato (first list item)
R=$(run_iez $IEZ ui tap --coords 200,214)
assert_ok "$R" "Tap Tomato"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Tomato"; then
  PASS=$((PASS + 1)); echo "  ✓ Tomato name on detail"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tomato name on detail"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Vegetables"; then
  PASS=$((PASS + 1)); echo "  ✓ Category chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Category chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Planted"; then
  PASS=$((PASS + 1)); echo "  ✓ Planted date"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Planted date"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Expected Harvest"; then
  PASS=$((PASS + 1)); echo "  ✓ Expected Harvest"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Expected Harvest"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Location"; then
  PASS=$((PASS + 1)); echo "  ✓ Location"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Location"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Status"; then
  PASS=$((PASS + 1)); echo "  ✓ Status"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Status"
fi

R=$(run_iez $IEZ ui exists --label "Update Status")
assert_ok "$R" "Update Status button"

R=$(run_iez $IEZ ui exists --label "Delete Item")
assert_ok "$R" "Delete Item button"

screenshot "03_detail"

echo "--- Update Status ---"
R=$(run_iez $IEZ ui tap --label "Update Status")
assert_ok "$R" "Tap Update Status"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Flowering"; then
  PASS=$((PASS + 1)); echo "  ✓ Status changed to Flowering"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Status changed to Flowering"
fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.5

echo "--- Add Plant Screen ---"
R=$(run_iez $IEZ ui tap --label "Add Plant")
assert_ok "$R" "Tap Add Plant FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Plant" --timeout 5)
assert_ok "$R" "Add Plant screen"

R=$(run_iez $IEZ ui exists --label "Plant Name")
assert_ok "$R" "Plant Name field"

R=$(run_iez $IEZ ui exists --label "Category")
assert_ok "$R" "Category dropdown"

R=$(run_iez $IEZ ui exists --label "Location")
assert_ok "$R" "Location dropdown"

R=$(run_iez $IEZ ui exists --label "Status")
assert_ok "$R" "Status dropdown"

screenshot "04_add_form"

# Fill form
R=$(run_iez $IEZ ui type "Rosemary" --label "Plant Name")
assert_ok "$R" "Type plant name"

R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Scroll down to see Add Plant button"
sleep 0.3

# Tap Add Plant button (bottom of form)
R=$(run_iez $IEZ ui tap --label "Add Plant")
assert_ok "$R" "Tap Add Plant save button"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Rosemary"; then
  PASS=$((PASS + 1)); echo "  ✓ New plant in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New plant in list"
fi

screenshot "05_after_add"

echo "--- Popup Menu: Calendar ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Calendar")
assert_ok "$R" "Tap Calendar"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Calendar" --timeout 5)
assert_ok "$R" "Calendar screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Planted"; then
  PASS=$((PASS + 1)); echo "  ✓ Planted dates visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Planted dates visible"
fi

screenshot "06_calendar"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Calendar"
sleep 0.5

echo "--- Popup Menu: Harvest Log ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu again"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Harvest Log")
assert_ok "$R" "Tap Harvest Log"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Harvest Log" --timeout 5)
assert_ok "$R" "Harvest Log screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Lemon Tree"; then
  PASS=$((PASS + 1)); echo "  ✓ Lemon Tree in harvest log"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Lemon Tree in harvest log"
fi

screenshot "07_harvest_log"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Harvest Log"
sleep 0.5

screenshot "08_final"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
