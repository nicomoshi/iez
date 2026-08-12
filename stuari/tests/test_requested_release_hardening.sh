#!/usr/bin/env bash

# Gherkin-style regressions for the requested release-harness hardening.
# These tests use compact AX fixtures and bounded shell doubles only; they do
# not launch a simulator or touch another checkout.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_requested_hardening.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

passes=0
failures=0
pass_test() { passes=$((passes + 1)); printf 'PASS: %s\n' "$1"; }
fail_test() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_true() {
  local description="$1"
  shift
  if "$@"; then pass_test "$description"; else fail_test "$description"; fi
}
assert_false() {
  local description="$1"
  shift
  if "$@"; then fail_test "$description"; else pass_test "$description"; fi
}
assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  if grep -Fq -- "$needle" "$file"; then pass_test "$description"; else fail_test "$description"; fi
}

export SKIP_DEVICE_DETECT=1
export STUARI_SUITE_DIR="$TMP_DIR"
export SCREENSHOTS="$TMP_DIR/valid-screenshots"
export AX_TREES="$TMP_DIR/valid-ax"
export DEVICE_ID="requested-hardening-device"
export IEZ="fake-iez"
mkdir -p "$SCREENSHOTS" "$AX_TREES"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/auth.sh"

root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
caption="$(printf '%*s' 49 '' | tr ' ' x)"
progress='{"role":"AXStaticText","label":"231 characters remaining","enabled":true,"frame":{"x":20,"y":738,"width":180,"height":20}}'
composer_identity='{"role":"AXStaticText","label":"New Check-in","enabled":true,"frame":{"x":80,"y":24,"width":120,"height":30}}'
back_button='{"role":"AXButton","label":"Go back","enabled":true,"frame":{"x":12,"y":20,"width":44,"height":44}}'
post_button='{"role":"AXButton","label":"Post","enabled":true,"frame":{"x":20,"y":764,"width":362,"height":52}}'

# Given the real compact AX state for a 49-character caption omits AXTextField
# When the progress wait runs Then rooted composer/progress proof still passes.
INPUT_TREE="{\"ok\":true,\"data\":{\"elements\":[$root,$composer_identity,$back_button,$post_button,$progress]}}"
run_iez() {
  local _binary="$1"
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    printf '%s\n' "$INPUT_TREE"
    return 0
  fi
  return 1
}
sleep() { :; }
assert_true "Given a 49-character caption When AX omits AXTextField Then exact 231-character progress with rooted composer proof passes" \
  wait_for_checkin_input_progress "$caption" 1 0

# Given a rooted composer with a wrong count When the wait runs Then it fails closed.
wrong_count_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$composer_identity,$back_button,$post_button,{\"role\":\"AXStaticText\",\"label\":\"230 characters remaining\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":738,\"width\":180,\"height\":20}}]}}"
INPUT_TREE="$wrong_count_tree"
assert_false "Given rooted composer proof with the wrong remaining count Then progress fails closed" \
  wait_for_checkin_input_progress "$caption" 1 0

# Given a count on a different route When the wait runs Then a count alone cannot prove the composer.
wrong_route_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$progress]}}"
INPUT_TREE="$wrong_route_tree"
assert_false "Given a correct count on the wrong route Then progress fails closed" \
  wait_for_checkin_input_progress "$caption" 1 0

# Given a same-length substituted field value When progress is correct Then
# the pre-submit gate may pass, but exact terminal caption proof still fails.
wrong_value="$(printf '%*s' 49 '' | tr ' ' y)"
equal_length_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$composer_identity,$back_button,$post_button,$progress,{\"role\":\"AXTextField\",\"label\":\"Share your progress...\",\"value\":\"$wrong_value\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":617,\"width\":362,\"height\":115}}]}}"
INPUT_TREE="$equal_length_tree"
assert_true "Given equal-length substituted input When progress is correct Then the pre-submit progress gate remains honest" \
  wait_for_checkin_input_progress "$caption" 1 0

wrong_post_tree="{\"ok\":true,\"data\":{\"elements\":[${root},{\"role\":\"AXStaticText\",\"label\":\"Feed\\nTab 1 of 3\",\"frame\":{\"x\":20,\"y\":80,\"width\":180,\"height\":44}},{\"role\":\"AXStaticText\",\"label\":\"Confirmed\\n$wrong_value\",\"frame\":{\"x\":20,\"y\":140,\"width\":362,\"height\":180}}]}}"
assert_false "Given equal-length substituted post text When terminal proof runs Then exact caption proof fails" \
  post_tree_has_exact_caption "$wrong_post_tree" "$caption"

# Given a selected Video mode semantic may be AXGenericElement When the video
# state is checked Then the selector and one enabled in-bounds capture button pass.
video_selector_generic='{"role":"AXGenericElement","label":"Camera mode selector. Video mode selected","enabled":true,"frame":{"x":220,"y":80,"width":150,"height":44}}'
video_capture='{"role":"AXButton","id":"camera_capture_video_button","label":"Start video recording","enabled":true,"frame":{"x":161,"y":728,"width":80,"height":80}}'
video_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$video_selector_generic,$video_capture]}}"
assert_true "Given GenericElement selected-mode semantics When Video state is checked Then the exact selector and capture button pass" \
  camera_tree_matches_state video "$video_tree"

