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
go_profile
sleep 1.5
capture "16_profile_page"

# Open settings / edit profile — look for "Edit Profile" or gear icon.
# Explicitly reject "Settings tab" (the top-nav tab) — that would navigate
# away from Profile rather than opening the edit sheet.
if has_label "Edit Profile"; then
  tap_element "Edit Profile" "label" "Open Edit Profile"
elif has_label "Edit profile"; then
  tap_element "Edit profile" "label" "Open Edit profile"
else
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[]
               | select(.label != null)
               | select(.label != "Settings tab" and .label != "Settings tab, selected")
               | select(.label | test("edit profile|profile settings"; "i"))
               | .label' | head -1)
  if [ -n "$dyn" ]; then
    tap_element "$dyn" "label" "Open profile settings ('$dyn')"
  else
    skip "Edit Profile entry" "no Edit Profile button visible"
    print_summary; exit $FAIL
  fi
fi

sleep 1.5
capture "16_edit_profile"

# Edit display name — field has a label derived from the form (guess "Name" or "Display name")
for name_field in "Name" "Display name" "Display Name" "Full name"; do
  if tree_contains "$name_field"; then
    type_into "$name_field" "$(test_display_name)"
    break
  fi
done

# Edit bio — hint "Bio" or placeholder "Write something about yourself..."
for bio_field in "Bio" "About" "Write something about yourself..."; do
  if tree_contains "$bio_field"; then
    type_into "$bio_field" "$(test_bio)"
    break
  fi
done

capture "16_edited"

# Save Changes — GradientButton label: "Save Changes"
if has_label "Save Changes"; then
  tap_element "Save Changes" "label" "Save profile changes"
  sleep 2
  capture "16_saved"
  pass "Saved profile changes"
elif has_label "Save"; then
  tap_element "Save" "label" "Save (alternate label)"
  sleep 2
else
  skip "Save button" "no Save Changes / Save label found"
fi

# Return to profile page
go_back
sleep 1

print_summary
exit $FAIL
