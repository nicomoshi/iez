#!/usr/bin/env bash
# test_automation.sh — App 53: provider_shopper (Flutter Samples)
# Login → Catalog (infinite list with ADD) → Cart (BUY)
set -uo pipefail

IEZ=/Users/rudy/Developer/i_ez/bin/iez
PASS=0; FAIL=0; TOTAL=0
DEVICE_ID="70FFEC3F-07A7-4F3A-BC49-B5ABAB81491C"
BUNDLE="dev.flutter.providerShopper"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }

assert_ok() {
  local desc="$1" result="$2"
  TOTAL=$((TOTAL + 1))
  local ok; ok=$(echo "$result" | jq -r '.ok // false')
  if [ "$ok" = "true" ]; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

has_label() {
  run_iez $IEZ ui exists --label "$1" | jq -r '.ok' 2>/dev/null | grep -q true
}

assert_label() {
  local desc="$1" label="$2"
  TOTAL=$((TOTAL + 1))
  if has_label "$label"; then
    PASS=$((PASS + 1)); echo "  ✓ $desc"
  else
    FAIL=$((FAIL + 1)); echo "  ✗ $desc"
  fi
}

echo "=== App 53: provider_shopper ==="
echo ""

# ─── Login Screen ───
echo "── Login Screen ──"
assert_label "Welcome text" "Welcome"
assert_label "Username field" "Username"
assert_label "Password field" "Password"
assert_label "ENTER button" "ENTER"

R=$(run_iez $IEZ ui type "testuser" --label "Username")
assert_ok "Type username" "$R"
sleep 0.2

R=$(run_iez $IEZ ui type "pass123" --label "Password")
assert_ok "Type password" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_login.png)
assert_ok "Screenshot login" "$R"

R=$(run_iez $IEZ ui tap --label "ENTER")
assert_ok "Tap ENTER" "$R"
sleep 0.3

# ─── Catalog Screen ───
echo ""
echo "── Catalog Screen ──"
assert_label "Catalog heading" "Catalog"
assert_label "Item: Code Smell" "Code Smell"
assert_label "Item: Control Flow" "Control Flow"
assert_label "Item: Interpreter" "Interpreter"
assert_label "Item: Recursion" "Recursion"
assert_label "Item: Sprint" "Sprint"
assert_label "Item: Heisenbug" "Heisenbug"
assert_label "ADD button" "ADD"

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_catalog.png)
assert_ok "Screenshot catalog" "$R"

# Add items to cart — first ADD button at ~(354,162) based on frame x=322,y=138,w=64,h=48
R=$(run_iez $IEZ ui tap --coords 354,162)
assert_ok "Add item 1 (Code Smell)" "$R"
sleep 0.2

assert_label "Item 1 shows ADDED" "ADDED"

# Second ADD button — Control Flow row at y≈194+24=218
R=$(run_iez $IEZ ui tap --coords 354,218)
assert_ok "Add item 2 (Control Flow)" "$R"
sleep 0.2

# Third ADD button — Interpreter row at y≈258+24=282
R=$(run_iez $IEZ ui tap --coords 354,282)
assert_ok "Add item 3 (Interpreter)" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_added.png)
assert_ok "Screenshot with 3 added" "$R"

# Scroll down to see more items
R=$(run_iez $IEZ ui swipe up)
assert_ok "Scroll catalog down" "$R"
sleep 0.2

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_scrolled.png)
assert_ok "Screenshot scrolled" "$R"

# Scroll back up to reveal SliverAppBar
R=$(run_iez $IEZ ui swipe down)
assert_ok "Scroll back up" "$R"
sleep 0.2

# ─── Cart Screen ───
echo ""
echo "── Cart Screen ──"
# Cart icon is in app bar top-right (no text label) — use coords ~(378, 90)
R=$(run_iez $IEZ ui tap --coords 378,90)
assert_ok "Tap cart icon (coords)" "$R"
sleep 0.3

assert_label "Cart heading" "Cart"
assert_label "BUY button" "BUY"

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_cart.png)
assert_ok "Screenshot cart" "$R"

# Check cart has items
TREE=$(run_iez $IEZ ui tree --compact)
CART_ITEMS=$(echo "$TREE" | jq '[.data.elements[] | select(.label | test("Code Smell|Control Flow|Interpreter"))] | length')
TOTAL=$((TOTAL + 1))
if [ "$CART_ITEMS" -gt 0 ]; then
  PASS=$((PASS + 1)); echo "  ✓ Cart has items ($CART_ITEMS)"
else
  FAIL=$((FAIL + 1)); echo "  ✗ Cart has items ($CART_ITEMS)"
fi

# Total price = 3 × $42 = $126
assert_label "Total price \$126" "\$126"

# Tap BUY
R=$(run_iez $IEZ ui tap --label "BUY")
assert_ok "Tap BUY" "$R"
sleep 0.3

# Snackbar should appear
assert_label "Snackbar: Buying not supported" "Buying not supported yet."

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_buy.png)
assert_ok "Screenshot after BUY" "$R"

# Go back to catalog
R=$(run_iez $IEZ ui tap --label "Back")
assert_ok "Navigate back to catalog" "$R"
sleep 0.3

assert_label "Back on catalog" "Catalog"

R=$(run_iez $IEZ ui screenshot --out /tmp/shopper_final.png)
assert_ok "Screenshot final state" "$R"

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="
