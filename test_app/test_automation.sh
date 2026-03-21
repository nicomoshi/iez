#!/bin/bash
# Test automation for Apps 119-121: PlantCare/GradeBook/PetTracker
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
  xcrun simctl terminate "$DEVICE_ID" com.test.plantCare 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.gradeBook 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" com.test.petTracker 2>/dev/null || true
  sleep 1
  kill_runners
  xcrun simctl uninstall "$DEVICE_ID" com.test.plantCare 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.gradeBook 2>/dev/null || true
  xcrun simctl uninstall "$DEVICE_ID" com.test.petTracker 2>/dev/null || true
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
echo "=== App 119: PlantCare ==="
# ============================================================

fresh_launch "com.test.plantCare" \
  "$SCRIPT_DIR/plant_care/build/ios/iphonesimulator/Runner.app" \
  "Plant Care"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Plant Care"
assert_tree_has "All filter" "All"
assert_tree_has "Indoor filter" "Indoor"
assert_tree_has "Outdoor filter" "Outdoor"
assert_tree_has "Succulents filter" "Succulents"
assert_tree_has "Herbs filter" "Herbs"
assert_tree_has "Monstera" "Monstera"
assert_tree_has "Basil" "Basil"
assert_tree_has "Aloe Vera" "Aloe Vera"
assert_tree_has "Tomato" "Tomato"
assert_tree_has "Snake Plant" "Snake Plant"
assert_tree_has "Lavender" "Lavender"
assert_tree_has "Healthy emoji" "🌿"
assert_tree_has "Needs water emoji" "🍂"
assert_tree_has "Add Plant FAB" "Add Plant"

echo "--- Filter by Indoor ---"
R=$(run_iez "$IEZ" ui tap --label "Indoor")
assert_ok "Tap Indoor filter" "$R"
sleep 1

refresh_tree
assert_tree_has "Monstera indoor" "Monstera"
assert_tree_has "Snake Plant indoor" "Snake Plant"

echo "--- Filter back to All ---"
R=$(run_iez "$IEZ" ui tap --label "All")
assert_ok "Tap All filter" "$R"
sleep 1

echo "--- Tap plant for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,220")
assert_ok "Tap Monstera" "$R"
sleep 1

refresh_tree
assert_tree_has "Detail name" "Monstera"
assert_tree_has "Species" "Monstera Deliciosa"
assert_tree_has "Water Now" "Water Now"
assert_tree_has "Edit button" "Edit"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from detail" "$R"
sleep 1

echo "--- Navigate to Care Tips ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Care Tips")
assert_ok "Tap Care Tips" "$R"
sleep 1

refresh_tree
assert_tree_has "Care Tips heading" "Care Tips"
assert_tree_has "Watering Basics" "Watering Basics"
assert_tree_has "Sunlight Guide" "Sunlight Guide"
assert_tree_has "Common Problems" "Common Problems"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Care Tips" "$R"
sleep 1

echo "--- Add new plant ---"
R=$(run_iez "$IEZ" ui tap --label "Add Plant")
assert_ok "Tap Add Plant" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Plant"
assert_tree_has "Name field" "Name"
assert_tree_has "Species field" "Species"
assert_tree_has "Location field" "Location"
assert_tree_has "Save button" "Save Plant"

R=$(run_iez "$IEZ" ui type "Fern" --label "Name")
assert_ok "Type plant name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Boston Fern" --label "Species")
assert_ok "Type species" "$R"
sleep 0.5

# Dismiss keyboard and save
R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Plant")
assert_ok "Tap Save Plant" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Plant Care"
assert_tree_has "New plant visible" "Fern"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app119_plantcare.png)
assert_ok "Screenshot PlantCare" "$R"

# ============================================================
echo ""
echo "=== App 120: GradeBook ==="
# ============================================================

fresh_launch "com.test.gradeBook" \
  "$SCRIPT_DIR/grade_book/build/ios/iphonesimulator/Runner.app" \
  "Grade Book"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Grade Book"
assert_tree_has "Data Structures" "Data Structures"
assert_tree_has "Linear Algebra" "Linear Algebra"
assert_tree_has "Operating Systems" "Operating Systems"
assert_tree_has "Art History" "Art History"
assert_tree_has "A grade" "A (94%)"
assert_tree_has "B+ grade" "B+ (88%)"
assert_tree_has "Add Course FAB" "Add Course"

echo "--- Tap course for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,155")
assert_ok "Tap Data Structures" "$R"
sleep 1

refresh_tree
assert_tree_has "Course title" "Data Structures"
assert_tree_has "Instructor" "Prof. Smith"
assert_tree_has "Midterm" "Midterm"
assert_tree_has "Final" "Final"
assert_tree_has "Labs" "Labs"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from course detail" "$R"
sleep 1

echo "--- Navigate to Summary ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Summary")
assert_ok "Tap Summary" "$R"
sleep 1

