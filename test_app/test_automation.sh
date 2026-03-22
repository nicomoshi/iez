#!/bin/bash
# Test automation for Apps 155-157: TimeCapsule/SketchPad/GiftTracker
set -uo pipefail

IEZ="/Users/rudy/Developer/i_ez/bin/iez"
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0; TOTAL=0

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p' || true; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok
  ok=$(echo "$result" | jq -r '.ok // false' 2>/dev/null || echo "false")
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
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

kill_runners() {
  local pids
  pids=$(ps aux 2>/dev/null | grep "CoreSimulator/Devices.*Runner.app/Runner" | grep -v grep | awk '{print $2}') || true
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 2
  fi
}

fresh_launch() {
  local bid="$1" app_path="$2" expected="$3"
  xcrun simctl terminate "$DEVICE_ID" com.iez.timeCapsule 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.sketchPad 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.giftTracker 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.iez.timeCapsule 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.sketchPad 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.giftTracker 2>/dev/null || true
  sleep 1
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 1
  xcrun simctl launch "$DEVICE_ID" "$bid"
  local app_name
  for _ in 1 2 3 4 5 6 7 8; do
    sleep 2
    app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || echo "")
    if [ "$app_name" = "$expected" ]; then
      echo "  ✔ $expected is in foreground"
      return 0
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

# ============================================================
echo "=== App 155: TimeCapsule ==="
# ============================================================

fresh_launch "com.iez.timeCapsule" "$SCRIPT_DIR/time_capsule/build/ios/iphonesimulator/Runner.app" "Time Capsule"
sleep 2

echo "--- Capsules screen ---"
refresh_tree
assert_tree_has "App heading" "TimeCapsule"
assert_tree_has "College Memories capsule" "College Memories"
assert_tree_has "New Year Goals capsule" "New Year Goals"
assert_tree_has "Birthday Letter capsule" "Birthday Letter"
assert_tree_has "Create Capsule FAB" "Create Capsule"

echo "--- Tab bar ---"
assert_tree_has "Capsules tab" "Capsules"
assert_tree_has "Opened tab" "Opened"
assert_tree_has "Timeline tab" "Timeline"

echo "--- Tap capsule detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,170)
assert_ok "Tap College Memories" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Capsule Details title" "Capsule Details"
assert_tree_has "Status section" "Status"
assert_tree_has "Sealed status" "Sealed"
assert_tree_has "Opens On section" "Opens On"
assert_tree_has "Items section" "Items"
assert_tree_has "Delete Capsule button" "Delete Capsule"

echo "--- Back to capsules ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to capsules" "$R"
sleep 1

echo "--- Tap Opened tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Opened tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Opened heading" "Opened"
assert_tree_has "High School Photos" "High School Photos"
assert_tree_has "Time Capsule 2020" "Time Capsule 2020"

echo "--- Tap Timeline tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Timeline tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Timeline heading" "Timeline"
assert_tree_has "2025 section" "2025"
assert_tree_has "2024 section" "2024"

echo "--- Back to Capsules tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Capsules tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Capsules"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Create Capsule ---"
R=$(run_iez "$IEZ" ui tap --label "Create Capsule")
assert_ok "Tap Create Capsule FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Create Capsule page" "Create Capsule"
assert_tree_has "Capsule Name field" "Capsule Name"
assert_tree_has "Open Date field" "Open Date"
assert_tree_has "Message field" "Message"
assert_tree_has "Save Capsule button" "Save Capsule"

echo "--- Fill capsule form ---"
R=$(run_iez "$IEZ" ui type "Test Capsule" --label "Capsule Name")
assert_ok "Type capsule name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "Dec 2030" --label "Open Date")
assert_ok "Type open date" "$R"
sleep 0.5

echo "--- Submit capsule ---"
R=$(run_iez "$IEZ" ui tap --label "Save Capsule")
assert_ok "Tap Save Capsule" "$R"
sleep 1.5

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app155_capsule.png)
assert_ok "Screenshot TimeCapsule" "$R"

# ============================================================
echo ""
echo "=== App 156: SketchPad ==="
# ============================================================

fresh_launch "com.iez.sketchPad" "$SCRIPT_DIR/sketch_pad/build/ios/iphonesimulator/Runner.app" "Sketch Pad"
sleep 2

echo "--- Sketches screen ---"
refresh_tree
assert_tree_has "App heading" "SketchPad"
assert_tree_has "Sunset sketch" "Sunset"
assert_tree_has "Mountain sketch" "Mountain"
assert_tree_has "Cat Portrait sketch" "Cat Portrait"
assert_tree_has "City Skyline sketch" "City Skyline"
assert_tree_has "New Sketch FAB" "New Sketch"

echo "--- Tab bar ---"
assert_tree_has "Sketches tab" "Sketches"
assert_tree_has "Gallery tab" "Gallery"
assert_tree_has "Tools tab" "Tools"

echo "--- Tap sketch detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,155)
assert_ok "Tap Sunset" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Sketch Details title" "Sketch Details"
assert_tree_has "Created section" "Created"
assert_tree_has "Tags section" "Tags"
assert_tree_has "Colors Used section" "Colors Used"
assert_tree_has "Delete Sketch button" "Delete Sketch"

echo "--- Back to sketches ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to sketches" "$R"
sleep 1

