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
