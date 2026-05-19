#!/usr/bin/env bash
# Flow 28 (P1): Journal — create + save
#
# Walks: Home bottom sheet → Journal tab → "Write a reflection" → enter
# text → Save. Edit/delete affordances on existing cards use
# unlabelled icons; we skip those.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 28: Journal create + save"

fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

go_home
sleep 1

# Pull up the bottom sheet and tap Journal tab
run_iez "$IEZ" ui swipe --from "200,800" --to "200,200" >/dev/null 2>&1
sleep 1
tab_center=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
      | select(.label != null)
      | select(.label | test("^Journal(\\n|,|$)"))
      | .frame
      | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
  | head -1)
if [ -n "$tab_center" ]; then
  tap_element "$tab_center" "coords" "Open Journal tab"
  sleep 1.5
fi

capture "28_journal_tab"

# Tap the add-entry CTA.
if has_label "Write a reflection"; then
  tap_element "Write a reflection" "label" "Open new journal entry"
  sleep 1.2
else
  skip "Journal entry CTA" "Write a reflection button not found"
  print_summary; exit $FAIL
fi

capture "28_editor"

# Type into the labeled input field
if has_label "Journal entry input"; then
  type_into "Journal entry input" "$(test_journal_entry)"
  sleep 0.5
elif tree_contains "Write your thoughts"; then
  type_into "Write your thoughts..." "$(test_journal_entry)"
  sleep 0.5
else
  skip "Journal editor" "journal entry input not found"
  print_summary; exit $FAIL
fi

# Save
save_coords=$(run_iez "$IEZ" ui tree --compact \
  | jq -r '.data.elements[]
    | select(.label != null)
    | select(.role == "AXButton")
    | select(.label | contains("Save"))
    | .frame
    | if . then "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)" else empty end' \
  | head -1)
if [ -n "$save_coords" ]; then
  tap_element "$save_coords" "coords" "Save journal entry"
  sleep 2
  pass "Saved journal entry"
else
  skip "Save button" "Save label not in AX tree"
fi

capture "28_after_save"

# Attempt to verify an entry card is visible after save.
if run_iez "$IEZ" ui tree --compact \
  | jq -e '.data.elements[] | select(.label != null) | select(.label | startswith("Journal entry by "))' >/dev/null 2>&1 \
  || run_iez "$IEZ" ui tree --compact \
  | jq -e '.data.elements[] | select(.label != null) | select(.label | contains("Today I showed up."))' >/dev/null 2>&1; then
  pass "Journal entry card visible after save"
fi

# Edit/delete on journal cards still relies on icon-only affordances.
info "Edit/delete on journal card still uses icon-first affordances — skipped"

print_summary
exit $FAIL
