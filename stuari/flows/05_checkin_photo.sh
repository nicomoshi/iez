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

PHOTO_FIXTURE_CLEANUP_RAN=0
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=0
cleanup_photo_due_now_fixture() {
  if [ "${PHOTO_FIXTURE_CLEANUP_RAN:-0}" = "1" ]; then
    return 0
  fi
  PHOTO_FIXTURE_CLEANUP_RAN=1
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
    fail "Reserved due-now occurrence fixture cleanup failed for photo flow"
    return 1
  fi
  mark_flow_cleanup_complete
}

finish_photo_flow() {
  cleanup_photo_due_now_fixture
  trap - EXIT INT TERM
  print_summary
  exit $FAIL
}

exit_photo_flow_for_signal() {
  local signal_status="${1:-1}"
  cleanup_photo_due_now_fixture
  trap - EXIT INT TERM
  exit "$signal_status"
}

trap cleanup_photo_due_now_fixture EXIT
trap 'exit_photo_flow_for_signal 130' INT
trap 'exit_photo_flow_for_signal 143' TERM

if ! ensure_verified_alice_session; then
  fail "Verified Alice persisted session ready for photo flow"
  capture "05_alice_session_not_ready"
  finish_photo_flow
fi

if ! reseed_due_now_occurrence_fixture; then
  fail "Due-now authoritative occurrence fixture available for photo flow"
  finish_photo_flow
fi

fresh_launch; sleep 2
if on_onboarding_page; then complete_onboarding; fi
if ! persisted_session_is_verified_alice; then
  fail "Fresh relaunch preserved verified Alice persisted session for photo flow"
  capture "05_relaunch_lost_alice"
  finish_photo_flow
fi
if ! wait_for_due_now_occurrence_drift_authority 20 1; then
  fail "Local Drift authority ready for due-now photo fixture"
  capture "05_drift_authority_missing"
  finish_photo_flow
fi

go_home
capture "05_home"

# Tap the reserved due-now fixture card in the home carousel to open the
# camera. The exact card id prevents another habit from satisfying this flow.
# Tapping a card runs home_page's `_handleCheckInTap`, which pushes the
# Camera page only for due or missed habits. SIMULATOR_MOCK_CAMERA replaces
# hardware on iOS simulators but must not bypass that product rule.
habit_id="$DUE_NOW_HABIT_CARD_ID"
camera_shell_visible() {
  has_id "camera_capture_photo_button" ||
    has_id "camera_mode_photo_button" ||
    tree_contains "Take photo"
}
if ! fail_fast_stuari_foreground_app_identity "photo flow carousel selection before"; then
  finish_photo_flow
fi
if ! select_habit_card_by_id "$habit_id"; then
  fail "Reserved due-now fixture card selected exactly for photo flow"
  capture "05_habit_selection_failed"
  finish_photo_flow
fi
if ! fail_fast_stuari_foreground_app_identity "photo flow carousel selection after"; then
  finish_photo_flow
fi

selected_habit_id="$(current_visible_habit_card_id)"
if [ "$selected_habit_id" != "$habit_id" ]; then
  fail "Centered habit card matched the reserved due-now fixture id"
  capture "05_wrong_centered_habit"
  finish_photo_flow
fi
if ! wait_for_habit_card_actionable "$habit_id" 8 0.25; then
  fail "Reserved due-now fixture card became actionable before camera entry"
  capture "05_non_actionable_selected_habit"
  finish_photo_flow
fi
selected_habit_label="$(current_visible_habit_card_label)"
if ! habit_card_label_is_actionable "$selected_habit_label"; then
  fail "Reserved due-now fixture card is actionable before camera entry"
  capture "05_non_actionable_selected_habit"
  finish_photo_flow
fi
pass "Selected exact actionable due-now fixture card"
capture "05_habit_selected"

if ! tap_element "$habit_id" "id" "Tap exact actionable habit card ('$habit_id')" "AXButton"; then
  capture "05_habit_tap_failed"
  finish_photo_flow
fi
sleep 1

sleep 2
if ! camera_shell_visible; then
  fail "Camera shell opened for the selected exact actionable habit"
  capture "05_occurrence_capture_context_blocked"
  finish_photo_flow
fi
pass "Camera shell opened for the selected occurrence"
capture "05_camera_opened"

# Camera-originated routes can expose either normal or scaled AX frames.
# Resolve rendered coordinates per tree, then require each state transition.
if ! has_id "camera_capture_photo_button"; then
  fail "Shutter button not found"
  capture "05_no_shutter"
  finish_photo_flow
fi
if ! tap_camera_control_by_id "camera_capture_photo_button" "Shutter (photo)"; then
  capture "05_photo_shutter_tap_failed"
  finish_photo_flow
fi
if ! wait_for_camera_state "captured" 10 0.25; then
  fail "Photo capture reached captured-media state"
  capture "05_photo_capture_state_missing"
  finish_photo_flow
fi
pass "Photo capture reached captured-media state"
capture "05_photo_captured"

# Continue to post composition
if ! tap_camera_control_by_id \
    "camera_continue_to_post_button" "Continue to post composer"; then
  capture "05_continue_to_post_tap_failed"
  finish_photo_flow
fi
if ! wait_for_camera_state "compose" 10 0.25; then
  fail "Photo capture opened the real post composer"
  capture "05_compose_state_missing"
  finish_photo_flow
fi
pass "Photo capture opened the real post composer"

# Type an optional caption. Keep the value in memory so the feed assertion can
# prove the just-submitted post is visible immediately, before confirmation.
post_description="$(stuari_due_now_fixture_post_caption)"
if [ -z "$post_description" ]; then
  fail "Unique photo post caption derived from the active due-now fixture"
  finish_photo_flow
fi
if ! type_into_checkin_route_field "Share your progress..." "$post_description"; then
  capture "05_caption_interaction_failed"
  finish_photo_flow
fi
if ! wait_for_checkin_input_progress "$post_description" 8 0.25; then
  fail "Photo input length/progress reflected after composer interaction"
  capture "05_input_progress_missing"
  finish_photo_flow
fi
pass "Photo input length/progress reflected in the composer"
if ! dismiss_checkin_route_keyboard; then
  capture "05_keyboard_dismissal_failed"
  finish_photo_flow
fi

capture "05_compose"

# Submit — "Post" button
if ! submit_checkin_post_with_one_delivery_retry "Submit post" 15 0.25 0; then
  capture "05_post_interaction_failed"
  finish_photo_flow
fi
if ! wait_for_checkin_post_completion 15 0.25; then
  fail "Photo post left the composer and returned to Home"
  capture "05_post_completion_missing"
  finish_photo_flow
fi
pass "Photo check-in submitted and returned to Home"
capture "05_posted"

expand_home_sheet_to_feed
if wait_for_exact_post_caption "$post_description" 12 0.25; then
  capture "05_feed_after_post"
  if tree_contains "Posting..." || tree_contains "Syncing..." || tree_contains "Retrying..."; then
    pass "Exact photo caption appears in an optimistic feed post"
  else
    pass "Exact photo caption appears in the published feed post"
  fi
else
  fail "Exact photo caption did not appear in a rendered feed post"
  capture "05_feed_missing_new_post"
fi

go_home
sleep 1
if ! wait_for_visible_habit_card 3; then
  if ! stuari_app_swipe "200,330" "200,780" "Reveal habit carousel after photo post"; then
    fail "Reveal habit carousel after photo post"
  fi
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
finish_photo_flow
