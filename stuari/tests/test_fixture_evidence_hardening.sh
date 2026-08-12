#!/usr/bin/env bash

# Behavioral Given/When/Then regressions for exact Flow 18 AX restoration,
# Flow 15 lifecycle-bound SQLite ownership, and manifest-driven evidence
# validation. No simulator or Stuari checkout is touched.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "/tmp/stuari_fixture_evidence.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

passes=0
failures=0
pass_test() { passes=$((passes + 1)); printf 'PASS: %s\n' "$1"; }
fail_test() { failures=$((failures + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_true() { local d="$1"; shift; if "$@"; then pass_test "$d"; else fail_test "$d"; fi; }
assert_false() { local d="$1"; shift; if "$@"; then fail_test "$d"; else pass_test "$d"; fi; }
assert_eq() {
  local expected="$1" actual="$2" description="$3"
  [ "$expected" = "$actual" ] && pass_test "$description" || fail_test "$description (expected '$expected', got '$actual')"
}

export SKIP_DEVICE_DETECT=1
export STUARI_SUITE_DIR="$TMP_DIR"
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
source "$ROOT_DIR/stuari/lib/common.sh"

# Given mocked AX JSON for the exact Settings control
# When the pure toggle-state helper inspects it
# Then only a unique exact role/value/state-off control passes.
root='{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}'
off_switch='{"role":"AXSwitch","label":"Force offline mode","value":false,"frame":{"x":20,"y":200,"width":300,"height":48}}'
on_switch='{"role":"AXSwitch","label":"Force offline mode","value":true,"frame":{"x":20,"y":200,"width":300,"height":48}}'
off_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$off_switch]}}"
on_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$on_switch]}}"
missing_tree="{\"ok\":true,\"data\":{\"elements\":[$root]}}"
ambiguous_tree="{\"ok\":true,\"data\":{\"elements\":[$root,$off_switch,$off_switch]}}"
wrong_role_tree="{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Force offline mode\",\"value\":false,\"frame\":{\"x\":20,\"y\":200,\"width\":300,\"height\":48}}]}}"

assert_true "Given exact off AX state When helper runs Then CLEAN-eligible off proof succeeds" \
  stuari_ax_forced_offline_toggle_is_off "$off_tree"
assert_false "Given exact on AX state When helper runs Then off proof rejects it" \
  stuari_ax_forced_offline_toggle_is_off "$on_tree"
assert_false "Given missing Settings control When helper runs Then off proof fails closed" \
  stuari_ax_forced_offline_toggle_is_off "$missing_tree"
assert_false "Given ambiguous Settings controls When helper runs Then off proof fails closed" \
  stuari_ax_forced_offline_toggle_is_off "$ambiguous_tree"
assert_false "Given wrong control role When helper runs Then off proof fails closed" \
  stuari_ax_forced_offline_toggle_is_off "$wrong_role_tree"

# Given a Flow 18 source-only load with a mocked Settings/Home AX sequence
# When restoration runs
# Then it navigates to Settings, toggles only an on control, re-reads off, and
# writes CLEAN only after the online Home proof.
STUARI_FLOW18_SOURCE_ONLY=1 source "$ROOT_DIR/stuari/flows/18_offline.sh"
RESTORE_STATE=on
RESTORE_TAPS=0
RESTORE_NAVIGATION="$TMP_DIR/restore.navigation"
RESTORE_CLEAN="$TMP_DIR/restore.clean"
: >"$RESTORE_NAVIGATION"
: >"$RESTORE_CLEAN"
fresh_launch() { printf 'fresh\n' >>"$RESTORE_NAVIGATION"; }
go_settings() { printf 'settings\n' >>"$RESTORE_NAVIGATION"; return 0; }
go_home() { printf 'home\n' >>"$RESTORE_NAVIGATION"; RESTORE_STATE=home; return 0; }
mark_flow_cleanup_complete() { printf 'CLEAN\n' >>"$RESTORE_CLEAN"; }
has_label() { return 1; }
tree_contains() { return 1; }
run_iez() {
  case "$RESTORE_STATE" in
    on) printf '%s\n' "$on_tree" ;;
    off) printf '%s\n' "$off_tree" ;;
    home) printf '%s\n' "{\"ok\":true,\"data\":{\"elements\":[$root,{\"role\":\"AXButton\",\"label\":\"Home tab, selected\",\"frame\":{\"x\":20,\"y\":800,\"width\":100,\"height\":44}}]}}" ;;
    ambiguous) printf '%s\n' "$ambiguous_tree" ;;
    missing) printf '%s\n' "$missing_tree" ;;
  esac
}
tap_element() {
  RESTORE_TAPS=$((RESTORE_TAPS + 1))
  RESTORE_STATE=off
  return 0
}
FORCED_OFFLINE_ENABLED=true
RESTORE_STATE=on
assert_true "Given Settings reports on then restoration toggles once and proves off before Home" \
  restore_forced_online
