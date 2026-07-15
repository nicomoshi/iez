#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_auth_drift_test.XXXXXX")"
FAKE_PLIST="$TMP_DIR/fake.plist"
FAKE_APP_CONTAINER="$TMP_DIR/app_container"
FAKE_DB_PATH="$FAKE_APP_CONTAINER/tmp/stuari_offline.sqlite"
FAKE_CAROUSEL_STATE="$TMP_DIR/carousel.state"
FAKE_CAROUSEL_CARDS="$TMP_DIR/carousel.cards"

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

assert_eq() {
  local expected="$1" actual="$2" description="$3"
  [ "$expected" = "$actual" ] || fail_test "$description (expected '$expected', got '$actual')"
}

assert_file_contains() {
  local needle="$1" file="$2" description="$3"
  grep -Fq -- "$needle" "$file" || fail_test "$description (missing: $needle)"
}

touch "$FAKE_PLIST"
mkdir -p "$FAKE_APP_CONTAINER/tmp"

export SKIP_DEVICE_DETECT=1
export SCREENSHOTS="$TMP_DIR/screenshots"
export AX_TREES="$TMP_DIR/ax"
export STUARI_AUTH_PREFERENCES_PATH="$FAKE_PLIST"
export STUARI_FIXTURE_APP_CONTAINER_DATA_PATH="$FAKE_APP_CONTAINER"
export IEZ="fake-iez"
export DEVICE_ID="test-device"

source "$ROOT_DIR/stuari/lib/common.sh"
source "$ROOT_DIR/stuari/lib/auth.sh"
source "$ROOT_DIR/stuari/lib/fixtures.sh"
eval "$(declare -f login_with_dev_magic | sed '1s/login_with_dev_magic/stuari_real_login_with_dev_magic/')"
eval "$(declare -f reset_simulator_auth_tokens_to_auth_page | sed '1s/reset_simulator_auth_tokens_to_auth_page/stuari_real_reset_simulator_auth_tokens_to_auth_page/')"

_stuari_real_write_decl="$(declare -f stuari_auth_write_preferences_json_atomically)"
eval "$(printf '%s\n' "$_stuari_real_write_decl" | sed '1s/stuari_auth_write_preferences_json_atomically/_stuari_real_write_inner/')"
stuari_auth_write_preferences_json_atomically() {
  _stuari_real_write_inner "$@" && {
    printf 'WRITE\n' >> "$FAKE_XCRUN_LOG"
    return 0
  }
  return 1
}

write_preferences_plist() {
  local mode="${1:-none}"
  case "$mode" in
    alice)
      cat >"$FAKE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>flutter.sb-test-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_ALICE_USER_ID","email":"$STUARI_AUTH_ALICE_EMAIL"}}</string>
</dict>
</plist>
EOF
      ;;
    bob)
      cat >"$FAKE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>flutter.sb-test-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_BOB_USER_ID","email":"$STUARI_AUTH_BOB_EMAIL"}}</string>
</dict>
</plist>
EOF
      ;;
    malformed)
      cat >"$FAKE_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>flutter.sb-test-auth-token</key>
  <string>not-json</string>
</dict>
</plist>
EOF
      ;;
    multiple)
      cat >"$FAKE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>flutter.sb-a-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_ALICE_USER_ID","email":"$STUARI_AUTH_ALICE_EMAIL"}}</string>
  <key>flutter.sb-b-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_BOB_USER_ID","email":"$STUARI_AUTH_BOB_EMAIL"}}</string>
</dict>
</plist>
EOF
      ;;
    none)
      cat >"$FAKE_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
      ;;
    mixed)
      cat >"$FAKE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>flutter.sb-a-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_ALICE_USER_ID","email":"$STUARI_AUTH_ALICE_EMAIL"}}</string>
  <key>app.theme</key>
  <string>sunrise</string>
  <key>flutter.sb-b-auth-token</key>
  <string>{"user":{"id":"$STUARI_AUTH_BOB_USER_ID","email":"$STUARI_AUTH_BOB_EMAIL"}}</string>
  <key>launchCount</key>
  <integer>7</integer>
</dict>
</plist>
EOF
      ;;
    *)
      fail_test "unknown plist mode: $mode"
      ;;
  esac
}

