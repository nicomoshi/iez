#!/usr/bin/env bash
# Flow 05: Check-In with Photo
#
# Walks: Home → tap habit → check-in FAB → Camera (photo mode) → capture
#         → compose post → Post.
#
# Camera widgets (from lib/camera/widgets/):
#   camera_controls.dart
#     label: 'Take photo' / 'Take photo with N second countdown'
#     label: 'Stop recording' (during video)
#   camera_mode_selector.dart
#     label: 'Photo mode' / 'Video mode' / 'Camera mode selector...'
#   submit_form_description.dart hint: 'Share your progress...'
#   submit_form_post_button.dart child: 'Post'

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 05: Check-In with Photo"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home
capture "05_home"

# Tap an actionable habit card in the home carousel to open the camera.
# Tapping a card runs home_page's `_handleCheckInTap`, which pushes the
# Camera page only for due or missed habits. SIMULATOR_MOCK_CAMERA replaces
# hardware on iOS simulators but must not bypass that product rule.
wait_for_visible_habit_card 15 || true
habit_id=$(actionable_habit_card_id)
habit_label=$(actionable_habit_card_label)
camera_shell_visible() {
  has_id "camera_capture_photo_button" ||
    has_id "camera_mode_photo_button" ||
    tree_contains "Take photo"
}
if [ -n "$habit_id" ]; then
  r=$(run_iez "$IEZ" ui tap --id "$habit_id")
  if [ "$(json_ok "$r")" = "true" ]; then
    pass "Tap: Tap habit card by id ('$habit_id')"
  else
    info "Habit id tap did not report success; trying visible card coordinates"
  fi
elif [ -n "$habit_label" ]; then
  tap_element "$habit_label" "label" "Tap habit card ('$habit_label')"
elif has_label "Check In" || tree_contains "Check In"; then
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Check In")) | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Tap Check In button ('$dyn')"
  else
    tap_element "Check In" "label" "Tap Check In"
  fi
else
  fail "Check In entry not available for photo flow"
  capture "05_no_actionable_habit"
  print_summary
  exit $FAIL
fi

sleep 1
if ! camera_shell_visible && [ -n "$habit_id" ]; then
  habit_coords=$(coords_for_id "$habit_id")
  if [ -n "$habit_coords" ] && [ "$habit_coords" != "null" ] && [ "$habit_coords" != "," ]; then
    tap_element "$habit_coords" "coords" "Tap visible habit card center ('$habit_id')"
  fi
fi
sleep 1
if ! camera_shell_visible && [ -n "$habit_label" ]; then
  tap_first_matching_label_regex \
    " habit, (Tap to check in|Streak at risk)" \
    "" \
    "Tap actionable habit card by visible label" || true
fi

sleep 2
if ! camera_shell_visible; then
  app_container=$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data 2>/dev/null)
  db_path="$app_container/tmp/stuari_offline.sqlite"
  occurrence_count=""
  if [ -f "$db_path" ]; then
    occurrence_count=$(sqlite3 "$db_path" \
      "select count(*) from occurrence_snapshots;" 2>/dev/null)
  fi
  info "Local authoritative occurrence snapshots: ${occurrence_count:-unavailable}"
  if tree_contains "Refresh this habit before checking in" ||
    [ "${occurrence_count:-0}" -eq 0 ]; then
    fail "Authoritative occurrence capture context unavailable; check-in failed closed"
  else
    fail "Camera shell did not open for the selected actionable habit"
  fi
  capture "05_occurrence_capture_context_blocked"
  print_summary
  exit $FAIL
fi
pass "Camera shell opened for the selected occurrence"
capture "05_camera_opened"

# Ensure we're on Photo mode
if has_id "camera_mode_photo_button"; then
  tap_element "camera_mode_photo_button" "id" "Select Photo mode"
  sleep 0.5
elif has_label "Photo mode"; then
  tap_element "Photo mode" "label" "Select Photo mode"
  sleep 0.5
fi

