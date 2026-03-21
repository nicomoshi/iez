#!/bin/bash
# Test automation for Apps 113-115: PodcastPlayer/ProjectBoard/TravelLog
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
  xcrun simctl terminate "$DEVICE_ID" com.test.podcastPlayer 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.projectBoard 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.travelLog 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.podcastPlayer 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.projectBoard 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.travelLog 2>/dev/null || true
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
echo "=== App 113: PodcastPlayer ==="
# ============================================================

fresh_launch "com.test.podcastPlayer" \
  "$SCRIPT_DIR/podcast_player/build/ios/iphonesimulator/Runner.app" \
  "Podcast Player"

echo "--- Episodes Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Podcast Player"
assert_tree_has "Future of AI" "The Future of AI"
assert_tree_has "Deep Work" "Deep Work Habits"
assert_tree_has "Startup Secrets" "Startup Secrets"
assert_tree_has "Flutter State" "Flutter State Management"
assert_tree_has "Mindful Morning" "Mindful Morning"
assert_tree_has "Market Trends" "Market Trends 2026"
assert_tree_has "Downloads button" "Downloads"
assert_tree_has "Queue button" "Queue"

echo "--- Switch to Shows tab (coords — NavigationBar) ---"
R=$(run_iez "$IEZ" ui tap --coords "301,800")
assert_ok "Tap Shows tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Tech Talk show" "Tech Talk"
assert_tree_has "Productivity Pod" "Productivity Pod"
assert_tree_has "Business Weekly" "Business Weekly"
assert_tree_has "Code Radio" "Code Radio"
assert_tree_has "Wellness Hour" "Wellness Hour"

echo "--- Switch back to Episodes (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "100,800")
assert_ok "Tap Episodes tab" "$R"
sleep 1

echo "--- Tap episode to see detail (coords) ---"
EP_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Deep Work")) | .frame.y' 2>/dev/null)
if [ -n "$EP_Y" ] && [ "$EP_Y" != "null" ]; then
  EP_CENTER=$((EP_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$EP_CENTER")
  assert_ok "Tap Deep Work Habits" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Episode title" "Deep Work Habits"
  assert_tree_has "Show name" "Productivity Pod"
  assert_tree_has "Duration chip" "32 min"
  assert_tree_has "About heading" "About this episode"
  assert_tree_has "Play button" "Play Episode"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 7)); FAIL=$((FAIL + 7))
  echo "  ✗ Could not find Deep Work coords (skipping 7 assertions)"
fi

echo "--- Navigate to Downloads (empty) ---"
R=$(run_iez "$IEZ" ui tap --label "Downloads")
assert_ok "Tap Downloads" "$R"
sleep 1

refresh_tree
assert_tree_has "Downloads heading" "Downloads"
assert_tree_has "No downloads" "No downloads yet"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Downloads" "$R"
sleep 1

echo "--- Navigate to Queue ---"
R=$(run_iez "$IEZ" ui tap --label "Queue")
assert_ok "Tap Queue" "$R"
sleep 1

refresh_tree
assert_tree_has "Queue heading" "Up Next"
assert_tree_has "AI in queue" "The Future of AI"
assert_tree_has "Deep Work in queue" "Deep Work Habits"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Queue" "$R"
sleep 1

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app113_podcastplayer.png)
assert_ok "Screenshot PodcastPlayer" "$R"

# ============================================================
echo ""
echo "=== App 114: ProjectBoard ==="
# ============================================================

fresh_launch "com.test.projectBoard" \
  "$SCRIPT_DIR/project_board/build/ios/iphonesimulator/Runner.app" \
  "Project Board"

echo "--- Todo Tab (Home) ---"
refresh_tree
assert_tree_has "App title" "Project Board"
assert_tree_has "Todo tab" "Todo"
assert_tree_has "In Progress tab" "In Progress"
assert_tree_has "Done tab" "Done"
assert_tree_has "Design Login" "Design Login Page"
assert_tree_has "Setup CI" "Setup CI Pipeline"
assert_tree_has "Write Unit Tests" "Write Unit Tests"
assert_tree_has "Stats button" "Stats"
assert_tree_has "Add Card FAB" "Add Card"

echo "--- Switch to In Progress tab (coords — TabBar multi-line labels) ---"
R=$(run_iez "$IEZ" ui tap --coords "201,142")
assert_ok "Tap In Progress tab" "$R"
sleep 1

refresh_tree
assert_tree_has "API Auth" "API Authentication"
assert_tree_has "Database Schema" "Database Schema"

echo "--- Switch to Done tab (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "335,142")
assert_ok "Tap Done tab" "$R"
sleep 1

refresh_tree
assert_tree_has "Project Setup" "Project Setup"
assert_tree_has "Requirements Doc" "Requirements Doc"