LOGIN_CONTRACT_CALLS="$TMP_DIR/login_contract.calls"
login_contract_output="$(
  (
    FAKE_AUTH_PAGE="auth"

    capture() { :; }
    has_label() {
      case "$1" in
        "$LABEL_DEV_EMAIL"|"$LABEL_DEV_PASSWORD"|"$LABEL_DEV_SIGN_IN")
          return 0
          ;;
        "Allow"|"Don't Allow")
          return 1
          ;;
        *)
          return 1
          ;;
      esac
    }
    tree_contains() { return 1; }
    on_home_page() { [ "${FAKE_AUTH_PAGE:-auth}" = "home" ]; }
    on_onboarding_page() { [ "${FAKE_AUTH_PAGE:-auth}" = "onboarding" ]; }
    run_iez() {
      if [ "${1:-}" = "$IEZ" ]; then
        shift
      fi

      if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tree" ] && [ "${3:-}" = "--compact" ]; then
        printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXTextField","label":"Dev email","frame":{"x":20,"y":100,"width":300,"height":50}},{"role":"AXTextField","label":"Dev password","frame":{"x":20,"y":200,"width":300,"height":50}}]}}'
        return 0
      fi

      if [ "${1:-}" = "ui" ] && [ "${2:-}" = "tap" ] && [ "${3:-}" = "--coords" ]; then
        case "${4:-}" in
          "308,125")
            printf 'FOCUS_EMAIL_RIGHT\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
          "308,225")
            printf 'FOCUS_PASSWORD_RIGHT\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
          *)
            printf 'FOCUS_OTHER\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
        esac
      elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "tap" ] && [ "${3:-}" = "--label" ]; then
        case "${4:-}" in
          "$LABEL_DEV_SIGN_IN")
            printf 'SUBMIT\n' >> "$LOGIN_CONTRACT_CALLS"
            FAKE_AUTH_PAGE="home"
            ;;
        esac
      elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "type" ]; then
        case "${3:-}" in
          "$STUARI_AUTH_ALICE_EMAIL")
            printf 'TYPE_EMAIL\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
          "${STUARI_TEST_PASSWORD:-iez-test-password-2026}")
            printf 'TYPE_PASSWORD\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
          *)
            printf 'TYPE_OTHER\n' >> "$LOGIN_CONTRACT_CALLS"
            ;;
        esac
      elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "key" ] && [ "${3:-}" = "42" ]; then
        printf 'CLEAR_KEY\n' >> "$LOGIN_CONTRACT_CALLS"
      elif [ "${1:-}" = "ui" ] && [ "${2:-}" = "swipe" ] && [ "${3:-}" = "down" ]; then
        printf 'DISMISS_KEYBOARD\n' >> "$LOGIN_CONTRACT_CALLS"
      fi

      printf '{"ok":true,"data":{}}\n'
      return 0
    }

    stuari_real_login_with_dev_magic "$STUARI_AUTH_ALICE_EMAIL" "${STUARI_TEST_PASSWORD:-iez-test-password-2026}"
  ) 2>&1
)"

[ "$(grep -c '^TYPE_EMAIL$' "$LOGIN_CONTRACT_CALLS")" = "1" ] || \
  fail_test "Explicit Alice dev login types the email field exactly once"
[ "$(grep -c '^TYPE_PASSWORD$' "$LOGIN_CONTRACT_CALLS")" = "1" ] || \
  fail_test "Explicit Alice dev login types the password field exactly once"
[ "$(grep -c '^FOCUS_EMAIL_RIGHT$' "$LOGIN_CONTRACT_CALLS")" = "1" ] || \
  fail_test "Given a unique Dev email frame When overwriting explicitly Then it taps the right inset once"
[ "$(grep -c '^FOCUS_PASSWORD_RIGHT$' "$LOGIN_CONTRACT_CALLS")" = "1" ] || \
  fail_test "Given a unique Dev password frame When overwriting explicitly Then it taps the right inset once"
[ "$(grep -c '^FOCUS_OTHER$' "$LOGIN_CONTRACT_CALLS" || true)" = "0" ] || \
  fail_test "Explicit Alice dev login must not tap an unresolved coordinate"
printf '%s' "$login_contract_output" | grep -Fq "$STUARI_AUTH_ALICE_EMAIL" && \
  fail_test "Explicit Alice dev login must not print the email credential"
printf '%s' "$login_contract_output" | grep -Fq "${STUARI_TEST_PASSWORD:-iez-test-password-2026}" && \
  fail_test "Explicit Alice dev login must not print the password credential"
pass_test "Given unique Dev field frames When explicitly logging in Then it taps right insets and prints no credentials"

if (
  run_iez() {
    printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXTextField","label":"Dev email","frame":{"x":20,"y":100,"width":300,"height":50}},{"role":"AXTextField","label":"Dev email","frame":{"x":20,"y":100,"width":300,"height":50}}]}}'
  }
  stuari_auth_text_field_right_inset_coords "$LABEL_DEV_EMAIL" >/dev/null
); then
  fail_test "Given duplicate exact Dev fields When resolving overwrite coordinates Then it fails closed"
fi
if (
  run_iez() {
    printf '%s\n' '{"ok":true,"data":{"elements":[{"role":"AXTextField","label":"Dev email","frame":{"x":20,"y":100,"width":0,"height":50}}]}}'
  }
  stuari_auth_text_field_right_inset_coords "$LABEL_DEV_EMAIL" >/dev/null
); then
  fail_test "Given a zero-width Dev field When resolving overwrite coordinates Then it fails closed"
fi
pass_test "Given duplicate or zero Dev field frames When resolving overwrite coordinates Then it fails closed"

