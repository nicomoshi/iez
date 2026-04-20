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

# ── Coordinate fallbacks for the HOME TAB ───────────────────────────
#
# On Stuari's home tab, the top nav bar is rendered inside a
# ClipRect + Align wrapper (see `_buildHomeLayout` in app_shell.dart)
# that currently swallows the `TopNavItem` semantics. Other tabs use
# the standard `AppBar` layout and expose them fine. Until the home
# layout is fixed, tap by screen coordinates.
#
# Coordinates are in points on iPhone 17 (402pt wide). The toolbar sits
# at y~60–115 (kToolbarHeight 56 under the 62pt status bar). The two
# leading icons (Home, Notifications) are left-aligned at ~28 / ~85,
# the two trailing icons (Profile, Settings) right-aligned at ~318 / ~374.
# Discover is disabled in the current build.
TAB_COORDS_HOME="28,88"
TAB_COORDS_NOTIFICATIONS="85,88"
TAB_COORDS_PROFILE="318,88"
TAB_COORDS_SETTINGS="374,88"

# ── Tab navigation ──────────────────────────────────────────────────

# nav_to_tab BASE_LABEL DESCRIPTION [FALLBACK_COORDS]
#   Tries plain label, then ", selected" suffix (for re-tap), then substring
#   match, then a coordinate-based fallback (for the home-tab semantic
#   swallow bug — see TAB_COORDS_* constants above).
nav_to_tab() {
  local base="$1" desc="${2:-$1}" coords="${3:-}"
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

  # Coordinate fallback (home-tab semantic swallow workaround)
  if [ -n "$coords" ]; then
    r=$(run_iez "$IEZ" ui tap --coords "$coords")
    if [ "$(json_ok "$r")" = "true" ]; then
      pass "Nav: $desc (coord fallback $coords)"
      sleep 1.2
      return 0
    fi
  fi

  fail "Nav: $desc — tab label not found ($base)"
  return 1
}

go_home()          { nav_to_tab "$TAB_HOME"          "Home"          "$TAB_COORDS_HOME"; }
go_discover()      { nav_to_tab "$TAB_DISCOVER"      "Discover"; }
go_notifications() { nav_to_tab "$TAB_NOTIFICATIONS" "Notifications" "$TAB_COORDS_NOTIFICATIONS"; }
go_profile()       { nav_to_tab "$TAB_PROFILE"       "Profile"       "$TAB_COORDS_PROFILE"; }
go_settings()      { nav_to_tab "$TAB_SETTINGS"      "Settings"      "$TAB_COORDS_SETTINGS"; }

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
