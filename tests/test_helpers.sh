#!/usr/bin/env bash
# test_helpers.sh — Test assertion helpers for iez

_TEST_PASS=0
_TEST_FAIL=0
_TEST_TOTAL=0
_TEST_NAME=""

test_start() {
    _TEST_NAME="$1"
    _TEST_TOTAL=$((_TEST_TOTAL + 1))
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        _TEST_PASS=$((_TEST_PASS + 1))
        printf '  \033[0;32mPASS\033[0m %s %s\n' "$_TEST_NAME" "$msg"
    else
        _TEST_FAIL=$((_TEST_FAIL + 1))
        printf '  \033[0;31mFAIL\033[0m %s %s\n' "$_TEST_NAME" "$msg"
        printf '    expected: %s\n    actual:   %s\n' "$expected" "$actual"
    fi
}

assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="$3"
    local msg="${4:-$field == $expected}"

    local actual
    actual=$(echo "$json" | jq -r "$field" 2>/dev/null)

    assert_eq "$expected" "$actual" "$msg"
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-exit code}"

    assert_eq "$expected" "$actual" "$msg"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-contains '$needle'}"

    if echo "$haystack" | grep -q "$needle"; then
        _TEST_PASS=$((_TEST_PASS + 1))
        printf '  \033[0;32mPASS\033[0m %s %s\n' "$_TEST_NAME" "$msg"
    else
        _TEST_FAIL=$((_TEST_FAIL + 1))
        printf '  \033[0;31mFAIL\033[0m %s %s\n' "$_TEST_NAME" "$msg"
        printf '    expected to contain: %s\n' "$needle"
    fi
}

test_summary() {
    echo ""
    echo "═══════════════════════════════════════"
    printf 'Tests: %d total, \033[0;32m%d passed\033[0m, \033[0;31m%d failed\033[0m\n' \
        "$_TEST_TOTAL" "$_TEST_PASS" "$_TEST_FAIL"
    echo "═══════════════════════════════════════"

    [[ $_TEST_FAIL -eq 0 ]] && return 0 || return 1
}
