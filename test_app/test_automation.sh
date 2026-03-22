#!/bin/bash
# Test automation for Apps 176-178: MeditationTimer/ChoreChart/WarrantyTracker
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
  xcrun simctl terminate "$DEVICE_ID" com.iez.meditationTimer 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.choreChart 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.iez.warrantyTracker 2>/dev/null || true
  sleep 2
  kill_runners
  sleep 2
  xcrun simctl uninstall "$DEVICE_ID" com.iez.meditationTimer 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.choreChart 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.iez.warrantyTracker 2>/dev/null || true
  sleep 2
  xcrun simctl install "$DEVICE_ID" "$app_path"
  sleep 2
  xcrun simctl launch "$DEVICE_ID" "$bid"
  local app_name
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 3
    app_name=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.role=="AXApplication") | .label' 2>/dev/null || echo "")
    if [ "$app_name" = "$expected" ]; then
      echo "  ✔ $expected is in foreground"
      return 0
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

# Helper: tap element by finding coords from tree
tap_by_coords() {
  local label_grep="$1"
  local coords
  coords=$(run_iez "$IEZ" ui tree --compact | jq -r --arg g "$label_grep" '.data.elements[] | select(.label | test($g; "s")) | "\(.frame.x + .frame.width/2 | floor),\(.frame.y + .frame.height/2 | floor)"' 2>/dev/null | head -1)
  if [ -n "$coords" ]; then
    run_iez "$IEZ" ui tap --coords "$coords"
  else
    echo '{"ok":false,"error":"element not found"}'
  fi
}

# ============================================================
echo "=== App 176: MeditationTimer ==="
# ============================================================
# 4-tab layout: Tab1=50,800 Tab2=150,800 Tab3=250,800 Tab4=350,800

APP176_PATH="$SCRIPT_DIR/meditation_timer/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.meditationTimer" "$APP176_PATH" "Meditation Timer"
sleep 2

# --- Meditate tab (default) ---
refresh_tree
assert_tree_has "176.01 Meditate heading" "Meditate"
assert_tree_has "176.02 Morning Calm preset" "Morning Calm"
assert_tree_has "176.03 Deep Focus preset" "Deep Focus"
assert_tree_has "176.04 Sleep Well preset" "Sleep Well"
assert_tree_has "176.05 Stress Relief preset" "Stress Relief"
assert_tree_has "176.06 Body Scan preset" "Body Scan"
assert_tree_has "176.07 New Preset FAB" "New Preset"

# Tap into Morning Calm → timer page
R=$(tap_by_coords "Morning Calm")
assert_ok "176.08 Tap Morning Calm" "$R"
sleep 1

refresh_tree
assert_tree_has "176.09 Timer heading" "Morning Calm"
assert_tree_has "176.10 Category label" "Mindfulness"
assert_tree_has "176.11 Timer display" "05:00"
assert_tree_has "176.12 Session info" "5 minute session"
assert_tree_has "176.13 Start button" "Start"
assert_tree_has "176.14 Reset button" "Reset"

# Tap Start → timer starts
R=$(run_iez "$IEZ" ui tap --label "Start")
assert_ok "176.15 Tap Start" "$R"
sleep 2

refresh_tree
assert_tree_has "176.16 Pause button appears" "Pause"

# Tap Pause
R=$(tap_by_coords "Pause")
assert_ok "176.17 Tap Pause" "$R"
sleep 0.5

refresh_tree
assert_tree_has "176.18 Start reappears after pause" "Start"

# Tap Reset
R=$(tap_by_coords "Reset")
assert_ok "176.19 Tap Reset" "$R"
sleep 0.5

refresh_tree
assert_tree_has "176.20 Timer reset to 05:00" "05:00"

# Go back
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "176.21 Tap Back from timer" "$R"
sleep 1

# Navigate to History tab (coord-based)
R=$(run_iez "$IEZ" ui tap --coords 150,800)
assert_ok "176.22 Tap History tab" "$R"
sleep 1

