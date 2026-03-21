#!/usr/bin/env bash
# Apps 74-76: MultiCounter / PasswordValidator / ShoppingCart
set -euo pipefail
IEZ="./bin/iez"
PASS=0; FAIL=0; TOTAL=0
START=$(date +%s)
BUNDLE_ID="com.example.bottomNavNested"

run_iez() { "$@" 2>/dev/null | sed -n '/^{/,/^}/p'; }
assert_ok() {
  local ok; ok=$(echo "$1" | jq -r '.ok // false')
  TOTAL=$((TOTAL+1))
  if [ "$ok" = "true" ]; then PASS=$((PASS+1)); echo "  ✓ $2"
  else FAIL=$((FAIL+1)); echo "  ✗ $2"; fi
}
has_label() { run_iez $IEZ ui exists --label "$1" | jq -r '.ok' | grep -q true; }
has_text() {
  run_iez $IEZ ui tree --compact | jq -r '.data.elements[]?.label // empty' | grep -qF "$1"
}
rebuild_and_launch() {
  xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.3
  cd /Users/rudy/Developer/i_ez/test_app && flutter build ios --simulator --no-codesign 2>&1 | tail -1
  xcrun simctl install booted build/ios/iphonesimulator/Runner.app
  xcrun simctl launch booted "$BUNDLE_ID" 2>/dev/null
  cd /Users/rudy/Developer/i_ez
  sleep 1.5
}

########################################################################
# APP 74: MultiCounter — Multiple independent counters + total
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App74());
class App74 extends StatelessWidget {
  const App74({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'MultiCounter',
      theme: ThemeData(colorSchemeSeed: Colors.lime, useMaterial3: true),
      home: const MultiCounterHome());
  }
}
class MultiCounterHome extends StatefulWidget {
  const MultiCounterHome({super.key});
  @override
  State<MultiCounterHome> createState() => _MultiCounterHomeState();
}
class _MultiCounterHomeState extends State<MultiCounterHome> {
  final Map<String, int> _counters = {'Red': 0, 'Green': 0, 'Blue': 0};
  int get _total => _counters.values.fold(0, (a, b) => a + b);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MultiCounter')),
      body: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Text('Total: $_total', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium),
        ),
        ..._counters.entries.map((e) => ListTile(
          title: Text('${e.key}: ${e.value}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.remove), tooltip: 'Decrease ${e.key}',
              onPressed: () => setState(() => _counters[e.key] = e.value - 1)),
            IconButton(icon: const Icon(Icons.add), tooltip: 'Increase ${e.key}',
              onPressed: () => setState(() => _counters[e.key] = e.value + 1)),
          ]),
        )),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(16), child:
          FilledButton(onPressed: () => setState(() {
            for (var k in _counters.keys) _counters[k] = 0;
          }), child: const Text('Reset All'))),
        const SizedBox(height: 16),
      ]),
    );
  }
}
DART

echo "========================================"
echo "APP 74: MultiCounter"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "MultiCounter" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Total: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Total 0"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Total 0"; }
has_text "Red: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Red 0"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Red 0"; }
has_text "Green: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Green 0"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Green 0"; }
has_text "Blue: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Blue 0"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Blue 0"; }
has_label "Reset All" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Reset btn"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Reset btn"; }

echo "Step 2: Increment Red"
R=$(run_iez $IEZ ui tap --label "Increase Red"); assert_ok "$R" "+Red"
sleep 0.2
R=$(run_iez $IEZ ui tap --label "Increase Red"); assert_ok "$R" "+Red"
sleep 0.2
R=$(run_iez $IEZ ui tap --label "Increase Red"); assert_ok "$R" "+Red"
sleep 0.3
has_text "Red: 3" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Red 3"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Red 3"; }

echo "Step 3: Increment Green"
R=$(run_iez $IEZ ui tap --label "Increase Green"); assert_ok "$R" "+Green"
sleep 0.2
R=$(run_iez $IEZ ui tap --label "Increase Green"); assert_ok "$R" "+Green"
sleep 0.3
has_text "Green: 2" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Green 2"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Green 2"; }

echo "Step 4: Decrement Blue"
R=$(run_iez $IEZ ui tap --label "Decrease Blue"); assert_ok "$R" "-Blue"
sleep 0.3
has_text "Blue: -1" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Blue -1"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Blue -1"; }

