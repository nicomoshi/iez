#!/usr/bin/env bash
# Flow 24 (P0): Delete account destructive path (cancel confirmation)
#
# Walks: Settings -> Account -> Delete Account -> confirmation dialog.
# This flow CANCELS the confirmation - actually deleting the seeded
# fixture user would break every subsequent flow. Verifies the
# destructive dialog renders and confirm/cancel buttons are reachable.
#
# Source: lib/settings/view/account_settings_page.dart

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"

section "Flow 24: Delete account (cancel)"

account_delete_cancel_dialog_is_safe_to_cancel() {
  local tree="${1:-}"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -e '
    def fully_contained_by($root):
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);
    def is_safe_button($root):
      .role == "AXButton"
      and (.enabled != false)
      and fully_contained_by($root);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | [(.data.elements // [])[]? | select(.label == "Cancel")] as $cancel
    | [(.data.elements // [])[]? | select(.label == "Delete Account")] as $delete
    | ($cancel | length) == 1
      and ($delete | length) == 1
      and ($cancel[0] | is_safe_button($root))
      and ($delete[0] | is_safe_button($root))
  ' >/dev/null 2>&1
}

account_delete_tile_label_from_tree() {
  local tree="${1:-}"
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -er '
    def fully_contained_by($root):
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | [(.data.elements // [])[]?
      | select(.role == "AXButton")
      | select((.label | type) == "string")
      | select(.label != "Delete Account")
      | select(.label | test("Delete Account"; "i"))
      | select(fully_contained_by($root))
    ] as $tiles
    | select(($tiles | length) == 1)
    | $tiles[0].label
  ' 2>/dev/null
}

account_delete_post_cancel_state_is_safe() {
  local tree="${1:-}" account_tile_label="${2:-}"
  [ -n "$account_tile_label" ] || return 1
  stuari_ax_tree_has_expected_app_root "$tree" || return 1

  printf '%s\n' "$tree" | jq -e --arg tile "$account_tile_label" '
    def fully_contained_by($root):
      (.frame | type) == "object"
      and ((.frame.x | type) == "number")
      and ((.frame.y | type) == "number")
      and ((.frame.width | type) == "number")
      and ((.frame.height | type) == "number")
      and .frame.width > 0
      and .frame.height > 0
      and .frame.x >= $root.x
      and .frame.y >= $root.y
      and (.frame.x + .frame.width) <= ($root.x + $root.width)
      and (.frame.y + .frame.height) <= ($root.y + $root.height);

    [(.data.elements // [])[]? | select(.role == "AXApplication")][0].frame as $root
    | ([ (.data.elements // [])[]?
      | select(.role == "AXButton")
      | select(.label == "Cancel" or .label == "Keep Account" or .label == "Delete Account")
    ] | length) == 0
    and ([ (.data.elements // [])[]?
      | select(.role == "AXButton")
      | select(.label == $tile)
    ] | length) == 1
    and ([ (.data.elements // [])[]?
      | select(.role == "AXButton")
      | select(.label == $tile)
    ][0] | fully_contained_by($root))
  ' >/dev/null 2>&1
}

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_settings
sleep 1.5
capture "24_settings"

# Settings -> Account (not 'Account' tab, this is the sub-page tile)
if has_label "Account"; then
  tap_element "Account" "label" "Open Account sub-page"
  sleep 2
else
  skip "Account sub-page" "tile not visible"
  print_summary; exit $FAIL
fi

capture "24_account_page"

# The SettingsTile merges with its section header into a single button
# labeled "Danger Zone\nDelete Account". Match the compound label or
# fall back to substring match.
account_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
delete_label="$(account_delete_tile_label_from_tree "$account_tree" 2>/dev/null || true)"

if [ -n "$delete_label" ]; then
  if ! tap_element "$delete_label" "label" "Tap Delete Account tile"; then
    fail "Delete Account tile action could not be delivered"
    print_summary; exit $FAIL
  fi
  sleep 1.5
else
  skip "Delete Account" "tile not visible (tree dump empty)"
  print_summary; exit $FAIL
fi

capture "24_confirm_dialog"

# Verify destructive confirm dialog visible
dialog_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if account_delete_cancel_dialog_is_safe_to_cancel "$dialog_tree"; then
  pass "Destructive confirm dialog visible"
else
  fail "Account deletion dialog lacks one safe Cancel button under the Stuari app root"
  print_summary; exit $FAIL
fi

# CANCEL the dialog (destructive action would nuke the seed user).
if ! account_delete_cancel_dialog_is_safe_to_cancel "${dialog_tree:-}"; then
  fail "Cancel button missing or ambiguous - refusing to dismiss or confirm account deletion"
  print_summary; exit $FAIL
fi

if ! tap_element "Cancel" "label" "Cancel delete"; then
  fail "Cancel action could not be delivered - refusing to continue"
  print_summary; exit $FAIL
fi
sleep 1

# One fresh AX tree must prove both dialog dismissal and restoration of the
# exact Account tile under the expected Stuari application root.
post_cancel_tree="$(run_iez "$IEZ" ui tree --compact 2>/dev/null || true)"
if account_delete_post_cancel_state_is_safe "$post_cancel_tree" "$delete_label"; then
  pass "Cancel tapped - account dialog dismissed and Account screen preserved"
else
  fail "Cancel did not restore the prior safe Account screen under the Stuari app root"
  capture "24_post_cancel_failed"
  print_summary; exit $FAIL
fi

capture "24_post_cancel"

# Back out of Account page
go_back
sleep 1
go_back
sleep 1

print_summary
exit $FAIL