refresh_tree
assert_tree_has "176.23 Morning Calm session" "Morning Calm"
assert_tree_has "176.24 Deep Focus session" "Deep Focus"
assert_tree_has "176.25 Sleep Well session" "Sleep Well"
assert_tree_has "176.26 Yesterday label" "Yesterday"

# Navigate to Stats tab
R=$(run_iez "$IEZ" ui tap --coords 250,800)
assert_ok "176.27 Tap Stats tab" "$R"
sleep 1

refresh_tree
assert_tree_has "176.28 Overview card" "Overview"
assert_tree_has "176.29 Total Sessions" "Total Sessions"
assert_tree_has "176.30 Total Minutes" "Total Minutes"
assert_tree_has "176.31 Current Streak" "Current Streak"
assert_tree_has "176.32 Daily Goal in stats" "Daily Goal"
assert_tree_has "176.33 By Category card" "By Category"
assert_tree_has "176.34 Mindfulness category" "Mindfulness"
assert_tree_has "176.35 Focus category" "Focus"

# Navigate to Settings tab
R=$(run_iez "$IEZ" ui tap --coords 350,800)
assert_ok "176.36 Tap Settings tab" "$R"
sleep 1

refresh_tree
assert_tree_has "176.37 Dark Mode toggle" "Dark Mode"
assert_tree_has "176.38 Sound toggle" "Sound"
assert_tree_has "176.39 Daily Goal setting" "15 minutes"
assert_tree_has "176.40 About item" "Meditation Timer v1.0"

# Tap About
R=$(tap_by_coords "Meditation Timer v1.0")
assert_ok "176.41 Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "176.42 About dialog content" "meditation practice"
assert_tree_has "176.43 Close button" "Close"

R=$(run_iez "$IEZ" ui tap --label "Close")
assert_ok "176.44 Close About dialog" "$R"
sleep 1

# Toggle Dark Mode
R=$(tap_by_coords "Dark Mode")
assert_ok "176.45 Toggle Dark Mode" "$R"
sleep 0.5

# Tap Daily Goal setting
R=$(tap_by_coords "15 minutes")
assert_ok "176.46 Tap Daily Goal" "$R"
sleep 1

refresh_tree
assert_tree_has "176.47 Set Daily Goal dialog" "Set Daily Goal"
assert_tree_has "176.48 Minutes per day field" "Minutes per day"

R=$(run_iez "$IEZ" ui type "20" --label "Minutes per day")
assert_ok "176.49 Type new goal" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "176.50 Tap Save" "$R"
sleep 1

# Back to Meditate tab to add new preset
R=$(run_iez "$IEZ" ui tap --coords 50,800)
assert_ok "176.51 Tap Meditate tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "New Preset")
assert_ok "176.52 Tap New Preset FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "176.53 New Preset dialog" "New Preset"
assert_tree_has "176.54 Preset Name field" "Preset Name"
assert_tree_has "176.55 Duration field" "Duration (minutes)"

R=$(run_iez "$IEZ" ui type "Evening Wind Down" --label "Preset Name")
assert_ok "176.56 Type preset name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Create")
assert_ok "176.57 Tap Create" "$R"
sleep 1

refresh_tree
assert_tree_has "176.58 New preset appears" "Evening Wind Down"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_176_meditation.png)
assert_ok "176.59 Screenshot meditation presets" "$R"

echo ""
echo "  App 176 subtotal: $PASS/$TOTAL passed"
echo ""

# ============================================================
echo "=== App 177: ChoreChart ==="
# ============================================================
# 4-tab layout: Tab1=50,800 Tab2=150,800 Tab3=250,800 Tab4=350,800

APP177_PATH="$SCRIPT_DIR/chore_chart/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.choreChart" "$APP177_PATH" "Chore Chart"
sleep 2