assert_eq "1" "$RESTORE_TAPS" "Restoration toggles only when the exact control is on"
assert_eq "CLEAN" "$(cat "$RESTORE_CLEAN")" "CLEAN is written only after off plus online proof"
assert_eq $'fresh\nsettings\nhome' "$(cat "$RESTORE_NAVIGATION")" \
  "Restoration follows the Settings then Home lifecycle"

for invalid_state in ambiguous missing; do
  : >"$RESTORE_NAVIGATION"
  : >"$RESTORE_CLEAN"
  RESTORE_STATE="$invalid_state"
  FORCED_OFFLINE_ENABLED=true
  RESTORE_TAPS=0
  assert_false "Given $invalid_state Settings state Then restoration fails before cleanup is marked" \
    restore_forced_online
  assert_eq "0" "$RESTORE_TAPS" "Given $invalid_state Settings state Then no toggle is delivered"
  assert_false "Given $invalid_state Settings state Then CLEAN is not written" test -s "$RESTORE_CLEAN"
done

# Given two exact lifecycle tokens and a temporary SQLite notifications schema
# When fixtures are inserted, backed up, restored, and cleaned
# Then identities are collision-safe and token B cannot mutate token A.
source "$ROOT_DIR/stuari/lib/notification_fixture.sh"
DB_PATH="$TMP_DIR/notifications.sqlite"
sqlite3 "$DB_PATH" <<'SQL'
create table notifications (
  id text primary key,
  user_id text not null,
  type text not null,
  title text not null,
  body text not null,
  data text not null,
  is_read integer not null,
  created_at integer not null,
  sync_version integer not null
);
SQL
TOKEN_A=11111111-2222-4333-8444-555555555555
TOKEN_B=22222222-3333-4444-8555-666666666666
notification_fixture_init_identity "$TOKEN_A"
fixture_a_id="$NOTIFICATION_FIXTURE_ID"
fixture_a_backup="$NOTIFICATION_BACKUP_TABLE"
notification_fixture_init_identity "$TOKEN_B"
fixture_b_id="$NOTIFICATION_FIXTURE_ID"
fixture_b_backup="$NOTIFICATION_BACKUP_TABLE"
assert_false "Given distinct lifecycle tokens Then fixture row identifiers cannot collide" test "$fixture_a_id" = "$fixture_b_id"
assert_false "Given distinct lifecycle tokens Then backup table identifiers cannot collide" test "$fixture_a_backup" = "$fixture_b_backup"

notification_fixture_insert_row "$DB_PATH" "$TOKEN_A" user-a group-a
assert_true "Given token A When its fixture is inserted Then exact ownership is provable" \
  notification_fixture_row_is_owned "$DB_PATH" "$TOKEN_A"
assert_false "Given token A exists When token A inserts again Then overwrite is refused" \
  notification_fixture_insert_row "$DB_PATH" "$TOKEN_A" user-a group-a
assert_false "Given token A exists When token B cleans rows Then A is untouched and cleanup is refused" \
  notification_fixture_cleanup_row "$DB_PATH" "$TOKEN_B"
assert_true "Given token B cleanup was attempted Then token A remains owned" \
  notification_fixture_row_is_owned "$DB_PATH" "$TOKEN_A"

notification_fixture_create_backup "$DB_PATH" "$TOKEN_A"
assert_true "Given token A claims the live table Then its exact backup ownership is provable" \
  notification_fixture_backup_is_owned "$DB_PATH" "$TOKEN_A"
