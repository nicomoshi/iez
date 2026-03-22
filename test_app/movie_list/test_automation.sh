#!/usr/bin/env bash
# test_automation.sh — MovieList (App 167)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.movieList"
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

echo "=== MovieList Test Suite ==="
fresh_launch

echo "--- Watchlist Tab ---"
R=$(run_iez $IEZ ui wait --label "MovieList" --timeout 5)
assert_ok "$R" "MovieList heading"

R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"
R=$(run_iez $IEZ ui exists --label "Sci-Fi")
assert_ok "$R" "Sci-Fi filter chip"
R=$(run_iez $IEZ ui exists --label "Thriller")
assert_ok "$R" "Thriller filter chip"
R=$(run_iez $IEZ ui exists --label "Animation")
assert_ok "$R" "Animation filter chip"
R=$(run_iez $IEZ ui exists --label "Search")
assert_ok "$R" "Search button"
R=$(run_iez $IEZ ui exists --label "Add Movie")
assert_ok "$R" "Add Movie FAB"

TOTAL=$((TOTAL + 1)); if tree_contains "Inception"; then PASS=$((PASS + 1)); echo "  ✓ Inception"; else FAIL=$((FAIL + 1)); echo "  ✗ Inception"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "The Matrix"; then PASS=$((PASS + 1)); echo "  ✓ The Matrix"; else FAIL=$((FAIL + 1)); echo "  ✗ The Matrix"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Parasite"; then PASS=$((PASS + 1)); echo "  ✓ Parasite"; else FAIL=$((FAIL + 1)); echo "  ✗ Parasite"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Spirited Away"; then PASS=$((PASS + 1)); echo "  ✓ Spirited Away"; else FAIL=$((FAIL + 1)); echo "  ✗ Spirited Away"; fi

screenshot "01_watchlist"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui tap --label "Sci-Fi")
assert_ok "$R" "Tap Sci-Fi filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "Inception"; then PASS=$((PASS + 1)); echo "  ✓ Inception after Sci-Fi"; else FAIL=$((FAIL + 1)); echo "  ✗ Inception after Sci-Fi"; fi
TOTAL=$((TOTAL + 1)); if ! tree_contains "Parasite"; then PASS=$((PASS + 1)); echo "  ✓ Parasite hidden"; else FAIL=$((FAIL + 1)); echo "  ✗ Parasite hidden"; fi

R=$(run_iez $IEZ ui tap --label "Animation")
assert_ok "$R" "Tap Animation filter"
sleep 0.3
TOTAL=$((TOTAL + 1)); if tree_contains "Spirited Away"; then PASS=$((PASS + 1)); echo "  ✓ Spirited Away after Animation"; else FAIL=$((FAIL + 1)); echo "  ✗ Spirited Away after Animation"; fi

R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All to reset"
sleep 0.3

echo "--- Movie Detail ---"
# Tap Inception (first movie in list)
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Inception")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
R=$(run_iez $IEZ ui tap --coords "$COORDS")
assert_ok "$R" "Tap Inception"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Movie Details" --timeout 5)
assert_ok "$R" "Movie Details heading"

TOTAL=$((TOTAL + 1)); if tree_contains "Inception"; then PASS=$((PASS + 1)); echo "  ✓ Title on detail"; else FAIL=$((FAIL + 1)); echo "  ✗ Title on detail"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Sci-Fi"; then PASS=$((PASS + 1)); echo "  ✓ Genre"; else FAIL=$((FAIL + 1)); echo "  ✗ Genre"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "2010"; then PASS=$((PASS + 1)); echo "  ✓ Year"; else FAIL=$((FAIL + 1)); echo "  ✗ Year"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "4.5/5.0"; then PASS=$((PASS + 1)); echo "  ✓ Rating"; else FAIL=$((FAIL + 1)); echo "  ✗ Rating"; fi

R=$(run_iez $IEZ ui exists --label "Delete Movie")
assert_ok "$R" "Delete Movie button"

screenshot "02_detail"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from detail"
sleep 0.3

echo "--- Watched Tab ---"
R=$(run_iez $IEZ ui tap --coords 200,800)
assert_ok "$R" "Tap Watched tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "The Godfather"; then PASS=$((PASS + 1)); echo "  ✓ The Godfather"; else FAIL=$((FAIL + 1)); echo "  ✗ The Godfather"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Pulp Fiction"; then PASS=$((PASS + 1)); echo "  ✓ Pulp Fiction"; else FAIL=$((FAIL + 1)); echo "  ✗ Pulp Fiction"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Watched"; then PASS=$((PASS + 1)); echo "  ✓ Watched section header"; else FAIL=$((FAIL + 1)); echo "  ✗ Watched section header"; fi