echo "--- Switch back to Todo (coords) ---"
R=$(run_iez "$IEZ" ui tap --coords "67,142")
assert_ok "Tap Todo tab" "$R"
sleep 1

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Board Stats"
assert_tree_has "Overview" "Overview"
assert_tree_has "Total Cards" "Total Cards: 7"
assert_tree_has "By Priority" "By Priority"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Navigate to Add Card ---"
R=$(run_iez "$IEZ" ui tap --label "Add Card")
assert_ok "Tap Add Card" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Card"
assert_tree_has "Card title field" "Card title"
assert_tree_has "Assignee field" "Assignee"
assert_tree_has "Priority dropdown" "Priority"
assert_tree_has "Save button" "Save Card"

echo "--- Add a new card ---"
R=$(run_iez "$IEZ" ui type "Review PR" --label "Card title")
assert_ok "Type card title" "$R"
sleep 0.5

# Dismiss keyboard by swiping down, then tap Save
R=$(run_iez "$IEZ" ui swipe down)
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Save Card")
assert_ok "Tap Save Card" "$R"
sleep 1

echo "--- Verify new card in Todo ---"
refresh_tree
assert_tree_has "Back on board" "Project Board"
assert_tree_has "New card visible" "Review PR"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app114_projectboard.png)
assert_ok "Screenshot ProjectBoard" "$R"

# ============================================================
echo ""
echo "=== App 115: TravelLog ==="
# ============================================================

fresh_launch "com.test.travelLog" \
  "$SCRIPT_DIR/travel_log/build/ios/iphonesimulator/Runner.app" \
  "Travel Log"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Travel Log"
assert_tree_has "Kyoto" "Kyoto"
assert_tree_has "Barcelona" "Barcelona"
assert_tree_has "Reykjavik" "Reykjavik"
assert_tree_has "Machu Picchu" "Machu Picchu"
assert_tree_has "Cape Town" "Cape Town"
assert_tree_has "Santorini" "Santorini"
assert_tree_has "All filter" "All"
assert_tree_has "5 Stars filter" "5 Stars"
assert_tree_has "Favorites filter" "Favorites"
assert_tree_has "Stats button" "Stats"
assert_tree_has "Add Trip FAB" "Add Trip"

echo "--- Filter by 5 Stars ---"
R=$(run_iez "$IEZ" ui tap --label "5 Stars")
assert_ok "Tap 5 Stars filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Kyoto (5 stars)" "Kyoto"
assert_tree_has "Reykjavik (5 stars)" "Reykjavik"
assert_tree_has "Machu Picchu (5 stars)" "Machu Picchu"

echo "--- Reset to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap trip to see detail (coords) ---"
TRIP_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Kyoto")) | .frame.y' 2>/dev/null)
if [ -n "$TRIP_Y" ] && [ "$TRIP_Y" != "null" ]; then
  TRIP_CENTER=$((TRIP_Y + 36))
  R=$(run_iez "$IEZ" ui tap --coords "200,$TRIP_CENTER")
  assert_ok "Tap Kyoto" "$R"
  sleep 1

  refresh_tree
  assert_tree_has "Detail title" "Kyoto"
  assert_tree_has "Country" "Japan"
  assert_tree_has "Date chip" "Oct 2025"
  assert_tree_has "Photos chip" "234 photos"
  assert_tree_has "Highlight heading" "Highlight"
  assert_tree_has "Highlight text" "Bamboo forest at sunrise"

  R=$(run_iez "$IEZ" ui tap --label "Back")
  assert_ok "Back from detail" "$R"
  sleep 1
else
  TOTAL=$((TOTAL + 8)); FAIL=$((FAIL + 8))
  echo "  ✗ Could not find Kyoto coords (skipping 8 assertions)"
fi

echo "--- Navigate to Stats ---"
R=$(run_iez "$IEZ" ui tap --label "Stats")
assert_ok "Tap Stats" "$R"
sleep 1

refresh_tree
assert_tree_has "Stats heading" "Travel Stats"
assert_tree_has "Overview" "Overview"
assert_tree_has "Total Trips" "Total Trips: 6"
assert_tree_has "Countries heading" "Countries"
assert_tree_has "Japan" "Japan"
assert_tree_has "Spain" "Spain"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Stats" "$R"
sleep 1

echo "--- Navigate to Add Trip ---"
R=$(run_iez "$IEZ" ui tap --label "Add Trip")
assert_ok "Tap Add Trip" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Trip"
assert_tree_has "Destination field" "Destination"
assert_tree_has "Country field" "Country"
assert_tree_has "Highlight field" "Highlight"
assert_tree_has "Save button" "Save Trip"

echo "--- Add a new trip ---"
R=$(run_iez "$IEZ" ui type "Bali" --label "Destination")
assert_ok "Type destination" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Indonesia" --label "Country")
assert_ok "Type country" "$R"
sleep 0.5

# Dismiss keyboard and scroll to Save button
R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Trip")
assert_ok "Tap Save Trip" "$R"
sleep 1

echo "--- Verify new trip ---"
refresh_tree
assert_tree_has "Back on home" "Travel Log"
assert_tree_has "New trip visible" "Bali"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app115_travellog.png)
assert_ok "Screenshot TravelLog" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
