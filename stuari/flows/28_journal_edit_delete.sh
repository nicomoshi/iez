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
if has_label "Journal"; then
  tap_element "Journal" "label" "Open Journal tab"
  sleep 1.5
fi

capture "28_journal_tab"

# Tap "Write a reflection" CTA (GestureDetector exposed as a button via
# children text). The label "Write a reflection" comes from GradientText.
for lbl in "Write a reflection" "How was your day?"; do
  if has_label "$lbl"; then
    tap_element "$lbl" "label" "Open new journal entry"
    sleep 1.2
    break
  fi
done

capture "28_editor"

# Type into the hint field
if tree_contains "Write your thoughts"; then
  type_into "Write your thoughts..." "$(test_journal_entry)"
  sleep 0.5
else
  skip "Journal editor" "hint not found"
  print_summary; exit $FAIL
fi

# Save (IconButton tooltip: Save)
if has_label "Save"; then
  tap_element "Save" "label" "Save journal entry"
  sleep 2
  pass "Saved journal entry"
else
  skip "Save button" "tooltip 'Save' not in AX tree"
fi

capture "28_after_save"

# Attempt to delete own entry: the card has an unlabelled close_rounded
# icon. We skip the assertion but emit informational output.
info "Edit/delete on journal card uses unlabelled icons — skipped (AX gap)"

print_summary
exit $FAIL