# Tap the shutter ("Take photo" or the countdown variant)
shutter_label=""
photo_captured=0
if has_id "camera_capture_photo_button"; then
  tap_element "camera_capture_photo_button" "id" "Shutter (photo)"
  sleep 2
  capture "05_photo_captured"
  photo_captured=1
elif has_label "Take photo"; then
  shutter_label="Take photo"
else
  shutter_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Take photo")) | .label' | head -1)
fi
if [ "$photo_captured" -eq 1 ]; then
  :
elif [ -n "$shutter_label" ]; then
  tap_element "$shutter_label" "label" "Shutter ($shutter_label)"
  sleep 2
  capture "05_photo_captured"
else
  fail "Shutter button not found"
  capture "05_no_shutter"
fi

# Continue to post composition
if has_id "camera_continue_to_post_button"; then
  tap_element "camera_continue_to_post_button" "id" "Continue to post composer"
  sleep 1.5
elif has_label "Continue to post"; then
  tap_element "Continue to post" "label" "Continue to post composer"
  sleep 1.5
fi

# Type an optional caption. Keep the value in memory so the feed assertion can
# prove the just-submitted post is visible immediately, before confirmation.
post_description="$(test_post_description)"
post_description_display="$(
  printf '%s' "$post_description" \
    | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
)"
wait_for_tree_text "Post" 8 || true
if tree_contains "Share your progress"; then
  type_into "Share your progress..." "$post_description"
fi

capture "05_compose"

# Submit — "Post" button
if has_label "Post"; then
  tap_element "Post" "label" "Submit post"
  sleep 3
  capture "05_posted"
  pass "Photo check-in submitted"

  go_home
  sleep 1
  expand_home_sheet_to_feed
  capture "05_feed_after_post"
  if wait_for_tree_text "$post_description" 12 ||
     wait_for_tree_text "$post_description_display" 2; then
    pass "New check-in appears in feed immediately"
  elif tree_contains "Posting..." || tree_contains "Syncing..." || tree_contains "Retrying..."; then
    pass "New check-in appears as optimistic feed card"
  else
    fail "New check-in did not appear in feed after posting"
    capture "05_feed_missing_new_post"
  fi

  go_home
  sleep 1
  if ! wait_for_visible_habit_card 3; then
    run_iez "$IEZ" ui swipe --from "200,330" --to "200,780" >/dev/null
    sleep 1
  fi
  if ! wait_for_visible_habit_card 8; then
    fail "Habit carousel visible after posting"
    capture "05_home_after_post_missing_card"
  fi
  capture "05_home_after_post"
  selected_habit_label=$(current_visible_habit_card_label)
  selected_habit_name=$(
    printf '%s' "$selected_habit_label" |
      sed 's/^Habit card: //; s/ habit,.*$//'
  )
  pull_to_refresh_home
  wait_for_visible_habit_card 5 || true
  capture "05_home_after_post_refresh"
  submitted_card_label=$(current_visible_habit_card_label)
  submitted_habit_name=$(
    printf '%s' "$submitted_card_label" |
      sed 's/^Habit card: //; s/ habit,.*$//'
  )
  if [ -z "$submitted_card_label" ]; then
    fail "Submitted habit card remains visible after refresh"
    capture "05_refresh_missing_submitted_card"
  elif [ -n "$selected_habit_name" ] &&
    [ "$submitted_habit_name" != "$selected_habit_name" ]; then
    fail "Submitted habit remains selected after refresh ($selected_habit_name -> $submitted_habit_name)"
    capture "05_refresh_changed_submitted_card"
  elif echo "$submitted_card_label" | grep -q "Tap to check in"; then
    fail "Submitted habit card re-enabled check-in after refresh"
    capture "05_refresh_reenabled_checkin"
  else
    pass "Submitted habit card stays selected and blocked after refresh"
  fi
else
  skip "Post button" "not visible (may need to scroll or fill required fields)"
fi

print_summary
exit $FAIL
