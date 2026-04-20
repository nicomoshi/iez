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

# Open camera by tapping a habit card (same approach as flow 05).
# See 05_checkin_photo.sh for the rationale behind matching " habit, ".
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
if [ -n "$habit_label" ]; then
  tap_element "$habit_label" "label" "Tap habit card ('$habit_label')"
else
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Check In")) | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Tap Check In"
  else
    skip "Check In entry" "no habit card or Check In button visible"
  fi
fi
sleep 2
capture "06_camera_opened"

# Switch to Video mode
if has_label "Video mode"; then
  tap_element "Video mode" "label" "Select Video mode"
  sleep 0.5
  capture "06_video_mode"
else
  skip "Video mode toggle" "mode selector not exposed"
fi

# Start recording
rec_label=""
if has_label "Start video recording"; then
  rec_label="Start video recording"
else
  rec_label=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[] | select(.label != null) | select(.label | startswith("Start video recording")) | .label' | head -1)
fi
if [ -n "$rec_label" ]; then
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
if has_label "Continue to post"; then
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
  skip "Post button" "not visible"
fi

print_summary
exit $FAIL