FAKE_PAGE="auth"
FAKE_SIGN_OUT_CALLS=0
FAKE_LOGIN_CALLS=0
FAKE_RESET_CALLS=0
FAKE_CFPREFSD_RESTORE=0
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
FAKE_XCRUN_LOG="$TMP_DIR/xcrun.log"
fresh_launch() { :; }
capture() { :; }
on_home_page() { [ "${FAKE_PAGE:-auth}" = "home" ]; }
on_auth_page() { [ "${FAKE_PAGE:-auth}" = "auth" ]; }
on_onboarding_page() { [ "${FAKE_PAGE:-auth}" = "onboarding" ]; }
sign_out() {
  FAKE_SIGN_OUT_CALLS=$((FAKE_SIGN_OUT_CALLS + 1))
  FAKE_PAGE="auth"
  write_preferences_plist none
  return 0
}
reset_auth_state() {
  FAKE_PAGE="auth"
  write_preferences_plist none
  return 0
}
reset_simulator_auth_tokens_to_auth_page() {
  FAKE_RESET_CALLS=$((FAKE_RESET_CALLS + 1))
  FAKE_PAGE="auth"
  write_preferences_plist none
  return 0
}
login_with_dev_magic() {
  FAKE_LOGIN_CALLS=$((FAKE_LOGIN_CALLS + 1))
  write_preferences_plist alice
  FAKE_PAGE="onboarding"
  return 0
}
complete_onboarding() {
  FAKE_PAGE="home"
  return 0
}
xcrun() {
  if [ "${1:-}" = "simctl" ] && [ "${2:-}" = "launch" ]; then
    printf 'LAUNCH %s %s\n' "${3:-}" "${4:-}" >> "$FAKE_XCRUN_LOG"
    FAKE_LAUNCH_CALLS=$((FAKE_LAUNCH_CALLS + 1))
    FAKE_PAGE="auth"
    return 0
  fi
  if [ "${1:-}" = "simctl" ] && [ "${2:-}" = "terminate" ]; then
    printf 'TERMINATE %s %s\n' "${3:-}" "${4:-}" >> "$FAKE_XCRUN_LOG"
    return 0
  fi
  if [ "${1:-}" = "simctl" ] && [ "${2:-}" = "spawn" ]; then
    printf 'INVALIDATE %s %s %s\n' "${3:-}" "${4:-}" "${5:-}" >> "$FAKE_XCRUN_LOG"
    FAKE_INVALIDATION_CALLS=$((FAKE_INVALIDATION_CALLS + 1))
    if [ "$FAKE_CFPREFSD_FAILURE" = "1" ]; then
      return 1
    fi
    if [ "$FAKE_CFPREFSD_RESTORE" = "1" ]; then
      # Model cfprefsd flushing its cached pre-reset dictionary after the
      # daemon is invalidated. The real reset must detect this before launch.
      write_preferences_plist mixed
    fi
    return 0
  fi
  return 1
}

write_preferences_plist bob
if persisted_session_is_verified_alice; then
  fail_test "Given Bob persisted When verifying Alice principal Then it rejects"
fi
pass_test "Given Bob persisted When verifying Alice principal Then it rejects"

write_preferences_plist alice
persisted_session_is_verified_alice || fail_test "Given exact Alice persisted When verifying principal Then it succeeds"
principal_json="$(read_persisted_session_principal_json)" || fail_test "Given dotted plist key When reading persisted principal Then it parses the exact session payload"
assert_eq \
  "{\"id\":\"$STUARI_AUTH_ALICE_USER_ID\",\"email\":\"$STUARI_AUTH_ALICE_EMAIL\"}" \
  "$principal_json" \
  "Dotted Supabase plist key parses via full-plist JSON indexing"
pass_test "Given exact Alice persisted When verifying principal Then it succeeds"

write_preferences_plist malformed
if read_persisted_session_principal_json >/dev/null 2>&1; then
  fail_test "Given malformed persisted session When reading principal Then it rejects"
fi
pass_test "Given malformed persisted session When reading principal Then it rejects"

write_preferences_plist multiple
if read_persisted_session_principal_json >/dev/null 2>&1; then
  fail_test "Given multiple auth-token keys When reading principal Then it rejects"
fi
pass_test "Given multiple auth-token keys When reading principal Then it rejects"

run_forced_alice_reset_case() {
  local plist_mode="$1" page="$2" description="$3"

  write_preferences_plist "$plist_mode"
  FAKE_PAGE="$page"
  FAKE_SIGN_OUT_CALLS=0
  FAKE_LOGIN_CALLS=0
  FAKE_RESET_CALLS=0

  ensure_verified_alice_session || fail_test "$description"
  assert_eq "0" "$FAKE_SIGN_OUT_CALLS" "$description keeps UI sign-out unused"
  assert_eq "1" "$FAKE_RESET_CALLS" "$description resets persisted auth tokens exactly once"
  assert_eq "1" "$FAKE_LOGIN_CALLS" "$description types Alice credentials exactly once"
  assert_eq "home" "$FAKE_PAGE" "$description resolves onboarding to home"
  persisted_session_is_verified_alice || fail_test "$description persists verified Alice"
  pass_test "$description"
}

