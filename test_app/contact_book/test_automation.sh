#!/usr/bin/env bash
# test_automation.sh — ContactBook (App 170)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.contactBook"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then PASS=$((PASS + 1)); echo "  ✓ $2"
  else FAIL=$((FAIL + 1)); echo "  ✗ $2"; fi
}
tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}
fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 2
}
screenshot() { run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1; }

echo "=== ContactBook Test Suite ==="
fresh_launch

echo "--- Contacts Tab ---"
R=$(run_iez $IEZ ui wait --label "Contact Book" --timeout 5)
assert_ok "$R" "Contact Book heading"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter"
R=$(run_iez $IEZ ui exists --label "Family")
assert_ok "$R" "Family filter"
R=$(run_iez $IEZ ui exists --label "Work")
assert_ok "$R" "Work filter"
R=$(run_iez $IEZ ui exists --label "Friends")
assert_ok "$R" "Friends filter"
R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"
R=$(run_iez $IEZ ui exists --label "Add Contact")
assert_ok "$R" "Add Contact FAB"

TOTAL=$((TOTAL + 1)); if tree_contains "Alice Johnson"; then PASS=$((PASS + 1)); echo "  ✓ Alice Johnson"; else FAIL=$((FAIL + 1)); echo "  ✗ Alice Johnson"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Bob Smith"; then PASS=$((PASS + 1)); echo "  ✓ Bob Smith"; else FAIL=$((FAIL + 1)); echo "  ✗ Bob Smith"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Carol White"; then PASS=$((PASS + 1)); echo "  ✓ Carol White"; else FAIL=$((FAIL + 1)); echo "  ✗ Carol White"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "David Brown"; then PASS=$((PASS + 1)); echo "  ✓ David Brown"; else FAIL=$((FAIL + 1)); echo "  ✗ David Brown"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Eve Davis"; then PASS=$((PASS + 1)); echo "  ✓ Eve Davis"; else FAIL=$((FAIL + 1)); echo "  ✗ Eve Davis"; fi

screenshot "01_contacts"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Family")
assert_ok "$R" "Tap Family filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "Alice Johnson"; then PASS=$((PASS + 1)); echo "  ✓ Alice after Family filter"; else FAIL=$((FAIL + 1)); echo "  ✗ Alice after Family filter"; fi
TOTAL=$((TOTAL + 1)); if ! tree_contains "Bob Smith"; then PASS=$((PASS + 1)); echo "  ✓ Bob hidden after Family"; else FAIL=$((FAIL + 1)); echo "  ✗ Bob hidden after Family"; fi

R=$(run_iez $IEZ ui tap --label "Work")
assert_ok "$R" "Tap Work filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "Bob Smith"; then PASS=$((PASS + 1)); echo "  ✓ Bob after Work filter"; else FAIL=$((FAIL + 1)); echo "  ✗ Bob after Work filter"; fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All to reset"
sleep 0.3

echo "--- Contact Detail ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Alice Johnson")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap Alice Johnson"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Contact Details" --timeout 5)
assert_ok "$R" "Contact Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Alice Johnson"; then PASS=$((PASS + 1)); echo "  ✓ Name on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Name on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "555-0101"; then PASS=$((PASS + 1)); echo "  ✓ Phone number"; else FAIL=$((FAIL + 1)); echo "  ✗ Phone number"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "alice@example.com"; then PASS=$((PASS + 1)); echo "  ✓ Email"; else FAIL=$((FAIL + 1)); echo "  ✗ Email"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "123 Maple St"; then PASS=$((PASS + 1)); echo "  ✓ Address"; else FAIL=$((FAIL + 1)); echo "  ✗ Address"; fi

R=$(run_iez $IEZ ui exists --label "Delete Contact")
assert_ok "$R" "Delete Contact button"

screenshot "02_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Groups Tab ---"
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Groups tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Groups" --timeout 5)
assert_ok "$R" "Groups heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Family"; then PASS=$((PASS + 1)); echo "  ✓ Family group"; else FAIL=$((FAIL + 1)); echo "  ✗ Family group"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Work"; then PASS=$((PASS + 1)); echo "  ✓ Work group"; else FAIL=$((FAIL + 1)); echo "  ✗ Work group"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Friends"; then PASS=$((PASS + 1)); echo "  ✓ Friends group"; else FAIL=$((FAIL + 1)); echo "  ✗ Friends group"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "2 members"; then PASS=$((PASS + 1)); echo "  ✓ Member count visible"; else FAIL=$((FAIL + 1)); echo "  ✗ Member count visible"; fi

screenshot "03_groups"

echo "--- Favorites Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Favorites tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Favorites" --timeout 5)
assert_ok "$R" "Favorites heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Alice Johnson"; then PASS=$((PASS + 1)); echo "  ✓ Alice in favorites"; else FAIL=$((FAIL + 1)); echo "  ✗ Alice in favorites"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Carol White"; then PASS=$((PASS + 1)); echo "  ✓ Carol in favorites"; else FAIL=$((FAIL + 1)); echo "  ✗ Carol in favorites"; fi

screenshot "04_favorites"

echo "--- Search Page ---"
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Contacts tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Contacts" --timeout 5)
assert_ok "$R" "Search Contacts heading"

R=$(run_iez $IEZ ui type "bob" --label "Search")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Bob Smith"; then PASS=$((PASS + 1)); echo "  ✓ Search result: Bob"; else FAIL=$((FAIL + 1)); echo "  ✗ Search result: Bob"; fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from search"
sleep 0.3

echo "--- Add Contact ---"
R=$(run_iez $IEZ ui tap --label "Add Contact")
assert_ok "$R" "Tap Add Contact FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Contact" --timeout 5)
assert_ok "$R" "Add Contact heading"

R=$(run_iez $IEZ ui exists --label "First Name")
assert_ok "$R" "First Name field"
R=$(run_iez $IEZ ui exists --label "Last Name")
assert_ok "$R" "Last Name field"
R=$(run_iez $IEZ ui exists --label "Phone")
assert_ok "$R" "Phone field"
R=$(run_iez $IEZ ui exists --label "Email")
assert_ok "$R" "Email field"
R=$(run_iez $IEZ ui exists --label "Save Contact")
assert_ok "$R" "Save Contact button"

R=$(run_iez $IEZ ui type "Test" --label "First Name")
assert_ok "$R" "Type first name"
R=$(run_iez $IEZ ui type "User" --label "Last Name")
assert_ok "$R" "Type last name"

R=$(run_iez $IEZ ui tap --label "Save Contact")
assert_ok "$R" "Tap Save Contact"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Test User"; then PASS=$((PASS + 1)); echo "  ✓ New contact in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New contact in list"; fi

screenshot "05_after_add"

echo "--- Delete Contact ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test User")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test User"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete Contact")
  assert_ok "$R" "Tap Delete Contact"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "Test User"; then PASS=$((PASS + 1)); echo "  ✓ Test User deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ Test User deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test User (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Contact (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test User deleted (skipped)"
fi

screenshot "06_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
