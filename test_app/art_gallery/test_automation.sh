#!/usr/bin/env bash
# test_automation.sh — ArtGallery (App 173)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.test.artGallery"
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
echo "=== ArtGallery Test Suite ==="
# =========================================

fresh_launch

echo "--- Gallery Tab (Home) ---"
R=$(run_iez $IEZ ui wait --label "Art Gallery" --timeout 5)
assert_ok "$R" "Art Gallery heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Starry Night"; then
  PASS=$((PASS + 1)); echo "  ✓ Starry Night artwork visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Starry Night artwork visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "The Persistence of Memory"; then
  PASS=$((PASS + 1)); echo "  ✓ The Persistence of Memory visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ The Persistence of Memory visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Girl with a Pearl Earring"; then
  PASS=$((PASS + 1)); echo "  ✓ Girl with a Pearl Earring visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Girl with a Pearl Earring visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Water Lilies"; then
  PASS=$((PASS + 1)); echo "  ✓ Water Lilies visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Water Lilies visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "The Great Wave"; then
  PASS=$((PASS + 1)); echo "  ✓ The Great Wave visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ The Great Wave visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "The Kiss"; then
  PASS=$((PASS + 1)); echo "  ✓ The Kiss visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ The Kiss visible"
fi

screenshot "01_gallery"

echo "--- Artwork Detail (Starry Night) ---"
# Starry Night card at y=130..374, x=12..195 — tap center
R=$(run_iez $IEZ ui tap --coords 103,252)
assert_ok "$R" "Tap Starry Night card"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Starry Night" --timeout 5)
assert_ok "$R" "Starry Night heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Van Gogh"; then
  PASS=$((PASS + 1)); echo "  ✓ Van Gogh artist name"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Van Gogh artist name"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Oil on Canvas"; then
  PASS=$((PASS + 1)); echo "  ✓ Medium: Oil on Canvas"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Medium: Oil on Canvas"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "1889"; then
  PASS=$((PASS + 1)); echo "  ✓ Year: 1889"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Year: 1889"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "73.7 cm x 92.1 cm"; then
  PASS=$((PASS + 1)); echo "  ✓ Dimensions"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Dimensions"
fi

screenshot "02_starry_night_detail"

echo "--- Favorite Toggle ---"
R=$(run_iez $IEZ ui tap --label "Favorite")
assert_ok "$R" "Tap Favorite button"
sleep 0.3

TOTAL=$((TOTAL + 1))
if has_label "Favorited"; then
  PASS=$((PASS + 1)); echo "  ✓ Favorited label after toggle"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Favorited label after toggle"
fi

screenshot "03_favorited"

# Toggle back
R=$(run_iez $IEZ ui tap --label "Favorited")
assert_ok "$R" "Tap Favorited to unfavorite"
sleep 0.3

TOTAL=$((TOTAL + 1))
if has_label "Favorite"; then
  PASS=$((PASS + 1)); echo "  ✓ Favorite label restored"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Favorite label restored"
fi

echo "--- Back to Gallery ---"
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Starry Night detail"
sleep 0.5

echo "--- Artists Tab ---"
R=$(run_iez $IEZ ui tap --coords 201,811)
assert_ok "$R" "Tap Artists tab"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Van Gogh"; then
  PASS=$((PASS + 1)); echo "  ✓ Van Gogh in artists list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Van Gogh in artists list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Dali"; then
  PASS=$((PASS + 1)); echo "  ✓ Dali in artists list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Dali in artists list"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Monet"; then
  PASS=$((PASS + 1)); echo "  ✓ Monet in artists list"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Monet in artists list"
fi

screenshot "04_artists_tab"

echo "--- Artist Profile (Van Gogh) ---"
R=$(run_iez $IEZ ui tap --coords 200,140)
assert_ok "$R" "Tap Van Gogh artist"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "Van Gogh" --timeout 5)
assert_ok "$R" "Van Gogh profile heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Post-Impressionism"; then
  PASS=$((PASS + 1)); echo "  ✓ Post-Impressionism style"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Post-Impressionism style"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Biography"; then
  PASS=$((PASS + 1)); echo "  ✓ Biography section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Biography section"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Artworks"; then
  PASS=$((PASS + 1)); echo "  ✓ Artworks section"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Artworks section"
fi

screenshot "05_van_gogh_profile"

echo "--- Back from Artist Profile ---"
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from Van Gogh profile"
sleep 0.5

echo "--- Exhibitions Tab ---"
R=$(run_iez $IEZ ui tap --coords 335,811)
assert_ok "$R" "Tap Exhibitions tab"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Impressionist Masters"; then
  PASS=$((PASS + 1)); echo "  ✓ Impressionist Masters exhibition"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Impressionist Masters exhibition"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Modern Visions"; then
  PASS=$((PASS + 1)); echo "  ✓ Modern Visions exhibition"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Modern Visions exhibition"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Main Hall"; then
  PASS=$((PASS + 1)); echo "  ✓ Main Hall location"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Main Hall location"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "East Wing"; then
  PASS=$((PASS + 1)); echo "  ✓ East Wing location"
else
  FAIL=$((FAIL + 1)); echo "  ✗ East Wing location"
fi

screenshot "06_exhibitions_tab"

echo "--- About Screen (via menu) ---"
R=$(run_iez $IEZ ui tap --label "Show menu")
assert_ok "$R" "Tap Show menu"
sleep 0.3

R=$(run_iez $IEZ ui tap --label "About")
assert_ok "$R" "Tap About menu item"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "About" --timeout 5)
assert_ok "$R" "About screen heading"

TOTAL=$((TOTAL + 1))
if tree_contains "info@artgallery.com"; then
  PASS=$((PASS + 1)); echo "  ✓ Email address visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Email address visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "(555) 123-4567"; then
  PASS=$((PASS + 1)); echo "  ✓ Phone number visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Phone number visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "123 Museum Drive"; then
  PASS=$((PASS + 1)); echo "  ✓ Address visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Address visible"
fi

screenshot "07_about"

R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "$R" "Back from About"
sleep 0.3

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
