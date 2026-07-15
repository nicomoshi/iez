#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stuari_signal_cleanup.XXXXXX")"
PHOTO_FLOW="$ROOT_DIR/stuari/flows/05_checkin_photo.sh"
VIDEO_FLOW="$ROOT_DIR/stuari/flows/06_checkin_video.sh"

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
  grep -Fq "$needle" "$file" || fail_test "$description"
}

extract_function() {
  local function_name="$1" file="$2"
  awk -v fn="$function_name" '
    $0 ~ "^" fn "\\(\\) \\{$" { in_fn=1 }
    in_fn { print }
    in_fn && $0 == "}" { exit }
  ' "$file"
}

run_signal_handler_test() {
  local flow_file="$1" handler_name="$2" cleanup_name="$3" status="$4" description="$5"
  local log_file="$TMP_DIR/${handler_name}_${status}.log"
  local actual_status

  (
    eval "$cleanup_name() { printf 'cleanup=1\n' >> '$log_file'; }"
    print_summary() { printf 'summary=1\n' >> "$log_file"; }
    eval "$(extract_function "$handler_name" "$flow_file")"
    trap 'printf "exit-trap\n" >> "'"$log_file"'"' EXIT
    "$handler_name" "$status"
  )
  actual_status="$?"

  assert_eq "$status" "$actual_status" "$description exits with the signal-style status"
  assert_eq "cleanup=1" "$(cat "$log_file")" "$description runs cleanup exactly once and suppresses EXIT continuation"
  pass_test "$description"
}

assert_file_contains "trap cleanup_photo_due_now_fixture EXIT" "$PHOTO_FLOW" \
  "Photo flow keeps the normal EXIT cleanup trap"
assert_file_contains "trap 'exit_photo_flow_for_signal 130' INT" "$PHOTO_FLOW" \
  "Photo flow wires INT to the signal exit handler"
assert_file_contains "trap 'exit_photo_flow_for_signal 143' TERM" "$PHOTO_FLOW" \
  "Photo flow wires TERM to the signal exit handler"
assert_file_contains "trap cleanup_video_due_now_fixture EXIT" "$VIDEO_FLOW" \
  "Video flow keeps the normal EXIT cleanup trap"
assert_file_contains "trap 'exit_video_flow_for_signal 130' INT" "$VIDEO_FLOW" \
  "Video flow wires INT to the signal exit handler"
assert_file_contains "trap 'exit_video_flow_for_signal 143' TERM" "$VIDEO_FLOW" \
  "Video flow wires TERM to the signal exit handler"

run_signal_handler_test \
  "$PHOTO_FLOW" \
  "exit_photo_flow_for_signal" \
  "cleanup_photo_due_now_fixture" \
  "130" \
  "Photo INT handler"
run_signal_handler_test \
  "$PHOTO_FLOW" \
  "exit_photo_flow_for_signal" \
  "cleanup_photo_due_now_fixture" \
  "143" \
  "Photo TERM handler"
run_signal_handler_test \
  "$VIDEO_FLOW" \
  "exit_video_flow_for_signal" \
  "cleanup_video_due_now_fixture" \
  "130" \
  "Video INT handler"
run_signal_handler_test \
  "$VIDEO_FLOW" \
  "exit_video_flow_for_signal" \
  "cleanup_video_due_now_fixture" \
  "143" \
  "Video TERM handler"

printf 'All signal cleanup checks passed.\n'
