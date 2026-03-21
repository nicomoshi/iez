#!/bin/bash
# Test automation for Apps 116-118: InventoryApp/WorkoutTracker/BookLibrary
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
  xcrun simctl terminate "$DEVICE_ID" com.test.inventoryApp 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.workoutTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.bookLibrary 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.inventoryApp 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.workoutTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.bookLibrary 2>/dev/null || true
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
echo "=== App 116: InventoryApp ==="
# ============================================================

fresh_launch "com.test.inventoryApp" \
  "$SCRIPT_DIR/inventory_app/build/ios/iphonesimulator/Runner.app" \
  "Inventory App"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Inventory"
assert_tree_has "All filter" "All"
assert_tree_has "Electronics filter" "Electronics"
assert_tree_has "Furniture filter" "Furniture"
assert_tree_has "Kitchen filter" "Kitchen"
assert_tree_has "Office filter" "Office"
assert_tree_has "MacBook Pro" "MacBook Pro"
assert_tree_has "Standing Desk" "Standing Desk"
assert_tree_has "Coffee Maker" "Coffee Maker"
assert_tree_has "Blender Pro" "Blender Pro"
assert_tree_has "Keyboard MX" "Keyboard MX"
assert_tree_has "Add Item FAB" "Add Item"

echo "--- Filter by Electronics ---"
R=$(run_iez "$IEZ" ui tap --label "Electronics")
assert_ok "Tap Electronics filter" "$R"
sleep 1

refresh_tree
assert_tree_has "MacBook filtered" "MacBook Pro"
assert_tree_has "Monitor filtered" "Monitor 27in"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap item to see detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,470")
assert_ok "Tap MacBook Pro" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail name" "MacBook Pro"
assert_tree_has "Detail category" "Electronics"
assert_tree_has "Detail price" "2499"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Stats"
assert_tree_has "Total Items" "Total Items"
assert_tree_has "Total Value" "Total Value"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Add new item ---"
R=$(run_iez "$IEZ" ui tap --label "Add Item")
assert_ok "Tap Add Item" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Item"
assert_tree_has "Name field" "Name"
assert_tree_has "Quantity field" "Quantity"
assert_tree_has "Price field" "Price"
assert_tree_has "Save button" "Save Item"

R=$(run_iez "$IEZ" ui type "Webcam HD" --label "Name")
assert_ok "Type item name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "3" --label "Quantity")
assert_ok "Type quantity" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "89" --label "Price")
assert_ok "Type price" "$R"
sleep 0.5

# Dismiss keyboard and save
R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Item")
assert_ok "Tap Save Item" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Inventory"
assert_tree_has "New item visible" "Webcam HD"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app116_inventory.png)
assert_ok "Screenshot InventoryApp" "$R"

# ============================================================
echo ""
echo "=== App 117: WorkoutTracker ==="
# ============================================================

fresh_launch "com.test.workoutTracker" \
  "$SCRIPT_DIR/workout_tracker/build/ios/iphonesimulator/Runner.app" \
  "Workout Tracker"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Workout Tracker"
assert_tree_has "Today's Summary" "Today's Summary"
assert_tree_has "Categories" "Categories"
assert_tree_has "Chest card" "Chest"
assert_tree_has "Back card" "Back"
assert_tree_has "Legs card" "Legs"
assert_tree_has "Arms card" "Arms"
assert_tree_has "Shoulders card" "Shoulders"
assert_tree_has "Core card" "Core"
assert_tree_has "History button" "History"
assert_tree_has "Add Workout button" "Add Workout"

echo "--- Tap Chest category ---"
R=$(run_iez "$IEZ" ui tap --coords "200,340")
assert_ok "Tap Chest" "$R"
sleep 1

refresh_tree
assert_tree_has "Chest title" "Chest"
assert_tree_has "Bench Press" "Bench Press"
assert_tree_has "Incline Press" "Incline Press"
assert_tree_has "Chest Fly" "Chest Fly"

