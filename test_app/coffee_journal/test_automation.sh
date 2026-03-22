#!/usr/bin/env bash
# test_automation.sh — CoffeeJournal (App 161)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.coffeeJournal"
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
echo "=== CoffeeJournal Test Suite ==="
# =========================================

fresh_launch

echo "--- Home Screen ---"
R=$(run_iez $IEZ ui wait --label "Coffee Journal" --timeout 5)
assert_ok "$R" "App title visible"

R=$(run_iez $IEZ ui exists --label "Add Coffee")
assert_ok "$R" "Add Coffee FAB"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"

R=$(run_iez $IEZ ui exists --label "Pour Over")
assert_ok "$R" "Pour Over filter chip"

R=$(run_iez $IEZ ui exists --label "Espresso")
assert_ok "$R" "Espresso filter chip"

R=$(run_iez $IEZ ui exists --label "French Press")
assert_ok "$R" "French Press filter chip"

TOTAL=$((TOTAL + 1))
if tree_contains "Ethiopian Yirgacheffe"; then
  PASS=$((PASS + 1)); echo "  ✓ Ethiopian Yirgacheffe in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Ethiopian Yirgacheffe in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Sumatra Mandheling"; then
  PASS=$((PASS + 1)); echo "  ✓ Sumatra Mandheling in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Sumatra Mandheling in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Colombia Supremo"; then
  PASS=$((PASS + 1)); echo "  ✓ Colombia Supremo in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Colombia Supremo in list"
fi

screenshot "01_home"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Pour Over")
assert_ok "$R" "Tap Pour Over filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Ethiopian Yirgacheffe"; then
  PASS=$((PASS + 1)); echo "  ✓ Ethiopian visible after Pour Over filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Ethiopian visible after Pour Over filter"
fi

TOTAL=$((TOTAL + 1))
if ! tree_contains "Sumatra Mandheling"; then
  PASS=$((PASS + 1)); echo "  ✓ Sumatra hidden after Pour Over filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Sumatra hidden after Pour Over filter"
fi

R=$(run_iez $IEZ ui tap --label "Espresso")
assert_ok "$R" "Tap Espresso filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Colombia Supremo"; then
  PASS=$((PASS + 1)); echo "  ✓ Colombia visible after Espresso filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Colombia visible after Espresso filter"
fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All filter to reset"
sleep 0.3

screenshot "02_filters"

echo "--- Detail Screen ---"
# Tap Ethiopian Yirgacheffe (first item at y=174)
R=$(run_iez $IEZ ui tap --coords 200,214)
assert_ok "$R" "Tap Ethiopian Yirgacheffe"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Coffee Details" --timeout 5)
assert_ok "$R" "Coffee Details heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Ethiopian Yirgacheffe"; then
  PASS=$((PASS + 1)); echo "  ✓ Coffee name on detail"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Coffee name on detail"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Blue Bottle"; then
  PASS=$((PASS + 1)); echo "  ✓ Roaster visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Roaster visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Ethiopia"; then
  PASS=$((PASS + 1)); echo "  ✓ Origin visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Origin visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Pour Over"; then
  PASS=$((PASS + 1)); echo "  ✓ Brew method chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Brew method chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Light"; then
  PASS=$((PASS + 1)); echo "  ✓ Roast level chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Roast level chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Tasting Notes"; then
  PASS=$((PASS + 1)); echo "  ✓ Tasting Notes label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tasting Notes label"
fi

R=$(run_iez $IEZ ui exists --label "Delete Entry")
assert_ok "$R" "Delete Entry button"

screenshot "03_detail"

# Go back
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.5

echo "--- Add Coffee Screen ---"
R=$(run_iez $IEZ ui tap --label "Add Coffee")
assert_ok "$R" "Tap Add Coffee FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Coffee" --timeout 5)
assert_ok "$R" "Add Coffee screen"