echo "--- Tap Gallery tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap Gallery tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Gallery heading" "Gallery"
assert_tree_has "Sunset in gallery" "Sunset"
assert_tree_has "Mountain in gallery" "Mountain"
assert_tree_has "Cat Portrait in gallery" "Cat Portrait"

echo "--- Tap Tools tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Tools tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Tools heading" "Tools"
assert_tree_has "Pencil tool" "Pencil"
assert_tree_has "Brush tool" "Brush"
assert_tree_has "Eraser tool" "Eraser"
assert_tree_has "Fill tool" "Fill"
assert_tree_has "Brush Size label" "Brush Size"

echo "--- Back to Sketches tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Sketches tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Sketches"

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap New Sketch ---"
R=$(run_iez "$IEZ" ui tap --label "New Sketch")
assert_ok "Tap New Sketch FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "New Sketch page" "New Sketch"
assert_tree_has "Sketch Name field" "Sketch Name"
assert_tree_has "Tags field" "Tags"
assert_tree_has "Canvas Size dropdown" "Canvas Size"
assert_tree_has "Start Drawing button" "Start Drawing"

echo "--- Fill sketch form ---"
R=$(run_iez "$IEZ" ui type "Test Sketch" --label "Sketch Name")
assert_ok "Type sketch name" "$R"
sleep 0.5

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app156_sketch.png)
assert_ok "Screenshot SketchPad" "$R"

echo "--- Back from New Sketch ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from New Sketch" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 157: GiftTracker ==="
# ============================================================

fresh_launch "com.iez.giftTracker" "$SCRIPT_DIR/gift_tracker/build/ios/iphonesimulator/Runner.app" "Gift Tracker"
sleep 2

echo "--- Ideas screen ---"
refresh_tree
assert_tree_has "App title present" "Gift Tracker"
assert_tree_has "Wireless Earbuds idea" "Wireless Earbuds"
assert_tree_has "Book Set idea" "Book Set"
assert_tree_has "Scented Candle idea" "Scented Candle"
assert_tree_has "Gift Card idea" "Gift Card"
assert_tree_has "Board Game idea" "Board Game"
assert_tree_has "Add Idea FAB" "Add Idea"

echo "--- Tab bar ---"
assert_tree_has "Ideas tab" "Ideas"
assert_tree_has "People tab" "People"
assert_tree_has "Budget tab" "Budget"

echo "--- Tap idea detail (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 200,155)
assert_ok "Tap Wireless Earbuds" "$R"
sleep 1.5
refresh_tree
assert_tree_has "Gift Details title" "Gift Details"
assert_tree_has "Price Range section" "Price Range"
assert_tree_has "For section" "For"
assert_tree_has "Status section" "Status"
assert_tree_has "Delete Idea button" "Delete Idea"

echo "--- Back to ideas ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back to ideas" "$R"
sleep 1

echo "--- Tap People tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 201,790)
assert_ok "Tap People tab" "$R"
sleep 1
refresh_tree
assert_tree_has "People heading" "People"
assert_tree_has "Mom" "Mom"
assert_tree_has "Dad" "Dad"
assert_tree_has "Sister" "Sister"
assert_tree_has "Best Friend" "Best Friend"

echo "--- Tap Budget tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 335,790)
assert_ok "Tap Budget tab" "$R"
sleep 1
refresh_tree
assert_tree_has "Budget heading" "Budget"
assert_tree_has "Total Budget" "Total Budget"
assert_tree_has "Spent" "Spent"
assert_tree_has "Remaining" "Remaining"

echo "--- Back to Ideas tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords 67,790)
assert_ok "Tap Ideas tab" "$R"
sleep 1

echo "--- Tap Search ---"
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "Tap Search icon" "$R"
sleep 1
refresh_tree
assert_tree_has "Search page" "Search Gifts"
assert_tree_has "All filter" "All"
assert_tree_has 'Under $25 filter' 'Under $25'
assert_tree_has 'Under $50 filter' 'Under $50'
assert_tree_has 'Over $50 filter' 'Over $50'

echo "--- Back from search ---"
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from search" "$R"
sleep 1

echo "--- Tap Add Idea ---"
R=$(run_iez "$IEZ" ui tap --label "Add Idea")
assert_ok "Tap Add Idea FAB" "$R"
sleep 1
refresh_tree
assert_tree_has "Add Idea page" "Add Idea"
assert_tree_has "Gift Name field" "Gift Name"
assert_tree_has "Min Price field" "Min Price"
assert_tree_has "Max Price field" "Max Price"
assert_tree_has "Recipient dropdown" "Recipient"
assert_tree_has "Save Idea button" "Save Idea"

echo "--- Fill idea form ---"
R=$(run_iez "$IEZ" ui type "Test Gift" --label "Gift Name")
assert_ok "Type gift name" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "10" --label "Min Price")
assert_ok "Type min price" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui type "20" --label "Max Price")
assert_ok "Type max price" "$R"
sleep 0.5

echo "--- Submit idea ---"
R=$(run_iez "$IEZ" ui tap --label "Save Idea")
assert_ok "Tap Save Idea" "$R"
sleep 1.5

echo "--- Screenshot ---"
R=$(run_iez "$IEZ" ui screenshot --out /tmp/app157_gift.png)
assert_ok "Screenshot GiftTracker" "$R"

echo ""
echo "========================================"
echo "RESULTS: $PASS passed / $TOTAL total ($FAIL failed)"
echo "========================================"
exit $FAIL