echo "--- Tap exercise for detail ---"
# Bench Press is first item; get its Y coordinate
BP_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Bench Press")) | .frame.y' 2>/dev/null)
if [ -n "$BP_Y" ] && [ "$BP_Y" != "null" ]; then
  BP_CENTER=$((BP_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$BP_CENTER")
else
  R=$(run_iez "$IEZ" ui tap --coords "200,180")
fi
assert_ok "Tap Bench Press" "$R"
sleep 1

refresh_tree
assert_tree_has "Exercise title" "Bench Press"
assert_tree_has "Add Set" "Add Set"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from exercise detail" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from exercise list" "$R"
sleep 1

echo "--- Navigate to History ---"
R=$(run_iez "$IEZ" ui tap --label "History")
assert_ok "Tap History" "$R"
sleep 1

refresh_tree
assert_tree_has "History heading" "History"
assert_tree_has "Chest Day" "Chest Day"
assert_tree_has "Leg Day" "Leg Day"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from History" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Workout Stats")
assert_ok "Tap Workout Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Workout Stats"
assert_tree_has "Total Workouts" "Total Workouts"
assert_tree_has "Favorite Exercise" "Favorite Exercise"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Add Workout ---"
R=$(run_iez "$IEZ" ui tap --label "Add Workout")
assert_ok "Tap Add Workout" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Workout"
assert_tree_has "Exercise Name field" "Exercise Name"
assert_tree_has "Save button" "Save Workout"

R=$(run_iez "$IEZ" ui type "Deadlift" --label "Exercise Name")
assert_ok "Type exercise name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Workout")
assert_ok "Tap Save Workout" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Workout Tracker"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app117_workout.png)
assert_ok "Screenshot WorkoutTracker" "$R"

# ============================================================
echo ""
echo "=== App 118: BookLibrary ==="
# ============================================================

fresh_launch "com.test.bookLibrary" \
  "$SCRIPT_DIR/book_library/build/ios/iphonesimulator/Runner.app" \
  "Book Library"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Book Library"
assert_tree_has "All filter" "All"
assert_tree_has "Reading filter" "Reading"
assert_tree_has "Completed filter" "Completed"
assert_tree_has "Want to Read" "Want to Read"
assert_tree_has "Dune" "Dune"
assert_tree_has "1984" "1984"
assert_tree_has "Project Hail Mary" "Project Hail Mary"
assert_tree_has "Atomic Habits" "Atomic Habits"
assert_tree_has "The Hobbit" "The Hobbit"
assert_tree_has "Clean Code" "Clean Code"
assert_tree_has "Sapiens" "Sapiens"
assert_tree_has "Neuromancer" "Neuromancer"
assert_tree_has "Add Book FAB" "Add Book"

echo "--- Filter by Reading ---"
R=$(run_iez "$IEZ" ui tap --label "Reading")
assert_ok "Tap Reading filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Hail Mary reading" "Project Hail Mary"
assert_tree_has "Sapiens reading" "Sapiens"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap book for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,180")
assert_ok "Tap Dune" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail title" "Dune"
assert_tree_has "Author" "Frank Herbert"
assert_tree_has "Rating stars" "★★★★★"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Move to Shelf" "Move to Shelf"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Stats"
assert_tree_has "Total Books" "Total Books"
assert_tree_has "Total Pages" "Total Pages"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Add new book ---"
R=$(run_iez "$IEZ" ui tap --label "Add Book")
assert_ok "Tap Add Book" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Book"
assert_tree_has "Title field" "Title"
assert_tree_has "Author field" "Author"
assert_tree_has "Save button" "Save Book"

R=$(run_iez "$IEZ" ui type "Snow Crash" --label "Title")
assert_ok "Type book title" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Neal Stephenson" --label "Author")
assert_ok "Type author" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Book")
assert_ok "Tap Save Book" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Book Library"
assert_tree_has "New book visible" "Snow Crash"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app118_booklibrary.png)
assert_ok "Screenshot BookLibrary" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
