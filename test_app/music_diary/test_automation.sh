#!/usr/bin/env bash
# test_automation.sh — MusicDiary (App 169)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.musicDiary"
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

echo "=== MusicDiary Test Suite ==="
fresh_launch

echo "--- Albums Tab ---"
R=$(run_iez $IEZ ui wait --label "Music Diary" --timeout 5)
assert_ok "$R" "Music Diary heading"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"
R=$(run_iez $IEZ ui exists --label "Rock")
assert_ok "$R" "Rock filter chip"
R=$(run_iez $IEZ ui exists --label "Jazz")
assert_ok "$R" "Jazz filter chip"
R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"
R=$(run_iez $IEZ ui exists --label "Add Album")
assert_ok "$R" "Add Album FAB"

TOTAL=$((TOTAL + 1)); if tree_contains "OK Computer"; then PASS=$((PASS + 1)); echo "  ✓ OK Computer"; else FAIL=$((FAIL + 1)); echo "  ✗ OK Computer"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Kind of Blue"; then PASS=$((PASS + 1)); echo "  ✓ Kind of Blue"; else FAIL=$((FAIL + 1)); echo "  ✗ Kind of Blue"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Random Access Memories"; then PASS=$((PASS + 1)); echo "  ✓ Random Access Memories"; else FAIL=$((FAIL + 1)); echo "  ✗ Random Access Memories"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "folklore"; then PASS=$((PASS + 1)); echo "  ✓ folklore"; else FAIL=$((FAIL + 1)); echo "  ✗ folklore"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "To Pimp a Butterfly"; then PASS=$((PASS + 1)); echo "  ✓ To Pimp a Butterfly"; else FAIL=$((FAIL + 1)); echo "  ✗ To Pimp a Butterfly"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Goldberg Variations"; then PASS=$((PASS + 1)); echo "  ✓ Goldberg Variations"; else FAIL=$((FAIL + 1)); echo "  ✗ Goldberg Variations"; fi

screenshot "01_albums"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Rock")
assert_ok "$R" "Tap Rock filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "OK Computer"; then PASS=$((PASS + 1)); echo "  ✓ OK Computer after Rock filter"; else FAIL=$((FAIL + 1)); echo "  ✗ OK Computer after Rock filter"; fi
TOTAL=$((TOTAL + 1)); if ! tree_contains "Kind of Blue"; then PASS=$((PASS + 1)); echo "  ✓ Kind of Blue hidden"; else FAIL=$((FAIL + 1)); echo "  ✗ Kind of Blue hidden"; fi

R=$(run_iez $IEZ ui tap --label "Jazz")
assert_ok "$R" "Tap Jazz filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "Kind of Blue"; then PASS=$((PASS + 1)); echo "  ✓ Kind of Blue after Jazz filter"; else FAIL=$((FAIL + 1)); echo "  ✗ Kind of Blue after Jazz filter"; fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All to reset"
sleep 0.3

echo "--- Album Detail ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("OK Computer")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap OK Computer"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Album Details" --timeout 5)
assert_ok "$R" "Album Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "OK Computer"; then PASS=$((PASS + 1)); echo "  ✓ Title on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Title on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Radiohead"; then PASS=$((PASS + 1)); echo "  ✓ Artist"; else FAIL=$((FAIL + 1)); echo "  ✗ Artist"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Rock"; then PASS=$((PASS + 1)); echo "  ✓ Genre chip"; else FAIL=$((FAIL + 1)); echo "  ✗ Genre chip"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Thoughts"; then PASS=$((PASS + 1)); echo "  ✓ Thoughts section"; else FAIL=$((FAIL + 1)); echo "  ✗ Thoughts section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "masterpiece"; then PASS=$((PASS + 1)); echo "  ✓ Thoughts content"; else FAIL=$((FAIL + 1)); echo "  ✗ Thoughts content"; fi

R=$(run_iez $IEZ ui exists --label "Unlike")
assert_ok "$R" "Unlike button (pre-liked)"

