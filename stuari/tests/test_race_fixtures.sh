#!/usr/bin/env bash
# RED/GREEN regression fixtures for the Stuari occurrence harness races:
#
# 1. macOS mktemp templates must end with XXXXXX. Putting `.sql` (or any
#    suffix) after XXXXXX makes mktemp create a LITERAL file name instead of
#    substituting the random suffix, so a second allocation from the same
#    template fails with "File exists" (the permanent TMPDIR race observed in
#    flows 05/06 cleanup).
#
# 2. The local Drift occurrence authority must match the EXACT fresh remote
#    occurrence id that reseed created. Counting open/window/status rows alone
#    accepts a stale pre-reseed row; the camera RPC then rejects that stale id
#    ("This check-in is no longer available") and the flow fails after the
#    card was already tapped.
#
# 3. The bounded Drift authority wait must accept the exact fresh occurrence
#    id only once it propagates into local Drift.
#
# 4. Flows 05/06 must wait (bounded) for the exact centered habit card to
#    render its actionable semantic label before checking it.
#
# No simulator, installed app, or live Supabase project is touched: supabase,
# sqlite, and run_iez are all stubbed below.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_race_fixtures.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail_test() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass_test() {
  printf 'PASS: %s\n' "$1"
}

export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export IEZ="fake-iez"
export DEVICE_ID="race-test-device"
export STUARI_APP_REPO_DIR="$TMP_DIR/app-repo"
mkdir -p "$STUARI_APP_REPO_DIR"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/fixtures.sh"

# ── 1. Safe unique temp allocation ──────────────────────────────────
FIXTURES_FILE="$ROOT_DIR/stuari/lib/fixtures.sh"
AUTH_FILE="$ROOT_DIR/stuari/lib/auth.sh"
for f in "$FIXTURES_FILE" "$AUTH_FILE"; do
  if grep -nE 'mktemp .*XXXXXX\.(sql|json|plist)' "$f"; then
    fail_test "mktemp template in $f must end with XXXXXX (no suffix after it)"
  fi
done
pass_test "all harness mktemp templates end with XXXXXX"

alloc_a="$(mktemp "$TMP_DIR/stuari_race_alloc.XXXXXX" 2>/dev/null)" || \
  fail_test "first unique temp allocation from a trailing-XXXXXX template failed"
alloc_b="$(mktemp "$TMP_DIR/stuari_race_alloc.XXXXXX" 2>/dev/null)" || \
  fail_test "second unique temp allocation from the same template collided"
[ "$alloc_a" != "$alloc_b" ] || fail_test "two allocations from the same template must be distinct"
literal_left="$(find "$TMP_DIR" -maxdepth 1 -name 'stuari_race_alloc*XXXXXX*' | wc -l | tr -d ' ')"
[ "$literal_left" = "0" ] || fail_test "template must not leave a literal XXXXXX file behind"
rm -f "$alloc_a" "$alloc_b"
pass_test "unique temp allocation is collision-free and leaves no literal template file"

# ── 2/3. Exact remote occurrence id synchronization ─────────────────
FRESH_OCCURRENCE_ID="11111111-2222-3333-4444-555555555555"
STALE_OCCURRENCE_ID="99999999-8888-7777-6666-555555555555"
export STUARI_DUE_NOW_OCCURRENCE_ID="$FRESH_OCCURRENCE_ID"

FAKE_DRIFT_DB="$TMP_DIR/stuari_offline.sqlite"
: > "$FAKE_DRIFT_DB"
DRIFT_PROBE_SQL_CAPTURE="$TMP_DIR/drift_probe.sql"
DRIFT_PROBE_CALLS="$TMP_DIR/drift_probe.calls"
DRIFT_STORED_OCCURRENCE_ID="$STALE_OCCURRENCE_ID"
DRIFT_FRESH_AVAILABLE_AFTER="0"

stuari_fixture_drift_db_path() {
  printf '%s\n' "$FAKE_DRIFT_DB"
}