run_forced_alice_reset_case \
  bob \
  onboarding \
  "Given Bob persisted outside Home When forcing Alice Then it resets tokens, signs in, and verifies Alice"
run_forced_alice_reset_case \
  malformed \
  splash \
  "Given malformed persisted auth token When forcing Alice Then it resets tokens, signs in, and verifies Alice"
run_forced_alice_reset_case \
  multiple \
  splash \
  "Given multiple persisted auth-token keys When forcing Alice Then it resets tokens, signs in, and verifies Alice"

write_preferences_plist mixed
FAKE_PAGE="splash"
FAKE_CFPREFSD_RESTORE=0
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
: >"$FAKE_XCRUN_LOG"
stuari_real_reset_simulator_auth_tokens_to_auth_page || \
  fail_test "Given mixed plist keys When resetting simulator auth tokens Then it deletes only matching auth-token keys"
prefs_json="$(stuari_auth_preferences_json "$FAKE_PLIST")" || \
  fail_test "Given mixed plist keys When resetting simulator auth tokens Then the plist remains readable"
printf '%s\n' "$prefs_json" | jq -e '
  ."app.theme" == "sunrise"
  and .launchCount == 7
  and ([keys[]? | select(test("^flutter\\.sb-.*-auth-token$"))] | length) == 0
' >/dev/null 2>&1 || \
  fail_test "Given mixed plist keys When resetting simulator auth tokens Then unrelated keys survive and auth-token keys are removed"
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID
WRITE
INVALIDATE $DEVICE_ID /usr/bin/killall cfprefsd
LAUNCH $DEVICE_ID $BUNDLE_ID" "$(cat "$FAKE_XCRUN_LOG")" \
  "Reset helper terminates, writes atomically, invalidates cfprefsd once, and relaunches the Stuari app"
assert_eq "1" "$FAKE_INVALIDATION_CALLS" \
  "Reset helper invalidates cfprefsd exactly once"
assert_eq "1" "$FAKE_LAUNCH_CALLS" \
  "Successful reset launches Stuari exactly once after persistence verification"
pass_test "Given mixed plist keys When resetting simulator auth tokens Then unrelated keys survive and only auth-token keys are deleted"

write_preferences_plist mixed
FAKE_PAGE="splash"
FAKE_CFPREFSD_RESTORE=0
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
: >"$FAKE_XCRUN_LOG"
if (
  mv() { return 1; }
  stuari_real_reset_simulator_auth_tokens_to_auth_page
); then
  fail_test "Given plist mutation failure When resetting simulator auth tokens Then it fails closed"
fi
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID" "$(cat "$FAKE_XCRUN_LOG")" \
  "Mutation failure stops after terminating the Stuari app"
assert_eq "0" "$FAKE_INVALIDATION_CALLS" \
  "Mutation failure does not invalidate cfprefsd"
assert_eq "0" "$FAKE_LAUNCH_CALLS" \
  "Mutation failure does not launch Stuari"
assert_eq "2" "$(stuari_auth_matching_token_keys "$FAKE_PLIST" | sed '/^$/d' | wc -l | tr -d ' ')" \
  "Mutation failure leaves matching auth-token keys intact"
pass_test "Given plist mutation failure When resetting simulator auth tokens Then it fails closed"

FAKE_CFPREFSD_RESTORE=1
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
write_preferences_plist mixed
FAKE_PAGE="splash"
: >"$FAKE_XCRUN_LOG"
if stuari_real_reset_simulator_auth_tokens_to_auth_page; then
  fail_test "Given persistent auth-token override When resetting Then it fails closed before launch"
fi
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID
WRITE
INVALIDATE $DEVICE_ID /usr/bin/killall cfprefsd" "$(cat "$FAKE_XCRUN_LOG")" \
  "Fail-closed reset terminates, writes atomically, spawns cfprefsd, and does not launch"
assert_eq "1" "$FAKE_INVALIDATION_CALLS" \
  "Persistent auth-token override still invalidates cfprefsd exactly once"
assert_eq "0" "$FAKE_LAUNCH_CALLS" \
  "Persistent auth-token override does not launch Stuari"
prefs_json="$(stuari_auth_preferences_json "$FAKE_PLIST")" || \
  fail_test "Given persistent auth-token override When resetting Then the plist remains readable"
printf '%s\n' "$prefs_json" | jq -e '
  .["app.theme"] == "sunrise"
  and .launchCount == 7
  and ([keys[]? | select(test("^flutter\\.sb-.*-auth-token$"))] | length) == 2
' >/dev/null 2>&1 || \
  fail_test "Given persistent auth-token override When resetting Then restored auth keys and unrelated prefs remain observable"
pass_test "Given persistent auth-token override When resetting Then it fails closed without launch"
FAKE_CFPREFSD_RESTORE=0