video_button_selector="${video_tree/AXGenericElement/AXButton}"
assert_false "Given the selected-mode selector has the wrong AXButton role Then Video state fails closed" \
  camera_tree_matches_state video "$video_button_selector"

disabled_video="${video_tree/\"enabled\":true,\"frame\":{\"x\":161/\"enabled\":false,\"frame\":{\"x\":161}"
assert_false "Given a disabled video capture button Then Video state fails closed" \
  camera_tree_matches_state video "$disabled_video"
offscreen_video="${video_tree/\"x\":161,\"y\":728/\"x\":500,\"y\":728}"
assert_false "Given an out-of-bounds video capture button Then Video state fails closed" \
  camera_tree_matches_state video "$offscreen_video"
duplicate_video="{\"ok\":true,\"data\":{\"elements\":[$root,$video_selector_generic,$video_capture,$video_capture]}}"
assert_false "Given duplicate enabled in-bounds video capture buttons Then Video state fails closed" \
  camera_tree_matches_state video "$duplicate_video"
duplicate_selector="{\"ok\":true,\"data\":{\"elements\":[$root,$video_selector_generic,$video_selector_generic,$video_capture]}}"
assert_false "Given duplicate selected-mode selectors Then Video state fails closed" \
  camera_tree_matches_state video "$duplicate_selector"
wrong_selector="${video_tree/Camera mode selector. Video mode selected/Camera mode selector. Photo mode selected}"
assert_false "Given the wrong selected-mode label Then Video state fails closed" \
  camera_tree_matches_state video "$wrong_selector"

# Given a transient centered card and a durable canonical card When selecting
# the Flow32 target Then the bounded exact-id selector reaches the canonical card.
CAROUSEL_STATE="$TMP_DIR/carousel.state"
printf '0\n' >"$CAROUSEL_STATE"
CAROUSEL_TREE() {
  local id="$1"
  printf '%s\n' "{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"id\":\"$id\",\"label\":\"Habit card: target habit, Tap to check in\",\"enabled\":true,\"frame\":{\"x\":78,\"y\":118,\"width\":245,\"height\":382}}]}}"
}
run_iez() {
  local _binary="$1"
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    if [ "$(cat "$CAROUSEL_STATE")" -eq 0 ]; then CAROUSEL_TREE "habit_card_transient"; else CAROUSEL_TREE "$SEEDED_GROUP_CARD_ID"; fi
    return 0
  fi
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "swipe" ]; then
    printf '1\n' >"$CAROUSEL_STATE"
    printf '%s\n' '{"ok":true,"data":{"swiped":true}}'
    return 0
  fi
  return 1
}
assert_true "Given Flow32 starts on a transient centered card When selecting the canonical id Then the exact canonical card is selected" \
  select_habit_card_by_id "$SEEDED_GROUP_CARD_ID" 2 0
assert_true "Given canonical selection succeeds Then the visible card id is the durable seeded card" \
  test "$(current_visible_habit_card_id)" = "$SEEDED_GROUP_CARD_ID"
printf '0\n' >"$CAROUSEL_STATE"
assert_false "Given the durable canonical card is missing Then selection fails normally without a transient fallback" \
  select_habit_card_by_id "habit_card_missing" 1 0

FLOW32_FILE="$ROOT_DIR/stuari/flows/32_habit_detail.sh"
assert_file_contains 'select_habit_card_by_id "$SEEDED_GROUP_CARD_ID"' "$FLOW32_FILE" \
  "Flow32 selects the durable canonical SEEDED_GROUP_CARD_ID"
assert_file_contains 'if ! select_habit_card_by_id "$SEEDED_GROUP_CARD_ID"' "$FLOW32_FILE" \
  "Flow32 fails normally when canonical selection is unavailable"

# Given readiness recovery runs under a release ledger When it captures an
# unready AX state Then the artifacts are explicitly diagnostic and publish no event.
assert_file_contains 'capture "auth_ax_not_ready_initial" diagnostic' "$ROOT_DIR/stuari/lib/auth.sh" \
  "Auth readiness initial failure uses diagnostic capture"