stuari_fixture_now_epoch_ms() {
  printf '2000000000000\n'
}

stuari_fixture_sqlite_query() {
  local db_path="$1" query="$2" calls="" expected_id=""
  [ "$db_path" = "$FAKE_DRIFT_DB" ] || return 1
  [ "$query" = "select 1;" ] && return 0

  printf '%s\n' "$query" > "$DRIFT_PROBE_SQL_CAPTURE"
  calls="$(cat "$DRIFT_PROBE_CALLS")"
  calls=$((calls + 1))
  printf '%s\n' "$calls" > "$DRIFT_PROBE_CALLS"

  expected_id="$(printf '%s\n' "$query" \
    | sed -n "s/.*occurrence_id = '\([^']*\)'.*/\1/p" \
    | head -1)"
  if [ "$expected_id" != "$DRIFT_STORED_OCCURRENCE_ID" ]; then
    printf '1|0\n'
    return 0
  fi
  if [ "$calls" -ge "$DRIFT_FRESH_AVAILABLE_AFTER" ]; then
    printf '1|1\n'
  else
    printf '1|0\n'
  fi
}

sleep() {
  :
}

# Stale row: group/occurrence counts and window/status match, but the local
# occurrence id differs from the freshly reseeded remote id. Must fail closed.
printf '0\n' > "$DRIFT_PROBE_CALLS"
DRIFT_STORED_OCCURRENCE_ID="$STALE_OCCURRENCE_ID"
DRIFT_FRESH_AVAILABLE_AFTER="0"
if wait_for_due_now_occurrence_drift_authority 3 0; then
  fail_test "stale local occurrence (id != fresh remote id) must be rejected despite matching count/window/status"
fi
grep -Fq "occurrence_id = '$FRESH_OCCURRENCE_ID'" "$DRIFT_PROBE_SQL_CAPTURE" || \
  fail_test "Drift authority probe must filter the exact fresh remote occurrence id"
pass_test "stale local occurrence rejected; probe filters the exact fresh remote occurrence id"

# Fresh propagation: the exact remote id appears in local Drift on the third
# probe. The bounded wait must accept it only once propagated.
printf '0\n' > "$DRIFT_PROBE_CALLS"
DRIFT_STORED_OCCURRENCE_ID="$FRESH_OCCURRENCE_ID"
DRIFT_FRESH_AVAILABLE_AFTER="3"
wait_for_due_now_occurrence_drift_authority 5 0 || \
  fail_test "bounded wait must accept the exact fresh remote occurrence once propagated"
[ "$(cat "$DRIFT_PROBE_CALLS")" = "3" ] || \
  fail_test "bounded wait must not accept before the fresh id propagates (probes=$(cat "$DRIFT_PROBE_CALLS"))"
pass_test "bounded wait accepts the exact fresh remote occurrence only once propagated"

# ── 4. Bounded actionable label wait ────────────────────────────────
ACTIONABLE_TARGET_ID="habit_card_bbbb0000-0000-0000-0000-000000000010"
AX_CALLS_FILE="$TMP_DIR/ax_calls"
AX_MODE="delayed-actionable"
printf '0\n' > "$AX_CALLS_FILE"

run_iez() {
  local _binary="$1" calls=""
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    calls="$(cat "$AX_CALLS_FILE")"
    calls=$((calls + 1))
    printf '%s\n' "$calls" > "$AX_CALLS_FILE"
    if [ "$AX_MODE" = "delayed-actionable" ] && [ "$calls" -ge 3 ]; then
      printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"habit_card_bbbb0000-0000-0000-0000-000000000010","label":"Habit card: IEZ Due Now Check-In habit, Tap to check in","frame":{"x":150,"y":250,"width":92,"height":120},"enabled":true}]}}'
    else
      printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"habit_card_bbbb0000-0000-0000-0000-000000000010","label":"Habit card: IEZ Due Now Check-In habit, On track","frame":{"x":150,"y":250,"width":92,"height":120},"enabled":true}]}}'
    fi
    return 0
  fi
  return 1
}

