#!/usr/bin/env bash
# test_automation.sh — QuoteWall (App 172)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.quoteWall"
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

echo "=== QuoteWall Test Suite ==="
fresh_launch

echo "--- Quotes Tab ---"
R=$(run_iez $IEZ ui wait --label "QuoteWall" --timeout 5)
assert_ok "$R" "QuoteWall heading"

R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"
R=$(run_iez $IEZ ui exists --label "Add Quote")
assert_ok "$R" "Add Quote FAB"

TOTAL=$((TOTAL + 1)); if tree_contains "The only way to do great work"; then PASS=$((PASS + 1)); echo "  ✓ Jobs quote 1"; else FAIL=$((FAIL + 1)); echo "  ✗ Jobs quote 1"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Be yourself"; then PASS=$((PASS + 1)); echo "  ✓ Wilde quote"; else FAIL=$((FAIL + 1)); echo "  ✗ Wilde quote"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "difficulty lies opportunity"; then PASS=$((PASS + 1)); echo "  ✓ Einstein quote"; else FAIL=$((FAIL + 1)); echo "  ✗ Einstein quote"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Stay hungry"; then PASS=$((PASS + 1)); echo "  ✓ Jobs quote 2"; else FAIL=$((FAIL + 1)); echo "  ✗ Jobs quote 2"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Steve Jobs"; then PASS=$((PASS + 1)); echo "  ✓ Steve Jobs author"; else FAIL=$((FAIL + 1)); echo "  ✗ Steve Jobs author"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Oscar Wilde"; then PASS=$((PASS + 1)); echo "  ✓ Oscar Wilde author"; else FAIL=$((FAIL + 1)); echo "  ✗ Oscar Wilde author"; fi

screenshot "01_quotes"

echo "--- Quote Detail ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Be yourself")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap Wilde quote"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Quote Details" --timeout 5)
assert_ok "$R" "Quote Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Be yourself"; then PASS=$((PASS + 1)); echo "  ✓ Quote text on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Quote text on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Oscar Wilde"; then PASS=$((PASS + 1)); echo "  ✓ Author on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Author on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Source"; then PASS=$((PASS + 1)); echo "  ✓ Source section"; else FAIL=$((FAIL + 1)); echo "  ✗ Source section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Tags"; then PASS=$((PASS + 1)); echo "  ✓ Tags section"; else FAIL=$((FAIL + 1)); echo "  ✗ Tags section"; fi

R=$(run_iez $IEZ ui exists --label "Delete Quote")
assert_ok "$R" "Delete Quote button"

screenshot "02_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Authors Tab ---"
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Authors tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "Authors"; then PASS=$((PASS + 1)); echo "  ✓ Authors header"; else FAIL=$((FAIL + 1)); echo "  ✗ Authors header"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Steve Jobs"; then PASS=$((PASS + 1)); echo "  ✓ Steve Jobs in authors"; else FAIL=$((FAIL + 1)); echo "  ✗ Steve Jobs in authors"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Oscar Wilde"; then PASS=$((PASS + 1)); echo "  ✓ Oscar Wilde in authors"; else FAIL=$((FAIL + 1)); echo "  ✗ Oscar Wilde in authors"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Albert Einstein"; then PASS=$((PASS + 1)); echo "  ✓ Albert Einstein in authors"; else FAIL=$((FAIL + 1)); echo "  ✗ Albert Einstein in authors"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "2 quotes"; then PASS=$((PASS + 1)); echo "  ✓ Quote count for Jobs"; else FAIL=$((FAIL + 1)); echo "  ✗ Quote count for Jobs"; fi

screenshot "03_authors"

echo "--- Tags Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Tags tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "Tags"; then PASS=$((PASS + 1)); echo "  ✓ Tags header"; else FAIL=$((FAIL + 1)); echo "  ✗ Tags header"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Inspiration"; then PASS=$((PASS + 1)); echo "  ✓ Inspiration tag"; else FAIL=$((FAIL + 1)); echo "  ✗ Inspiration tag"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Wisdom"; then PASS=$((PASS + 1)); echo "  ✓ Wisdom tag"; else FAIL=$((FAIL + 1)); echo "  ✗ Wisdom tag"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Life"; then PASS=$((PASS + 1)); echo "  ✓ Life tag"; else FAIL=$((FAIL + 1)); echo "  ✗ Life tag"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Success"; then PASS=$((PASS + 1)); echo "  ✓ Success tag"; else FAIL=$((FAIL + 1)); echo "  ✗ Success tag"; fi

screenshot "04_tags"

echo "--- Search Page ---"
R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Quotes" --timeout 5)
assert_ok "$R" "Search Quotes heading"

R=$(run_iez $IEZ ui type "einstein" --label "Search")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "difficulty lies opportunity"; then PASS=$((PASS + 1)); echo "  ✓ Einstein search result"; else FAIL=$((FAIL + 1)); echo "  ✗ Einstein search result"; fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from search"
sleep 0.3

echo "--- Add Quote ---"
# Go to Quotes tab
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Quotes tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Add Quote")
assert_ok "$R" "Tap Add Quote FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Quote" --timeout 5)
assert_ok "$R" "Add Quote heading"

R=$(run_iez $IEZ ui exists --label "Quote Text")
assert_ok "$R" "Quote Text field"
R=$(run_iez $IEZ ui exists --label "Author")
assert_ok "$R" "Author field"
R=$(run_iez $IEZ ui exists --label "Source")
assert_ok "$R" "Source field"
R=$(run_iez $IEZ ui exists --label "Save Quote")
assert_ok "$R" "Save Quote button"

R=$(run_iez $IEZ ui type "Test quote text" --label "Quote Text")
assert_ok "$R" "Type quote"
R=$(run_iez $IEZ ui type "Test Author" --label "Author")
assert_ok "$R" "Type author"

R=$(run_iez $IEZ ui tap --label "Save Quote")
assert_ok "$R" "Tap Save Quote"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Test quote text"; then PASS=$((PASS + 1)); echo "  ✓ New quote in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New quote in list"; fi

screenshot "05_after_add"

echo "--- Delete Quote ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test quote text")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test quote"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete Quote")
  assert_ok "$R" "Tap Delete Quote"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "Test quote text"; then PASS=$((PASS + 1)); echo "  ✓ Test quote deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ Test quote deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test quote (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Quote (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test quote deleted (skipped)"
fi

screenshot "06_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
