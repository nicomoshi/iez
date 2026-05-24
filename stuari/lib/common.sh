#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Shared iEZ Test Helpers
#
# Source this file from every flow script. Provides:
#   - Path/env constants (IEZ, BUNDLE_ID, SCREENSHOTS)
#   - Pass/fail counters + colored output (pass, fail, skip)
#   - App lifecycle: fresh_launch, dismiss_all, wait_for_main_ui
#   - Interaction helpers: assert_element, type_into, capture
#   - JSON helpers for iez output
# ──────────────────────────────────────────────────────────────────────

# Guard against double-sourcing
if [ "${STUARI_COMMON_LOADED:-}" = "1" ]; then return 0; fi
STUARI_COMMON_LOADED=1

set +e  # Never exit on a failed assertion — counters track state instead

# ── Paths & Environment ─────────────────────────────────────────────

STUARI_SUITE_DIR="${STUARI_SUITE_DIR:-$HOME/Developer/i_ez/stuari}"
IEZ_REPO_DIR="${IEZ_REPO_DIR:-$HOME/Developer/i_ez}"
IEZ="${IEZ:-$IEZ_REPO_DIR/bin/iez}"

# Default dev flavor bundle id. Override via STUARI_BUNDLE_ID to test stg/prod.
BUNDLE_ID="${STUARI_BUNDLE_ID:-com.stuari.stuari.dev}"
SEEDED_GROUP_ID="${SEEDED_GROUP_ID:-bbbb0000-0000-0000-0000-000000000001}"
SEEDED_GROUP_CARD_ID="habit_card_$SEEDED_GROUP_ID"

SCREENSHOTS="${SCREENSHOTS:-$STUARI_SUITE_DIR/screenshots}"
mkdir -p "$SCREENSHOTS"

# Make iez discoverable on PATH for child processes
export PATH="$IEZ_REPO_DIR/bin:$PATH"

# ── Counters (inherited by sourcing scripts) ────────────────────────

PASS="${PASS:-0}"
FAIL="${FAIL:-0}"
SKIP="${SKIP:-0}"
TOTAL="${TOTAL:-0}"

# ── Simulator Detection ─────────────────────────────────────────────

detect_device() {
  if [ -n "${IEZ_DEVICE_UDID:-}" ]; then
    DEVICE_ID="$IEZ_DEVICE_UDID"
    return 0
  fi
  DEVICE_ID=$(xcrun simctl list devices booted -j 2>/dev/null \
    | jq -r '.devices[][] | select(.state == "Booted") | .udid' | head -1)
  if [ -z "$DEVICE_ID" ]; then
    printf '\033[1;31mERROR:\033[0m No booted simulator found. Boot one first: iez sim boot\n' >&2
    return 1
  fi
  export DEVICE_ID
}

# ── JSON / iez Helpers ──────────────────────────────────────────────

# Run an iez command and strip any non-JSON stderr noise.
# Usage: run_iez "$IEZ" ui tap --id some_id
run_iez() {
  "$@" 2>/dev/null | sed -n '/^{/,/^}/p'
}

# Extract .ok from a JSON response; default false.
json_ok() { echo "$1" | jq -r '.ok // false' 2>/dev/null; }

# ── Logging / Counters ──────────────────────────────────────────────

pass() {
  PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1))
  printf '  \033[1;32m✓\033[0m %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1))
  printf '  \033[1;31m✗\033[0m %s\n' "$1"
  [ "${VERBOSE:-}" = "1" ] && [ -n "${2:-}" ] && echo "$2" | jq . >&2
}

skip() {
  SKIP=$((SKIP + 1)); TOTAL=$((TOTAL + 1))
  printf '  \033[1;33m⊘\033[0m %s (skipped: %s)\n' "$1" "${2:-n/a}"
}

info() {
  printf '  \033[1;34mℹ\033[0m %s\n' "$1"
}

section() {
  echo ""
  echo "━━━ $1 ━━━"
}

# assert_ok JSON MSG   — pass if .ok==true, fail otherwise
assert_ok() {
  local ok; ok=$(json_ok "$1")
  if [ "$ok" = "true" ]; then pass "$2"; else fail "$2" "$1"; fi
}

