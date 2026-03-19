#!/usr/bin/env bash
# test_core.sh — Tests for core.sh functions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../lib/core.sh"

echo "=== Testing lib/core.sh ==="

# --- Version ---
test_start "version"
assert_eq "1.0.0" "$IEZ_VERSION" "version is 1.0.0"

# --- Exit codes ---
test_start "exit_codes"
assert_eq "0" "$EXIT_OK" "EXIT_OK"
assert_eq "1" "$EXIT_FAIL" "EXIT_FAIL"
assert_eq "2" "$EXIT_USAGE" "EXIT_USAGE"
assert_eq "3" "$EXIT_NO_BACKEND" "EXIT_NO_BACKEND"
assert_eq "4" "$EXIT_NO_SIM" "EXIT_NO_SIM"
assert_eq "5" "$EXIT_NO_APP" "EXIT_NO_APP"
assert_eq "10" "$EXIT_CONFIG" "EXIT_CONFIG"

# --- Timer ---
test_start "timer"
iez_timer_start
sleep 0.1
elapsed=$(iez_timer_elapsed)
if [[ "$elapsed" -gt 0 ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    printf '  \033[0;32mPASS\033[0m %s elapsed=%dms\n' "$_TEST_NAME" "$elapsed"
else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    printf '  \033[0;31mFAIL\033[0m %s elapsed=%dms (expected >0)\n' "$_TEST_NAME" "$elapsed"
fi

# --- Response envelope ---
test_start "iez_response"
iez_timer_start
resp=$(iez_response "test.action" '{"key":"value"}' "test_backend")
assert_json_field "$resp" ".ok" "true" "ok is true"
assert_json_field "$resp" ".action" "test.action" "action matches"
assert_json_field "$resp" ".data.key" "value" "data.key matches"
assert_json_field "$resp" ".backend" "test_backend" "backend matches"

# --- Error envelope ---
test_start "iez_error"
iez_timer_start
err=$(iez_error "test.fail" "TEST_CODE" "test message" "backend")
assert_json_field "$err" ".ok" "false" "ok is false"
assert_json_field "$err" ".action" "test.fail" "action matches"
assert_json_field "$err" ".error.code" "TEST_CODE" "error code matches"
assert_json_field "$err" ".error.message" "test message" "error message matches"

# --- Flag parsing ---
test_start "iez_parse_flag"
val=$(iez_parse_flag "--label" --label "Login" --id "btn1")
assert_eq "Login" "$val" "--label parsed"

val=$(iez_parse_flag "--id" --label "Login" --id "btn1")
assert_eq "btn1" "$val" "--id parsed"

val=$(iez_parse_flag "--missing" --label "Login" 2>/dev/null) || val="NOT_FOUND"
assert_eq "NOT_FOUND" "$val" "missing flag returns error"

# --- Has flag ---
test_start "iez_has_flag"
iez_has_flag "--verbose" --verbose --json
assert_eq "0" "$?" "found --verbose"

iez_has_flag "--missing" --verbose --json 2>/dev/null || true

test_summary
