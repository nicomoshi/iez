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

VIDEO_FIXTURE_CLEANUP_RAN=0
VIDEO_FIXTURE_RESEEDED=0
cleanup_video_due_now_fixture() {
  if [ "${VIDEO_FIXTURE_CLEANUP_RAN:-0}" = "1" ]; then
    return 0
  fi
  VIDEO_FIXTURE_CLEANUP_RAN=1
  if [ "${VIDEO_FIXTURE_RESEEDED:-0}" != "1" ]; then
    return 0
  fi
  if ! cleanup_due_now_occurrence_fixture; then
    fail "Reserved due-now occurrence fixture cleanup succeeded for video flow"
    return 1
  fi
}

finish_video_flow() {
  cleanup_video_due_now_fixture
  trap - EXIT INT TERM
  print_summary
  exit $FAIL
}

exit_video_flow_for_signal() {
  local signal_status="${1:-1}"
  cleanup_video_due_now_fixture
  trap - EXIT INT TERM
  exit "$signal_status"
}

trap cleanup_video_due_now_fixture EXIT
trap 'exit_video_flow_for_signal 130' INT
trap 'exit_video_flow_for_signal 143' TERM

if ! ensure_verified_alice_session; then
  fail "Verified Alice persisted session ready for video flow"
  capture "06_alice_session_not_ready"
  finish_video_flow
fi

if ! reseed_due_now_occurrence_fixture; then
  fail "Due-now authoritative occurrence fixture available for video flow"
  finish_video_flow
fi
VIDEO_FIXTURE_RESEEDED=1

fresh_launch; sleep 2
if on_onboarding_page; then complete_onboarding; fi
if ! persisted_session_is_verified_alice; then
  fail "Fresh relaunch preserved verified Alice persisted session for video flow"
  capture "06_relaunch_lost_alice"
  finish_video_flow
fi
if ! wait_for_due_now_occurrence_drift_authority 20 1; then
  fail "Local Drift authority ready for due-now video fixture"
  capture "06_drift_authority_missing"
  finish_video_flow
fi

go_home

# Open camera by tapping the reserved due-now fixture card. Mock camera
# replaces simulator hardware only; it must not bypass check-in eligibility.
habit_id="$DUE_NOW_HABIT_CARD_ID"
camera_shell_visible() {
  has_id "camera_capture_video_button" ||
  has_id "camera_mode_video_button" ||
  has_id "camera_mode_photo_button" ||
  tree_contains "Video mode" ||
  tree_contains "Take photo"
}
capture "06_home"
if ! select_habit_card_by_id "$habit_id"; then
  fail "Reserved due-now fixture card selected exactly for video flow"
  capture "06_habit_selection_failed"
  finish_video_flow
fi

selected_habit_id="$(current_visible_habit_card_id)"
selected_habit_label="$(current_visible_habit_card_label)"
if [ "$selected_habit_id" != "$habit_id" ]; then
  fail "Centered habit card matched the reserved due-now fixture id"
  capture "06_wrong_centered_habit"
  finish_video_flow
fi
if ! habit_card_label_is_actionable "$selected_habit_label"; then
  fail "Reserved due-now fixture card is actionable before video camera entry"
  capture "06_non_actionable_selected_habit"
  finish_video_flow
fi
pass "Selected exact actionable due-now fixture card"
capture "06_habit_selected"

r=$(run_iez "$IEZ" ui tap --id "$habit_id")
if [ "$(json_ok "$r")" = "true" ]; then
  pass "Tap: Tap habit card by id ('$habit_id')"
else
  info "Habit id tap did not report success; trying visible card coordinates"
fi
sleep 1
if ! camera_shell_visible; then
  habit_coords=$(coords_for_id "$habit_id")
  if [ -n "$habit_coords" ] && [ "$habit_coords" != "null" ] && [ "$habit_coords" != "," ]; then
    tap_element "$habit_coords" "coords" "Tap visible habit card center ('$habit_id')"
  fi
fi
sleep 1

sleep 2
if ! camera_shell_visible; then
  fail "Camera shell opened for the selected exact actionable habit"
  capture "06_occurrence_capture_context_blocked"
  finish_video_flow
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

finish_video_flow