R=$(run_iez $IEZ ui exists --label "Coffee Name")
assert_ok "$R" "Coffee Name field"

R=$(run_iez $IEZ ui exists --label "Roaster")
assert_ok "$R" "Roaster field"

R=$(run_iez $IEZ ui exists --label "Origin")
assert_ok "$R" "Origin field"

R=$(run_iez $IEZ ui exists --label "Brew Method")
assert_ok "$R" "Brew Method dropdown"

R=$(run_iez $IEZ ui exists --label "Roast Level")
assert_ok "$R" "Roast Level dropdown"

R=$(run_iez $IEZ ui exists --label "Save Coffee")
assert_ok "$R" "Save Coffee button"

screenshot "04_add_form"

# Fill form and save
R=$(run_iez $IEZ ui type "Test Brew" --label "Coffee Name")
assert_ok "$R" "Type coffee name"

R=$(run_iez $IEZ ui type "Test Roaster" --label "Roaster")
assert_ok "$R" "Type roaster"

R=$(run_iez $IEZ ui tap --label "Save Coffee")
assert_ok "$R" "Tap Save Coffee"
sleep 0.5

# Verify back on home and new entry visible
TOTAL=$((TOTAL + 1))
if tree_contains "Test Brew"; then
  PASS=$((PASS + 1)); echo "  ✓ New coffee in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New coffee in list"
fi

screenshot "05_after_add"

echo "--- Popup Menu: Roasters ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Roasters")
assert_ok "$R" "Tap Roasters"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Roasters" --timeout 5)
assert_ok "$R" "Roasters screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Blue Bottle"; then
  PASS=$((PASS + 1)); echo "  ✓ Blue Bottle roaster"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Blue Bottle roaster"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Stumptown"; then
  PASS=$((PASS + 1)); echo "  ✓ Stumptown roaster"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Stumptown roaster"
fi

screenshot "06_roasters"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Roasters"
sleep 0.5

echo "--- Popup Menu: Brew Stats ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu again"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Brew Stats")
assert_ok "$R" "Tap Brew Stats"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Brew Stats" --timeout 5)
assert_ok "$R" "Brew Stats screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Total Coffees"; then
  PASS=$((PASS + 1)); echo "  ✓ Total Coffees label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Total Coffees label"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Average Rating"; then
  PASS=$((PASS + 1)); echo "  ✓ Average Rating label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Average Rating label"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "By Brew Method"; then
  PASS=$((PASS + 1)); echo "  ✓ By Brew Method section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ By Brew Method section"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "By Roast Level"; then
  PASS=$((PASS + 1)); echo "  ✓ By Roast Level section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ By Roast Level section"
fi

screenshot "07_brew_stats"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Brew Stats"
sleep 0.5

echo "--- Delete Coffee ---"
# Tap the "Test Brew" entry — it should be the last item, swipe up first
R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Swipe up to find Test Brew"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Test Brew"; then
  PASS=$((PASS + 1)); echo "  ✓ Test Brew visible after scroll"
  # Tap it using tree coords
  COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Brew")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
  if [ -n "$COORDS" ]; then
    R=$(run_iez $IEZ ui tap --coords "$COORDS")
    assert_ok "$R" "Tap Test Brew"
    sleep 0.5
    R=$(run_iez $IEZ ui tap --label "Delete Entry")
    assert_ok "$R" "Tap Delete Entry"
    sleep 0.5
    TOTAL=$((TOTAL + 1))
    if ! tree_contains "Test Brew"; then
      PASS=$((PASS + 1)); echo "  ✓ Test Brew deleted"
    else
      FAIL=$((FAIL + 1)); echo "  ✗ Test Brew deleted"
    fi
  else
    FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Brew (no coords)"
    FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Entry (skipped)"
    FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Brew deleted (skipped)"
  fi
else
  FAIL=$((FAIL + 1)); echo "  ✗ Test Brew visible after scroll"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Brew (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Entry (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Brew deleted (skipped)"
fi

screenshot "08_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
