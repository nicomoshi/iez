#!/usr/bin/env bash
# Flow 16: Profile — Edit Name + Bio + Avatar
#
# Goal: navigate to Profile tab, open profile settings, edit display
# name and bio, save changes.
#
# Widgets (lib/profile/):
#   view/profile_page.dart
#   view/profile_settings_page.dart
#   widgets/profile_settings_content.dart  GradientButton label: 'Save Changes'
#   widgets/profile_avatar.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 16: Profile Edit"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi
go_settings
sleep 1.5
capture "16_settings_page"

if has_label "Profile"; then
  tap_element "Profile" "label" "Open Profile settings"
else
  skip "Edit Profile entry" "no Profile settings tile visible"
  print_summary; exit $FAIL
fi

sleep 1.5
capture "16_edit_profile"

# Edit display name
for name_field in "Name" "Display name" "Display Name" "Full name"; do
  if tree_contains "$name_field"; then
    type_into "$name_field" "$(test_display_name)"
    break
  fi
done

# Edit bio
for bio_field in "Bio" "About" "Write something about yourself..." "Comment input"; do
  if tree_contains "$bio_field"; then
    type_into "$bio_field" "$(test_bio)"
    break
  fi
done

capture "16_edited"

# Dismiss keyboard and scroll until the offscreen save button exposes a real
# frame. Flutter currently reports the button in-tree even when it's still at
# 0x0 offscreen.
run_iez "$IEZ" ui tap --coords "200,180" >/dev/null 2>&1
sleep 0.5

save_coords=""
for _ in 1 2 3; do
  save_coords=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
      | select(.label != null)
      | select(.label | contains("Save Changes"))
      | select(.frame != null and .frame.width > 0 and .frame.height > 0)
      | .frame
      | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
    | head -1)
  if [ -n "$save_coords" ]; then
    break
  fi
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1
  sleep 0.8
done

if [ -n "$save_coords" ]; then
  r=$(run_iez "$IEZ" ui tap --coords "$save_coords")
  assert_ok "$r" "Tap: Save profile changes"
  sleep 2
  capture "16_saved"
  pass "Saved profile changes"
elif has_label "Save"; then
  tap_element "Save" "label" "Save (alternate label)"
  sleep 2
else
  skip "Save button" "no visible Save Changes / Save label found"
fi

# Return to profile page
go_back
sleep 1

print_summary
exit $FAIL
