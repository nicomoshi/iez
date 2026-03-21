#!/bin/bash
# Test automation for Apps 131-133: HealthDiary/SkillTree/TeamRoster
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
  xcrun simctl terminate "$DEVICE_ID" com.test.healthDiary 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.skillTree 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.teamRoster 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.healthDiary 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.skillTree 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.teamRoster 2>/dev/null || true
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
echo "=== App 131: HealthDiary ==="
# ============================================================

fresh_launch "com.test.healthDiary" \
  "$SCRIPT_DIR/health_diary/build/ios/iphonesimulator/Runner.app" \
  "Health Diary"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Health Diary"
assert_tree_has "Summary card" "Today's Summary"
assert_tree_has "Water intake" "5 glasses"
assert_tree_has "Calories" "870 cal"
assert_tree_has "Sleep hours" "7.5h"
assert_tree_has "All filter" "All"
assert_tree_has "Water filter" "Water"
assert_tree_has "Meals filter" "Meals"
assert_tree_has "Sleep filter" "Sleep"
assert_tree_has "Mood filter" "Mood"
assert_tree_has "Water entry" "Water: 3 glasses"
assert_tree_has "Oatmeal entry" "Oatmeal and fruit"
assert_tree_has "Chicken salad" "Grilled chicken salad"
assert_tree_has "Mood entry" "Mood: happy"
assert_tree_has "Sleep entry" "Sleep: 7.5 hours"
assert_tree_has "Add Entry FAB" "Add Entry"

echo "--- Filter by Water ---"
R=$(run_iez "$IEZ" ui tap --label "Water")
assert_ok "Tap Water filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Water 3 glasses" "Water: 3 glasses"
assert_tree_has "Water 2 glasses" "Water: 2 glasses"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap entry for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,430")
assert_ok "Tap Oatmeal entry" "$R"
sleep 1

refresh_tree
assert_tree_has "Meal name" "Oatmeal and fruit"
assert_tree_has "Edit button" "Edit"
assert_tree_has "Delete button" "Delete"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Goals ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Goals")
assert_ok "Tap Goals" "$R"
sleep 1

refresh_tree
assert_tree_has "Goals heading" "Goals"
assert_tree_has "Water goal" "Water"
assert_tree_has "Calories goal" "Calories"
assert_tree_has "Sleep goal" "Sleep"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Goals" "$R"
sleep 1

echo "--- Add new entry ---"
R=$(run_iez "$IEZ" ui tap --label "Add Entry")
assert_ok "Tap Add Entry" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Entry"
assert_tree_has "Save button" "Save Entry"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app131_healthdiary.png)
assert_ok "Screenshot HealthDiary" "$R"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Add" "$R"
sleep 1

# ============================================================
echo ""
echo "=== App 132: SkillTree ==="
# ============================================================

fresh_launch "com.test.skillTree" \
  "$SCRIPT_DIR/skill_tree/build/ios/iphonesimulator/Runner.app" \
  "Skill Tree"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Skill Tree"
assert_tree_has "Programming" "Programming"
assert_tree_has "Design" "Design"
assert_tree_has "Languages" "Languages"
assert_tree_has "Music" "Music"
assert_tree_has "Add Skill FAB" "Add Skill"

echo "--- Expand Programming category ---"
R=$(run_iez "$IEZ" ui tap --coords "200,138")
assert_ok "Tap Programming" "$R"
sleep 1

refresh_tree
assert_tree_has "Dart skill" "Dart"
assert_tree_has "Python skill" "Python"
assert_tree_has "SQL skill" "SQL"

echo "--- Tap Dart for detail ---"
DART_Y=$(run_iez "$IEZ" ui tree --compact | jq -r '.data.elements[] | select(.label | contains("Dart")) | .frame.y' 2>/dev/null | head -1)
if [ -n "$DART_Y" ] && [ "$DART_Y" != "null" ]; then
  DART_CENTER=$((DART_Y + 28))
  R=$(run_iez "$IEZ" ui tap --coords "200,$DART_CENTER")
