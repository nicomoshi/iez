#!/usr/bin/env bash
# test_cli.sh — Integration tests for the iez CLI entry point
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IEZ="$SCRIPT_DIR/../bin/iez"
source "$SCRIPT_DIR/test_helpers.sh"

echo "=== Testing iez CLI ==="

# --- Version ---
test_start "iez --version"
output=$($IEZ --version 2>/dev/null)
assert_contains "$output" "iez v" "outputs version"

# --- Help ---
test_start "iez --help"
output=$($IEZ --help 2>/dev/null)
assert_contains "$output" "Unified iOS Simulator" "shows help"
assert_contains "$output" "sim" "lists sim group"
assert_contains "$output" "ui" "lists ui group"

# --- Group help ---
test_start "iez sim --help"
output=$($IEZ sim --help 2>/dev/null)
assert_contains "$output" "Simulator Lifecycle" "shows sim help"

test_start "iez ui --help"
output=$($IEZ ui --help 2>/dev/null)
assert_contains "$output" "UI Automation" "shows ui help"

test_start "iez app --help"
output=$($IEZ app --help 2>/dev/null)
assert_contains "$output" "App Build" "shows app help"

# --- Doctor ---
test_start "iez doctor"
output=$($IEZ doctor 2>/dev/null)
assert_json_field "$output" ".ok" "true" "doctor succeeds"
assert_json_field "$output" ".action" "doctor" "action is doctor"

# Check backends array exists
backend_count=$(echo "$output" | jq '.data.backends | length' 2>/dev/null)
if [[ "$backend_count" -gt 0 ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    printf '  \033[0;32mPASS\033[0m %s found %d backends\n' "$_TEST_NAME" "$backend_count"
else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    printf '  \033[0;31mFAIL\033[0m %s no backends found\n' "$_TEST_NAME"
fi

# --- Config ---
test_start "iez config show"
output=$($IEZ config show 2>/dev/null)
assert_json_field "$output" ".ok" "true" "config show succeeds"

test_start "iez config backends"
output=$($IEZ config backends 2>/dev/null)
assert_json_field "$output" ".ok" "true" "config backends succeeds"

# --- Sim list ---
test_start "iez sim list"
output=$($IEZ sim list 2>/dev/null)
assert_json_field "$output" ".ok" "true" "sim list succeeds"
assert_json_field "$output" ".action" "sim.list" "action is sim.list"

# --- Unknown command ---
test_start "iez unknown"
output=$($IEZ unknown 2>&1) || true
assert_contains "$output" "Unknown" "unknown command shows error"

# --- Unknown subcommand ---
test_start "iez sim unknown"
output=$($IEZ sim unknown 2>/dev/null) || true
assert_json_field "$output" ".ok" "false" "unknown subcommand fails" || true

test_summary