refresh_tree
assert_tree_has "Summary heading" "Summary"
assert_tree_has "GPA" "GPA"
assert_tree_has "Total Credits" "Total Credits"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Summary" "$R"
sleep 1

echo "--- Add new course ---"
R=$(run_iez "$IEZ" ui tap --label "Add Course")
assert_ok "Tap Add Course" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Course"
assert_tree_has "Course Name field" "Course Name"
assert_tree_has "Instructor field" "Instructor"
assert_tree_has "Credits field" "Credits"
assert_tree_has "Save button" "Save Course"

R=$(run_iez "$IEZ" ui type "Physics 101" --label "Course Name")
assert_ok "Type course name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Prof. Newton" --label "Instructor")
assert_ok "Type instructor" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "3" --label "Credits")
assert_ok "Type credits" "$R"
sleep 0.5

# Dismiss keyboard by tapping blank area, then tap Save
R=$(run_iez "$IEZ" ui tap --coords "200,120")
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Save Course")
assert_ok "Tap Save Course" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Grade Book"
assert_tree_has "New course visible" "Physics 101"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app120_gradebook.png)
assert_ok "Screenshot GradeBook" "$R"

# ============================================================
echo ""
echo "=== App 121: PetTracker ==="
# ============================================================

fresh_launch "com.test.petTracker" \
  "$SCRIPT_DIR/pet_tracker/build/ios/iphonesimulator/Runner.app" \
  "Pet Tracker"

echo "--- Home Screen ---"
refresh_tree
assert_tree_has "App title" "Pet Tracker"
assert_tree_has "Max" "Max"
assert_tree_has "Luna" "Luna"
assert_tree_has "Buddy" "Buddy"
assert_tree_has "Golden Retriever" "Golden Retriever"
assert_tree_has "Siamese" "Siamese"
assert_tree_has "Labrador" "Labrador"
assert_tree_has "Add Pet FAB" "Add Pet"

echo "--- Tap pet for detail ---"
R=$(run_iez "$IEZ" ui tap --coords "200,170")
assert_ok "Tap Max" "$R"
sleep 1

refresh_tree
assert_tree_has "Pet name" "Max"
assert_tree_has "Breed" "Golden Retriever"
assert_tree_has "Vaccinations button" "Vaccinations"
assert_tree_has "Feeding Schedule button" "Feeding Schedule"
assert_tree_has "Edit button" "Edit"

echo "--- Navigate to Vaccinations ---"
R=$(run_iez "$IEZ" ui tap --label "Vaccinations")
assert_ok "Tap Vaccinations" "$R"
sleep 1

refresh_tree
assert_tree_has "Vaccinations heading" "Vaccinations"
assert_tree_has "Rabies" "Rabies"
assert_tree_has "DHPP" "DHPP"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Vaccinations" "$R"
sleep 1

echo "--- Navigate to Feeding Schedule ---"
R=$(run_iez "$IEZ" ui tap --label "Feeding Schedule")
assert_ok "Tap Feeding Schedule" "$R"
sleep 1

refresh_tree
assert_tree_has "Feeding heading" "Feeding Schedule"
assert_tree_has "Kibble" "Kibble"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Feeding" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from pet detail" "$R"
sleep 1

echo "--- Navigate to Vet Directory ---"
R=$(run_iez "$IEZ" ui tap --label "Show menu")
assert_ok "Tap overflow menu" "$R"
sleep 1

R=$(run_iez "$IEZ" ui tap --label "Vet Directory")
assert_ok "Tap Vet Directory" "$R"
sleep 1

refresh_tree
assert_tree_has "Vet heading" "Vet Directory"
assert_tree_has "Dr. Sarah Wilson" "Dr. Sarah Wilson"
assert_tree_has "Dr. James Park" "Dr. James Park"
assert_tree_has "Dr. Emily Brown" "Dr. Emily Brown"

R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "Back from Vet Directory" "$R"
sleep 1

echo "--- Add new pet ---"
R=$(run_iez "$IEZ" ui tap --label "Add Pet")
assert_ok "Tap Add Pet" "$R"
sleep 1

refresh_tree
assert_tree_has "Add heading" "Add Pet"
assert_tree_has "Name field" "Name"
assert_tree_has "Breed field" "Breed"
assert_tree_has "Save button" "Save Pet"

R=$(run_iez "$IEZ" ui type "Coco" --label "Name")
assert_ok "Type pet name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Poodle" --label "Breed")
assert_ok "Type breed" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui tap --coords "200,300")
sleep 0.5
R=$(run_iez "$IEZ" ui swipe up)
sleep 0.5

R=$(run_iez "$IEZ" ui tap --label "Save Pet")
assert_ok "Tap Save Pet" "$R"
sleep 1

refresh_tree
assert_tree_has "Back on home" "Pet Tracker"
assert_tree_has "New pet visible" "Coco"

R=$(run_iez "$IEZ" ui screenshot --out /tmp/app121_pettracker.png)
assert_ok "Screenshot PetTracker" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
