#!/usr/bin/env bash
# test_automation.sh — BMICalculator (App 174)
set +e
IEZ=/Users/rudy/Developer/i_ez/bin/iez
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
PASS=0; FAIL=0; TOTAL=0
BUNDLE="com.test.bmiCalculator"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS="$APP_DIR/screenshots"
mkdir -p "$SCREENSHOTS"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $2"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $2"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

tree_contains() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[].label // empty' 2>/dev/null | grep -qF "$1"
}

fresh_launch() {
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE" 2>/dev/null || true
  sleep 0.3
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE" 2>/dev/null
  sleep 1.5
}

screenshot() {
  run_iez $IEZ ui screenshot --out "$SCREENSHOTS/$1.png" >/dev/null 2>&1
}

# =========================================
echo "=== BMICalculator Test Suite ==="
# =========================================

fresh_launch

echo "--- Input Screen ---"
R=$(run_iez $IEZ ui wait --label "BMI Calculator" --timeout 5)
assert_ok "$R" "BMI Calculator heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Male"; then
  PASS=$((PASS + 1)); echo "  ✓ Male gender card"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Male gender card"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Female"; then
  PASS=$((PASS + 1)); echo "  ✓ Female gender card"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Female gender card"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Height: 170 cm"; then
  PASS=$((PASS + 1)); echo "  ✓ Height card visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Height card visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Weight (kg)"; then
  PASS=$((PASS + 1)); echo "  ✓ Weight card visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Weight card visible"
fi

TOTAL=$((TOTAL + 1))
if tree_contains "Age"; then
  PASS=$((PASS + 1)); echo "  ✓ Age card visible"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Age card visible"
fi

R=$(run_iez $IEZ ui exists --label "Calculate")
assert_ok "$R" "Calculate button exists"

screenshot "01_input_screen"

echo "--- Select Female Gender ---"
# Female card at x=209, y=134, w=177, h=154 — tap center
R=$(run_iez $IEZ ui tap --coords 297,211)
assert_ok "$R" "Tap Female card"
sleep 0.3

screenshot "02_female_selected"

echo "--- Decrement Weight ---"
# Weight - button at x=36, y=508, w=64, h=53 — center (68, 534)
R=$(run_iez $IEZ ui tap --coords 68,534)
assert_ok "$R" "Tap Weight - button"
sleep 0.2
R=$(run_iez $IEZ ui tap --coords 68,534)
assert_ok "$R" "Tap Weight - button again"
sleep 0.2

TOTAL=$((TOTAL + 1))
if tree_contains "73"; then
  PASS=$((PASS + 1)); echo "  ✓ Weight decremented to 73"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Weight decremented to 73"
fi

screenshot "03_adjusted_values"

echo "--- Calculate BMI ---"
R=$(run_iez $IEZ ui tap --label "Calculate")
assert_ok "$R" "Tap Calculate"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "BMI Result" --timeout 5)
assert_ok "$R" "BMI Result heading"

TOTAL=$((TOTAL + 1))
if tree_contains "Your BMI"; then
  PASS=$((PASS + 1)); echo "  ✓ Your BMI label"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Your BMI label"
fi

# BMI for 73kg / 1.70m = 25.3 (Overweight)
TOTAL=$((TOTAL + 1))
if tree_contains "Overweight"; then
  PASS=$((PASS + 1)); echo "  ✓ Overweight category"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Overweight category"
fi

R=$(run_iez $IEZ ui exists --label "Recalculate")
assert_ok "$R" "Recalculate button"

screenshot "04_result_overweight"

echo "--- Recalculate ---"
R=$(run_iez $IEZ ui tap --label "Recalculate")
assert_ok "$R" "Tap Recalculate"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "BMI Calculator" --timeout 5)
assert_ok "$R" "Back on input screen"

screenshot "05_back_to_input"

echo "--- Calculate Default (Normal BMI) ---"
# Fresh launch to reset values
fresh_launch

R=$(run_iez $IEZ ui wait --label "BMI Calculator" --timeout 5)
assert_ok "$R" "Fresh launch BMI Calculator"

R=$(run_iez $IEZ ui tap --label "Calculate")
assert_ok "$R" "Tap Calculate with defaults"
sleep 0.5

R=$(run_iez $IEZ ui wait --label "BMI Result" --timeout 5)
assert_ok "$R" "BMI Result heading (default)"

# Default: 75kg / 1.70m = 25.95 → Overweight
TOTAL=$((TOTAL + 1))
if tree_contains "Your BMI"; then
  PASS=$((PASS + 1)); echo "  ✓ BMI result displayed"
else
  FAIL=$((FAIL + 1)); echo "  ✗ BMI result displayed"
fi

screenshot "06_result_default"

echo "--- Navigate back and test low BMI ---"
R=$(run_iez $IEZ ui tap --label "Recalculate")
assert_ok "$R" "Tap Recalculate"
sleep 0.5

# Decrease weight many times to get underweight
# Weight - button at x=36, y=508
for i in $(seq 1 30); do
  run_iez $IEZ ui tap --coords 68,534 >/dev/null
  sleep 0.1
done
sleep 0.3

R=$(run_iez $IEZ ui tap --label "Calculate")
assert_ok "$R" "Calculate low BMI"
sleep 0.5

TOTAL=$((TOTAL + 1))
if tree_contains "Underweight"; then
  PASS=$((PASS + 1)); echo "  ✓ Underweight category for low weight"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Underweight category for low weight"
fi

screenshot "07_result_underweight"

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