# --- Chores tab (default) ---
refresh_tree
assert_tree_has "177.01 App heading" "Chore Chart"
assert_tree_has "177.02 Completion counter" "0/8 done"
assert_tree_has "177.03 Wash Dishes chore" "Wash Dishes"
assert_tree_has "177.04 Vacuum Living Room" "Vacuum Living Room"
assert_tree_has "177.05 Take Out Trash" "Take Out Trash"
assert_tree_has "177.06 Clean Bathroom" "Clean Bathroom"
assert_tree_has "177.07 Mow Lawn" "Mow Lawn"
assert_tree_has "177.08 Make Bed" "Make Bed"
assert_tree_has "177.09 Feed Pets" "Feed Pets"
assert_tree_has "177.10 Dust Shelves" "Dust Shelves"
assert_tree_has "177.11 Add Chore FAB" "Add Chore"

# Toggle Wash Dishes checkbox (tap the checkbox element)
R=$(tap_by_coords "Wash Dishes")
assert_ok "177.12 Toggle Wash Dishes" "$R"
sleep 0.5

refresh_tree
assert_tree_has "177.13 Counter updates to 1/8" "1/8 done"

# Navigate to Family tab (coord-based)
R=$(run_iez "$IEZ" ui tap --coords 150,800)
assert_ok "177.14 Tap Family tab" "$R"
sleep 1

refresh_tree
assert_tree_has "177.15 Family Members heading" "Family Members"
assert_tree_has "177.16 Add Member FAB" "Add Member"

# Tap into Mom detail (use coords for multi-line emoji label)
R=$(run_iez "$IEZ" ui tap --coords 200,176)
assert_ok "177.17 Tap Mom member" "$R"
sleep 1

refresh_tree
assert_tree_has "177.18 Mom detail heading" "Mom"
assert_tree_has "177.19 Points stat" "Points"
assert_tree_has "177.20 Chores stat" "Chores"
assert_tree_has "177.21 Clean Bathroom chore" "Clean Bathroom"
assert_tree_has "177.22 Dust Shelves chore" "Dust Shelves"

# Go back
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "177.23 Tap Back from Mom" "$R"
sleep 1

# Tap into Alex detail (3rd member, ~y=344)
R=$(run_iez "$IEZ" ui tap --coords 200,344)
assert_ok "177.24 Tap Alex member" "$R"
sleep 1

refresh_tree
assert_tree_has "177.25 Alex detail heading" "Alex"
assert_tree_has "177.26 Wash Dishes chore" "Wash Dishes"
assert_tree_has "177.27 Make Bed chore" "Make Bed"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "177.28 Tap Back from Alex" "$R"
sleep 1

# Navigate to Points tab
R=$(run_iez "$IEZ" ui tap --coords 250,800)
assert_ok "177.29 Tap Points tab" "$R"
sleep 1

refresh_tree
assert_tree_has "177.30 Leaderboard heading" "Leaderboard"
assert_tree_has "177.31 Household Progress" "Household Progress"
assert_tree_has "177.32 Chores completed text" "chores completed"
assert_tree_has "177.33 Rankings section" "Rankings"

# Navigate to Settings tab
R=$(run_iez "$IEZ" ui tap --coords 350,800)
assert_ok "177.34 Tap Settings tab" "$R"
sleep 1

refresh_tree
assert_tree_has "177.35 Reset All Chores" "Reset All Chores"
assert_tree_has "177.36 Notifications" "Notifications"
assert_tree_has "177.37 About item" "Chore Chart v1.0"

# Tap Reset All Chores
R=$(tap_by_coords "Reset All Chores")
assert_ok "177.38 Tap Reset All Chores" "$R"
sleep 1

refresh_tree
assert_tree_has "177.39 Reset dialog title" "Reset Chores"
assert_tree_has "177.40 Reset confirmation text" "Are you sure"

R=$(run_iez "$IEZ" ui tap --label "Cancel")
assert_ok "177.41 Cancel reset dialog" "$R"
sleep 1

# Tap About
R=$(tap_by_coords "Chore Chart v1.0")
assert_ok "177.42 Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "177.43 About content" "household chores"
assert_tree_has "177.44 Close button" "Close"

R=$(run_iez "$IEZ" ui tap --label "Close")
assert_ok "177.45 Close About" "$R"
sleep 1

