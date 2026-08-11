#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
total_pass=0
total_fail=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [ -f "$test_file" ] || continue
  printf '\n=== %s ===\n' "$(basename "$test_file")"
  if bash "$test_file"; then
    total_pass=$((total_pass + 1))
  else
    total_fail=$((total_fail + 1))
  fi
done

printf '\nStuari suites: %d passed, %d failed.\n' "$total_pass" "$total_fail"
[ "$total_fail" -eq 0 ]
