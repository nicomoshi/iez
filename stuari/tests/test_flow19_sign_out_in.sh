#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FLOW_FILE="$ROOT_DIR/stuari/flows/19_sign_out_in.sh"

fail_test() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass_test() {
  printf 'PASS: %s\n' "$1"
}

line_of() {
  local needle="$1"
  grep -nF -- "$needle" "$FLOW_FILE" | head -1 | cut -d: -f1
}

line_of_after() {
  local needle="$1" previous="$2"
  grep -nF -- "$needle" "$FLOW_FILE" \
    | awk -F: -v previous="$previous" '$1 > previous { print $1; exit }'
}

assert_present() {
  local needle="$1" description="$2"
  [ -n "$(line_of "$needle")" ] || fail_test "$description (missing: $needle)"
}

assert_ordered() {
  local description="$1"
  shift
  local previous=0 needle line
  for needle in "$@"; do
    line="$(line_of_after "$needle" "$previous")"
    [ -n "$line" ] || fail_test "$description (missing: $needle)"
    [ "$line" -gt "$previous" ] || fail_test "$description (out of order at: $needle)"
    previous="$line"
  done
}

assert_present 'terminate_app' \
  "Flow 19 terminates the app after sign-out"
assert_present 'capture "19_after_terminate_relaunch"' \
  "Flow 19 captures the post-terminate/relaunch state"

assert_ordered \
  "Flow 19 orders sign-out, terminate/relaunch, auth checkpoint, and re-login" \
  'sign_out' \
  'capture "19_after_sign_out"' \
  'terminate_app' \
  'fresh_launch' \
  'if on_auth_page && ! on_home_page; then' \
  'capture "19_after_terminate_relaunch"' \
  'login_with_dev_magic' \
  'if on_home_page; then'

pass_test "Flow 19 proves auth remains after terminate/relaunch before re-login"
