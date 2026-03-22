#!/usr/bin/env bash
# test_automation.sh — SleepTracker (App 168)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.sleepTracker"
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

echo "=== SleepTracker Test Suite ==="
fresh_launch

echo "--- Log Tab ---"
R=$(run_iez $IEZ ui wait --label "Sleep Tracker" --timeout 5)
assert_ok "$R" "Sleep Tracker heading"

R=$(run_iez $IEZ ui exists --label "Add Entry")
assert_ok "$R" "Add Entry FAB"
R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"

TOTAL=$((TOTAL + 1)); if tree_contains "March 20"; then PASS=$((PASS + 1)); echo "  ✓ March 20 entry"; else FAIL=$((FAIL + 1)); echo "  ✗ March 20 entry"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "March 19"; then PASS=$((PASS + 1)); echo "  ✓ March 19 entry"; else FAIL=$((FAIL + 1)); echo "  ✗ March 19 entry"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "March 18"; then PASS=$((PASS + 1)); echo "  ✓ March 18 entry"; else FAIL=$((FAIL + 1)); echo "  ✗ March 18 entry"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "March 17"; then PASS=$((PASS + 1)); echo "  ✓ March 17 entry"; else FAIL=$((FAIL + 1)); echo "  ✗ March 17 entry"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "March 16"; then PASS=$((PASS + 1)); echo "  ✓ March 16 entry"; else FAIL=$((FAIL + 1)); echo "  ✗ March 16 entry"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Good"; then PASS=$((PASS + 1)); echo "  ✓ Quality chip: Good"; else FAIL=$((FAIL + 1)); echo "  ✗ Quality chip: Good"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Excellent"; then PASS=$((PASS + 1)); echo "  ✓ Quality chip: Excellent"; else FAIL=$((FAIL + 1)); echo "  ✗ Quality chip: Excellent"; fi

screenshot "01_log"

echo "--- Sleep Detail ---"
# Tap March 20 entry (first in list)
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("March 20")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap March 20"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Sleep Details" --timeout 5)
assert_ok "$R" "Sleep Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "March 20"; then PASS=$((PASS + 1)); echo "  ✓ Date on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Date on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Duration"; then PASS=$((PASS + 1)); echo "  ✓ Duration section"; else FAIL=$((FAIL + 1)); echo "  ✗ Duration section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Quality"; then PASS=$((PASS + 1)); echo "  ✓ Quality section"; else FAIL=$((FAIL + 1)); echo "  ✗ Quality section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Bedtime"; then PASS=$((PASS + 1)); echo "  ✓ Bedtime info"; else FAIL=$((FAIL + 1)); echo "  ✗ Bedtime info"; fi

R=$(run_iez $IEZ ui exists --label "Delete Entry")
assert_ok "$R" "Delete Entry button"

screenshot "02_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Stats Tab ---"
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Stats tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "Stats"; then PASS=$((PASS + 1)); echo "  ✓ Stats header"; else FAIL=$((FAIL + 1)); echo "  ✗ Stats header"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Average Sleep"; then PASS=$((PASS + 1)); echo "  ✓ Average Sleep"; else FAIL=$((FAIL + 1)); echo "  ✗ Average Sleep"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Best Night"; then PASS=$((PASS + 1)); echo "  ✓ Best Night"; else FAIL=$((FAIL + 1)); echo "  ✗ Best Night"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Weekly Summary"; then PASS=$((PASS + 1)); echo "  ✓ Weekly Summary"; else FAIL=$((FAIL + 1)); echo "  ✗ Weekly Summary"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "5 nights logged"; then PASS=$((PASS + 1)); echo "  ✓ Nights logged count"; else FAIL=$((FAIL + 1)); echo "  ✗ Nights logged count"; fi

screenshot "03_stats"

echo "--- Settings Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Settings tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "Settings"; then PASS=$((PASS + 1)); echo "  ✓ Settings header"; else FAIL=$((FAIL + 1)); echo "  ✗ Settings header"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Sleep Reminders"; then PASS=$((PASS + 1)); echo "  ✓ Sleep Reminders switch"; else FAIL=$((FAIL + 1)); echo "  ✗ Sleep Reminders switch"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Dark Mode"; then PASS=$((PASS + 1)); echo "  ✓ Dark Mode switch"; else FAIL=$((FAIL + 1)); echo "  ✗ Dark Mode switch"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Track Naps"; then PASS=$((PASS + 1)); echo "  ✓ Track Naps switch"; else FAIL=$((FAIL + 1)); echo "  ✗ Track Naps switch"; fi

screenshot "04_settings"

echo "--- Search Page ---"
R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Entries" --timeout 5)
assert_ok "$R" "Search Entries heading"

R=$(run_iez $IEZ ui type "Excellent" --label "Search")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "March 19"; then PASS=$((PASS + 1)); echo "  ✓ Excellent result: March 19"; else FAIL=$((FAIL + 1)); echo "  ✗ Excellent result: March 19"; fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from search"
sleep 0.3

echo "--- Add Entry Page ---"
# Go to Log tab
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Log tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Add Entry")
assert_ok "$R" "Tap Add Entry FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Entry" --timeout 5)
assert_ok "$R" "Add Entry heading"

R=$(run_iez $IEZ ui exists --label "Date")
assert_ok "$R" "Date field"
R=$(run_iez $IEZ ui exists --label "Bedtime")
assert_ok "$R" "Bedtime field"
R=$(run_iez $IEZ ui exists --label "Wake Time")
assert_ok "$R" "Wake Time field"
R=$(run_iez $IEZ ui exists --label "Quality")
assert_ok "$R" "Quality dropdown"
R=$(run_iez $IEZ ui exists --label "Save Entry")
assert_ok "$R" "Save Entry button"

screenshot "05_add_entry"

# Save with defaults
R=$(run_iez $IEZ ui tap --label "Save Entry")
assert_ok "$R" "Tap Save Entry"
sleep 0.5

# Should be back on log with 6 entries now
TOTAL=$((TOTAL + 1)); if tree_contains "March 22"; then PASS=$((PASS + 1)); echo "  ✓ New entry in log"; else FAIL=$((FAIL + 1)); echo "  ✗ New entry in log"; fi

screenshot "06_after_add"

echo "--- Delete Entry ---"
# Tap new entry (March 22 should be first)
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("March 22")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap March 22 entry"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete Entry")
  assert_ok "$R" "Tap Delete Entry"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "March 22"; then PASS=$((PASS + 1)); echo "  ✓ March 22 deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ March 22 deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap March 22 entry (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Entry (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ March 22 deleted (skipped)"
fi

screenshot "07_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
