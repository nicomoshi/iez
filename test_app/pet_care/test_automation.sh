#!/usr/bin/env bash
# test_automation.sh — PetCare (App 163)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.petCare"
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
echo "=== PetCare Test Suite ==="
# =========================================

fresh_launch

echo "--- Home Screen ---"
R=$(run_iez $IEZ ui wait --label "Pet Care" --timeout 5)
assert_ok "$R" "App title visible"

R=$(run_iez $IEZ ui exists --label "Add Pet")
assert_ok "$R" "Add Pet FAB"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"

R=$(run_iez $IEZ ui exists --label "Dog")
assert_ok "$R" "Dog filter chip"

R=$(run_iez $IEZ ui exists --label "Cat")
assert_ok "$R" "Cat filter chip"

TOTAL=$((TOTAL + 1))
if tree_contains "Buddy"; then
  PASS=$((PASS + 1)); echo "  ✓ Buddy in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Buddy in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Whiskers"; then
  PASS=$((PASS + 1)); echo "  ✓ Whiskers in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Whiskers in list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Kiwi"; then
  PASS=$((PASS + 1)); echo "  ✓ Kiwi in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Kiwi in list"
fi

screenshot "01_home"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Dog")
assert_ok "$R" "Tap Dog filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Buddy"; then
  PASS=$((PASS + 1)); echo "  ✓ Buddy visible after Dog filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Buddy visible after Dog filter"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Max"; then
  PASS=$((PASS + 1)); echo "  ✓ Max visible after Dog filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Max visible after Dog filter"
fi

TOTAL=$((TOTAL + 1))
if ! tree_contains "Whiskers"; then
  PASS=$((PASS + 1)); echo "  ✓ Whiskers hidden after Dog filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Whiskers hidden after Dog filter"
fi

R=$(run_iez $IEZ ui tap --label "Cat")
assert_ok "$R" "Tap Cat filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "Whiskers"; then
  PASS=$((PASS + 1)); echo "  ✓ Whiskers visible after Cat filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Whiskers visible after Cat filter"
fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Reset to All filter"
sleep 0.3

screenshot "02_filters"

echo "--- Detail Screen ---"
# Tap Buddy (first list item)
R=$(run_iez $IEZ ui tap --coords 200,214)
assert_ok "$R" "Tap Buddy"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Buddy" --timeout 5)
assert_ok "$R" "Buddy detail screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Golden Retriever"; then
  PASS=$((PASS + 1)); echo "  ✓ Breed visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Breed visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Dog"; then
  PASS=$((PASS + 1)); echo "  ✓ Species chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Species chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Age"; then
  PASS=$((PASS + 1)); echo "  ✓ Age info"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Age info"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Weight"; then
  PASS=$((PASS + 1)); echo "  ✓ Weight info"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Weight info"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Last Vet Visit"; then
  PASS=$((PASS + 1)); echo "  ✓ Last Vet Visit"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Last Vet Visit"
fi

R=$(run_iez $IEZ ui exists --label "Log Vet Visit")
assert_ok "$R" "Log Vet Visit button"

R=$(run_iez $IEZ ui exists --label "Edit Notes")
assert_ok "$R" "Edit Notes button"

screenshot "03_detail"

echo "--- Log Vet Visit ---"
R=$(run_iez $IEZ ui tap --label "Log Vet Visit")
assert_ok "$R" "Tap Log Vet Visit"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "2026-03-22"; then
  PASS=$((PASS + 1)); echo "  ✓ Vet visit updated to today"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Vet visit updated to today"
fi

echo "--- Edit Notes Dialog ---"
R=$(run_iez $IEZ ui tap --label "Edit Notes")
assert_ok "$R" "Tap Edit Notes"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Edit Notes" --timeout 5)
assert_ok "$R" "Edit Notes dialog"

R=$(run_iez $IEZ ui exists --label "Cancel")
assert_ok "$R" "Cancel button in dialog"

R=$(run_iez $IEZ ui exists --label "Save")
assert_ok "$R" "Save button in dialog"

screenshot "04_edit_notes_dialog"

R=$(run_iez $IEZ ui tap --label "Cancel")
assert_ok "$R" "Tap Cancel"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.5

echo "--- Add Pet Screen ---"
R=$(run_iez $IEZ ui tap --label "Add Pet")
assert_ok "$R" "Tap Add Pet FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Pet" --timeout 5)
assert_ok "$R" "Add Pet screen"

R=$(run_iez $IEZ ui exists --label "Pet Name")
assert_ok "$R" "Pet Name field"

R=$(run_iez $IEZ ui exists --label "Species")
assert_ok "$R" "Species dropdown"

R=$(run_iez $IEZ ui exists --label "Breed")
assert_ok "$R" "Breed field"

R=$(run_iez $IEZ ui exists --label "Age")
assert_ok "$R" "Age field"

screenshot "05_add_form"

# Fill form
R=$(run_iez $IEZ ui type "Luna" --label "Pet Name")
assert_ok "$R" "Type pet name"

R=$(run_iez $IEZ ui type "Labrador" --label "Breed")
assert_ok "$R" "Type breed"

R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Scroll to see Add Pet button"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Add Pet")
assert_ok "$R" "Tap Add Pet save"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Luna"; then
  PASS=$((PASS + 1)); echo "  ✓ New pet in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New pet in list"
fi

screenshot "06_after_add"

echo "--- Popup Menu: Vet Schedule ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Vet Schedule")
assert_ok "$R" "Tap Vet Schedule"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Vet Schedule" --timeout 5)
assert_ok "$R" "Vet Schedule screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Buddy"; then
  PASS=$((PASS + 1)); echo "  ✓ Buddy in vet schedule"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Buddy in vet schedule"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Last visit"; then
  PASS=$((PASS + 1)); echo "  ✓ Last visit info"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Last visit info"
fi

screenshot "07_vet_schedule"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Vet Schedule"
sleep 0.5

echo "--- Popup Menu: Care Tips ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap popup menu again"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Care Tips")
assert_ok "$R" "Tap Care Tips"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Care Tips" --timeout 5)
assert_ok "$R" "Care Tips screen"

TOTAL=$((TOTAL + 1))
if tree_contains "Nutrition"; then
  PASS=$((PASS + 1)); echo "  ✓ Nutrition tip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Nutrition tip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Exercise"; then
  PASS=$((PASS + 1)); echo "  ✓ Exercise tip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Exercise tip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Grooming"; then
  PASS=$((PASS + 1)); echo "  ✓ Grooming tip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Grooming tip"
fi

screenshot "08_care_tips"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Care Tips"
sleep 0.5

screenshot "09_final"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
