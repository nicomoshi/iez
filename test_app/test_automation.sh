#!/bin/bash
# Test automation for Apps 182-184: PollBooth/FlashSale/PetAdopt
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
  # Kill all Runner processes first
  kill_runners
  sleep 2
  # Uninstall ALL non-Apple apps
  local all_bids
  all_bids=$(xcrun simctl listapps "$DEVICE_ID" 2>/dev/null | grep CFBundleIdentifier | grep -v apple | sed 's/.*"\(.*\)".*/\1/' || true)
  for b in $all_bids; do
    xcrun simctl terminate "$DEVICE_ID" "$b" 2>/dev/null || true
    xcrun simctl uninstall "$DEVICE_ID" "$b" 2>/dev/null || true
  done
  sleep 3
  kill_runners
  sleep 2
  # Install and launch
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
    # If on home screen, try launching again
    if [ "$app_name" = " " ] || [ -z "$app_name" ]; then
      xcrun simctl launch "$DEVICE_ID" "$bid" 2>/dev/null || true
    fi
  done
  echo "  ❌ Failed to launch $expected (saw: '$app_name')"
}

tap_by_coords() {
  local label_grep="$1"
  local result
  result=$(run_iez "$IEZ" ui tree --compact)
  local x y w h
  read -r x y w h < <(echo "$result" | jq -r ".data.elements[] | select(.label | test(\"$label_grep\")) | \"\(.frame.x) \(.frame.y) \(.frame.width) \(.frame.height)\"" 2>/dev/null | head -1)
  if [ -n "$x" ] && [ "$x" != "null" ]; then
    local cx cy
    cx=$(echo "$x $w" | awk '{printf "%.0f", $1 + $2/2}')
    cy=$(echo "$y $h" | awk '{printf "%.0f", $1 + $2/2}')
    run_iez "$IEZ" ui tap --coords "$cx,$cy"
  else
    echo '{"ok":false,"error":"element not found"}'
  fi
}

echo "============================================================"
echo "  App 182: PollBooth"
echo "============================================================"

fresh_launch "com.iez.pollBooth" "$SCRIPT_DIR/poll_booth/build/ios/iphonesimulator/Runner.app" "Poll Booth"
sleep 2

# --- Polls Tab ---
refresh_tree
assert_tree_has "182.01 App title" "Poll Booth"
assert_tree_has "182.02 Polls tab visible" "Polls"
assert_tree_has "182.03 Stats tab visible" "Stats"
assert_tree_has "182.04 Create tab visible" "Create"
assert_tree_has "182.05 Technology poll" "Technology"
assert_tree_has "182.06 Best programming language" "Best programming language?"
assert_tree_has "182.07 Dart option" "Dart"
assert_tree_has "182.08 Python option" "Python"
assert_tree_has "182.09 Rust option" "Rust"
assert_tree_has "182.10 TypeScript option" "TypeScript"
assert_tree_has "182.11 Lifestyle poll" "Lifestyle"
assert_tree_has "182.12 Favorite season" "Favorite season?"
assert_tree_has "182.13 Show menu button" "Show menu"

# Vote on Dart
R=$(run_iez "$IEZ" ui tap --label "Dart")
assert_ok "182.14 Tap Dart to vote" "$R"
sleep 1

refresh_tree
assert_tree_has "182.15 Results show percentages" "29."

# Scroll down to see Work poll
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "182.16 Swipe up to scroll" "$R"
sleep 1

R=$(run_iez "$IEZ" ui swipe up)
assert_ok "182.17 Swipe up again" "$R"
sleep 1

R=$(run_iez "$IEZ" ui swipe up)
sleep 1

refresh_tree
assert_tree_has "182.18 Work poll visible" "Remote or Office?"

# Screenshot polls
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_182_polls.png)
assert_ok "182.19 Screenshot polls" "$R"

# --- Stats Tab --- (scroll back to top first so tab bar is stable)
R=$(run_iez "$IEZ" ui swipe down)
assert_ok "182.20a Scroll back to top" "$R"
sleep 0.5
R=$(run_iez "$IEZ" ui swipe down)
sleep 0.5

R=$(tap_by_coords "^Stats")
assert_ok "182.20 Tap Stats tab" "$R"
sleep 1.5

refresh_tree
assert_tree_has "182.21 Statistics heading" "Statistics"
assert_tree_has "182.22 Total Polls stat" "Total Polls"
assert_tree_has "182.23 Total Votes stat" "Total Votes"
assert_tree_has "182.24 Active Polls stat" "Active Polls"
assert_tree_has "182.25 Most Popular stat" "Most Popular"
assert_tree_has "182.26 Fully Remote top" "Fully Remote"
assert_tree_has "182.27 Votes by Category" "Votes by Category"
assert_tree_has "182.28 Technology category" "Technology"
assert_tree_has "182.29 Food category votes" "Food"