wait_for_habit_card_actionable "$ACTIONABLE_TARGET_ID" 5 0 || \
  fail_test "bounded wait must accept the exact centered card once its actionable label renders"
[ "$(cat "$AX_CALLS_FILE")" = "3" ] || \
  fail_test "bounded wait must not proceed before the actionable label renders (reads=$(cat "$AX_CALLS_FILE"))"

AX_MODE="never-actionable"
printf '0\n' > "$AX_CALLS_FILE"
if wait_for_habit_card_actionable "$ACTIONABLE_TARGET_ID" 2 0; then
  fail_test "bounded wait must fail closed when the actionable label never renders"
fi
[ "$(cat "$AX_CALLS_FILE")" = "8" ] || \
  fail_test "bounded wait must respect the exact poll bound (reads=$(cat "$AX_CALLS_FILE"), expected 8)"
unset -f sleep
pass_test "bounded actionable label wait accepts on render and fails closed on timeout"

# -- 5. Flow 20 semantic wizard actions ------------------------------
FLOW20_FILE="$ROOT_DIR/stuari/flows/20_habit_edit.sh"
flow20_wizard_block="$(sed -n '/^# Walk forward through the PageView wizard/,/^# Final save/p' "$FLOW20_FILE")"
printf '%s\n' "$flow20_wizard_block" | grep -Fq 'tap_first_matching_exact_labels' || \
  fail_test "Flow 20 must reuse the exact legacy-or-semantic wizard action helper"
printf '%s\n' "$flow20_wizard_block" | grep -Fq '"Continue: habit name"' || \
  fail_test "Flow 20 must accept the semantic habit-name Continue label"
printf '%s\n' "$flow20_wizard_block" | grep -Fq '"Skip: habit image"' || \
  fail_test "Flow 20 must preserve the semantic image Skip label"
if printf '%s\n' "$flow20_wizard_block" | grep -Eq 'has_label "(Continue|Skip)"|tap_element "(Continue|Skip)"'; then
  fail_test "Flow 20 wizard must not depend on legacy-only Continue or Skip checks"
fi

enabled_action_fixture='{"ok":true,"data":{"elements":[{"label":"Continue: habit name","enabled":false,"frame":{"x":20,"y":500,"width":200,"height":56}},{"label":"Continue: habit name","enabled":true,"frame":{"x":100,"y":600,"width":160,"height":56}}]}}'
enabled_action_coords="$(
  run_iez() { printf '%s\n' "$enabled_action_fixture"; }
  first_coords_matching_exact_labels "Continue" "Continue: habit name"
)"
[ "$enabled_action_coords" = "180,628" ] || \
  fail_test "exact wizard action helper must ignore disabled semantic controls"
pass_test "Flow 20 uses enabled exact legacy-or-semantic wizard actions"

# -- 6. Flow 34 strict case-insensitive habit-name wait --------------
NAME_WAIT_CALLS_FILE="$TMP_DIR/name_wait.calls"
printf '0\n' > "$NAME_WAIT_CALLS_FILE"
run_iez() {
  local _binary="$1" calls=""
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    calls="$(cat "$NAME_WAIT_CALLS_FILE")"
    calls=$((calls + 1))
    printf '%s\n' "$calls" > "$NAME_WAIT_CALLS_FILE"
    if [ "$calls" -ge 3 ]; then
      printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"habit_card_exact","label":"Habit card: delete me 3273 habit, On track","frame":{"x":78,"y":118,"width":245,"height":382}}]}}'
    else
      printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"habit_card_collision","label":"Habit card: Delete Me 3273x habit, On track","frame":{"x":78,"y":118,"width":245,"height":382}}]}}'
    fi
    return 0
  fi
  return 1
}
sleep() { :; }
wait_for_habit_name "Delete Me 3273" 5 || \
  fail_test "bounded habit-name wait must accept the exact lowercased card once rendered"
