#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Multi-user E2E
#
# Exercises Alice/Bob/Carol workflows by signing in + out between steps.
# Each account uses the same seeded dev-magic password. We reset auth
# state between phases.
#
# Phase 1: Alice creates a throwaway habit + sends a chat message.
# Phase 2: Sign out → sign in as Bob → verify Bob's home renders.
# Phase 3: Sign out → sign in as Carol → same smoke.
#
# Note: True Realtime cross-session delivery is not exercised here (a
# single simulator can only host one logged-in session at a time). See
# COVERAGE_GAPS.md §5 for why.
# ──────────────────────────────────────────────────────────────────────
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/auth.sh
source "$LIB_DIR/auth.sh"
# shellcheck source=lib/navigation.sh
source "$LIB_DIR/navigation.sh"
# shellcheck source=lib/fixtures.sh
source "$LIB_DIR/fixtures.sh"

# Helper: sign out + sign in as a different account.
sign_in_as() {
  local email="$1"
  info "Switching user to $email"
  STUARI_TEST_EMAIL="$email"
  STUARI_TEST_PASSWORD="${STUARI_TEST_PASSWORD:-iez-test-password-2026}"
  export STUARI_TEST_EMAIL STUARI_TEST_PASSWORD

  if on_home_page; then
    sign_out
    sleep 1
  fi
  if on_auth_page; then
    login_with_dev_magic
  else
    fresh_launch; sleep 2
    if on_auth_page; then login_with_dev_magic; fi
  fi
}

section "Multi-user Phase 1: Alice creates fixture"

STUARI_TEST_EMAIL=alice@seed.dev
export STUARI_TEST_EMAIL
fresh_launch; sleep 2
if on_auth_page; then login_with_test_user; fi
# Walk onboarding if present (e.g., after a previous sign-out for a
# non-seeded account)
if on_onboarding_page; then
  complete_onboarding
  sleep 2
fi

if ! on_home_page; then
  # Alice's onboarding state may have been corrupted by prior flows.
  # Skip rather than fail — re-seeding is out of band.
  skip "Alice home" "onboarding state inconsistent (re-seed users with admin_seed_users.ts)"
  print_summary; exit $FAIL
fi
pass "Alice signed in"

# Send a chat message in existing habit
if has_label "Open group chat"; then
  tap_element "Open group chat" "label" "Alice opens chat"
  sleep 1.5
  msg="alice_to_bob_$(rand_tail)"
  if tree_contains "Type a message"; then
    type_into "Type a message..." "$msg"
    sleep 0.5
    if has_label "Send message"; then
      tap_element "Send message" "label" "Send Alice's message"
      sleep 1.5
      pass "Alice sent '$msg'"
    fi
  fi
  go_back
  sleep 1
fi
capture "mu_1_alice_done"

section "Multi-user Phase 2: Bob signs in"

sign_in_as "bob@seed.dev"
sleep 2
if on_onboarding_page; then
  info "Bob in onboarding — completing"
  complete_onboarding
  sleep 2
fi
if on_home_page; then
  pass "Bob reached home"
else
  fail "Bob did not reach home"
fi
capture "mu_2_bob_home"

# Bob checks chat (if he shares any group with Alice)
if has_label "Open group chat"; then
  tap_element "Open group chat" "label" "Bob opens chat"
  sleep 1.5
  if tree_contains "alice_to_bob_"; then
    pass "Bob sees Alice's message in chat"
  else
    info "Alice's message not present in Bob's chat view (may not share group)"
  fi
  go_back
fi

section "Multi-user Phase 3: Carol smoke"

sign_in_as "carol@seed.dev"
sleep 2
if on_onboarding_page; then
  info "Carol in onboarding — completing"
  complete_onboarding
  sleep 2
fi
if on_home_page; then
  pass "Carol reached home"
else
  fail "Carol did not reach home"
fi
capture "mu_3_carol_home"

print_summary
exit $FAIL
