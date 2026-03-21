#!/bin/bash
# Test automation for Apps 92-94: MusicPlayer, UnitConverter, PhotoGallery
set -euo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null)
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

has_label() {
  local result
  result=$(run_iez "$IEZ" ui exists --label "$1" | jq -r '.ok' 2>/dev/null || echo "false")
  [ "$result" = "true" ]
}

assert_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc (label '$label' not found)"
  fi
}

TREE_CACHE=""
refresh_tree() {
  TREE_CACHE=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[].label' 2>/dev/null || true)
}

tree_has() {
  echo "$TREE_CACHE" | grep -qF -- "$1" 2>/dev/null
}

assert_tree_has() {
  local desc="$1" substr="$2"
  TOTAL=$((TOTAL + 1))
  if tree_has "$substr"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc ('$substr' not in tree)"
  fi
}

# ============================================================
echo "=== App 92: MusicPlayer ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.musicPlayer 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.unitConverter 2>/dev/null || true
xcrun simctl terminate "$DEVICE_ID" com.test.photoGallery 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.musicPlayer
sleep 2

echo "--- Library Tab ---"
refresh_tree
assert_tree_has "My Music heading" "My Music"
assert_tree_has "Sunset Drive" "Sunset Drive"
assert_tree_has "Midnight Jazz" "Midnight Jazz"
assert_tree_has "Electric Dreams" "Electric Dreams"
assert_tree_has "Mountain High" "Mountain High"
assert_tree_has "Urban Groove" "Urban Groove"
assert_tree_has "Ocean Calm" "Ocean Calm"
assert_tree_has "The Waves artist" "The Waves"
assert_label "Library tab" $'Library\nTab 1 of 2'
assert_label "Playlists tab" $'Playlists\nTab 2 of 2'

echo "--- Now Playing ---"
# Tap first song (Sunset Drive)
R=$(run_iez "$IEZ" ui tap --coords 201,154)
assert_ok "Open Sunset Drive" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Now Playing heading" "Now Playing"
assert_tree_has "Song title" "Sunset Drive"
assert_tree_has "Artist name" "The Waves"
assert_label "Play button" "Play"
assert_label "Skip Previous" "Skip Previous"
assert_label "Skip Next" "Skip Next"
assert_label "Repeat button" "Repeat"
assert_label "Shuffle button" "Shuffle"
assert_label "Add to Playlist" "Add to Playlist"
assert_tree_has "Time start" "0:00"
assert_tree_has "Time end" "4:00"

# Play/Pause toggle
R=$(run_iez "$IEZ" ui tap --label "Play")
assert_ok "Tap Play" "$R"
sleep 0.3

assert_label "Pause shown" "Pause"

R=$(run_iez "$IEZ" ui tap --label "Pause")
assert_ok "Tap Pause" "$R"
sleep 0.3

# Skip next (button exists but no-op in this app)
R=$(run_iez "$IEZ" ui tap --label "Skip Next")
assert_ok "Tap Skip Next" "$R"
sleep 0.3

# Back
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to library" "$R"
sleep 0.3

echo "--- Playlists Tab ---"
R=$(run_iez "$IEZ" ui tap --label $'Playlists\nTab 2 of 2')
assert_ok "Switch to Playlists" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Playlists heading" "Playlists"
assert_tree_has "Favorites playlist" "Favorites"
assert_tree_has "Workout playlist" "Workout"
assert_tree_has "3 songs" "3 songs"
assert_tree_has "2 songs" "2 songs"

echo ""
echo "App 92 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "=== App 93: UnitConverter ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.musicPlayer 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.unitConverter
sleep 2

echo "--- Initial State ---"
refresh_tree
assert_tree_has "App heading" "Unit Converter"
assert_label "Length chip" "Length"
assert_label "Weight chip" "Weight"
assert_label "Temperature chip" "Temperature"
assert_label "Volume chip" "Volume"
assert_label "Enter value field" "Enter value"
assert_tree_has "From dropdown" "From"
assert_tree_has "To dropdown" "To"
assert_label "Swap button" "Swap"
assert_tree_has "Result placeholder" "Result"
assert_label "Clear History" "Clear History"

