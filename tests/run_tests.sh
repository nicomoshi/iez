#!/usr/bin/env bash
# run_tests.sh — Run all iez tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════╗"
echo "║        iez Test Suite              ║"
echo "╚════════════════════════════════════╝"
echo ""

total_pass=0
total_fail=0

run_test_file() {
    local file="$1"
    echo ""
    bash "$file"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        total_fail=$((total_fail + 1))
    else
        total_pass=$((total_pass + 1))
    fi
}

# Run all test files
for test_file in "$SCRIPT_DIR"/test_*.sh; do
    [[ -f "$test_file" ]] || continue
    [[ "$(basename "$test_file")" == "test_helpers.sh" ]] && continue
    run_test_file "$test_file"
done

echo ""
echo "╔════════════════════════════════════╗"
printf '║  Suites: %d passed, %d failed       ║\n' "$total_pass" "$total_fail"
echo "╚════════════════════════════════════╝"

[[ $total_fail -eq 0 ]] && exit 0 || exit 1
