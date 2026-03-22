#!/usr/bin/env bash
# test_automation.sh — DiaryApp (App 165)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.diaryApp"
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
  sleep 0.5
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 2
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# =========================================
echo "=== DiaryApp Test Suite ==="
# =========================================

fresh_launch

echo "--- Entries Tab (Home) ---"
R=$(run_iez $IEZ ui wait --label "My Diary" --timeout 5)
assert_ok "$R" "My Diary heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Great morning run"; then
  PASS=$((PASS + 1)); echo "  ✓ Entry: Great morning run"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Entry: Great morning run"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Busy work day"; then
  PASS=$((PASS + 1)); echo "  ✓ Entry: Busy work day"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Entry: Busy work day"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Weekend plans"; then
  PASS=$((PASS + 1)); echo "  ✓ Entry: Weekend plans"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Entry: Weekend plans"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "exercise, outdoor"; then
  PASS=$((PASS + 1)); echo "  ✓ Tags visible on entry"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tags visible on entry"
fi

screenshot "01_entries"

echo "--- Entry Detail ---"
# Tap first entry (Great morning run at y~118)
R=$(run_iez $IEZ ui tap --coords 200,150)
assert_ok "$R" "Tap Great morning run"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Entry" --timeout 5)
assert_ok "$R" "Entry detail heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Great morning run"; then
  PASS=$((PASS + 1)); echo "  ✓ Title on detail"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Title on detail"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Ran 5km in the park"; then
  PASS=$((PASS + 1)); echo "  ✓ Content visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Content visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "exercise"; then
  PASS=$((PASS + 1)); echo "  ✓ Tag chip: exercise"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tag chip: exercise"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "outdoor"; then
  PASS=$((PASS + 1)); echo "  ✓ Tag chip: outdoor"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tag chip: outdoor"
fi

screenshot "02_entry_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Search ---"
# Search icon is in AppBar actions (top right)
R=$(run_iez $IEZ ui tap --coords 380,90)
assert_ok "$R" "Tap Search icon"
sleep 0.3

# Type in search
R=$(run_iez $IEZ ui type "morning" --coords 200,90)
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Great morning run"; then
  PASS=$((PASS + 1)); echo "  ✓ Search result: morning run"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Search result: morning run"
fi

TOTAL=$((TOTAL + 1))
if ! tree_contains "Busy work day"; then
  PASS=$((PASS + 1)); echo "  ✓ Busy work day filtered out"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Busy work day filtered out"
fi

screenshot "03_search"

# Close search
R=$(run_iez $IEZ ui tap --coords 380,90)
assert_ok "$R" "Close search"
sleep 0.3

echo "--- Favorite Toggle ---"
# Favorite buttons are trailing icons on each entry row
# First entry (Great morning run) — favorite icon at far right, around x=370, y=150
R=$(run_iez $IEZ ui tap --coords 370,150)
assert_ok "$R" "Tap favorite on first entry"
sleep 0.3

screenshot "04_favorited"

echo "--- Favorites Tab ---"
# Favorites tab at x=134..268, y=760
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Favorites tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Favorites" --timeout 5)
assert_ok "$R" "Favorites heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Great morning run"; then
  PASS=$((PASS + 1)); echo "  ✓ Favorited entry appears"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Favorited entry appears"
fi

screenshot "05_favorites"

echo "--- Stats Tab ---"
# Stats tab at x=268..402, y=760
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Stats tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Stats" --timeout 5)
assert_ok "$R" "Stats heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Mood Distribution"; then
  PASS=$((PASS + 1)); echo "  ✓ Mood Distribution label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Mood Distribution label"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Happy"; then
  PASS=$((PASS + 1)); echo "  ✓ Happy mood"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Happy mood"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Neutral"; then
  PASS=$((PASS + 1)); echo "  ✓ Neutral mood"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Neutral mood"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Excited"; then
  PASS=$((PASS + 1)); echo "  ✓ Excited mood"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Excited mood"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Top Tags"; then
  PASS=$((PASS + 1)); echo "  ✓ Top Tags section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Top Tags section"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Total entries: 3"; then
  PASS=$((PASS + 1)); echo "  ✓ Total entries count"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Total entries count"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "outdoor (2)"; then
  PASS=$((PASS + 1)); echo "  ✓ Tag count: outdoor (2)"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Tag count: outdoor (2)"
fi

screenshot "06_stats"

echo "--- New Entry via Bottom Sheet ---"
# Go back to Entries tab
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Entries tab"
sleep 0.3

# FAB (edit icon) should appear — bottom right
R=$(run_iez $IEZ ui tap --coords 370,720)
assert_ok "$R" "Tap FAB to add entry"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "New Entry"; then
  PASS=$((PASS + 1)); echo "  ✓ New Entry bottom sheet"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New Entry bottom sheet"
fi

R=$(run_iez $IEZ ui exists --label "Title")
assert_ok "$R" "Title field"

R=$(run_iez $IEZ ui exists --label "How was your day?")
assert_ok "$R" "Content field"

R=$(run_iez $IEZ ui exists --label "Tags (comma separated)")
assert_ok "$R" "Tags field"

R=$(run_iez $IEZ ui exists --label "Save Entry")
assert_ok "$R" "Save Entry button"

screenshot "07_new_entry_sheet"

echo "--- Save New Entry ---"
R=$(run_iez $IEZ ui type "Test Entry" --label "Title")
assert_ok "$R" "Type title"

R=$(run_iez $IEZ ui type "This is a test diary entry" --label "How was your day?")
assert_ok "$R" "Type content"

R=$(run_iez $IEZ ui tap --label "Save Entry")
assert_ok "$R" "Tap Save Entry"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Test Entry"; then
  PASS=$((PASS + 1)); echo "  ✓ New entry in list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ New entry in list"
fi

screenshot "08_after_save"

echo "--- Delete Entry via Detail ---"
# Tap Test Entry — it should be the first/top entry
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Entry")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test Entry"
  sleep 0.5

  # Delete icon in AppBar (top right)
  R=$(run_iez $IEZ ui tap --coords 380,90)
  assert_ok "$R" "Tap Delete icon"
  sleep 0.5

  TOTAL=$((TOTAL + 1))
  if ! tree_contains "Test Entry"; then
    PASS=$((PASS + 1)); echo "  ✓ Test Entry deleted"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ Test Entry deleted"
  fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Entry (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete icon (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Entry deleted (skipped)"
fi

screenshot "09_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
