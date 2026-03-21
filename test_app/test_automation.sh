#!/bin/bash
# Test automation for Apps 122-124: MusicLibrary/JobTracker/HomeManager
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
  xcrun simctl terminate "$DEVICE_ID" com.test.musicLibrary 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.jobTracker 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.homeManager 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.musicLibrary 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.jobTracker 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.homeManager 2>/dev/null || true
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
echo "=== App 122: MusicLibrary ==="
# ============================================================

fresh_launch "com.test.musicLibrary" \
  "$SCRIPT_DIR/music_library/build/ios/iphonesimulator/Runner.app" \
  "Music Library"

echo "--- Songs Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Music Library"
assert_tree_has "Bohemian Rhapsody" "Bohemian Rhapsody"
assert_tree_has "Billie Jean" "Billie Jean"
assert_tree_has "Hotel California" "Hotel California"
assert_tree_has "Imagine" "Imagine"
assert_tree_has "Smells Like Teen Spirit" "Smells Like Teen Spirit"
assert_tree_has "Sweet Child O Mine" "Sweet Child O Mine"
assert_tree_has "Songs tab" "Songs"
assert_tree_has "Albums tab" "Albums"
assert_tree_has "Playlists tab" "Playlists"

echo "--- Tap song for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,140")
assert_ok "Tap Bohemian Rhapsody" "$R"
sleep 1

refresh_tree
assert_tree_has "Song title" "Bohemian Rhapsody"
assert_tree_has "Artist" "Queen"
assert_tree_has "Album" "A Night at the Opera"
assert_tree_has "Add to Playlist" "Add to Playlist"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from song detail" "$R"
sleep 1

echo "--- Switch to Albums tab (coords — BottomNavigationBar) ---"
R=$(run_iez "$IEZ" ui tap --coords "201,810")
assert_ok "Tap Albums tab" "$R"
sleep 1

refresh_tree
assert_tree_has "A Night at the Opera" "A Night at the Opera"
assert_tree_has "Thriller" "Thriller"
assert_tree_has "Nevermind" "Nevermind"

echo "--- Tap album for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "100,200")
assert_ok "Tap album" "$R"
sleep 1

refresh_tree
assert_tree_has "Album detail" "A Night at the Opera"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from album detail" "$R"
sleep 1

echo "--- Switch to Playlists tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "335,810")
assert_ok "Tap Playlists tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Road Trip playlist" "Road Trip"
assert_tree_has "Workout playlist" "Workout"

echo "--- Navigate to Equalizer ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Equalizer")
assert_ok "Tap Equalizer" "$R"
sleep 1

refresh_tree
assert_tree_has "Equalizer heading" "Equalizer"
assert_tree_has "Flat preset" "Flat"
assert_tree_has "Rock preset" "Rock"
assert_tree_has "Jazz preset" "Jazz"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Equalizer" "$R"
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app122_musiclibrary.png)
assert_ok "Screenshot MusicLibrary" "$R"

# ============================================================
echo ""
echo "=== App 123: JobTracker ==="
# ============================================================

fresh_launch "com.test.jobTracker" \
  "$SCRIPT_DIR/job_tracker/build/ios/iphonesimulator/Runner.app" \
  "Job Tracker"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Job Tracker"
assert_tree_has "All filter" "All"
assert_tree_has "Applied filter" "Applied"
assert_tree_has "Interview filter" "Interview"
assert_tree_has "Offer filter" "Offer"
assert_tree_has "Rejected filter" "Rejected"
assert_tree_has "Google" "Google"
assert_tree_has "Apple" "Apple"
assert_tree_has "Meta" "Meta"
assert_tree_has "Netflix" "Netflix"
assert_tree_has "Spotify" "Spotify"
assert_tree_has "Add FAB" "Add"

echo "--- Filter by Interview ---"
R=$(run_iez "$IEZ" ui tap --label "Interview")
assert_ok "Tap Interview filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Apple interview" "Apple"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap application for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,230")
assert_ok "Tap Google" "$R"
sleep 1

refresh_tree
assert_tree_has "Company" "Google"
assert_tree_has "Position" "Senior Flutter Dev"
assert_tree_has "Salary" '180k'
assert_tree_has "Update Status" "Update Status"
assert_tree_has "Edit button" "Edit"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Analytics ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Analytics")
assert_ok "Tap Analytics" "$R"
sleep 1

refresh_tree
assert_tree_has "Analytics heading" "Analytics"
assert_tree_has "Total Applications" "Total Applications"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Analytics" "$R"
sleep 1

echo "--- Add new application ---"
R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Tap Add" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Application"
assert_tree_has "Company field" "Company"
assert_tree_has "Position field" "Position"
assert_tree_has "Save button" "Save Application"

R=$(run_iez "$IEZ" ui type "Amazon" --label "Company")
assert_ok "Type company" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "SDE III" --label "Position")
assert_ok "Type position" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 1

R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Application")
assert_ok "Tap Save Application" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Job Tracker"
assert_tree_has "New application" "Amazon"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app123_jobtracker.png)
assert_ok "Screenshot JobTracker" "$R"

# ============================================================
echo ""
echo "=== App 124: HomeManager ==="
# ============================================================

fresh_launch "com.test.homeManager" \
  "$SCRIPT_DIR/home_manager/build/ios/iphonesimulator/Runner.app" \
  "Home Manager"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Home Manager"
assert_tree_has "Living Room" "Living Room"
assert_tree_has "Bedroom" "Bedroom"
assert_tree_has "Kitchen" "Kitchen"
assert_tree_has "Garage" "Garage"
assert_tree_has "Device counts" "3 devices"
assert_tree_has "Add Room FAB" "Add Room"

echo "--- Tap room for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,155")
assert_ok "Tap Living Room" "$R"
sleep 1

refresh_tree
assert_tree_has "Room title" "Living Room"
assert_tree_has "Smart Light" "Smart Light"
assert_tree_has "Smart TV" "Smart TV"
assert_tree_has "Thermostat" "Thermostat"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from room detail" "$R"
sleep 1

echo "--- Navigate to Settings ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Settings")
assert_ok "Tap Settings" "$R"
sleep 1

refresh_tree
assert_tree_has "Settings heading" "Settings"
assert_tree_has "Temperature Unit" "Temperature Unit"
assert_tree_has "Notifications" "Notifications"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Settings" "$R"
sleep 1

echo "--- Add new room ---"
R=$(run_iez "$IEZ" ui tap --label "Add Room")
assert_ok "Tap Add Room" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Room"
assert_tree_has "Room Name field" "Room Name"
assert_tree_has "Save button" "Save Room"

R=$(run_iez "$IEZ" ui type "Office" --label "Room Name")
assert_ok "Type room name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Room")
assert_ok "Tap Save Room" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Home Manager"
assert_tree_has "New room visible" "Office"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app124_homemanager.png)
assert_ok "Screenshot HomeManager" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