echo "--- Length Conversion ---"
R=$(run_iez "$IEZ" ui type "100" --label "Enter value")
assert_ok "Type 100" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Result shows feet" "328.084"
assert_tree_has "History entry" "100 Meters"

echo "--- Swap Units ---"
R=$(run_iez "$IEZ" ui tap --label "Swap")
assert_ok "Swap units" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Swapped From" "Feet"
assert_tree_has "Swapped To" "Meters"

echo "--- Switch Category ---"
R=$(run_iez "$IEZ" ui tap --label "Weight")
assert_ok "Switch to Weight" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Weight units" "Kilograms"

R=$(run_iez "$IEZ" ui tap --label "Temperature")
assert_ok "Switch to Temperature" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Temp units" "Celsius"

echo "--- Clear History ---"
R=$(run_iez "$IEZ" ui tap --label "Clear History")
assert_ok "Clear history" "$R"
sleep 0.3

refresh_tree
assert_tree_has "History cleared" "No conversions yet"

echo ""
echo "App 93 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "=== App 94: PhotoGallery ==="
# ============================================================

xcrun simctl terminate "$DEVICE_ID" com.test.unitConverter 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" com.test.photoGallery
sleep 2

echo "--- Photos Tab ---"
refresh_tree
assert_tree_has "Gallery heading" "Gallery"
assert_label "All filter" "All"
assert_label "Nature filter" "Nature"
assert_label "Urban filter" "Urban"
assert_label "People filter" "People"
assert_tree_has "Photo 1" "Photo 1"
assert_tree_has "Photo 2" "Photo 2"
assert_tree_has "Photo 3" "Photo 3"
assert_label "Add Photo FAB" "Add Photo"
assert_label "Photos tab" $'Photos\nTab 1 of 2'
assert_label "Albums tab" $'Albums\nTab 2 of 2'

echo "--- Filter ---"
R=$(run_iez "$IEZ" ui tap --label "Nature")
assert_ok "Filter by Nature" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Nature photos visible" "Photo"

R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Reset to All" "$R"
sleep 0.3

echo "--- Photo Detail ---"
# Tap Photo 1 (first grid cell)
R=$(run_iez "$IEZ" ui tap --coords 67,225)
assert_ok "Open Photo 1" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Photo 1 heading" "Photo 1"
assert_label "Like button" "Like"
assert_label "Share button" "Share"
assert_label "Delete button" "Delete"
assert_label "More options" "More options"
assert_label "Back button" "Back"

R=$(run_iez "$IEZ" ui tap --label "Like")
assert_ok "Like photo" "$R"
sleep 0.2

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to gallery" "$R"
sleep 0.5

echo "--- Add Photo Dialog ---"
R=$(run_iez "$IEZ" ui tap --label "Add Photo")
assert_ok "Open Add Photo" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Add Photo title" "Add Photo"
assert_label "Title field" "Title"
assert_tree_has "Category dropdown" "Category"
assert_label "Cancel button" "Cancel"
assert_label "Add button" "Add"

R=$(run_iez "$IEZ" ui type "Test 123" --label "Title")
assert_ok "Type photo title" "$R"
sleep 0.3

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Add photo (dismiss dialog)" "$R"
sleep 0.5

echo "--- Albums Tab ---"
R=$(run_iez "$IEZ" ui tap --label $'Albums\nTab 2 of 2')
assert_ok "Switch to Albums" "$R"
sleep 0.5

refresh_tree
assert_tree_has "Albums heading" "Albums"
assert_tree_has "Nature album" "Nature"
assert_tree_has "Urban album" "Urban"
assert_tree_has "People album" "People"
assert_tree_has "5 photos" "5 photos"

echo ""
echo "App 94 subtotal: $PASS/$TOTAL"
echo ""

# ============================================================
echo "========================================"
echo "TOTAL: $PASS passed, $FAIL failed, $TOTAL total"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