write_preferences_plist none
FAKE_PAGE="splash"
FAKE_CFPREFSD_RESTORE=0
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
: >"$FAKE_XCRUN_LOG"
stuari_real_reset_simulator_auth_tokens_to_auth_page || \
  fail_test "Given no persisted auth keys When resetting Then it still invalidates cfprefsd and reaches auth"
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID
INVALIDATE $DEVICE_ID /usr/bin/killall cfprefsd
LAUNCH $DEVICE_ID $BUNDLE_ID" "$(cat "$FAKE_XCRUN_LOG")" \
  "No-key reset still invalidates cfprefsd before launch"
assert_eq "1" "$FAKE_INVALIDATION_CALLS" \
  "No-key reset invalidates cfprefsd exactly once"
pass_test "Given no persisted auth keys When resetting Then it invalidates cfprefsd once before launch"

write_preferences_plist none
FAKE_PAGE="splash"
FAKE_CFPREFSD_RESTORE=1
FAKE_CFPREFSD_FAILURE=0
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
: >"$FAKE_XCRUN_LOG"
if stuari_real_reset_simulator_auth_tokens_to_auth_page; then
  fail_test "Given no on-disk auth keys but stale cfprefsd cache When resetting Then it fails closed"
fi
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID
INVALIDATE $DEVICE_ID /usr/bin/killall cfprefsd" "$(cat "$FAKE_XCRUN_LOG")" \
  "Stale cfprefsd cache is checked before launch even without on-disk auth keys"
assert_eq "1" "$FAKE_INVALIDATION_CALLS" \
  "Stale cfprefsd cache is invalidated exactly once"
assert_eq "0" "$FAKE_LAUNCH_CALLS" \
  "Stale cfprefsd cache prevents launch"
pass_test "Given no on-disk auth keys but stale cfprefsd cache When resetting Then it fails closed without launch"

write_preferences_plist mixed
FAKE_PAGE="splash"
FAKE_CFPREFSD_RESTORE=0
FAKE_CFPREFSD_FAILURE=1
FAKE_INVALIDATION_CALLS=0
FAKE_LAUNCH_CALLS=0
: >"$FAKE_XCRUN_LOG"
if stuari_real_reset_simulator_auth_tokens_to_auth_page; then
  fail_test "Given cfprefsd invalidation failure When resetting Then it fails closed"
fi
assert_eq "TERMINATE $DEVICE_ID $BUNDLE_ID
WRITE
INVALIDATE $DEVICE_ID /usr/bin/killall cfprefsd" "$(cat "$FAKE_XCRUN_LOG")" \
  "cfprefsd invalidation failure stops before launch"
assert_eq "1" "$FAKE_INVALIDATION_CALLS" \
  "cfprefsd invalidation failure still attempts exactly one invalidation"
assert_eq "0" "$FAKE_LAUNCH_CALLS" \
  "cfprefsd invalidation failure does not launch Stuari"
pass_test "Given cfprefsd invalidation failure When resetting Then it fails closed without launch"
FAKE_CFPREFSD_FAILURE=0

sqlite3 "$FAKE_DB_PATH" <<SQL
create table groups (id text primary key, created_by text, name text, deleted_at integer);
create table occurrence_snapshots (
  occurrence_id text,
  habit_id text,
  group_id text,
  user_id text,
  status text,
  post_id text,
  opens_at integer,
  submission_closes_at integer
);
SQL

now_ms="$(date +%s000)"
open_ms="$((now_ms - 1000))"
close_ms="$((now_ms + 60000))"

sqlite3 "$FAKE_DB_PATH" <<SQL
insert into groups (id, created_by, name, deleted_at)
values ('$DUE_NOW_HABIT_GROUP_ID', '$STUARI_AUTH_ALICE_USER_ID', '$DUE_NOW_HABIT_NAME', null);
insert into occurrence_snapshots (
  occurrence_id, habit_id, group_id, user_id, status, post_id, opens_at, submission_closes_at
) values (
  'occ-1', '$DUE_NOW_HABIT_GROUP_ID', '$DUE_NOW_HABIT_GROUP_ID', '$STUARI_AUTH_ALICE_USER_ID', 'open', null, $open_ms, $close_ms
);
SQL

wait_for_due_now_occurrence_drift_authority 1 0 || \
  fail_test "Given exact Alice Drift authority When waiting for due-now occurrence Then it succeeds"
pass_test "Given exact Alice Drift authority When waiting for due-now occurrence Then it succeeds"

sqlite3 "$FAKE_DB_PATH" <<SQL
update occurrence_snapshots
   set habit_id = 'bbbb0000-0000-0000-0000-000000000099'
 where group_id = '$DUE_NOW_HABIT_GROUP_ID';
SQL

if wait_for_due_now_occurrence_drift_authority 2 0; then
  fail_test "Given mismatched Drift habit_id When waiting for due-now occurrence Then it times out and rejects"
fi
pass_test "Given mismatched Drift habit_id When waiting for due-now occurrence Then it times out and rejects"

flow04_file="$ROOT_DIR/stuari/flows/04_habit_group.sh"
flow04_created_checks=$(sed -n '/if \[ "$CREATE_SUBMITTED" = "1" \]; then/,/^# Invite flow:/p' "$flow04_file")
assert_file_contains 'HABIT_NAME="${STUARI_FLOW04_HABIT_NAME:-$(test_habit_name)}"' "$flow04_file" \
  "Flow 04 generates a unique habit name unless an enclosing flow supplies one"
