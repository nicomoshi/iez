#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FLOW_FILE="$ROOT_DIR/stuari/flows/03_auth_signin.sh"
AUTH_FILE="$ROOT_DIR/stuari/lib/auth.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_flow03_sign_out.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

failures=0
passes=0

pass_test() {
  passes=$((passes + 1))
  printf 'PASS: %s\n' "$1"
}

fail_test() {
  failures=$((failures + 1))
  printf 'FAIL: %s\n' "$1" >&2
}

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  if grep -Fq -- "$needle" "$file"; then
    pass_test "$description"
  else
    fail_test "$description (missing '$needle')"
  fi
}

assert_eq() {
  local expected="$1" actual="$2" description="$3"
  if [ "$expected" = "$actual" ]; then
    pass_test "$description"
  else
    fail_test "$description (expected '$expected', got '$actual')"
  fi
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    pass_test "$description"
  else
    fail_test "$description"
  fi
}

assert_false() {
  local description="$1"
  shift
  if "$@"; then
    fail_test "$description"
  else
    pass_test "$description"
  fi
}

# Given Flow 03 records current-run evidence, When sign-out captures states,
# Then every state ID remains inside the selected flow namespace.
assert_file_contains 'sign_out "03_"' "$FLOW_FILE" \
  "Given Flow 03 signs out When it captures evidence Then it supplies the 03_ state prefix"
assert_file_contains 'first_coords_matching_sign_out_confirmation' "$AUTH_FILE" \
  "Given sign-out confirmation is destructive When resolving its target Then auth uses the strict confirmation resolver"
if grep -Eq '^[[:space:]]*sign_out[[:space:]]*$' "$FLOW_FILE"; then
  fail_test "Given Flow 03 signs out Then it must not call the unscoped sign_out capture path"
else
  pass_test "Given Flow 03 signs out Then it does not call the unscoped sign_out capture path"
fi

export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export IEZ="fake-iez"
export DEVICE_ID="flow03-test-device"
source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/auth.sh"

valid_root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
settings_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":16,\"y\":280,\"width\":370,\"height\":56}}]}}"
dialog_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":16,\"y\":300,\"width\":370,\"height\":56}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
ambiguous_dialog_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":210,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":300,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_confirm_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_cancel_action\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_confirm_with_legacy_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_duplicate_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}}]}}"
stable_disabled_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":false,\"frame\":{\"x\":20,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_off_root_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":500,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_zero_size_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXButton\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":500,\"width\":0,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"
stable_wrong_role_tree="{\"ok\":true,\"data\":{\"elements\":[$valid_root,{\"role\":\"AXStaticText\",\"id\":\"sign_out_confirm_action\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":500,\"width\":78,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Cancel\",\"enabled\":true,\"frame\":{\"x\":120,\"y\":500,\"width\":90,\"height\":46}},{\"role\":\"AXButton\",\"label\":\"Sign Out\",\"enabled\":true,\"frame\":{\"x\":240,\"y\":500,\"width\":78,\"height\":46}}]}}"

run_iez() {
  printf '%s\n' "$SIGN_OUT_TREE"
}

SIGN_OUT_TREE="$dialog_tree"
dialog_coords="$(first_coords_matching_sign_out_confirmation 2>/dev/null || true)"
assert_eq "279,523" "$dialog_coords" \
  "Given the sign-out dialog has duplicate labels When resolving confirmation Then it selects the unique lower AXButton"

SIGN_OUT_TREE="$settings_tree"
assert_false \
  "Given only the Settings Sign Out button is visible When resolving confirmation Then the helper refuses to tap" \
  first_coords_matching_sign_out_confirmation

SIGN_OUT_TREE="$ambiguous_dialog_tree"
assert_false \
  "Given two confirmation AXButtons tie When resolving confirmation Then the helper fails closed" \
  first_coords_matching_sign_out_confirmation

SIGN_OUT_TREE="$stable_confirm_tree"
assert_eq "279,523" "$(first_coords_matching_sign_out_confirmation 2>/dev/null || true)" \
  "Given the stable confirm id is valid When resolving confirmation Then it selects that id"

SIGN_OUT_TREE="$stable_confirm_with_legacy_tree"
assert_eq "59,523" "$(first_coords_matching_sign_out_confirmation 2>/dev/null || true)" \
  "Given a stable confirm id and legacy labels coexist When resolving confirmation Then the id wins"

for malformed_tree in "$stable_duplicate_tree" "$stable_disabled_tree" \
  "$stable_off_root_tree" "$stable_zero_size_tree" "$stable_wrong_role_tree"; do
  SIGN_OUT_TREE="$malformed_tree"
  assert_false \
    "Given a malformed stable confirm id When resolving confirmation Then legacy fallback is forbidden" \
    first_coords_matching_sign_out_confirmation
done

printf 'Flow 03 sign-out checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
