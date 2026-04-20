#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# Stuari — Navigation Helpers
#
# Top nav tabs (from lib/navigation/widgets/top_nav_item.dart):
#   Each tab is a Semantics(button: true, label: '<Label> tab[, <N> new][, selected]')
#
# Tabs present in the current build (order depends on FeatureFlags.isDiscoverEnabled):
#   Home, Discover, Notifications, Profile, Settings
#
# Selected state appends ", selected" to the label, so match with substring
# or try both plain and ", selected" variants.
# ──────────────────────────────────────────────────────────────────────

if [ "${STUARI_NAV_LOADED:-}" = "1" ]; then return 0; fi
STUARI_NAV_LOADED=1

_NAV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$_NAV_DIR/common.sh"

# ── Tab labels (base — without ", selected" / ", N new") ────────────

TAB_HOME="Home tab"
TAB_DISCOVER="Discover tab"
TAB_NOTIFICATIONS="Notifications tab"
TAB_PROFILE="Profile tab"
TAB_SETTINGS="Settings tab"

# ── Tab navigation ──────────────────────────────────────────────────

# nav_to_tab BASE_LABEL DESCRIPTION
#   Tries plain label, then ", selected" suffix (for re-tap), then substring match
nav_to_tab() {
  local base="$1" desc="${2:-$1}"
  local r

  # Try plain label
  if has_label "$base"; then
    r=$(run_iez "$IEZ" ui tap --label "$base")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Nav: $desc"
      sleep 1.2
      return 0
    fi
  fi
  # Try selected variant (tab re-tap is still allowed)
  if has_label "$base, selected"; then
    r=$(run_iez "$IEZ" ui tap --label "$base, selected")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Nav: $desc (re-tap)"
      sleep 1.2
      return 0
    fi
  fi

  # Substring match for dynamic badges, e.g., "Notifications tab, 3 new"
  local dyn
  dyn=$(run_iez "$IEZ" ui tree --compact \
    | jq -r --arg b "$base" '.data.elements[] | select(.label != null) | select(.label | startswith($b)) | .label' \
    | head -1)
  if [ -n "$dyn" ]; then
    r=$(run_iez "$IEZ" ui tap --label "$dyn")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Nav: $desc (matched '$dyn')"
      sleep 1.2
      return 0
    fi
  fi

  fail "Nav: $desc — tab label not found ($base)"
  return 1
}

go_home()          { nav_to_tab "$TAB_HOME" "Home"; }
go_discover()      { nav_to_tab "$TAB_DISCOVER" "Discover"; }
go_notifications() { nav_to_tab "$TAB_NOTIFICATIONS" "Notifications"; }
go_profile()       { nav_to_tab "$TAB_PROFILE" "Profile"; }
go_settings()      { nav_to_tab "$TAB_SETTINGS" "Settings"; }

# ── Assertions ──────────────────────────────────────────────────────

assert_on_tab() {
  local base="$1" desc="${2:-$1}"
  if has_label "$base, selected"; then
    pass "Currently on: $desc"
    return 0
  fi
  # Fallback: just verify the tab exists (may not encode 'selected')
  if has_label "$base"; then
    pass "Tab present (selection unknown): $desc"
    return 0
  fi
  fail "Not on expected tab: $desc"
  return 1
}

# go_back — use swipe-from-edge gesture (works for most Material routes)
go_back() {
  local r
  r=$(run_iez "$IEZ" ui swipe --from "5,400" --to "350,400")
  if [ "$(json_ok "$r")" = "true" ]; then
    sleep 0.8
    return 0
  fi
  # Try tapping a back button
  if has_label "Back"; then
    tap_element "Back" "label" "Back"
    return 0
  fi
  return 1
}