echo "Step 5: Check total"
has_text "Total: 4" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Total 4"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Total 4"; }

echo "Step 6: Reset"
R=$(run_iez $IEZ ui tap --label "Reset All"); assert_ok "$R" "Reset"
sleep 0.3
has_text "Total: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Total reset"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Total reset"; }
has_text "Red: 0" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Red reset"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Red reset"; }

echo ""

########################################################################
# APP 75: PasswordValidator — Real-time validation with strength meter
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App75());
class App75 extends StatelessWidget {
  const App75({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'PasswordApp',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const PasswordHome());
  }
}
class PasswordHome extends StatefulWidget {
  const PasswordHome({super.key});
  @override
  State<PasswordHome> createState() => _PasswordHomeState();
}
class _PasswordHomeState extends State<PasswordHome> {
  String _password = '';
  bool _obscure = true;
  bool _submitted = false;
  bool get _hasLength => _password.length >= 8;
  bool get _hasUpper => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _password.contains(RegExp(r'[!@#$%^&*]'));
  int get _strength => [_hasLength, _hasUpper, _hasDigit, _hasSpecial].where((b) => b).length;
  String get _strengthLabel => ['Weak', 'Fair', 'Good', 'Strong'][(_strength - 1).clamp(0, 3)];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PasswordApp')),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_submitted) Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('Password accepted!', style: TextStyle(color: Colors.green)),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            onChanged: (v) => setState(() { _password = v; _submitted = false; }),
          ),
          const SizedBox(height: 16),
          if (_password.isNotEmpty) ...[
            LinearProgressIndicator(value: _strength / 4),
            const SizedBox(height: 8),
            Text('Strength: $_strengthLabel'),
            const SizedBox(height: 16),
            _check('8+ characters', _hasLength),
            _check('Uppercase letter', _hasUpper),
            _check('Digit', _hasDigit),
            _check('Special character', _hasSpecial),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _strength == 4 ? () => setState(() => _submitted = true) : null,
            child: const Text('Submit'),
          ),
        ],
      )),
    );
  }
  Widget _check(String label, bool met) => Row(children: [
    Icon(met ? Icons.check_circle : Icons.cancel,
      color: met ? Colors.green : Colors.red, size: 20),
    const SizedBox(width: 8),
    Text(label),
  ]);
}
DART

echo "========================================"
echo "APP 75: PasswordApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "PasswordApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_label "Password" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Password field"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Password field"; }
has_label "Submit" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Submit button"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Submit button"; }

echo "Step 2: Type weak password"
R=$(run_iez $IEZ ui type "abc" --label "Password"); assert_ok "$R" "Type weak"
sleep 0.5
has_text "Strength: Weak" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Weak strength"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Weak strength"; }
has_text "8+ characters" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Length check"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Length check"; }

echo "Step 3: Toggle visibility"
R=$(run_iez $IEZ ui tap --label "Show password"); assert_ok "$R" "Show password"
sleep 0.3
has_label "Hide password" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Toggle to hide"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Toggle to hide"; }
R=$(run_iez $IEZ ui tap --label "Hide password"); assert_ok "$R" "Hide password"
sleep 0.3

echo "Step 4: Type strong password"
# Clear and retype — restart app to reset
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null; sleep 0.3
xcrun simctl launch booted "$BUNDLE_ID" 2>/dev/null; sleep 1.5
R=$(run_iez $IEZ ui type "MyPass1!" --label "Password"); assert_ok "$R" "Type strong"
sleep 0.5
has_text "Strength: Strong" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Strong"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Strong"; }

echo "Step 5: Submit"
R=$(run_iez $IEZ ui tap --label "Submit"); assert_ok "$R" "Submit"
sleep 0.3
has_text "Password accepted" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Accepted"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Accepted"; }

echo ""