# Back to Chores tab to add new chore
R=$(run_iez "$IEZ" ui tap --coords 50,800)
assert_ok "177.46 Tap Chores tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Add Chore")
assert_ok "177.47 Tap Add Chore FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "177.48 New Chore dialog" "New Chore"
assert_tree_has "177.49 Chore Name field" "Chore Name"
assert_tree_has "177.50 Room field" "Room"

R=$(run_iez "$IEZ" ui type "Wash Windows" --label "Chore Name")
assert_ok "177.51 Type chore name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Living Room" --label "Room")
assert_ok "177.52 Type room" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "177.53 Tap Add button" "$R"
sleep 1

refresh_tree
assert_tree_has "177.54 New chore appears" "Wash Windows"

# Go to Family tab and add member
R=$(run_iez "$IEZ" ui tap --coords 150,800)
assert_ok "177.55 Tap Family tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Add Member")
assert_ok "177.56 Tap Add Member FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "177.57 Add Family Member dialog" "Add Family Member"

R=$(run_iez "$IEZ" ui type "Jordan" --label "Name")
assert_ok "177.58 Type member name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "177.59 Tap Add button" "$R"
sleep 1

refresh_tree
assert_tree_has "177.60 New member appears" "Jordan"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_177_chorechart.png)
assert_ok "177.61 Screenshot family members" "$R"

echo ""
echo "  App 177 cumulative: $PASS/$TOTAL passed"
echo ""

# ============================================================
echo "=== App 178: WarrantyTracker ==="
# ============================================================
# 3-tab layout: Tab1=67,800 Tab2=201,800 Tab3=335,800

APP178_PATH="$SCRIPT_DIR/warranty_tracker/build/ios/iphonesimulator/Runner.app"
fresh_launch "com.iez.warrantyTracker" "$APP178_PATH" "Warranty Tracker"
sleep 2

# --- Warranties tab (default) ---
refresh_tree
assert_tree_has "178.01 My Warranties heading" "My Warranties"
assert_tree_has "178.02 MacBook Pro" "MacBook Pro"
assert_tree_has "178.03 Washing Machine" "Washing Machine"
assert_tree_has "178.04 Running Shoes" "Running Shoes"
assert_tree_has "178.05 Blender" "Blender"
assert_tree_has "178.06 Headphones" "Headphones"
assert_tree_has "178.07 Office Chair" "Office Chair"
assert_tree_has "178.08 Search button" "Search"
assert_tree_has "178.09 Filter button" "Filter"
assert_tree_has "178.10 Add Warranty FAB" "Add Warranty"
assert_tree_has "178.11 Active chip" "Active"
assert_tree_has "178.12 Expired chip" "Expired"

# Tap into MacBook Pro detail
R=$(tap_by_coords "MacBook Pro")
assert_ok "178.13 Tap MacBook Pro" "$R"
sleep 1

refresh_tree
assert_tree_has "178.14 Detail heading" "MacBook Pro"
assert_tree_has "178.15 Product Details section" "Product Details"
assert_tree_has "178.16 Brand Apple" "Apple"
assert_tree_has "178.17 Category Electronics" "Electronics"
assert_tree_has "178.18 Warranty Period section" "Warranty Period"
assert_tree_has "178.19 Purchase Date" "Purchase Date"
assert_tree_has "178.20 Expiry Date" "Expiry Date"
assert_tree_has "178.21 Notes section" "Notes"
assert_tree_has "178.22 AppleCare note" "AppleCare"
assert_tree_has "178.23 Delete button" "Delete"

# Go back
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "178.24 Tap Back from detail" "$R"
sleep 1

# Tap Search
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "178.25 Tap Search button" "$R"
sleep 1

refresh_tree
assert_tree_has "178.26 Search dialog" "Search Warranties"
assert_tree_has "178.27 Search field" "Search by product or brand"

R=$(run_iez "$IEZ" ui type "Sony" --label "Search by product or brand")
assert_ok "178.28 Type search query" "$R"
sleep 0.5