[ "$(cat "$NAME_WAIT_CALLS_FILE")" = "3" ] || \
  fail_test "habit-name wait must reject prefix/suffix collisions before exact propagation"
unset -f sleep

FLOW34_FILE="$ROOT_DIR/stuari/flows/34_habit_delete_persistence.sh"
grep -Fq 'wait_for_habit_name "$HABIT_NAME"' "$FLOW34_FILE" || \
  fail_test "Flow 34 must retain the bounded habit-name wait before deletion"
wait_for_habit_name_block="$(sed -n '/^wait_for_habit_name() {/,/^}/p' "$ROOT_DIR/stuari/lib/common.sh")"
printf '%s\n' "$wait_for_habit_name_block" | grep -Fq 'habit_card_label_matches_name' || \
  fail_test "habit-name wait must use the strict case-insensitive bounded card matcher"
pass_test "Flow 34 waits for an exact case-insensitive habit card name without collisions"

# -- 7. Camera controls use rendered coordinates and terminal states -------
CAMERA_TREE_CALLS_FILE="$TMP_DIR/camera_tree.calls"
CAMERA_TREE_MODE="scaled-control"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
run_iez() {
  local _binary="$1" calls=""
  shift
  if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ]; then
    calls="$(cat "$CAMERA_TREE_CALLS_FILE")"
    calls=$((calls + 1))
    printf '%s\n' "$calls" > "$CAMERA_TREE_CALLS_FILE"
    case "$CAMERA_TREE_MODE" in
      scaled-control)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"Mock camera (simulator)","frame":{"x":0,"y":0,"width":134,"height":291.3333333333}},{"id":"camera_capture_photo_button","label":"Take photo","frame":{"x":53.6666666667,"y":242.6666666667,"width":26.6666666667,"height":26.6666666667}}]}}'
        ;;
      normal-control)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"Mock camera (simulator)","frame":{"x":0,"y":0,"width":402,"height":874}},{"id":"camera_capture_photo_button","label":"Take photo","frame":{"x":161,"y":728,"width":80,"height":80}}]}}'
        ;;
      invalid-scale-control)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"Mock camera (simulator)","frame":{"x":0,"y":0,"width":180,"height":400}},{"id":"camera_capture_photo_button","label":"Take photo","frame":{"x":80,"y":360,"width":40,"height":40}}]}}'
        ;;
      delayed-video)
        if [ "$calls" -ge 3 ]; then
          printf '%s\n' '{"ok":true,"data":{"elements":[{"label":"Camera mode selector. Video mode selected"},{"id":"camera_capture_video_button","label":"Start video recording"}]}}'
        else
          printf '%s\n' '{"ok":true,"data":{"elements":[{"label":"Camera mode selector. Photo mode selected"},{"id":"camera_capture_photo_button","label":"Take photo"}]}}'
        fi
        ;;
      never-compose)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"id":"camera_capture_photo_button","label":"Take photo"}]}}'
        ;;
      compose-with-stale-camera-nodes)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXStaticText","label":"New Check-in"},{"role":"AXButton","label":"Go back"},{"role":"AXButton","label":"Post"},{"role":"AXTextField","label":"Share your progress..."},{"role":"AXButton","id":"camera_capture_photo_button","label":"Take photo"}]}}'
        ;;
      scaled-composer-control)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"Mock camera (simulator)","frame":{"x":0,"y":0,"width":134,"height":291.3333333333}},{"role":"AXButton","label":"Post","frame":{"x":6.6666666667,"y":254.6666666667,"width":120.6666666667,"height":17.3333333333}},{"role":"AXTextField","label":"Share your progress...","value":"","frame":{"x":6.6666666667,"y":205.6666666667,"width":120.6666666667,"height":38.3333333333}}]}}'
        ;;
      delayed-caption)
        if [ "$calls" -ge 3 ]; then
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXGenericElement","label":"271 characters remaining"}]}}'
        else
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXGenericElement","label":"272 characters remaining"}]}}'
        fi
        ;;
      wrong-caption-count)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXTextField","label":"Share your progress...","value":""},{"role":"AXGenericElement","label":"270 characters remaining"}]}}'
        ;;
      compose-ready)
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"New Check-in"},{"role":"AXButton","label":"Go back"},{"role":"AXStaticText","label":"269 characters remaining"},{"role":"AXButton","label":"Post","frame":{"x":20,"y":764,"width":362,"height":52}}]}}'
        ;;
      delayed-compose-ready-boundary)
        if [ "$calls" -ge 9 ]; then
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"y":0,"x":0,"width":402,"height":874}},{"role":"AXStaticText","label":"269 characters remaining","frame":{"y":238.66666666666666,"x":108.06266276041667,"width":12.60400390625,"height":5.333333333333343}},{"id":"camera_continue_to_post_button","label":"Continue to post","role":"AXButton","frame":{"y":248,"x":107.33333333333333,"width":21.33333333333333,"height":21.333333333333314}},{"role":"AXButton","label":"Go back","frame":{"y":23.333333333333332,"x":2.6666666666666665,"width":16,"height":16}},{"role":"AXStaticText","label":"Mock camera (simulator)","frame":{"y":0,"x":0,"width":134,"height":291.3333333333333}},{"role":"AXStaticText","label":"New Check-in","frame":{"y":24.666666666666668,"x":18.666666666666668,"width":35.367996215820312,"height":7.666666666666668}},{"role":"AXButton","label":"Post","frame":{"y":254.66666666666666,"x":6.666666666666667,"width":120.66666666666667,"height":17.333333333333343}},{"id":"camera_capture_photo_button","label":"Take photo","role":"AXButton","frame":{"y":242.66666666666666,"x":53.666666666666664,"width":26.666666666666664,"height":26.666666666666657}}]}}'
        else
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}},{"role":"AXStaticText","label":"New Check-in"},{"role":"AXButton","label":"Go back"},{"role":"AXStaticText","label":"269 characters remaining"},{"role":"AXButton","label":"Post","frame":{"x":20,"y":850,"width":362,"height":52}}]}}'
        fi
        ;;
      delayed-post-home)
        if [ "$calls" -ge 3 ]; then
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXButton","label":"Home tab, selected"},{"id":"habit_card_bbbb0000-0000-0000-0000-000000000010","label":"Habit card: IEZ Due Now Check-In habit, Waiting for confirmation","frame":{"x":78,"y":118,"width":245,"height":382}}]}}'
        else
          printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXStaticText","label":"New Check-in"},{"role":"AXButton","label":"Post"},{"role":"AXTextField","label":"Share your progress...","value":"day 42 ok"}]}}'
        fi
        ;;
    esac
    return 0
  fi
  return 1
}