assert_file_contains 'capture "auth_ax_not_ready_final" diagnostic' "$ROOT_DIR/stuari/lib/auth.sh" \
  "Auth readiness final failure uses diagnostic capture"
assert_file_contains 'diagnostic_mode=0' "$ROOT_DIR/stuari/lib/common.sh" \
  "Common capture helper has an explicit diagnostic mode"
if awk '/capture "auth_[A-Za-z0-9_]+"/ && $0 !~ / diagnostic([[:space:]]|$)/ { found=1 } END { exit found ? 0 : 1 }' \
  "$ROOT_DIR/stuari/lib/auth.sh"; then
  fail_test "Every reusable auth helper capture must be diagnostic"
else
  pass_test "Every reusable auth helper capture is excluded from published release states"
fi

# Given readiness recovery captures a stable but non-publishable AX snapshot
# When capture runs in diagnostic mode Then it leaves only explicitly invalid
# artifacts and does not append a release event.
DIAGNOSTIC_EVENTS="$TMP_DIR/diagnostic.events"
DIAGNOSTIC_SCREENSHOTS="$TMP_DIR/diagnostic-screenshots"
DIAGNOSTIC_AX="$TMP_DIR/diagnostic-ax"
if (
  SCREENSHOTS="$DIAGNOSTIC_SCREENSHOTS"
  AX_TREES="$DIAGNOSTIC_AX"
  STUARI_EVIDENCE_RUN_ID="11111111-2222-4333-8444-555555555555"
  STUARI_EVIDENCE_EVENT_FILE="$DIAGNOSTIC_EVENTS"
  CAPTURE_SEQUENCE=0
  mkdir -p "$SCREENSHOTS" "$AX_TREES"
  : >"$STUARI_EVIDENCE_EVENT_FILE"
  run_iez() {
    local _binary="$1"
    shift
    if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
      printf '%s\n' "$INPUT_TREE"
      return 0
    fi
    if [ "${1:-}" = "ui" ] && [ "${2:-}" = "screenshot" ]; then
      printf 'png\n' >"${4:-}"
      printf '%s\n' '{"ok":true,"data":{}}'
      return 0
    fi
    return 1
  }
  capture "auth_ax_not_ready_initial" diagnostic
  [ ! -s "$STUARI_EVIDENCE_EVENT_FILE" ] || exit 1
  [ -n "$(find "$SCREENSHOTS" "$AX_TREES" -type f -name '*.invalid.*' -print -quit)" ] || exit 1
  [ -z "$(find "$SCREENSHOTS" "$AX_TREES" -type f ! -name '*.invalid.*' -print -quit)" ] || exit 1
); then
  pass_test "Given diagnostic readiness capture runs Then invalid artifacts stay out of the published event ledger"
else
  fail_test "Diagnostic readiness capture must not publish valid release evidence"
fi

