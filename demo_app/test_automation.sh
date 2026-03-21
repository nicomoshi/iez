#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# iez Demo App – End-to-End Automation Test
# Exercises: sim boot, app build-run, tap, type, scroll, nav, screenshot
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS="$SCRIPT_DIR/screenshots"
STEP=0

# Add iez to PATH
export PATH="$REPO_ROOT/bin:$PATH"

# ── Helpers ──────────────────────────────────────────────────────────

step() {
  STEP=$((STEP + 1))
  printf '\n\033[1;36m── Step %02d: %s\033[0m\n' "$STEP" "$1"
}

run_iez() {
  # Run iez, extract only the JSON object from output (skip non-JSON lines)
  "$@" 2>/dev/null | sed -n '/^{/,/^}/p'
}

assert_ok() {
  local json="$1" label="$2"
  local ok
  ok=$(echo "$json" | jq -r '.ok // false')
  if [ "$ok" != "true" ]; then
    printf '\033[1;31m✗ FAIL: %s\033[0m\n' "$label"
    echo "$json" | jq . >&2
    exit 1
  fi
  printf '\033[1;32m✓ %s\033[0m\n' "$label"
}

snap() {
  local name="$1"
  local out="$SCREENSHOTS/step${STEP}_${name}.png"
  local result
  result=$(run_iez iez ui screenshot --out "$out")
  assert_ok "$result" "screenshot → $name"
}

# ── Setup ────────────────────────────────────────────────────────────

mkdir -p "$SCREENSHOTS"
cd "$SCRIPT_DIR"

# ── 1. Boot simulator ───────────────────────────────────────────────

DEVICE="${IEZ_DEVICE:-iPhone 17 Pro}"

step "Boot simulator ($DEVICE)"
result=$(run_iez iez sim boot --device "$DEVICE")
assert_ok "$result" "sim boot"

# ── 2. Build & launch app ───────────────────────────────────────────

step "Build and launch app"
result=$(run_iez iez app build-run)
assert_ok "$result" "app build-run"

# give the app time to render its first frame
sleep 3

# ── 3. Wait for Login screen ────────────────────────────────────────

step "Wait for Login screen"
result=$(run_iez iez ui wait --label "Login" --timeout 15)
assert_ok "$result" "wait for Login"
snap "login_screen"

# ── 4. Type email ───────────────────────────────────────────────────

step "Type email"
result=$(run_iez iez ui tap --label "Email")
assert_ok "$result" "tap Email field"
sleep 0.5
result=$(run_iez iez ui type "test@iez.dev")
assert_ok "$result" "type email"
snap "email_typed"

# ── 5. Type password ────────────────────────────────────────────────

step "Type password"
result=$(run_iez iez ui tap --label "Password")
assert_ok "$result" "tap Password field"
sleep 0.5
result=$(run_iez iez ui type "secret")
assert_ok "$result" "type password"
snap "password_typed"

# ── 6. Tap Login ────────────────────────────────────────────────────

step "Tap Log In button"
result=$(run_iez iez ui tap --label "Log In")
assert_ok "$result" "tap Log In"
sleep 1

# ── 7. Verify Home screen ───────────────────────────────────────────

step "Verify Home screen"
result=$(run_iez iez ui wait --label "Item 1" --timeout 10)
assert_ok "$result" "wait for Item 1 (Home screen loaded)"
snap "home_screen"

# ── 8. Scroll down the list ─────────────────────────────────────────

step "Scroll down list"
result=$(run_iez iez ui swipe up)
assert_ok "$result" "swipe up (1)"
sleep 0.5
result=$(run_iez iez ui swipe up)
assert_ok "$result" "swipe up (2)"
sleep 0.5
result=$(run_iez iez ui swipe up)
assert_ok "$result" "swipe up (3)"
snap "scrolled_list"

# ── 9. Tap a list item ──────────────────────────────────────────────

step "Tap list item"
result=$(run_iez iez ui tap --label "Item 15")
assert_ok "$result" "tap Item 15"
sleep 1
snap "item_tapped"

# ── 10. Navigate to Profile tab ─────────────────────────────────────

step "Navigate to Profile tab"
result=$(run_iez iez ui tap --coords 201,800)
assert_ok "$result" "tap Profile tab"
sleep 1
snap "profile_tab"

# ── 11. Navigate to Settings tab ────────────────────────────────────

step "Navigate to Settings tab"
result=$(run_iez iez ui tap --coords 335,800)
assert_ok "$result" "tap Settings tab"
sleep 1
snap "settings_tab"

# ── 12. Tap Logout ──────────────────────────────────────────────────

step "Tap Logout"
result=$(run_iez iez ui tap --label "Logout")
assert_ok "$result" "tap Logout"
sleep 1

# ── 13. Verify back on Login screen ─────────────────────────────────

step "Verify Login screen after logout"
result=$(run_iez iez ui wait --label "Login" --timeout 10)
assert_ok "$result" "wait for Login (after logout)"
snap "back_to_login"

# ── Done ─────────────────────────────────────────────────────────────

printf '\n\033[1;32m════════════════════════════════════════\033[0m\n'
printf '\033[1;32m  All %d steps passed!\033[0m\n' "$STEP"
printf '\033[1;32m  Screenshots: %s\033[0m\n' "$SCREENSHOTS"
printf '\033[1;32m════════════════════════════════════════\033[0m\n'