R=$(tap_by_coords "^Search$")
assert_ok "178.29 Tap Search submit" "$R"
sleep 1

refresh_tree
assert_tree_has "178.30 Filtered to Headphones" "Headphones"

# Clear search via Search dialog
R=$(run_iez "$IEZ" ui tap --label "Search")
assert_ok "178.31 Tap Search again" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Clear")
assert_ok "178.32 Clear search" "$R"
sleep 1

# Tap Filter
R=$(run_iez "$IEZ" ui tap --label "Filter")
assert_ok "178.33 Tap Filter" "$R"
sleep 1

refresh_tree
assert_tree_has "178.34 Filter dialog title" "Filter by Category"
assert_tree_has "178.35 All option" "All"
assert_tree_has "178.36 Electronics option" "Electronics"
assert_tree_has "178.37 Appliances option" "Appliances"

# Select Electronics filter
R=$(tap_by_coords "^Electronics$")
assert_ok "178.38 Select Electronics filter" "$R"
sleep 1

refresh_tree
assert_tree_has "178.39 Filtered: MacBook Pro" "MacBook Pro"
assert_tree_has "178.40 Filtered: Headphones" "Headphones"

# Clear filter
R=$(run_iez "$IEZ" ui tap --label "Filter")
assert_ok "178.41 Tap Filter again" "$R"
sleep 1

R=$(tap_by_coords "^All$")
assert_ok "178.42 Select All filter" "$R"
sleep 1

# Navigate to Dashboard tab (coord-based for 3-tab)
R=$(run_iez "$IEZ" ui tap --coords 201,800)
assert_ok "178.43 Tap Dashboard tab" "$R"
sleep 1

refresh_tree
assert_tree_has "178.44 Dashboard heading" "Dashboard"
assert_tree_has "178.45 Active count" "Active"
assert_tree_has "178.46 Expiring Soon section" "Expiring Soon"
assert_tree_has "178.47 By Category section" "By Category"
assert_tree_has "178.48 Appliances category" "Appliances"
assert_tree_has "178.49 Electronics category" "Electronics"
assert_tree_has "178.50 Furniture category" "Furniture"

# Navigate to Settings tab
R=$(run_iez "$IEZ" ui tap --coords 335,800)
assert_ok "178.51 Tap Settings tab" "$R"
sleep 1

refresh_tree
assert_tree_has "178.52 Expiry Reminders" "Expiry Reminders"
assert_tree_has "178.53 Export Data" "Export Data"
assert_tree_has "178.54 About item" "Warranty Tracker v1.0"

# Tap About
R=$(tap_by_coords "Warranty Tracker v1.0")
assert_ok "178.55 Tap About" "$R"
sleep 1

refresh_tree
assert_tree_has "178.56 About content" "product warranties"
assert_tree_has "178.57 Close button" "Close"

R=$(run_iez "$IEZ" ui tap --label "Close")
assert_ok "178.58 Close About" "$R"
sleep 1

# Back to Warranties tab to add new warranty
R=$(run_iez "$IEZ" ui tap --coords 67,800)
assert_ok "178.59 Tap Warranties tab" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Add Warranty")
assert_ok "178.60 Tap Add Warranty FAB" "$R"
sleep 1

refresh_tree
assert_tree_has "178.61 Add Warranty dialog" "Add Warranty"
assert_tree_has "178.62 Product Name field" "Product Name"
assert_tree_has "178.63 Brand field" "Brand"
assert_tree_has "178.64 Notes field" "Notes"

R=$(run_iez "$IEZ" ui type "Smart TV" --label "Product Name")
assert_ok "178.65 Type product name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "LG" --label "Brand")
assert_ok "178.66 Type brand" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save")
assert_ok "178.67 Tap Save" "$R"
sleep 1

refresh_tree
assert_tree_has "178.68 New warranty appears" "Smart TV"

# Screenshot
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_178_warranty.png)
assert_ok "178.69 Screenshot warranty list" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  FINAL: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