assert_false "Given token A backup exists When token B claims a backup Then it cannot rename A" \
  notification_fixture_create_backup "$DB_PATH" "$TOKEN_B"
assert_false "Given token A backup exists When token B restores Then it cannot restore A" \
  notification_fixture_restore_backup "$DB_PATH" "$TOKEN_B"
assert_false "Given token A backup exists When token B drops Then it cannot drop A" \
  notification_fixture_drop_backup "$DB_PATH" "$TOKEN_B"
assert_true "Given token A backup exists When token A restores Then the exact table is restored" \
  notification_fixture_restore_backup "$DB_PATH" "$TOKEN_A"
assert_true "Given restored token A row When token A cleans Then exact row deletion succeeds" \
  notification_fixture_cleanup_row "$DB_PATH" "$TOKEN_A"
assert_eq "0" "$(sqlite3 "$DB_PATH" "select count(*) from notifications;")" \
  "Token B never overwrote or restored token A data"

# Given a manifest declaring two selected flow states
# When evidence artifacts are validated
# Then exact declared runtime stems are accepted and montage is invoked only
# after all mapping/security checks pass.
MANIFEST="$TMP_DIR/manifest.json"
jq -n '{
  schema_version: 1,
  flow_count: 2,
  flows: [
    {number:"04", name:"04_habit_group", path:"flows/04_habit_group.sh", states:["04_frequency_page","04_checkins_page"]},
    {number:"05", name:"05_checkin_photo", path:"flows/05_checkin_photo.sh", states:["05_home"]}
  ]
}' >"$MANIFEST"
IDENTIFY="$TMP_DIR/identify.sh"
MONTAGE="$TMP_DIR/montage.sh"
MONTAGE_CALLS="$TMP_DIR/montage.calls"
cat >"$IDENTIFY" <<'EOF'
#!/usr/bin/env bash
printf 'PNG|120|120|True|1\n'
EOF
cat >"$MONTAGE" <<'EOF'
#!/usr/bin/env bash
printf 'called\n' >>"$MONTAGE_CALLS"
for output; do :; done
printf 'png\n' >"$output"
EOF
chmod +x "$IDENTIFY" "$MONTAGE"
export STUARI_IMAGE_IDENTIFY_BIN="$IDENTIFY" STUARI_IMAGE_MONTAGE_BIN="$MONTAGE" MONTAGE_CALLS
setup_evidence() {
  EVIDENCE_ROOT="$TMP_DIR/evidence"
  SCREENSHOTS="$EVIDENCE_ROOT/screenshots"
  AX_TREES="$EVIDENCE_ROOT/ax"
  LOG_DIR="$EVIDENCE_ROOT/logs"
  RESULTS_FILE="$EVIDENCE_ROOT/flow_results.tsv"
  CONTACT_SHEET_FILE="$EVIDENCE_ROOT/contact-sheet.png"
  EVIDENCE_MANIFEST="$EVIDENCE_ROOT/evidence-manifest.json"
  STUARI_EVIDENCE_RUN_ID=aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee
  STUARI_EVIDENCE_EVENT_FILE="$EVIDENCE_ROOT/evidence-events.jsonl"
  export EVIDENCE_MANIFEST STUARI_EVIDENCE_RUN_ID STUARI_EVIDENCE_EVENT_FILE
  rm -rf "$EVIDENCE_ROOT"
  mkdir -p "$SCREENSHOTS" "$AX_TREES" "$LOG_DIR"
  printf 'flow\tresult\texit\tpass\tfail\tskip\tna\ttotal\tduration_seconds\tcleanup\n' >"$RESULTS_FILE"
  printf '04_habit_group\n05_checkin_photo\n' >"$EVIDENCE_ROOT/selected.txt"
  printf '04_habit_group\tPASS\t0\t1\t0\t0\t0\t1\t0\tCLEAN\n' >>"$RESULTS_FILE"
  printf '05_checkin_photo\tPASS\t0\t1\t0\t0\t0\t1\t0\tCLEAN\n' >>"$RESULTS_FILE"
  printf 'log\n' >"$LOG_DIR/04_habit_group.log"
  printf 'log\n' >"$LOG_DIR/05_checkin_photo.log"
  : >"$STUARI_EVIDENCE_EVENT_FILE"
  : >"$MONTAGE_CALLS"
}
write_pair() {
  local stem="$1" state_id="" flow_number=""
  state_id="$(printf '%s\n' "$stem" | sed -E 's/_[0-9]{8}_[0-9]{6}_[0-9]+_[0-9]{3}$//')"
  flow_number="${state_id%%_*}"
  printf 'png\n' >"$SCREENSHOTS/$stem.png"
  printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXApplication","label":"stuari-dev","frame":{"x":0,"y":0,"width":402,"height":874}}]}}' \
    >"$AX_TREES/$stem.json"
  jq -cn --arg run_id "$STUARI_EVIDENCE_RUN_ID" --arg state_id "$state_id" \
    --arg flow_number "$flow_number" --arg artifact_stem "$stem" \
    --arg screenshot_path "$SCREENSHOTS/$stem.png" --arg ax_path "$AX_TREES/$stem.json" \
    '{run_id:$run_id,state_id:$state_id,flow_number:$flow_number,
      artifact_stem:$artifact_stem,screenshot_path:$screenshot_path,ax_path:$ax_path,
      screenshot_command:["iez","--udid","test-device","ui","screenshot","--out",$screenshot_path],
      ax_command:["iez","--udid","test-device","ui","tree","--compact"],
      device_udid:"test-device",captured_at:"20260812_123456_123_001",result:"published"}' \
    >>"$STUARI_EVIDENCE_EVENT_FILE"
}
setup_evidence
write_pair 04_frequency_page_20260812_123456_123_001
write_pair 05_home_20260812_123457_123_002
source "$ROOT_DIR/stuari/lib/evidence_validator.sh"
assert_true "Given valid declared PNG/AX runtime pairs Then evidence validation succeeds" \
  validate_release_evidence stuari-dev "$EVIDENCE_ROOT/selected.txt" "$MANIFEST"
