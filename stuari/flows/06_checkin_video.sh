#!/usr/bin/env bash
# Flow 06: Check-In with Video
#
# Same entry as Flow 05 but switches the camera into Video mode, records
# a short clip (~3s), stops, then submits.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 06: Check-In with Video"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_home

# Open camera by tapping an actionable habit card. Mock camera replaces
# simulator hardware only; it must not bypass check-in eligibility.
wait_for_visible_habit_card 15 || true
habit_id=$(actionable_habit_card_id)
habit_label=$(actionable_habit_card_label)
camera_shell_visible() {
  has_id "camera_capture_video_button" ||
    has_id "camera_mode_video_button" ||
    has_id "camera_mode_photo_button" ||
    tree_contains "Video mode" ||
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
else
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Check In")) | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Tap Check In"
  else
    fail "Check In entry not available for video flow"
    capture "06_no_actionable_habit"
    print_summary
    exit $FAIL
  fi
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
    fail "Authoritative occurrence capture context unavailable; video check-in failed closed"
  else
    fail "Camera shell did not open for the selected actionable habit"
  fi
  capture "06_occurrence_capture_context_blocked"
  print_summary
  exit $FAIL
fi
pass "Camera shell opened for the selected occurrence"
capture "06_camera_opened"

# Switch to Video mode
if has_id "camera_mode_video_button"; then
  tap_element "camera_mode_video_button" "id" "Select Video mode"
  sleep 0.5
  capture "06_video_mode"
elif has_label "Video mode"; then
  tap_element "Video mode" "label" "Select Video mode"
  sleep 0.5
  capture "06_video_mode"
else
  fail "Video mode toggle not exposed"
fi

# Start recording
rec_label=""
recording_started=0
if has_id "camera_capture_video_button"; then
  tap_element "camera_capture_video_button" "id" "Start video recording"
  sleep 3
  capture "06_recording"
  recording_started=1
  if has_id "camera_stop_recording_button"; then
    tap_element "camera_stop_recording_button" "id" "Stop recording"
    sleep 2
    capture "06_stopped"
  elif has_label "Stop recording"; then
    tap_element "Stop recording" "label" "Stop recording"
    sleep 2
    capture "06_stopped"
  else
    fail "Stop recording button not found mid-recording"
  fi
elif has_label "Start video recording"; then
  rec_label="Start video recording"
else
  rec_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Start video recording")) | .label' | head -1)
fi
if [ "$recording_started" -eq 1 ]; then
  :
elif [ -n "$rec_label" ]; then
  tap_element "$rec_label" "label" "Start video recording ($rec_label)"
  # Record ~3 seconds
  sleep 3
  capture "06_recording"
  # Stop
  if has_label "Stop recording"; then
    tap_element "Stop recording" "label" "Stop recording"
    sleep 2
    capture "06_stopped"
  else
    fail "Stop recording button not found mid-recording"
  fi
else
  fail "Start video recording button not found"
fi

# Continue to post composition + submit
if has_id "camera_continue_to_post_button"; then
  tap_element "camera_continue_to_post_button" "id" "Continue to compose"
  sleep 1.5
elif has_label "Continue to post"; then
  tap_element "Continue to post" "label" "Continue to compose"
  sleep 1.5
fi

if tree_contains "Share your progress"; then
  type_into "Share your progress..." "$(test_post_description) video"
fi

capture "06_compose"

if has_label "Post"; then
  tap_element "Post" "label" "Submit video post"
  sleep 5  # Video uploads take longer
  capture "06_posted"
  pass "Video check-in submitted"
else
  fail "Post button not visible after video capture"
fi

print_summary
exit $FAIL