unset STUARI_CAMERA_AX_COORD_SCALE STUARI_CHECKIN_AX_COORD_SCALE
[ "$(camera_coords_for_id "camera_capture_photo_button")" = "201,768" ] || \
  fail_test "camera selector must auto-detect and correct a 402/134 scaled AX tree"

CAMERA_TREE_MODE="normal-control"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
[ "$(camera_coords_for_id "camera_capture_photo_button")" = "201,768" ] || \
  fail_test "camera selector must preserve coordinates for a normal 402/402 AX tree"

CAMERA_TREE_MODE="invalid-scale-control"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
if camera_coords_for_id "camera_capture_photo_button" >/dev/null; then
  fail_test "camera selector must fail closed for a non-integer camera/application scale ratio"
fi

sleep() { :; }
CAMERA_TREE_MODE="delayed-video"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_camera_state "video" 5 0 || \
  fail_test "camera state wait must accept video mode only after both selector and capture semantics update"
[ "$(cat "$CAMERA_TREE_CALLS_FILE")" = "3" ] || \
  fail_test "video state wait must remain bounded until semantic propagation"

CAMERA_TREE_MODE="never-compose"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
if wait_for_camera_state "compose" 2 0; then
  fail_test "camera state wait must fail closed while the camera shell remains visible"