assert_eq "called" "$(cat "$MONTAGE_CALLS")" \
  "Given valid mappings Then contact-sheet creation runs after validation"

run_invalid_evidence_case() {
  local name="$1" stem_a="$2" stem_b="$3" manifest="$4"
  setup_evidence
  write_pair "$stem_a"
  [ -n "$stem_b" ] && write_pair "$stem_b"
  : >"$MONTAGE_CALLS"
  assert_false "Given $name artifacts When evidence validates Then it is rejected before montage" \
    validate_release_evidence stuari-dev "$EVIDENCE_ROOT/selected.txt" "$manifest"
  assert_eq "0" "$(wc -l <"$MONTAGE_CALLS" | tr -d ' ')" \
    "Given $name artifacts Then montage is never invoked"
}

run_invalid_evidence_case "an unselected-flow artifact" \
  06_unknown_20260812_123458_123_003 "" "$MANIFEST"
run_invalid_evidence_case "an unknown declared state" \
  04_not_declared_20260812_123458_123_004 "" "$MANIFEST"
run_invalid_evidence_case "a malformed timestamp suffix" \
  04_home_2026bad_123458_123_005 "" "$MANIFEST"
run_invalid_evidence_case "a malformed pid suffix" \
  04_frequency_page_20260812_123459_pid_006 "" "$MANIFEST"
run_invalid_evidence_case "duplicate state mappings" \
  04_frequency_page_20260812_123460_123_007 \
  04_frequency_page_20260812_123461_124_008 "$MANIFEST"
run_invalid_evidence_case "a selected flow with no evidence" \
  04_frequency_page_20260812_123462_123_009 "" "$MANIFEST"
bad_manifest="$TMP_DIR/bad-manifest.json"
printf '%s\n' '{"schema_version":1,"flow_count":1,"flows":[{"number":"04","name":"04_habit_group","path":"flows/04_habit_group.sh","states":[]}]}' >"$bad_manifest"
run_invalid_evidence_case "a malformed empty-state manifest" \
  04_frequency_page_20260812_123463_123_010 "" "$bad_manifest"

printf 'Fixture/evidence hardening checks: %d passed, %d failed.\n' "$passes" "$failures"
[ "$failures" -eq 0 ]