R=$(run_iez $IEZ ui exists --label "Delete")
assert_ok "$R" "Delete button"

screenshot "02_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Liked Tab ---"
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Liked tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Liked Albums" --timeout 5)
assert_ok "$R" "Liked Albums heading"

TOTAL=$((TOTAL + 1)); if tree_contains "OK Computer"; then PASS=$((PASS + 1)); echo "  ✓ OK Computer in liked"; else FAIL=$((FAIL + 1)); echo "  ✗ OK Computer in liked"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Kind of Blue"; then PASS=$((PASS + 1)); echo "  ✓ Kind of Blue in liked"; else FAIL=$((FAIL + 1)); echo "  ✗ Kind of Blue in liked"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "To Pimp a Butterfly"; then PASS=$((PASS + 1)); echo "  ✓ To Pimp a Butterfly in liked"; else FAIL=$((FAIL + 1)); echo "  ✗ To Pimp a Butterfly in liked"; fi

screenshot "03_liked"

echo "--- Stats Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Stats tab"
sleep 0.3

R=$(run_iez $IEZ ui wait --label "Stats" --timeout 5)
assert_ok "$R" "Stats heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Total Albums"; then PASS=$((PASS + 1)); echo "  ✓ Total Albums"; else FAIL=$((FAIL + 1)); echo "  ✗ Total Albums"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Liked"; then PASS=$((PASS + 1)); echo "  ✓ Liked count"; else FAIL=$((FAIL + 1)); echo "  ✗ Liked count"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Average Rating"; then PASS=$((PASS + 1)); echo "  ✓ Average Rating"; else FAIL=$((FAIL + 1)); echo "  ✗ Average Rating"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "By Genre"; then PASS=$((PASS + 1)); echo "  ✓ By Genre section"; else FAIL=$((FAIL + 1)); echo "  ✗ By Genre section"; fi

screenshot "04_stats"

echo "--- Search Page ---"
# Go to Albums tab first
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Albums tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Albums" --timeout 5)
assert_ok "$R" "Search Albums heading"

R=$(run_iez $IEZ ui type "daft" --label "Search")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Random Access Memories"; then PASS=$((PASS + 1)); echo "  ✓ Search result: RAM"; else FAIL=$((FAIL + 1)); echo "  ✗ Search result: RAM"; fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from search"
sleep 0.3

echo "--- Add Album Page ---"
R=$(run_iez $IEZ ui tap --label "Add Album")
assert_ok "$R" "Tap Add Album FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Album" --timeout 5)
assert_ok "$R" "Add Album heading"

R=$(run_iez $IEZ ui exists --label "Album Title")
assert_ok "$R" "Album Title field"
R=$(run_iez $IEZ ui exists --label "Artist")
assert_ok "$R" "Artist field"
R=$(run_iez $IEZ ui exists --label "Year")
assert_ok "$R" "Year field"
R=$(run_iez $IEZ ui exists --label "Genre")
assert_ok "$R" "Genre dropdown"
R=$(run_iez $IEZ ui exists --label "Save Album")
assert_ok "$R" "Save Album button"

screenshot "05_add_album"

R=$(run_iez $IEZ ui type "Test Album" --label "Album Title")
assert_ok "$R" "Type album title"
R=$(run_iez $IEZ ui type "Test Artist" --label "Artist")
assert_ok "$R" "Type artist"

R=$(run_iez $IEZ ui tap --label "Save Album")
assert_ok "$R" "Tap Save Album"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Test Album"; then PASS=$((PASS + 1)); echo "  ✓ New album in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New album in list"; fi

screenshot "06_after_add"

echo "--- Delete Album ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Album")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test Album"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete")
  assert_ok "$R" "Tap Delete"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "Test Album"; then PASS=$((PASS + 1)); echo "  ✓ Test Album deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ Test Album deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Album (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Album deleted (skipped)"
fi

screenshot "07_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