else
  R=$(run_iez "$IEZ" ui tap --coords "200,180")
fi
assert_ok "Tap Dart" "$R"
sleep 1

refresh_tree
assert_tree_has "Skill title" "Dart"
assert_tree_has "Level" "Level"
assert_tree_has "Practice button" "Practice"
assert_tree_has "Edit button" "Edit"

echo "--- Tap Practice ---"
R=$(run_iez "$IEZ" ui tap --label "Practice")
assert_ok "Tap Practice" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from skill detail" "$R"
sleep 1

echo "--- Navigate to Achievements ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Achievements")
assert_ok "Tap Achievements" "$R"
sleep 1

refresh_tree
assert_tree_has "Achievements heading" "Achievements"
assert_tree_has "First Steps" "First Steps"
assert_tree_has "Level 5 Club" "Level 5 Club"
assert_tree_has "Polymath" "Polymath"
assert_tree_has "Master" "Master"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Achievements" "$R"
sleep 1

echo "--- Add new skill ---"
R=$(run_iez "$IEZ" ui tap --label "Add Skill")
assert_ok "Tap Add Skill" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Skill"
assert_tree_has "Skill Name field" "Skill Name"
assert_tree_has "Description field" "Description"
assert_tree_has "Save button" "Save Skill"

R=$(run_iez "$IEZ" ui type "Rust" --label "Skill Name")
assert_ok "Type skill name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Skill")
assert_ok "Tap Save Skill" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Skill Tree"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app132_skilltree.png)
assert_ok "Screenshot SkillTree" "$R"

# ============================================================
echo ""
echo "=== App 133: TeamRoster ==="
# ============================================================

fresh_launch "com.test.teamRoster" \
  "$SCRIPT_DIR/team_roster/build/ios/iphonesimulator/Runner.app" \
  "Team Roster"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Team Roster"
assert_tree_has "Team name" "Thunder Hawks"
assert_tree_has "Record" "12-5-1"
assert_tree_has "Alex Rivera" "Alex Rivera"
assert_tree_has "Jordan Kim" "Jordan Kim"
assert_tree_has "Casey Morgan" "Casey Morgan"
assert_tree_has "Taylor Smith" "Taylor Smith"
assert_tree_has "Sam Johnson" "Sam Johnson"
assert_tree_has "Active status" "Active"
assert_tree_has "Injured status" "Injured"
assert_tree_has "Bench status" "Bench"
assert_tree_has "Add FAB" "Add"

echo "--- Tap player for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,300")
assert_ok "Tap Alex Rivera" "$R"
sleep 1

refresh_tree
assert_tree_has "Player name" "Alex Rivera"
assert_tree_has "Position" "Forward"
assert_tree_has "Edit button" "Edit"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from player detail" "$R"
sleep 1

echo "--- Navigate to Schedule ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Schedule")
assert_ok "Tap Schedule" "$R"
sleep 1

refresh_tree
assert_tree_has "Schedule heading" "Schedule"
assert_tree_has "Lightning FC" "Lightning FC"
assert_tree_has "Storm United" "Storm United"
assert_tree_has "Phoenix Rising" "Phoenix Rising"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Schedule" "$R"
sleep 1

echo "--- Add new player ---"
R=$(run_iez "$IEZ" ui tap --label "Add")
assert_ok "Tap Add" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Player"
assert_tree_has "Name field" "Name"
assert_tree_has "Number field" "Number"
assert_tree_has "Position field" "Position"
assert_tree_has "Save button" "Save Player"

R=$(run_iez "$IEZ" ui type "Chris Lee" --label "Name")
assert_ok "Type player name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "15" --label "Number")
assert_ok "Type number" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Player")
assert_ok "Tap Save Player" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Team Roster"
assert_tree_has "New player" "Chris Lee"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app133_teamroster.png)
assert_ok "Screenshot TeamRoster" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