# Given a release flow publishes its own declared auth states When the reusable
# dev-login helper is invoked repeatedly Then helper transitions remain unique
# diagnostics and cannot collide in the current-run event ledger.
AUTH_TRANSITION_EVENTS="$TMP_DIR/auth-transition.events"
AUTH_TRANSITION_SCREENSHOTS="$TMP_DIR/auth-transition-screenshots"
AUTH_TRANSITION_AX="$TMP_DIR/auth-transition-ax"
if (
  SCREENSHOTS="$AUTH_TRANSITION_SCREENSHOTS"
  AX_TREES="$AUTH_TRANSITION_AX"
  STUARI_EVIDENCE_RUN_ID="22222222-3333-4444-8555-666666666666"
  STUARI_EVIDENCE_EVENT_FILE="$AUTH_TRANSITION_EVENTS"
  CAPTURE_SEQUENCE=0
  PASS=0
  FAIL=0
  SKIP=0
  NA=0
  TOTAL=0
  mkdir -p "$SCREENSHOTS" "$AX_TREES"
  : >"$STUARI_EVIDENCE_EVENT_FILE"
  INPUT_TREE="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Dev sign in\",\"enabled\":true,\"frame\":{\"x\":20,\"y\":680,\"width\":362,\"height\":52}}]}}"
  run_iez() {
    local _binary="$1"
    shift
    if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
      printf '%s\n' "$INPUT_TREE"
      return 0
    fi
    if [ "${1:-}" = "ui" ] && [ "${2:-}" = "screenshot" ]; then
      printf 'png\n' >"${4:-}"
      printf '%s\n' '{"ok":true,"data":{}}'
      return 0
    fi
    return 1
  }
  tap_element() { return 0; }
  has_label() { return 1; }
  tree_contains() { return 1; }
  on_home_page() { return 0; }
  on_onboarding_page() { return 1; }

  capture "03_auth_page" || exit 1
  login_with_dev_magic || exit 1
  login_with_dev_magic || exit 1
  capture "03_signed_in_home" || exit 1

  [ "$FAIL" -eq 0 ] || exit 1
  [ "$(jq -s 'length' "$STUARI_EVIDENCE_EVENT_FILE")" -eq 2 ] || exit 1
  jq -s -e '
    map(.state_id) == ["03_auth_page", "03_signed_in_home"]
    and ([.[].state_id] | length == (unique | length))
    and all(.[]; .run_id == "22222222-3333-4444-8555-666666666666")
  ' "$STUARI_EVIDENCE_EVENT_FILE" >/dev/null || exit 1
  [ "$(find "$SCREENSHOTS" -type f -name 'auth_*.invalid.png' | wc -l | tr -d ' ')" -eq 4 ] || exit 1
  [ "$(find "$AX_TREES" -type f -name 'auth_*.invalid.json' | wc -l | tr -d ' ')" -eq 4 ] || exit 1
  [ -z "$(find "$SCREENSHOTS" "$AX_TREES" -type f -name 'auth_*' ! -name '*.invalid.*' -print -quit)" ] || exit 1
  STUARI_VISUAL_MANIFEST_OUTPUT="$TMP_DIR/auth-transition-manifest.json" \
    bash "$ROOT_DIR/stuari/generate_visual_state_manifest.sh" || exit 1
  jq -s -e --slurpfile manifest "$TMP_DIR/auth-transition-manifest.json" '
    ($manifest[0].flows[] | select(.number == "03") | .states) as $declared
    | all(.[]; (.state_id as $state | $declared | index($state)) != null)
    and ($declared | index("auth_pre_dev_magic") == null)
    and ($declared | index("auth_post_dev_magic") == null)
  ' "$STUARI_EVIDENCE_EVENT_FILE" >/dev/null || exit 1
); then
  pass_test "Given repeated dev login under a release ledger Then only declared flow states publish and auth transitions remain unique diagnostics"
else
  fail_test "Repeated dev login must not publish or invalidate helper-level auth states"
fi

# Given a hanging exact-ownership SQL command When cleanup is bounded Then it
# fails closed and leaves the lifecycle responsible for cleanup.
assert_file_contains 'run_stuari_linked_sql_file_bounded' "$ROOT_DIR/stuari/lib/fixtures.sh" \
  "Due-now cleanup delegates through a bounded SQL runner"
assert_file_contains 'STUARI_DUE_NOW_CLEANUP_TIMEOUT_SECONDS' "$ROOT_DIR/stuari/lib/fixtures.sh" \
  "Due-now cleanup exposes a bounded timeout"
assert_file_contains 'CLEANUP_REQUIRED' "$ROOT_DIR/stuari/flows/06_checkin_video.sh" \
  "Video cleanup preserves fail-closed status vocabulary"
assert_file_contains 'CLEANUP_REQUIRED' "$ROOT_DIR/stuari/flows/05_checkin_photo.sh" \
  "Photo cleanup preserves fail-closed status vocabulary"

# Given the exact cleanup command hangs after ownership is established When the
# fixture cleanup times out Then the timeout is bounded and lifecycle status
# remains CLEANUP_REQUIRED rather than being mistaken for a successful delete.
export STUARI_APP_REPO_DIR="$TMP_DIR/fake-app"
mkdir -p "$STUARI_APP_REPO_DIR"
source "$ROOT_DIR/stuari/lib/fixtures.sh"
HANGING_SQL="$TMP_DIR/hanging-cleanup.sql"
printf 'select 1;\n' >"$HANGING_SQL"
run_stuari_linked_sql_file() { /bin/sleep 5; }
STUARI_DUE_NOW_CLEANUP_TIMEOUT_SECONDS=1
bounded_cleanup_rc=0
run_stuari_linked_sql_file_bounded "$HANGING_SQL" "Hanging cleanup fixture" 1 || bounded_cleanup_rc=$?
assert_true "Given hanging cleanup When bounded runner returns Then it uses the timeout contract" test "$bounded_cleanup_rc" -eq 124

supabase() { return 0; }
persisted_session_is_verified_alice() { return 0; }
new_due_now_occurrence_fixture_identity
STUARI_DUE_NOW_OCCURRENCE_ID="11111111-2222-4333-8444-555555555555"
STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED=1
cleanup_due_now_occurrence_fixture >/dev/null 2>&1
assert_true "Given cleanup ownership is required When SQL times out Then the lifecycle remains CLEANUP_REQUIRED" \
  test "${STUARI_DUE_NOW_FIXTURE_CLEANUP_REQUIRED:-0}" = 1

printf 'Requested release hardening: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
