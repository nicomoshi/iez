#!/usr/bin/env bash
# test_automation.sh — BookClub (App 175)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.iez.bookClub"
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
echo "=== BookClub Test Suite ==="
# =========================================

fresh_launch

echo "--- Home Screen (Book List) ---"
R=$(run_iez $IEZ ui wait --label "Book Club" --timeout 5)
assert_ok "$R" "Book Club heading"

TOTAL=$((TOTAL + 1))
if tree_contains "The Great Gatsby"; then
  PASS=$((PASS + 1)); echo "  ✓ The Great Gatsby visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ The Great Gatsby visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Dune"; then
  PASS=$((PASS + 1)); echo "  ✓ Dune visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Dune visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Sapiens"; then
  PASS=$((PASS + 1)); echo "  ✓ Sapiens visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Sapiens visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Gone Girl"; then
  PASS=$((PASS + 1)); echo "  ✓ Gone Girl visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Gone Girl visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Steve Jobs"; then
  PASS=$((PASS + 1)); echo "  ✓ Steve Jobs visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Steve Jobs visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Neuromancer"; then
  PASS=$((PASS + 1)); echo "  ✓ Neuromancer visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Neuromancer visible"
fi

R=$(run_iez $IEZ ui exists --label "Add Book")
assert_ok "$R" "Add Book FAB"

screenshot "01_home"

echo "--- Filter Chips ---"
R=$(run_iez $IEZ ui exists --label "All")
assert_ok "$R" "All filter chip"

R=$(run_iez $IEZ ui exists --label "Fiction")
assert_ok "$R" "Fiction filter chip"

R=$(run_iez $IEZ ui tap --label "Fiction")
assert_ok "$R" "Tap Fiction filter"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "The Great Gatsby"; then
  PASS=$((PASS + 1)); echo "  ✓ Great Gatsby in Fiction filter"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Great Gatsby in Fiction filter"
fi

screenshot "02_fiction_filter"

# Back to All
R=$(run_iez $IEZ ui tap --label "All")
assert_ok "$R" "Tap All filter"
sleep 0.3

echo "--- Book Detail (Dune) ---"
# Dune at y=262, full width — tap center
R=$(run_iez $IEZ ui tap --coords 200,302)
assert_ok "$R" "Tap Dune book"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Dune" --timeout 5)
assert_ok "$R" "Dune detail heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Frank Herbert"; then
  PASS=$((PASS + 1)); echo "  ✓ Frank Herbert author"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Frank Herbert author"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Sci-Fi"; then
  PASS=$((PASS + 1)); echo "  ✓ Sci-Fi genre chip"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Sci-Fi genre chip"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "250 of 412 pages read"; then
  PASS=$((PASS + 1)); echo "  ✓ Progress: 250 of 412 pages"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Progress: 250 of 412 pages"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Epic world-building"; then
  PASS=$((PASS + 1)); echo "  ✓ Review text visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Review text visible"
fi

R=$(run_iez $IEZ ui exists --label "Update Progress")
assert_ok "$R" "Update Progress button"

R=$(run_iez $IEZ ui exists --label "Mark Complete")
assert_ok "$R" "Mark Complete button"

screenshot "03_dune_detail"

echo "--- Mark Complete ---"
R=$(run_iez $IEZ ui tap --label "Mark Complete")
assert_ok "$R" "Tap Mark Complete"
sleep 0.3

TOTAL=$((TOTAL + 1))
if tree_contains "412 of 412 pages read"; then
  PASS=$((PASS + 1)); echo "  ✓ Dune marked 412/412"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Dune marked 412/412"
fi

screenshot "04_dune_completed"

echo "--- Back to Home ---"
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Dune detail"
sleep 0.5

echo "--- Genres Screen (via menu) ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap Show menu"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Genres")
assert_ok "$R" "Tap Genres menu"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Genres" --timeout 5)
assert_ok "$R" "Genres screen heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Fiction"; then
  PASS=$((PASS + 1)); echo "  ✓ Fiction genre listed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Fiction genre listed"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Mystery"; then
  PASS=$((PASS + 1)); echo "  ✓ Mystery genre listed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Mystery genre listed"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Biography"; then
  PASS=$((PASS + 1)); echo "  ✓ Biography genre listed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Biography genre listed"
fi

screenshot "05_genres"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Genres"
sleep 0.5

echo "--- Reading Stats (via menu) ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap Show menu again"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Reading Stats")
assert_ok "$R" "Tap Reading Stats"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Reading Stats" --timeout 5)
assert_ok "$R" "Reading Stats heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Total Books"; then
  PASS=$((PASS + 1)); echo "  ✓ Total Books stat"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Total Books stat"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Finished"; then
  PASS=$((PASS + 1)); echo "  ✓ Finished stat"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Finished stat"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Total Pages Read"; then
  PASS=$((PASS + 1)); echo "  ✓ Total Pages Read stat"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Total Pages Read stat"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Average Rating"; then
  PASS=$((PASS + 1)); echo "  ✓ Average Rating stat"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Average Rating stat"
fi

screenshot "06_reading_stats"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Reading Stats"
sleep 0.5

echo "--- Add Book Screen ---"
R=$(run_iez $IEZ ui tap --label "Add Book")
assert_ok "$R" "Tap Add Book FAB"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Add Book" --timeout 5)
assert_ok "$R" "Add Book screen heading"

R=$(run_iez $IEZ ui exists --label "Book Title")
assert_ok "$R" "Book Title field"

R=$(run_iez $IEZ ui exists --label "Author")
assert_ok "$R" "Author field"

R=$(run_iez $IEZ ui exists --label "Total Pages")
assert_ok "$R" "Total Pages field"

R=$(run_iez $IEZ ui exists --label "Genre")
assert_ok "$R" "Genre dropdown"

screenshot "07_add_book"

echo "--- Fill Add Book Form ---"
R=$(run_iez $IEZ ui type "The Hobbit" --label "Book Title")
assert_ok "$R" "Type book title"

R=$(run_iez $IEZ ui type "J.R.R. Tolkien" --label "Author")
assert_ok "$R" "Type author"

R=$(run_iez $IEZ ui type "310" --label "Total Pages")
assert_ok "$R" "Type total pages"

screenshot "08_form_filled"

echo "--- Submit New Book ---"
# Scroll down to see Add Book button
R=$(run_iez $IEZ ui swipe up)
assert_ok "$R" "Swipe up to reveal submit"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Add Book")
assert_ok "$R" "Tap Add Book submit"
sleep 0.5

# Should be back on home with new book
TOTAL=$((TOTAL + 1))
if tree_contains "The Hobbit"; then
  PASS=$((PASS + 1)); echo "  ✓ The Hobbit added to list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ The Hobbit added to list"
fi

screenshot "09_book_added"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