assert_file_contains 'type_into "e.g. Morning Run" "$HABIT_NAME"' "$flow04_file" \
  "Flow 04 types the generated habit name into the create form"
assert_eq "4" "$(printf '%s\n' "$flow04_created_checks" | grep -Fc 'wait_for_visible_habit_card_name "$HABIT_NAME"')" \
  "Flow 04 uses centered-card matching at all four created-habit checkpoints"
assert_eq "4" "$(printf '%s\n' "$flow04_created_checks" | grep -Fc 'current_visible_habit_card_label')" \
  "Flow 04 re-reads the centered card label at every created-habit checkpoint"
printf '%s\n' "$flow04_created_checks" | grep -Fq 'wait_for_habit_name "$HABIT_NAME"' && \
  fail_test "Flow 04 create checks must not use broad AX-tree habit-name matching"
grep -Fq 'capture "04_home_with_habit"' "$flow04_file" && \
  fail_test "Flow 04 must not label a pre-wait screenshot as created-habit evidence"

checkpoint_names=(
  04_created_habit_centered_immediate
  04_created_habit_centered_after_10s_no_interaction
  04_created_habit_centered_after_selected_home_retap
  04_created_habit_centered_after_relaunch
)
for checkpoint in "${checkpoint_names[@]}"; do
  assert_file_contains "capture \"$checkpoint\"" "$flow04_file" \
    "Flow 04 captures screenshot + compact AX evidence for $checkpoint"
  assert_file_contains "capture \"${checkpoint}_failure\"" "$flow04_file" \
    "Flow 04 captures failure evidence for $checkpoint"
  assert_file_contains "if capture \"$checkpoint\"" "$flow04_file" \
    "Flow 04 gates the passing assertion on complete evidence for $checkpoint"
done

first_centered_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'wait_for_visible_habit_card_name "$HABIT_NAME"' | sed -n '1s/:.*//p')
stability_sleep_line=$(printf '%s\n' "$flow04_created_checks" | grep -nE '^[[:space:]]*sleep 10[[:space:]]*$' | sed -n '1s/:.*//p')
second_centered_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'wait_for_visible_habit_card_name "$HABIT_NAME"' | sed -n '2s/:.*//p')
selected_home_retap_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'tap_element "$selected_home_label" "label" "Re-tap already-selected Home nav item"' | sed -n '1s/:.*//p')
third_centered_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'wait_for_visible_habit_card_name "$HABIT_NAME"' | sed -n '3s/:.*//p')
terminate_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'terminate_app' | sed -n '1s/:.*//p')
relaunch_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'fresh_launch' | sed -n '1s/:.*//p')
fourth_centered_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'wait_for_visible_habit_card_name "$HABIT_NAME"' | sed -n '4s/:.*//p')
natural_home_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'if wait_for_natural_home 10' | sed -n '1s/:.*//p')
[ -n "$first_centered_line" ] && [ -n "$stability_sleep_line" ] && [ -n "$second_centered_line" ] && \
  [ -n "$selected_home_retap_line" ] && [ -n "$third_centered_line" ] && \
  [ -n "$terminate_line" ] && [ -n "$relaunch_line" ] && [ -n "$fourth_centered_line" ] || \
  fail_test "Flow 04 static checkpoint markers must all be present"
[ -n "$natural_home_line" ] && [ "$natural_home_line" -lt "$first_centered_line" ] || \
  fail_test "Flow 04 must prove natural Home return before the immediate centered-card check"

relaunch_restore_segment=$(printf '%s\n' "$flow04_created_checks" | sed -n "${relaunch_line},${fourth_centered_line}p")
printf '%s\n' "$relaunch_restore_segment" | grep -Eq 'go_home|nav_to_tab|tap_element.*Home|pull_to_refresh_home|ui (tap|swipe|type|key)|type_into' && \
  fail_test "Flow 04 must not mutate Home navigation between relaunch/auth/onboarding restoration and the fourth centered-card assertion"

[ -n "$stability_sleep_line" ] && [ "$first_centered_line" -lt "$stability_sleep_line" ] && \
  [ "$stability_sleep_line" -lt "$second_centered_line" ] && \
  [ "$second_centered_line" -lt "$selected_home_retap_line" ] && \
  [ "$selected_home_retap_line" -lt "$third_centered_line" ] && \
  [ "$third_centered_line" -lt "$terminate_line" ] && \
  [ "$terminate_line" -lt "$relaunch_line" ] && \
  [ "$relaunch_line" -lt "$fourth_centered_line" ] || \
  fail_test "Flow 04 checkpoints must be ordered: immediate, 10s idle, selected Home re-tap, terminate/relaunch"
