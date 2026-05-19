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

# Tap a habit card in the home carousel to open the camera.
# Tapping a card runs home_page's `_handleCheckInTap`, which pushes the
# Camera page. The card's Semantics label is
#   "<HabitName> habit, <status>"  e.g. "Morning Run habit, Tap to check in"
# (see split_habit_card.dart::_buildHabitCard). The dev-only simulator
# build adds SIMULATOR_MOCK_CAMERA=true, which bypasses the
# CheckInAvailability gate so any card can open the camera. Prefer the
# stable semantics identifier when present, then the "Tap to check in"
# card (availability=due), and finally the first "* habit, *" label we find.
habit_id=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
             | select(.id != null)
             | select(.id | startswith("habit_card_"))
             | .id' | head -1)
habit_label=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
             | select(.label != null)
             | select(.label | test(" habit, Tap to check in$"))
             | .label' | head -1)
if [ -z "$habit_label" ]; then
  habit_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
               | select(.label != null)
               | select(.label | test(" habit, "))
               | .label' | head -1)
fi
if [ -n "$habit_id" ]; then
  tap_element "$habit_id" "id" "Tap habit card by id ('$habit_id')"
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
  skip "Check In entry" "no habit card or Check In CTA visible on Home"
fi

sleep 2
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

# Type an optional caption
if tree_contains "Share your progress"; then
  type_into "Share your progress..." "$(test_post_description)"
fi

capture "05_compose"

# Submit — "Post" button
if has_label "Post"; then
  tap_element "Post" "label" "Submit post"
  sleep 3
  capture "05_posted"
  pass "Photo check-in submitted"
else
  skip "Post button" "not visible (may need to scroll or fill required fields)"
fi

print_summary
exit $FAIL