# assert_fail JSON MSG — pass if .ok!=true (negative assertion)
assert_fail() {
  local ok; ok=$(json_ok "$1")
  if [ "$ok" != "true" ]; then pass "$2 (expected fail)"; else fail "$2 (should have failed)"; fi
}

# ── Existence Checks ────────────────────────────────────────────────

# `iez ui exists` reports command-success under `.ok` (always true on a
# running simulator) and element-presence under `.data.exists`. Early
# versions of this suite conflated the two — every `has_label` call
# returned 0 (truthy) regardless of whether the label was in the AX
# tree, which produced cascades of spurious `fail` lines in every flow.
# Always read `.data.exists`.
has_id() {
  run_iez "$IEZ" ui exists --id "$1" | jq -r '.data.exists' 2>/dev/null | grep -q true
}

has_label() {
  run_iez "$IEZ" ui exists --label "$1" | jq -r '.data.exists' 2>/dev/null | grep -q true
}

# Substring match against AX tree labels. Use for dynamic labels (e.g., "5 new").
tree_contains() {
  run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

tree_has_id() {
  run_iez "$IEZ" ui tree --compact \
    | jq -r '.data.elements[].id // empty' 2>/dev/null | grep -qF "$1"
}

wait_for_tree_text() {
  local text="$1" timeout="${2:-10}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if tree_contains "$text"; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

wait_for_habit_name() {
  local name="$1" timeout="${2:-8}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if tree_contains "$name"; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

# ── Smart Assertions ────────────────────────────────────────────────

# assert_element — wait for an element then assert it exists.
# Args:
#   $1 = identifier (id or label)
#   $2 = kind ("id" or "label"), default "label"
#   $3 = timeout seconds, default 8
#   $4 = friendly description for log
assert_element() {
  local ident="$1" kind="${2:-label}" timeout="${3:-8}" desc="${4:-$1}"
  local flag
  case "$kind" in
    id)    flag="--id" ;;
    label) flag="--label" ;;
    *)     flag="--label" ;;
  esac
  local r
  r=$(run_iez "$IEZ" ui wait $flag "$ident" --timeout "$timeout")
  local ok; ok=$(json_ok "$r")
  if [ "$ok" = "true" ]; then
    pass "Element visible: $desc"
    return 0
  else
    fail "Element missing: $desc ($kind=$ident)" "$r"
    return 1
  fi
}

# ── Interactions ────────────────────────────────────────────────────

# tap_element — tap by id or label with sensible fallbacks.
# Args: $1=identifier, $2=kind (id|label|coords), $3=desc
tap_element() {
  local ident="$1" kind="${2:-label}" desc="${3:-$1}"
  local r
  case "$kind" in
    id)     r=$(run_iez "$IEZ" ui tap --id "$ident") ;;
    coords) r=$(run_iez "$IEZ" ui tap --coords "$ident") ;;
    *)      r=$(run_iez "$IEZ" ui tap --label "$ident") ;;
  esac
  assert_ok "$r" "Tap: $desc"
  return $?
}

# type_into — focus a field (by label), type text, dismiss keyboard.
# Args: $1=field label (or id with --id prefix), $2=text
type_into() {
  local target="$1" text="$2" flag="--label"
  if [[ "$target" == --id* ]]; then
    flag="--id"; target="${target#--id }"
  fi
  local r
  r=$(run_iez "$IEZ" ui tap $flag "$target")
  assert_ok "$r" "Focus field: $target"
  sleep 0.4
  r=$(run_iez "$IEZ" ui type "$text")
  assert_ok "$r" "Type into $target: '$text'"
  sleep 0.3
}

# capture — take a timestamped screenshot.
# Args: $1=filename stem (no extension)
capture() {
  local stem="${1:-capture}"
  local stamp; stamp=$(date +%H%M%S)
  run_iez "$IEZ" ui screenshot --out "$SCREENSHOTS/${stem}_${stamp}.png" >/dev/null
}