immediate_capture_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'capture "04_created_habit_centered_immediate"' | sed -n '1s/:.*//p')
stability_capture_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'capture "04_created_habit_centered_after_10s_no_interaction"' | sed -n '1s/:.*//p')
retap_capture_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'capture "04_created_habit_centered_after_selected_home_retap"' | sed -n '1s/:.*//p')
relaunch_capture_line=$(printf '%s\n' "$flow04_created_checks" | grep -nF 'capture "04_created_habit_centered_after_relaunch"' | sed -n '1s/:.*//p')
[ "$first_centered_line" -lt "$immediate_capture_line" ] && \
  [ "$second_centered_line" -lt "$stability_capture_line" ] && \
  [ "$third_centered_line" -lt "$retap_capture_line" ] && \
  [ "$fourth_centered_line" -lt "$relaunch_capture_line" ] || \
  fail_test "Flow 04 must capture evidence after each centered-card assertion"

pre_natural_home=$(printf '%s\n' "$flow04_created_checks" | sed -n "1,${natural_home_line}p")
printf '%s\n' "$pre_natural_home" | grep -Eq 'go_home|nav_to_tab|tap_element.*Home' && \
  fail_test "Flow 04 must not navigate Home before proving Create Habit returned there naturally"

idle_segment=$(printf '%s\n' "$flow04_created_checks" | sed -n "${stability_sleep_line},$((second_centered_line - 1))p")
printf '%s\n' "$idle_segment" | grep -Eq 'tap_element|ui (tap|swipe|type|key)|fresh_launch|terminate_app|go_home|pull_to_refresh_home|type_into' && \
  fail_test "Flow 04 must not interact with the app during the 10-second no-interaction interval"

assert_file_contains 'selected_home_label="$(selected_home_nav_label)"' "$flow04_file" \
  "Flow 04 resolves the already-selected Home nav item from compact AX"
assert_file_contains 'tap_element "$selected_home_label" "label" "Re-tap already-selected Home nav item"' "$flow04_file" \
  "Flow 04 re-taps the already-selected Home nav item"
assert_file_contains 'capture "04_home_before_created_habit_center_check"' "$flow04_file" \
  "Flow 04 preserves the pre-centered Home evidence capture"
assert_file_contains 'capture "04_home_after_relaunch"' "$flow04_file" \
  "Flow 04 preserves the post-relaunch Home evidence capture"

for prior_check in \
  'capture "04_home_before_create"' \
  'capture "04_name_page"' \
  'capture "04_image_page"' \
  'capture "04_review_page"' \
  'tap_element "Create Habit" "label" "Review → Create Habit (submit)"' \
  'capture "04_post_create"' \
  'has_label "Members"' \
  'tap_element "Invite" "label" "Tap Invite"' \
  'tap_visible_habit_menu "Open habit settings"' \
  'has_label "View Details"' \
  'dismiss_all' \
  'print_summary'
do
  assert_file_contains "$prior_check" "$flow04_file" "Flow 04 preserves prior check: $prior_check"
done
pass_test "Given adjacent mounted habit cards When flow 04 verifies creation Then all four centered-card release checkpoints are ordered and gated"

write_fake_carousel_cards() {
  : > "$FAKE_CAROUSEL_CARDS"
  while [ "$#" -gt 0 ]; do
    printf '%s\n' "$1" >> "$FAKE_CAROUSEL_CARDS"
    shift
  done
}

reset_fake_carousel_state() {
  local mode="$1" index="$2"
  cat >"$FAKE_CAROUSEL_STATE" <<EOF
mode=$mode
index=$index
swipes=0
EOF
}

fake_carousel_get_state() {
  local key="$1"
  awk -F'=' -v key="$key" '$1 == key { print $2 }' "$FAKE_CAROUSEL_STATE"
}

fake_carousel_set_state() {
  local key="$1" value="$2"
  awk -F'=' -v key="$key" -v value="$value" '
    $1 == key { print key "=" value; next }
    { print }
  ' "$FAKE_CAROUSEL_STATE" > "$FAKE_CAROUSEL_STATE.tmp"
  mv "$FAKE_CAROUSEL_STATE.tmp" "$FAKE_CAROUSEL_STATE"
}

fake_carousel_card_count() {
  awk 'END { print NR }' "$FAKE_CAROUSEL_CARDS"
}

fake_carousel_card_id_at_index() {
  local index="$1"
  sed -n "$((index + 1))p" "$FAKE_CAROUSEL_CARDS"
}

render_fake_card_tree() {
  local card_id
  card_id="$(fake_carousel_card_id_at_index "$(fake_carousel_get_state index)")"
  cat <<JSON
{"ok":true,"data":{"elements":[{"id":"$card_id","label":"Habit card: $card_id habit, Tap to check in","frame":{"x":150,"y":250,"width":92,"height":120},"enabled":true}]}}
JSON
}