# --- Create Tab ---
R=$(tap_by_coords "^Create")
assert_ok "182.30 Tap Create tab" "$R"
sleep 1

refresh_tree
assert_tree_has "182.31 Create Poll heading" "Create Poll"
assert_tree_has "182.32 Question field" "Question"
assert_tree_has "182.33 Category dropdown" "Technology"
assert_tree_has "182.34 Option 1 field" "Option 1"
assert_tree_has "182.35 Option 2 field" "Option 2"
assert_tree_has "182.36 Option 3 field" "Option 3 (optional)"

# Create a new poll
R=$(run_iez "$IEZ" ui type "Best fruit?" --label "Question")
assert_ok "182.37 Type question" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Apple" --label "Option 1")
assert_ok "182.38 Type option 1" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Banana" --label "Option 2")
assert_ok "182.39 Type option 2" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Cherry" --label "Option 3 (optional)")
assert_ok "182.40 Type option 3" "$R"
sleep 0.5

# Screenshot create form
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_182_create.png)
assert_ok "182.41 Screenshot create form" "$R"

echo ""
echo "============================================================"
echo "  App 183: FlashSale"
echo "============================================================"

fresh_launch "com.iez.flashSale" "$SCRIPT_DIR/flash_sale/build/ios/iphonesimulator/Runner.app" "Flash Sale"
sleep 2

# --- Deals Tab ---
refresh_tree
assert_tree_has "183.01 App title Flash Sale" "Flash Sale"
assert_tree_has "183.02 Flash Sales heading" "Flash Sales"
assert_tree_has "183.03 Up to 60% OFF banner" "Up to 60% OFF"
assert_tree_has "183.04 Limited time text" "Limited time deals"
assert_tree_has "183.05 Deals tab" "Deals"
assert_tree_has "183.06 Saved tab" "Saved"
assert_tree_has "183.07 Profile tab" "Profile"
assert_tree_has "183.08 Wireless Earbuds Pro" "Wireless Earbuds Pro"
assert_tree_has "183.09 Running Shoes Elite" "Running Shoes Elite"
assert_tree_has "183.10 Smart Watch Band" "Smart Watch Band"
assert_tree_has "183.11 Show menu filter" "Show menu"

# Tap on Wireless Earbuds Pro deal (first card around y=290)
R=$(run_iez "$IEZ" ui tap --coords 201,290)
assert_ok "183.12 Tap Wireless Earbuds deal" "$R"
sleep 1

refresh_tree
assert_tree_has "183.13 Deal detail - title" "Wireless Earbuds Pro"
assert_tree_has "183.14 Deal detail - description" "Active noise cancellation"
assert_tree_has "183.15 Deal detail - category" "Electronics"
assert_tree_has "183.16 Deal detail - time" "3 hours"
assert_tree_has "183.17 Deal detail - stock" "22 of 100"
assert_tree_has "183.18 Deal detail - claimed" "78% claimed"
assert_tree_has "183.19 Deal detail - Save %" "Save 60%"
assert_tree_has "183.20 Claim Deal button" "Claim Deal"

# Screenshot deal detail
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_183_detail.png)
assert_ok "183.21 Screenshot deal detail" "$R"

# Go back
R=$(run_iez "$IEZ" ui tap --label "Back")
assert_ok "183.22 Tap Back" "$R"
sleep 1

# --- Saved Tab ---
R=$(tap_by_coords "^Saved")
assert_ok "183.23 Tap Saved tab" "$R"
sleep 1

refresh_tree
assert_tree_has "183.24 Saved Deals heading" "Saved Deals"
assert_tree_has "183.25 No saved deals text" "No saved deals yet"
assert_tree_has "183.26 Bookmark hint" "Tap the bookmark icon"

# --- Profile Tab ---
R=$(tap_by_coords "^Profile")
assert_ok "183.27 Tap Profile tab" "$R"
sleep 1

refresh_tree
assert_tree_has "183.28 Profile heading" "Profile"
assert_tree_has "183.29 User name" "Jane Doe"
assert_tree_has "183.30 User email" "jane.doe@email.com"
assert_tree_has "183.31 Saved count" "Saved"
assert_tree_has "183.32 Avg Discount" "Avg Discount"
assert_tree_has "183.33 Notifications" "Notifications"
assert_tree_has "183.34 Payment Methods" "Payment Methods"
assert_tree_has "183.35 Help Center" "Help Center"
assert_tree_has "183.36 About" "About"

# Screenshot profile
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_183_profile.png)
assert_ok "183.37 Screenshot profile" "$R"

echo ""
echo "============================================================"
echo "  App 184: PetAdopt"
echo "============================================================"