first_coords_matching_label_regex() {
  local regex="$1" flags="${2:-}"
  run_iez "$IEZ" ui tree --compact \
    | jq -r --arg regex "$regex" --arg flags "$flags" '.data.elements[]
      | select(.label != null)
      | select(.label | test($regex; $flags))
      | select(.frame != null and .frame.width > 0 and .frame.height > 0)
      | .frame
      | "\((.x + (.width / 2)) | floor),\((.y + (.height / 2)) | floor)"' \
    | head -1
}

tap_first_matching_label_regex() {
  local regex="$1" flags="${2:-}" desc="${3:-$1}"
  local coords
  coords=$(first_coords_matching_label_regex "$regex" "$flags")
  if [ -z "$coords" ] || [ "$coords" = "null" ] || [ "$coords" = "," ]; then
    return 1
  fi
  local r
  r=$(run_iez "$IEZ" ui tap --coords "$coords")
  assert_ok "$r" "Tap: $desc"
  return 0
}

current_visible_habit_card_id() {
  local center_x="${1:-196}"
  run_iez "$IEZ" ui tree --compact \
    | jq -r --argjson center_x "$center_x" '
      def abs: if . < 0 then -1 * . else . end;
      .data.elements[]
      | select(.id != null)
      | select(.id | startswith("habit_card_"))
      | select(.frame != null and .frame.width > 40 and .frame.height > 40)
      | [
          (((.frame.x + (.frame.width / 2)) - $center_x) | abs),
          (-1 * (.frame.width * .frame.height)),
          .id
        ]
      | @tsv' 2>/dev/null \
    | sort -n \
    | head -1 \
    | awk -F '\t' '{print $3}'
}

current_visible_habit_card_label() {
  local id
  id=$(current_visible_habit_card_id)
  if [ -z "$id" ]; then
    return 1
  fi
  run_iez "$IEZ" ui tree --compact \
    | jq -r --arg id "$id" '.data.elements[]
        | select(.id == $id)
        | .label // empty' 2>/dev/null \
    | head -1
}

wait_for_visible_habit_card() {
  local timeout="${1:-12}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if [ -n "$(current_visible_habit_card_id)" ]; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
}

pull_to_refresh_home() {
  local r
  r=$(run_iez "$IEZ" ui swipe --from "200,650" --to "200,830")
  assert_ok "$r" "Pull to refresh selected habit"
  sleep 3
}

expand_home_sheet_to_feed() {
  local r
  r=$(run_iez "$IEZ" ui swipe --from "200,700" --to "200,200")
  if [ "$(json_ok "$r")" = "true" ]; then
    pass "Expanded home bottom sheet"
  else
    fail "Expanded home bottom sheet" "$r"
    return 1
  fi
  sleep 1.5

  if has_label "Feed"; then
    tap_element "Feed" "label" "Switch to Feed tab"
    sleep 1
  fi
}

# ── App Lifecycle ───────────────────────────────────────────────────

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5

  local attempts=0
  while [ $attempts -lt 3 ]; do
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1
    sleep 3
    if run_iez "$IEZ" ui tree --compact \
      | jq -r '.data.elements[] | .label // empty' 2>/dev/null \
      | grep -qE '^(stuari-dev|stuari|Home tab|Home tab, selected|Sign in with Apple|Sign in with Google)$'; then
      return 0
    fi
    attempts=$((attempts + 1))
  done
}

terminate_app() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
}