run_iez() {
  local _binary="$1"
  shift

  if [ "$1" = "ui" ] && [ "$2" = "tree" ]; then
    render_fake_card_tree
    return 0
  fi

  if [ "$1" = "ui" ] && [ "$2" = "swipe" ]; then
    local from="" to="" from_x="" to_x="" mode index swipes max_index
    shift 2
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --from)
          from="$2"
          shift 2
          ;;
        --to)
          to="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    mode="$(fake_carousel_get_state mode)"
    index="$(fake_carousel_get_state index)"
    swipes="$(fake_carousel_get_state swipes)"
    swipes=$((swipes + 1))
    fake_carousel_set_state swipes "$swipes"
    from_x="${from%%,*}"
    to_x="${to%%,*}"
    max_index=$(( $(fake_carousel_card_count) - 1 ))

    case "$mode" in
      linear)
        if [ "$from_x" -gt "$to_x" ]; then
          [ "$index" -lt "$max_index" ] && index=$((index + 1))
        else
          [ "$index" -gt 0 ] && index=$((index - 1))
        fi
        ;;
      cycle)
        if [ "$index" = "0" ]; then
          index=1
        else
          index=0
        fi
        ;;
      stall)
        :
        ;;
    esac
    fake_carousel_set_state index "$index"

    printf '{"ok":true,"data":{}}\n'
    return 0
  fi

  return 1
}

export STUARI_HABIT_CARD_SETTLE_INTERVAL=0

habit_card_label_is_actionable "Habit card: Alpha habit, Tap to check in, selected" || \
  fail_test "Actionable habit labels allow harmless AX suffix text"
if habit_card_label_is_actionable "Habit card: Alpha habit, Completed"; then
  fail_test "Ineligible habit labels are rejected"
fi
pass_test "Actionable habit label matching stays strict but suffix-tolerant"

write_fake_carousel_cards "habit_card_alpha" "habit_card_bravo" "habit_card_charlie"
reset_fake_carousel_state linear 0
select_habit_card_by_id "habit_card_bravo" 4 0 || \
  fail_test "Given target in initial direction When selecting exact habit card Then it succeeds"
assert_eq "habit_card_bravo" "$(current_visible_habit_card_id)" "Initial-direction search lands on the exact centered card"
assert_eq "1" "$(fake_carousel_get_state swipes)" "Initial-direction search respects the exact bounded swipe count"
pass_test "Given target in initial direction When selecting exact habit card Then it succeeds"

long_carousel_cards=()
for i in $(seq 1 61); do
  long_carousel_cards+=("habit_card_$i")
done
write_fake_carousel_cards "${long_carousel_cards[@]}"
reset_fake_carousel_state linear 0
select_habit_card_by_id "habit_card_61" || \
  fail_test "Given a 61-card polluted carousel When selecting an exact distant habit card Then the default bound still succeeds"
assert_eq "habit_card_61" "$(current_visible_habit_card_id)" "Default carousel search lands on the exact distant card"
assert_eq "60" "$(fake_carousel_get_state swipes)" "Default carousel search covers distant cards within the expanded bound"
pass_test "Given a 61-card polluted carousel When selecting an exact distant habit card Then the default bound still succeeds"

write_fake_carousel_cards "habit_card_alpha" "habit_card_bravo" "habit_card_charlie"
reset_fake_carousel_state linear 2
select_habit_card_by_id "habit_card_alpha" 4 0 || \
  fail_test "Given target in reverse direction When selecting exact habit card Then it succeeds after reversing"
assert_eq "habit_card_alpha" "$(current_visible_habit_card_id)" "Reverse-direction search lands on the exact centered card"
assert_eq "3" "$(fake_carousel_get_state swipes)" "Reverse-direction search stops within the exact two-direction bound"
pass_test "Given target in reverse direction When selecting exact habit card Then it succeeds after reversing"

write_fake_carousel_cards "habit_card_alpha" "habit_card_bravo"
reset_fake_carousel_state stall 0
if select_habit_card_by_id "habit_card_missing" 6 0; then
  fail_test "Given stalled carousel When selecting missing habit card Then it stops within the bounded swipe count"
fi
assert_eq "2" "$(fake_carousel_get_state swipes)" "Stalled carousel search stops after one swipe per direction"
pass_test "Given stalled carousel When selecting missing habit card Then it stops within the bounded swipe count"

write_fake_carousel_cards "habit_card_alpha" "habit_card_bravo"
reset_fake_carousel_state cycle 0
if select_habit_card_by_id "habit_card_missing" 6 0; then
  fail_test "Given cyclic carousel When selecting missing habit card Then it stops within the bounded swipe count"
fi
assert_eq "4" "$(fake_carousel_get_state swipes)" "Cyclic carousel search stops on repeat detection in both directions"
pass_test "Given cyclic carousel When selecting missing habit card Then it stops within the bounded swipe count"

write_fake_carousel_cards "habit_card_alpha" "habit_card_bravo" "habit_card_charlie"
reset_fake_carousel_state linear 0
if select_habit_card_by_id "habit_card_missing" 1 0; then
  fail_test "Given a strict max-step bound When selecting a missing habit card Then it rejects"
fi
assert_eq "2" "$(fake_carousel_get_state swipes)" "Strict max-step bound applies independently per direction"
pass_test "Given a strict max-step bound When selecting a missing habit card Then it rejects within bounds"

printf 'All auth, Drift, and card-selection checks passed.\n'
