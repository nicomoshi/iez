#!/usr/bin/env bash
# Flow 04: Create Habit Group + Invite + Browse Members
#
# Walks the 7-page wizard in its actual PageView order (see
# lib/habit_group/view/create_habit_page.dart):
#
#   1. Name       → Continue
#   2. Image      → Continue (enabled once a cover image is selected;
#                   in SIMULATOR_MOCK_CAMERA=true builds, tapping
#                   "Add cover image" auto-loads a bundled sample)
#   3. Frequency  → Continue (default=daily, so schedule is skipped)
#   4. CheckIns   → Continue (a default check-in time exists)
#   5. Milestone  → Continue
#   6. Review     → "Create Habit" submit button
#
# After creating, navigates to the group's members list as a smoke check.

set +e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/auth.sh"
source "$SCRIPT_DIR/../lib/navigation.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

section "Flow 04: Habit Group Create + Invite + Members"
HABIT_NAME="${STUARI_FLOW04_HABIT_NAME:-$(test_habit_name)}"

wait_for_natural_home() {
  local timeout="${1:-10}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if on_home_page && [ -n "$(selected_home_nav_label)" ]; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

selected_home_nav_label() {
  run_iez "$IEZ" ui tree --compact \
    | jq -r --arg base "$TAB_HOME" '
        .data.elements[]?
        | select(.label != null)
        | select(
            .label == ($base + ", selected")
            or .label == ($base + ", selected tab")
            or ((.label | startswith($base + ", ")) and (.label | contains("selected")))
          )
        | .label
      ' 2>/dev/null \
    | head -1
}

fresh_launch; sleep 2

if on_auth_page; then login_with_test_user; fi
if on_onboarding_page; then complete_onboarding; fi

if ! on_home_page; then
  fail "Prereq: must be on Home to create a habit"
  print_summary; exit $FAIL
fi
go_home

capture "04_home_before_create"

# Look for a "Create Habit" CTA — the empty state card or the + FAB
CREATE_STARTED=0
CREATE_SUBMITTED=0
if has_id "create_habit_quick_action"; then
  tap_element "create_habit_quick_action" "id" "Start Create Habit flow (quick action)"
  CREATE_STARTED=1
elif has_id "create_habit_card"; then
  tap_element "create_habit_card" "id" "Start Create Habit flow (create card id)"
  CREATE_STARTED=1
elif has_label "Create Habit"; then
  tap_element "Create Habit" "label" "Start Create Habit flow"
  CREATE_STARTED=1
elif has_label "Create Habit. Tap to start a new journey."; then
  tap_element "Create Habit. Tap to start a new journey." "label" "Start Create Habit flow (long label)"
  CREATE_STARTED=1
elif has_label "Create new habit"; then
  tap_element "Create new habit" "label" "Start Create Habit flow (card)"
  CREATE_STARTED=1
else
  skip "Create Habit CTA" "not found on Home — user may already have habits; needs a + affordance"
  # Try a swipe to reveal it
  run_iez "$IEZ" ui swipe up >/dev/null 2>&1
  sleep 0.5
  if has_id "create_habit_quick_action"; then
    tap_element "create_habit_quick_action" "id" "Start Create Habit flow after swipe"
    CREATE_STARTED=1
  elif has_id "create_habit_card"; then
    tap_element "create_habit_card" "id" "Start Create Habit flow after swipe"
    CREATE_STARTED=1
  elif has_label "Create new habit"; then
    tap_element "Create new habit" "label" "Start Create Habit flow after swipe"
    CREATE_STARTED=1
  fi
fi

if [ "$CREATE_STARTED" != "1" ]; then
  fail "Create Habit entry point missing on Home"
  capture "04_create_entry_missing"
  print_summary
  exit $FAIL
fi

sleep 1.5
capture "04_name_page"

# Step 1: Name
if tree_contains "e.g. Morning Run"; then
  type_into "e.g. Morning Run" "$HABIT_NAME"
  run_iez "$IEZ" ui swipe down >/dev/null 2>&1
  sleep 0.5
  if tap_first_matching_exact_labels \
    "Continue" "Continue: habit name" "Name → Continue"; then
    sleep 1
  else
    fail "Name Continue action not reachable"
  fi
else
  fail "Name step did not expose the expected habit-name field"
  print_summary
  exit $FAIL
fi

capture "04_image_page"

# Step 2: Image — Continue is gated on selecting a cover image.
#
# In dev builds with SIMULATOR_MOCK_CAMERA=true, the CreateHabitImagePage
# short-circuits the Pexels gallery route and loads a bundled sample
# asset into the cubit when the placeholder is tapped. The placeholder's
# Semantics node is merged with its siblings on this page, so exact-label
# matching doesn't work — we detect the page via tree_contains and tap
# at the placeholder's known center coordinates (mid-screen, ~y=400).
#
# If the mock isn't active (e.g. staging build) Continue stays disabled
# and we fall back to the Skip button which advances without a cover.
if tree_contains "Add cover image"; then
  tap_element "200,400" "coords" "Image → tap placeholder (mock selects bundled sample)"
  sleep 1.5
  capture "04_image_selected"
fi

if tree_contains "Change cover image" || tree_contains "Change Image"; then
  # Mock succeeded — Continue is now enabled.
  if tap_first_matching_exact_labels \
    "Continue" "Continue: habit image" \
    "Image → Continue (cover image selected)"; then
    sleep 1
  else
    fail "Image Continue action not reachable after selecting a cover image"
  fi
elif tap_first_matching_exact_labels \
  "Skip" "Skip: habit image" "Image → Skip (no cover image selected)"; then
  sleep 1
elif tap_first_matching_exact_labels \
  "Continue" "Continue: habit image" "Image → Continue (fallback)"; then
  # Last-resort: try Continue anyway. This is usually a no-op when
  # disabled but keeps the flow compatible with any future UX where
  # the image step is optional-but-default-Continue.
  sleep 1
else
  skip "Image step" "neither Continue nor Skip reachable"
fi

# Walk through the remaining Continue-gated steps in wizard order:
# frequency (default=daily skips schedule) → checkins → milestone.
for step in frequency checkins milestone; do
  case "$step" in
    frequency) continue_semantic_label="Continue: habit frequency" ;;
    checkins) continue_semantic_label="Continue: check-in times" ;;
    milestone) continue_semantic_label="Continue: habit milestone" ;;
  esac
  capture "04_${step}_page"
  if tap_first_matching_exact_labels \
    "Continue" "$continue_semantic_label" "Step '$step' → Continue"; then
    sleep 1
  else
    info "Continue button not visible on '$step' step — may need to scroll or fill form"
    run_iez "$IEZ" ui swipe up >/dev/null 2>&1
    sleep 0.3
    if tap_first_matching_exact_labels \
      "Continue" "$continue_semantic_label" \
      "Step '$step' → Continue (after scroll)"; then
      sleep 1
    else
      fail "Step '$step' Continue action not reachable"
    fi
  fi