fi
[ "$(cat "$CAMERA_TREE_CALLS_FILE")" = "9" ] || \
  fail_test "compose state wait must include one final predicate evaluation at the timeout boundary"

CAMERA_TREE_MODE="compose-with-stale-camera-nodes"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_camera_state "compose" 2 0 || \
  fail_test "compose state wait must accept exact composer identity when Axe retains hidden camera-route nodes"

CAMERA_TREE_MODE="scaled-composer-control"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
[ "$(checkin_route_coords_for_label "Share your progress..." "AXTextField")" = "201,674" ] || \
  fail_test "check-in composer field must use its scaled rendered center"
[ "$(checkin_route_coords_for_label "Post" "AXButton")" = "201,790" ] || \
  fail_test "check-in Post control must use its scaled rendered center"

CAMERA_TREE_MODE="delayed-caption"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_checkin_caption "day 42 ok" 5 0 || \
  fail_test "caption wait must require the typed value to propagate into AX"
[ "$(cat "$CAMERA_TREE_CALLS_FILE")" = "3" ] || \
  fail_test "caption wait must not accept a wrong remaining-character count"

CAMERA_TREE_MODE="wrong-caption-count"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
if wait_for_checkin_caption "day 42 ok" 2 0; then
  fail_test "caption wait must reject an empty field with the wrong remaining count"
fi

CAMERA_TREE_MODE="compose-ready"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_camera_state "compose-ready" 2 0 || \
  fail_test "post-dismiss composer wait must accept full visible Post geometry without requiring a text-field node"

CAMERA_TREE_MODE="delayed-compose-ready-boundary"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_camera_state "compose-ready" 2 0 || \
  fail_test "post-dismiss composer wait must accept retry9's positive state at the timeout boundary"
[ "$(cat "$CAMERA_TREE_CALLS_FILE")" = "9" ] || \
  fail_test "post-dismiss composer wait must evaluate the final boundary tree exactly once"
grep -Fq 'wait_for_camera_state "compose-ready" 15 0.25' "$ROOT_DIR/stuari/lib/common.sh" || \
  fail_test "keyboard dismissal must allow a bounded 15-second composer-ready transition"

CAMERA_TREE_MODE="delayed-post-home"
printf '0\n' > "$CAMERA_TREE_CALLS_FILE"
wait_for_checkin_post_completion 5 0 || \
  fail_test "Post completion must require composer disappearance and the selected Home surface"
[ "$(cat "$CAMERA_TREE_CALLS_FILE")" = "3" ] || \
  fail_test "Post completion must fail closed while the composer remains visible"
unset -f sleep

for flow_file in \
  "$ROOT_DIR/stuari/flows/05_checkin_photo.sh" \
  "$ROOT_DIR/stuari/flows/06_checkin_video.sh"
do
  grep -Fq 'wait_for_camera_state "captured"' "$flow_file" || \
    fail_test "$(basename "$flow_file") must fail closed until captured media semantics appear"
  grep -Fq 'wait_for_camera_state "compose"' "$flow_file" || \
    fail_test "$(basename "$flow_file") must fail closed until the real composer appears"
  grep -Fq 'tap_checkin_route_control_by_label "Post" "AXButton"' "$flow_file" || \
    fail_test "$(basename "$flow_file") must submit Post at the scaled rendered coordinate"
  grep -Fq 'wait_for_checkin_post_completion' "$flow_file" || \
    fail_test "$(basename "$flow_file") must fail closed until Post returns to Home"
  grep -Fq 'dismiss_checkin_route_keyboard' "$flow_file" || \
    fail_test "$(basename "$flow_file") must dismiss the keyboard before resolving Post"
done
pass_test "camera controls use rendered coordinates and bounded semantic terminal states"

printf 'All harness race fixtures passed.\n'