# dismiss_all — close any modal, sheet, menu, or popover blocking the tree.
# Strategy (tries up to 5 times):
#   1. Sheet Grabber present → swipe down
#   2. PopoverDismissRegion present → tap
#   3. "Dismiss context menu" label → tap
#   4. "Close" / "Done" / "Cancel" label present → tap
#   5. Fallback: tap center screen, continue if main UI returns
dismiss_all() {
  local attempts=0
  while [ $attempts -lt 5 ]; do
    local tree; tree=$(run_iez "$IEZ" ui tree --compact)

    local has_sheet
    has_sheet=$(echo "$tree" | jq '[.data.elements[] | select(.label == "Sheet Grabber")] | length' 2>/dev/null)
    if [ "${has_sheet:-0}" -gt 0 ]; then
      run_iez "$IEZ" ui swipe down >/dev/null 2>&1
      sleep 1.2
      attempts=$((attempts + 1))
      continue
    fi

    local has_popover
    has_popover=$(echo "$tree" | jq '[.data.elements[] | select(.id == "PopoverDismissRegion")] | length' 2>/dev/null)
    if [ "${has_popover:-0}" -gt 0 ]; then
      run_iez "$IEZ" ui tap --id "PopoverDismissRegion" >/dev/null 2>&1
      sleep 1.2
      attempts=$((attempts + 1))
      continue
    fi

    local has_ctx
    has_ctx=$(echo "$tree" | jq '[.data.elements[] | select(.label == "Dismiss context menu")] | length' 2>/dev/null)
    if [ "${has_ctx:-0}" -gt 0 ]; then
      run_iez "$IEZ" ui tap --label "Dismiss context menu" >/dev/null 2>&1
      sleep 1.2
      attempts=$((attempts + 1))
      continue
    fi

    # No blocker detected
    return 0
  done
  return 0
}

# wait_for_main_ui — wait until a known always-present home element shows up.
# Stuari's top bar normally exposes "Home tab" / "Settings tab" labels, but
# on the Home tab itself the top nav is currently semantic-invisible (see
# navigation.sh for the workaround). So we also accept any of the
# bottom-sheet sub-tabs ("Feed", "Journal", "Stats") or the "Create new
# habit" / "Create Habit" affordance as evidence of a successful auth.
wait_for_main_ui() {
  local timeout="${1:-10}"
  local r
  # Prefer Home tab label (other tabs)
  r=$(run_iez "$IEZ" ui wait --label "Home tab" --timeout 3)
  [ "$(json_ok "$r")" = "true" ] && return 0
  r=$(run_iez "$IEZ" ui wait --label "Home tab, selected" --timeout 2)
  [ "$(json_ok "$r")" = "true" ] && return 0
  r=$(run_iez "$IEZ" ui wait --label "Settings tab" --timeout 2)
  [ "$(json_ok "$r")" = "true" ] && return 0
  # Home tab fallbacks
  r=$(run_iez "$IEZ" ui wait --label "Create new habit" --timeout 2)
  [ "$(json_ok "$r")" = "true" ] && return 0
  r=$(run_iez "$IEZ" ui wait --label "Create Habit" --timeout 2)
  [ "$(json_ok "$r")" = "true" ] && return 0
  dismiss_all
  sleep 1
  # Final broad sweep
  local i=0
  while [ $i -lt "$timeout" ]; do
    if has_label "Home tab" \
      || has_label "Settings tab" \
      || has_label "Create new habit" \
      || has_label "Create Habit" \
      || tree_contains "Tab 1 of 3"; then
      return 0
    fi
    sleep 1; i=$((i + 1))
  done
  return 1
}

# wait_for_auth_ui — on sign-in screen, wait for one of the OAuth buttons.
wait_for_auth_ui() {
  local timeout="${1:-10}"
  local r
  r=$(run_iez "$IEZ" ui wait --label "Sign in with Apple" --timeout "$timeout")
  [ "$(json_ok "$r")" = "true" ] && return 0
  r=$(run_iez "$IEZ" ui wait --label "Sign in with Google" --timeout 3)
  [ "$(json_ok "$r")" = "true" ]
}

# ── Summary ─────────────────────────────────────────────────────────

print_summary() {
  echo ""
  echo "╔══════════════════════════════════════════════════╗"
  printf "║  Results: \033[1;32m%d passed\033[0m / \033[1;31m%d failed\033[0m / \033[1;33m%d skipped\033[0m / %d total  ║\n" "$PASS" "$FAIL" "$SKIP" "$TOTAL"
  echo "╚══════════════════════════════════════════════════╝"
  echo "Screenshots: $SCREENSHOTS/"
}

# ── Initialize ──────────────────────────────────────────────────────

# Detect device lazily — flow scripts source common.sh then call detect_device.
# Flows can skip this (e.g., smoke runs) by setting SKIP_DEVICE_DETECT=1.
if [ "${SKIP_DEVICE_DETECT:-}" != "1" ]; then
  detect_device || true
fi