done

# Review page — final Create Habit button
capture "04_review_page"
if tap_first_matching_exact_labels \
  "Create Habit" "Create Habit: habit review" \
  "Review → Create Habit (submit)"; then
  CREATE_SUBMITTED=1
  pass "Submitted habit create form"
  capture "04_post_create"
else
  fail "Final Create Habit button not reachable from review page"
fi

# Create Habit should return to Home without any navigation tap. Keep each
# durability boundary independent so a failed assertion cannot hide evidence
# from the later safe checkpoints.
if [ "$CREATE_SUBMITTED" = "1" ]; then
  if wait_for_natural_home 10; then
    if capture "04_home_before_created_habit_center_check"; then
      pass "Immediate create-return boundary: Create Habit returned naturally to Home without a Home re-tap"
    else
      info "Immediate create-return boundary did not produce complete screenshot + compact AX evidence"
    fi
  else
    capture "04_created_habit_immediate_home_failure"
    fail "Immediate create-return boundary failed: Create Habit did not return naturally to Home"
  fi

  if on_home_page && \
    wait_for_visible_habit_card_name "$HABIT_NAME" 8; then
    immediate_label="$(current_visible_habit_card_label 2>/dev/null || true)"
    if habit_card_label_matches_name "$immediate_label" "$HABIT_NAME"; then
      if capture "04_created_habit_centered_immediate"; then
        pass "Immediate centered-card boundary: created habit is the visible centered Home card: $HABIT_NAME"
      else
        info "Immediate centered-card boundary did not produce complete screenshot + compact AX evidence"
      fi
    else
      capture "04_created_habit_centered_immediate_failure"
      fail "Immediate centered-card boundary failed: centered Home card label was '$immediate_label', expected '$HABIT_NAME'"
    fi
  else
    capture "04_created_habit_centered_immediate_failure"
    fail "Immediate centered-card boundary failed: created habit is not the visible centered Home card: $HABIT_NAME"
  fi

  # Deliberate stability boundary: no app interaction occurs during this
  # interval. The later AX read is centered-card-only and cannot move the
  # carousel or refresh the route.
  sleep 10
  if on_home_page && \
    wait_for_visible_habit_card_name "$HABIT_NAME" 8; then
    stability_label="$(current_visible_habit_card_label 2>/dev/null || true)"
    if habit_card_label_matches_name "$stability_label" "$HABIT_NAME"; then
      if capture "04_created_habit_centered_after_10s_no_interaction"; then
        pass "10-second no-interaction stability boundary: created habit remains the centered Home card: $HABIT_NAME"
      else
        info "10-second no-interaction stability boundary did not produce complete screenshot + compact AX evidence"
      fi
    else
      capture "04_created_habit_centered_after_10s_no_interaction_failure"
      fail "10-second no-interaction stability boundary failed: centered Home card label was '$stability_label', expected '$HABIT_NAME'"
    fi
  else
    capture "04_created_habit_centered_after_10s_no_interaction_failure"
    fail "10-second no-interaction stability boundary failed: created habit is no longer the centered Home card: $HABIT_NAME"
  fi

  selected_home_label="$(selected_home_nav_label)"
  selected_home_retapped=0
  if [ -n "$selected_home_label" ]; then
    if tap_element "$selected_home_label" "label" "Re-tap already-selected Home nav item"; then
      selected_home_retapped=1
    fi
  fi
  if [ "$selected_home_retapped" = "1" ] && \
    wait_for_visible_habit_card_name "$HABIT_NAME" 8; then
    selected_home_label_after_tap="$(current_visible_habit_card_label 2>/dev/null || true)"
    if habit_card_label_matches_name "$selected_home_label_after_tap" "$HABIT_NAME"; then
      if capture "04_created_habit_centered_after_selected_home_retap"; then
        pass "Selected Home re-tap boundary: created habit remains the centered Home card: $HABIT_NAME"
      else
        info "Selected Home re-tap boundary did not produce complete screenshot + compact AX evidence"
      fi
    else
      capture "04_created_habit_centered_after_selected_home_retap_failure"
      fail "Selected Home re-tap boundary failed: centered Home card label was '$selected_home_label_after_tap', expected '$HABIT_NAME'"
    fi
  else
    capture "04_created_habit_centered_after_selected_home_retap_failure"
    if [ -z "$selected_home_label" ]; then
      fail "Selected Home re-tap boundary failed: already-selected Home nav item was not visible"
    else
      fail "Selected Home re-tap boundary failed: selected Home nav tap did not succeed or the created habit was not centered: $HABIT_NAME"
    fi
  fi

  terminate_app
  fresh_launch
  if on_auth_page; then login_with_test_user; fi
  if on_onboarding_page; then complete_onboarding; fi
  if wait_for_natural_home 10 && \
    wait_for_visible_habit_card_name "$HABIT_NAME" 10; then
    relaunch_label="$(current_visible_habit_card_label 2>/dev/null || true)"
    capture "04_home_after_relaunch"
    if habit_card_label_matches_name "$relaunch_label" "$HABIT_NAME"; then
      if capture "04_created_habit_centered_after_relaunch"; then
        pass "Fresh relaunch/auth restore boundary: created habit remains the centered Home card: $HABIT_NAME"
      else
        info "Fresh relaunch/auth restore boundary did not produce complete screenshot + compact AX evidence"
      fi
    else
      capture "04_created_habit_centered_after_relaunch_failure"
      fail "Fresh relaunch/auth restore boundary failed: centered Home card label was '$relaunch_label', expected '$HABIT_NAME'"
    fi
  else
    capture "04_created_habit_centered_after_relaunch_failure"
    fail "Fresh relaunch/auth restore boundary failed: created habit is not the centered Home card after returning Home: $HABIT_NAME"
  fi
else
  fail "Created habit durability boundaries unavailable because Create Habit submission failed"
fi

# Invite flow: from habit card, tap → menu / members
run_iez "$IEZ" ui swipe down >/dev/null 2>&1 || true
sleep 1
go_home
sleep 0.8

if has_label "Members"; then
  tap_element "Members" "label" "Open members list"
  sleep 1.2
  capture "04_members_list"
  if has_label "Invite"; then
    tap_element "Invite" "label" "Tap Invite"
    sleep 1
    capture "04_invite_sheet"
    dismiss_all
  fi
elif tap_visible_habit_menu "Open habit settings"; then
  sleep 1
  if has_label "View Details"; then
    tap_element "View Details" "label" "Open habit details"
    sleep 1.5
    capture "04_habit_details"
    if tree_contains "Members" || has_label "Members"; then
      pass "Members section visible from habit details"
    else
      skip "Members section" "habit details opened but members heading not visible"
    fi
    go_back
    sleep 1
  else
    skip "View Details" "habit settings menu opened without View Details"
  fi
else
  skip "Members list" "entry point not found (may require tapping habit card first)"
fi

dismiss_all
print_summary
exit $FAIL
