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
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
cleanup_video_due_now_fixture() {
  if [ "${VIDEO_FIXTURE_CLEANUP_RAN:-0}" = "1" ]; then
    return 0
  fi
  VIDEO_FIXTURE_CLEANUP_RAN=1
  if [ "${STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED:-0}" != "1" ]; then
    mark_flow_cleanup_complete
    return 0
  fi
  # Publish the fail-closed state before the remote command starts. If the
  # flow receives TERM while cleanup is running, EXIT recovery cannot mistake
  # an interrupted command for proven cleanup.
  mark_flow_cleanup_required
  if ! cleanup_due_now_occurrence_fixture; then
    mark_flow_cleanup_required
    fail "Reserved due-now occurrence fixture cleanup failed for video flow"
    return 1
  fi
  mark_flow_cleanup_complete
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
if ! fail_fast_stuari_foreground_app_identity "video flow carousel selection before"; then
  finish_video_flow
fi
if ! select_habit_card_by_id "$habit_id"; then
  fail "Reserved due-now fixture card selected exactly for video flow"
  capture "06_habit_selection_failed"
  finish_video_flow
fi
if ! fail_fast_stuari_foreground_app_identity "video flow carousel selection after"; then
  finish_video_flow
fi

selected_habit_id="$(current_visible_habit_card_id)"
if [ "$selected_habit_id" != "$habit_id" ]; then
  fail "Centered habit card matched the reserved due-now fixture id"
  capture "06_wrong_centered_habit"
  finish_video_flow
fi
if ! wait_for_habit_card_actionable "$habit_id" 8 0.25; then
  fail "Reserved due-now fixture card became actionable before video camera entry"
  capture "06_non_actionable_selected_habit"
  finish_video_flow
fi
selected_habit_label="$(current_visible_habit_card_label)"
if ! habit_card_label_is_actionable "$selected_habit_label"; then
  fail "Reserved due-now fixture card is actionable before video camera entry"
  capture "06_non_actionable_selected_habit"
  finish_video_flow
fi
pass "Selected exact actionable due-now fixture card"
capture "06_habit_selected"

if ! tap_element "$habit_id" "id" "Tap exact actionable habit card ('$habit_id')" "AXButton"; then
  capture "06_habit_tap_failed"
  finish_video_flow
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
if ! has_id "camera_mode_video_button"; then
  fail "Video mode toggle not exposed"
  capture "06_video_mode_toggle_missing"
  finish_video_flow
fi
if ! tap_camera_control_by_id "camera_mode_video_button" "Select Video mode"; then
  capture "06_video_mode_tap_failed"
  finish_video_flow
fi
if ! wait_for_camera_state "video" 8 0.25; then
  fail "Camera entered video-selected state"
  capture "06_video_mode_state_missing"
  finish_video_flow
fi
pass "Camera entered video-selected state"
capture "06_video_mode"

# Start recording
if ! has_id "camera_capture_video_button"; then
  fail "Start video recording button not found"
  capture "06_video_capture_button_missing"
  finish_video_flow
fi
if ! tap_camera_control_by_id \
    "camera_capture_video_button" "Start video recording"; then
  capture "06_start_recording_tap_failed"
  finish_video_flow
fi
if ! wait_for_camera_state "recording" 8 0.25; then
  fail "Camera entered recording state"
  capture "06_recording_state_missing"
  finish_video_flow
fi
pass "Camera entered recording state"
sleep 3
capture "06_recording"
if ! tap_camera_control_by_id \
    "camera_stop_recording_button" "Stop recording"; then
  capture "06_stop_recording_tap_failed"
  finish_video_flow
fi
if ! wait_for_camera_state "captured" 15 0.25; then
  fail "Video recording reached captured-media state"
  capture "06_video_capture_state_missing"
  finish_video_flow
fi
pass "Video recording reached captured-media state"
capture "06_stopped"

# Continue to post composition + submit
if ! tap_camera_control_by_id \
    "camera_continue_to_post_button" "Continue to compose"; then
  capture "06_continue_to_post_tap_failed"
  finish_video_flow
fi
if ! wait_for_camera_state "compose" 10 0.25; then
  fail "Video capture opened the real post composer"
  capture "06_compose_state_missing"
  finish_video_flow
fi
pass "Video capture opened the real post composer"

video_caption_base="$(stuari_due_now_fixture_post_caption 2>/dev/null || true)"
if [ -z "$video_caption_base" ]; then
  fail "Unique video post caption derived from the active due-now fixture"
  finish_video_flow
fi
video_post_description="$video_caption_base video"
if ! type_into_checkin_route_field \
    "Share your progress..." "$video_post_description"; then
  capture "06_caption_interaction_failed"
  finish_video_flow
fi
if ! wait_for_checkin_input_progress "$video_post_description" 8 0.25; then
  fail "Video input length/progress reflected after composer interaction"
  capture "06_input_progress_missing"
  finish_video_flow
fi
pass "Video input length/progress reflected in the composer"
if ! dismiss_checkin_route_keyboard; then
  capture "06_keyboard_dismissal_failed"
  finish_video_flow
fi

capture "06_compose"

if ! submit_checkin_post_with_one_delivery_retry "Submit video post" 20 0.25 0; then
  capture "06_post_interaction_failed"
  finish_video_flow
fi
if ! wait_for_checkin_post_completion 20 0.25; then
  fail "Video post left the composer and returned to Home"
  capture "06_post_completion_missing"
  finish_video_flow
fi
pass "Video check-in submitted and returned to Home"
capture "06_posted"

expand_home_sheet_to_feed
if wait_for_exact_post_caption "$video_post_description" 15 0.25; then
  capture "06_feed_after_post"
  if tree_contains "Posting..." || tree_contains "Syncing..." || tree_contains "Retrying..."; then
    pass "Exact video caption appears in an optimistic feed post"
  else
    pass "Exact video caption appears in the published feed post"
  fi
else
  fail "Exact video caption did not appear in a rendered feed post"
  capture "06_feed_missing_new_post"
fi

finish_video_flow
