import 'package:flutter/material.dart';

void main() {
  runApp(const PlantShopApp());
}

class Plant {
  final String name;
  final double price;
  final String description;
  final String careLevel;
  final String category;

  const Plant({
    required this.name,
    required this.price,
    required this.description,
    required this.careLevel,
    required this.category,
  });
}

const List<Plant> allPlants = [
  Plant(
    name: 'Monstera',
    price: 25,
    description: 'A tropical plant with large, glossy leaves featuring natural holes. Perfect for adding a jungle vibe to any room.',
    careLevel: 'Moderate',
    category: 'Indoor',
  ),
  Plant(
    name: 'Snake Plant',
    price: 15,
    description: 'One of the hardiest houseplants. Tall, upright leaves with striking patterns. Excellent air purifier.',
    careLevel: 'Easy',
    category: 'Low Light',
  ),
  Plant(
    name: 'Pothos',
    price: 12,
    description: 'A trailing vine with heart-shaped leaves. Thrives in a variety of conditions and grows quickly.',
    careLevel: 'Easy',
    category: 'Low Light',
  ),
  Plant(
    name: 'Peace Lily',
    price: 18,
    description: 'Elegant white flowers and dark green leaves. Known for its air-cleaning abilities and graceful appearance.',
    careLevel: 'Moderate',
    category: 'Indoor',
  ),
  Plant(
    name: 'Fern',
    price: 10,
    description: 'Lush, feathery fronds that bring a touch of the forest indoors. Loves humidity and indirect light.',
    careLevel: 'Advanced',
    category: 'Outdoor',
  ),
];

class PlantShopApp extends StatelessWidget {
  const PlantShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<CartItem> _cartItems = [
    CartItem(plant: allPlants[0], quantity: 1), // Monstera
    CartItem(plant: allPlants[1], quantity: 1), // Snake Plant
  ];

  void _addToCart(Plant plant) {
    setState(() {
      final existing = _cartItems.indexWhere((item) => item.plant.name == plant.name);
      if (existing >= 0) {
        _cartItems[existing] = CartItem(
          plant: plant,
          quantity: _cartItems[existing].quantity + 1,
        );
      } else {
        _cartItems.add(CartItem(plant: plant, quantity: 1));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plant.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ShopTab(onAddToCart: _addToCart),
      CartTab(cartItems: _cartItems),
      const OrdersTab(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}

// --- Shop Tab ---

class ShopTab extends StatefulWidget {
  final void Function(Plant) onAddToCart;

  const ShopTab({super.key, required this.onAddToCart});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Indoor', 'Outdoor', 'Low Light'];

  List<Plant> get _filteredPlants {
    if (_selectedFilter == 'All') return allPlants;
    return allPlants.where((p) => p.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchPage(onAddToCart: widget.onAddToCart)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = _filteredPlants[index];
                return ListTile(
                  leading: const Icon(Icons.eco, color: Colors.green),
                  title: Text(plant.name),
                  subtitle: Text('\$${plant.price.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    tooltip: 'Add to Cart',
                    onPressed: () => widget.onAddToCart(plant),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantDetailPage(
                          plant: plant,
                          onAddToCart: widget.onAddToCart,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Plant Detail Page ---

class PlantDetailPage extends StatelessWidget {
  final Plant plant;
  final void Function(Plant) onAddToCart;

  const PlantDetailPage({super.key, required this.plant, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.eco, size: 100, color: Colors.green.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              plant.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Price',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${plant.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(plant.description),
            const SizedBox(height: 16),
            Text(
              'Care Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(plant.careLevel),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                onPressed: () {
                  onAddToCart(plant);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final void Function(Plant) onAddToCart;

  const SearchPage({super.key, required this.onAddToCart});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  List<Plant> get _results {
    if (_query.isEmpty) return allPlants;
    return allPlants
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Plants'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final plant = _results[index];
                return ListTile(
                  leading: const Icon(Icons.eco, color: Colors.green),
                  title: Text(plant.name),
                  subtitle: Text('\$${plant.price.toStringAsFixed(0)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantDetailPage(
                          plant: plant,
                          onAddToCart: widget.onAddToCart,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Cart Tab ---

class CartItem {
  final Plant plant;
  final int quantity;

  const CartItem({required this.plant, required this.quantity});
}

class CartTab extends StatelessWidget {
  final List<CartItem> cartItems;

  const CartTab({super.key, required this.cartItems});

  double get _total => cartItems.fold(0, (sum, item) => sum + item.plant.price * item.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: const Icon(Icons.eco, color: Colors.green),
                        title: Text(item.plant.name),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text(
                          '\$${(item.plant.price * item.quantity).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_total.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order placed!')),
                            );
                          },
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Orders Tab ---

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'Order #1001', 'date': 'March 18', 'items': 'Monstera, Pothos', 'total': '\$37'},
      {'id': 'Order #1002', 'date': 'March 15', 'items': 'Snake Plant, Fern', 'total': '\$25'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            leading: const Icon(Icons.receipt, color: Colors.green),
            title: Text(order['id']!),
            subtitle: Text('${order['date']} — ${order['items']}'),
            trailing: Text(
              order['total']!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        },
      ),
    );
  }
}