########################################################################
# APP 76: ShoppingCart — GridView + Badge + quantity + checkout dialog
########################################################################
cat > test_app/lib/main.dart << 'DART'
import 'package:flutter/material.dart';
void main() => runApp(const App76());
class App76 extends StatelessWidget {
  const App76({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'ShopApp',
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
      home: const ShopHome());
  }
}
class ShopHome extends StatefulWidget {
  const ShopHome({super.key});
  @override
  State<ShopHome> createState() => _ShopHomeState();
}
class _ShopHomeState extends State<ShopHome> {
  final _products = [
    {'name': 'Laptop', 'price': 999},
    {'name': 'Phone', 'price': 699},
    {'name': 'Tablet', 'price': 499},
    {'name': 'Watch', 'price': 299},
  ];
  final Map<String, int> _cart = {};
  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);
  int get _cartTotal => _cart.entries.fold(0, (sum, e) {
    final p = _products.firstWhere((p) => p['name'] == e.key);
    return sum + (p['price'] as int) * e.value;
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShopApp'), actions: [
        Badge(
          label: Text('$_cartCount'),
          isLabelVisible: _cartCount > 0,
          child: IconButton(icon: const Icon(Icons.shopping_cart), tooltip: 'Cart',
            onPressed: () => _showCart()),
        ),
      ]),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final p = _products[i];
          final name = p['name'] as String;
          final price = p['price'] as int;
          final qty = _cart[name] ?? 0;
          return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: Theme.of(ctx).textTheme.titleMedium),
              Text('\$$price'),
              const SizedBox(height: 8),
              if (qty > 0) Text('Qty: $qty'),
              FilledButton(
                onPressed: () => setState(() => _cart[name] = qty + 1),
                child: Text(qty > 0 ? 'Add More' : 'Add to Cart'),
              ),
            ],
          )));
        },
      ),
    );
  }
  void _showCart() {
    showModalBottomSheet(context: context, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Shopping Cart', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_cart.isEmpty) const Text('Cart is empty')
        else ..._cart.entries.map((e) => ListTile(
          title: Text(e.key), trailing: Text('x${e.value}'),
        )),
        const Divider(),
        Text('Total: \$$_cartTotal', style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_cart.isNotEmpty) FilledButton(onPressed: () {
          Navigator.pop(ctx);
          setState(() => _cart.clear());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed!')));
        }, child: const Text('Checkout')),
      ]),
    ));
  }
}
DART

echo "========================================"
echo "APP 76: ShopApp"
echo "========================================"
rebuild_and_launch

echo "Step 1: Initial state"
has_label "ShopApp" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Title"; }
has_text "Laptop" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Laptop"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Laptop"; }
has_text "Phone" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Phone"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Phone"; }
has_text "Tablet" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Tablet"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Tablet"; }
has_text "\$999" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Laptop price"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Laptop price"; }

echo "Step 2: Add Laptop to cart"
# Laptop's "Add to Cart" button at ~(103, 248)
R=$(run_iez $IEZ ui tap --coords 103,248); assert_ok "$R" "Add Laptop"
sleep 0.3
has_text "Qty: 1" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Qty 1"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Qty 1"; }

echo "Step 3: Add Phone"
# Phone's "Add to Cart" button at ~(300, 248)
R=$(run_iez $IEZ ui tap --coords 300,248); assert_ok "$R" "Add Phone"
sleep 0.3

echo "Step 4: Add more Laptop"
# After adding, Laptop card now shows "Qty: 1" so button shifts down a bit
R=$(run_iez $IEZ ui tap --coords 103,262); assert_ok "$R" "Add more Laptop"
sleep 0.3

echo "Step 5: Open cart"
R=$(run_iez $IEZ ui tap --label "Cart"); assert_ok "$R" "Open cart"
sleep 0.5
has_text "Shopping Cart" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cart title"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cart title"; }
has_text "Laptop" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Laptop in cart"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Laptop in cart"; }
has_text "Phone" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Phone in cart"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Phone in cart"; }
has_label "Checkout" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Checkout btn"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Checkout btn"; }

echo "Step 6: Checkout"
R=$(run_iez $IEZ ui tap --label "Checkout"); assert_ok "$R" "Checkout"
sleep 0.5
has_text "Order placed" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Order snackbar"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Order snackbar"; }

echo "Step 7: Verify empty cart"
sleep 3
R=$(run_iez $IEZ ui tap --label "Cart"); assert_ok "$R" "Open empty cart"
sleep 0.5
has_text "Cart is empty" && { TOTAL=$((TOTAL+1)); PASS=$((PASS+1)); echo "  ✓ Cart empty"; } || { TOTAL=$((TOTAL+1)); FAIL=$((FAIL+1)); echo "  ✗ Cart empty"; }

END=$(date +%s)
echo ""
echo "========================================"
echo "=== TOTAL: $PASS/$TOTAL passed ($FAIL failed) — T-100%: $((END-START))s ==="
echo "========================================"