screenshot "03_watched"

echo "--- Discover Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,800)
assert_ok "$R" "Tap Discover tab"
sleep 0.3

TOTAL=$((TOTAL + 1)); if tree_contains "Discover"; then PASS=$((PASS + 1)); echo "  ✓ Discover header"; else FAIL=$((FAIL + 1)); echo "  ✗ Discover header"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Trending"; then PASS=$((PASS + 1)); echo "  ✓ Trending section"; else FAIL=$((FAIL + 1)); echo "  ✗ Trending section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Top Rated"; then PASS=$((PASS + 1)); echo "  ✓ Top Rated section"; else FAIL=$((FAIL + 1)); echo "  ✗ Top Rated section"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "Oppenheimer"; then PASS=$((PASS + 1)); echo "  ✓ Oppenheimer card"; else FAIL=$((FAIL + 1)); echo "  ✗ Oppenheimer card"; fi
TOTAL=$((TOTAL + 1)); if tree_contains "The Dark Knight"; then PASS=$((PASS + 1)); echo "  ✓ The Dark Knight card"; else FAIL=$((FAIL + 1)); echo "  ✗ The Dark Knight card"; fi

screenshot "04_discover"

echo "--- Search Page ---"
R=$(run_iez $IEZ ui tap --label "Search")
assert_ok "$R" "Tap Search"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Search Movies" --timeout 5)
assert_ok "$R" "Search Movies heading"

R=$(run_iez $IEZ ui type "matrix" --label "Search Movies")
assert_ok "$R" "Type search query"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "The Matrix"; then PASS=$((PASS + 1)); echo "  ✓ Matrix in results"; else FAIL=$((FAIL + 1)); echo "  ✗ Matrix in results"; fi

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from search"
sleep 0.3

echo "--- Add Movie ---"
# Go to Watchlist tab first
R=$(run_iez $IEZ ui tap --coords 67,800)
assert_ok "$R" "Tap Watchlist tab"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Add Movie")
assert_ok "$R" "Tap Add Movie FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Movie" --timeout 5)
assert_ok "$R" "Add Movie heading"

R=$(run_iez $IEZ ui exists --label "Movie Title")
assert_ok "$R" "Movie Title field"
R=$(run_iez $IEZ ui exists --label "Genre")
assert_ok "$R" "Genre dropdown"
R=$(run_iez $IEZ ui exists --label "Year")
assert_ok "$R" "Year field"
R=$(run_iez $IEZ ui exists --label "Save Movie")
assert_ok "$R" "Save Movie button"

screenshot "05_add_movie"

R=$(run_iez $IEZ ui type "Test Film" --label "Movie Title")
assert_ok "$R" "Type movie title"

R=$(run_iez $IEZ ui tap --label "Save Movie")
assert_ok "$R" "Tap Save Movie"
sleep 0.5

TOTAL=$((TOTAL + 1)); if tree_contains "Test Film"; then PASS=$((PASS + 1)); echo "  ✓ New movie in list"; else FAIL=$((FAIL + 1)); echo "  ✗ New movie in list"; fi

screenshot "06_after_add"

echo "--- Delete Movie ---"
COORDS=$($IEZ ui tree --compact 2>/dev/null | sed -n '/^{/,/^}/p' | jq -r '.data.elements[] | select(.label | contains("Test Film")) | "\(.frame.x + .frame.width/2),\(.frame.y + .frame.height/2)"' 2>/dev/null | head -1)
if [ -n "$COORDS" ]; then
  R=$(run_iez $IEZ ui tap --coords "$COORDS")
  assert_ok "$R" "Tap Test Film"
  sleep 0.5
  R=$(run_iez $IEZ ui tap --label "Delete Movie")
  assert_ok "$R" "Tap Delete Movie"
  sleep 0.5
  TOTAL=$((TOTAL + 1)); if ! tree_contains "Test Film"; then PASS=$((PASS + 1)); echo "  ✓ Test Film deleted"; else FAIL=$((FAIL + 1)); echo "  ✗ Test Film deleted"; fi
else
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Test Film (no coords)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Tap Delete Movie (skipped)"
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  ✗ Test Film deleted (skipped)"
fi

screenshot "07_after_delete"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