fresh_launch "com.iez.petAdopt" "$SCRIPT_DIR/pet_adopt/build/ios/iphonesimulator/Runner.app" "Pet Adopt"
sleep 2

# --- Browse Tab ---
refresh_tree
assert_tree_has "184.01 App title Pet Adopt" "Pet Adopt"
assert_tree_has "184.02 Find a Pet heading" "Find a Pet"
assert_tree_has "184.03 Browse tab" "Browse"
assert_tree_has "184.04 Favorites tab" "Favorites"
assert_tree_has "184.05 Add Pet tab" "Add Pet"
assert_tree_has "184.06 Search field" "Search by name or breed"
assert_tree_has "184.07 All filter chip" "All"
assert_tree_has "184.08 Dog filter chip" "Dog"
assert_tree_has "184.09 Cat filter chip" "Cat"
assert_tree_has "184.10 Rabbit filter chip" "Rabbit"
assert_tree_has "184.11 Bird filter chip" "Bird"
assert_tree_has "184.12 8 pets available" "8 pets available"
assert_tree_has "184.13 Buddy listing" "Buddy"
assert_tree_has "184.14 Luna listing" "Luna"
assert_tree_has "184.15 Max listing" "Max"
assert_tree_has "184.16 Coco listing" "Coco"
assert_tree_has "184.17 Kiwi listing" "Kiwi"

# Tap Buddy to see detail
R=$(run_iez "$IEZ" ui tap --coords 201,330)
assert_ok "184.18 Tap Buddy card" "$R"
sleep 1

refresh_tree
assert_tree_has "184.19 Detail - Buddy heading" "Buddy"
assert_tree_has "184.20 Detail - breed info" "Golden Retriever"
assert_tree_has "184.21 Detail - shelter" "Happy Paws Shelter"
assert_tree_has "184.22 Detail - Dog chip" "Dog"

# Scroll down to see more detail elements
R=$(run_iez "$IEZ" ui swipe up)
assert_ok "184.23 Scroll detail down" "$R"
sleep 1

refresh_tree
assert_tree_has "184.24 Detail - description" "Friendly and playful"
assert_tree_has "184.25 Detail - Vaccinated chip" "Vaccinated"
assert_tree_has "184.26 Detail - Neutered chip" "Neutered"
assert_tree_has "184.27 About section" "About"
assert_tree_has "184.28 Adopt Me button" "Adopt Me"

# Tap Adopt Me to see dialog
R=$(run_iez "$IEZ" ui tap --label "Adopt Me")
assert_ok "184.29 Tap Adopt Me" "$R"
sleep 2

refresh_tree
assert_tree_has "184.30 Adoption dialog title" "Adoption Request"
assert_tree_has "184.31 Dialog message" "Your request to adopt Buddy"
assert_tree_has "184.32 OK button" "OK"

# Dismiss dialog — OK dismisses and pops back to browse
R=$(run_iez "$IEZ" ui tap --label "OK")
assert_ok "184.33 Dismiss adoption dialog" "$R"
sleep 2

# Screenshot browse
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_184_browse.png)
assert_ok "184.34 Screenshot browse" "$R"

# --- Favorites Tab ---
R=$(tap_by_coords "^Favorites")
assert_ok "184.35 Tap Favorites tab" "$R"
sleep 1

refresh_tree
assert_tree_has "184.36 Favorites heading" "Favorites"
assert_tree_has "184.37 No favorites yet" "No favorites yet"
assert_tree_has "184.38 Heart hint text" "Heart a pet to save it here"

# --- Add Pet Tab ---
R=$(tap_by_coords "^Add Pet")
assert_ok "184.39 Tap Add Pet tab" "$R"
sleep 1

refresh_tree
assert_tree_has "184.40 List a Pet heading" "List a Pet"
assert_tree_has "184.41 Pet Name field" "Pet Name"
assert_tree_has "184.42 Type dropdown" "Dog"
assert_tree_has "184.43 Breed field" "Breed"
assert_tree_has "184.44 Gender dropdown" "Male"
assert_tree_has "184.45 Description field" "Description"
assert_tree_has "184.46 Shelter Name field" "Shelter Name"
assert_tree_has "184.47 List Pet button" "List Pet"

# Fill in new pet form
R=$(run_iez "$IEZ" ui type "Daisy" --label "Pet Name")
assert_ok "184.48 Type pet name" "$R"
sleep 0.5

R=$(run_iez "$IEZ" ui type "Poodle" --label "Breed")
assert_ok "184.49 Type breed" "$R"
sleep 0.5

# Screenshot add pet form
R=$(run_iez "$IEZ" ui screenshot --out /tmp/iez_184_addpet.png)
assert_ok "184.50 Screenshot add pet form" "$R"

# ============================================================
echo ""
echo "========================================="
echo "  FINAL: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
