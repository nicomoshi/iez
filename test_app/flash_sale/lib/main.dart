import 'package:flutter/material.dart';

void main() {
  runApp(const FlashSaleApp());
}

// --- Data Models ---

enum DealCategory { electronics, fashion, home, food, sports }

extension DealCategoryLabel on DealCategory {
  String get label {
    switch (this) {
      case DealCategory.electronics: return 'Electronics';
      case DealCategory.fashion: return 'Fashion';
      case DealCategory.home: return 'Home';
      case DealCategory.food: return 'Food';
      case DealCategory.sports: return 'Sports';
    }
  }

  IconData get icon {
    switch (this) {
      case DealCategory.electronics: return Icons.devices;
      case DealCategory.fashion: return Icons.checkroom;
      case DealCategory.home: return Icons.home;
      case DealCategory.food: return Icons.restaurant;
      case DealCategory.sports: return Icons.sports_basketball;
    }
  }
}

class Deal {
  final String id;
  final String title;
  final String description;
  final double originalPrice;
  final double salePrice;
  final DealCategory category;
  final int hoursLeft;
  final int claimed;
  final int totalAvailable;
  bool isSaved;

  Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.salePrice,
    required this.category,
    required this.hoursLeft,
    required this.claimed,
    required this.totalAvailable,
    this.isSaved = false,
  });

  int get discount => ((1 - salePrice / originalPrice) * 100).round();
  int get remaining => totalAvailable - claimed;
  double get claimedPercent => claimed / totalAvailable;
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<Deal> _deals = [
    Deal(id: '1', title: 'Wireless Earbuds Pro', description: 'Active noise cancellation, 24h battery life', originalPrice: 149.99, salePrice: 59.99, category: DealCategory.electronics, hoursLeft: 3, claimed: 78, totalAvailable: 100),
    Deal(id: '2', title: 'Running Shoes Elite', description: 'Lightweight mesh, responsive cushioning', originalPrice: 189.99, salePrice: 79.99, category: DealCategory.sports, hoursLeft: 5, claimed: 45, totalAvailable: 80),
    Deal(id: '3', title: 'Smart Watch Band', description: 'Stainless steel, fits all models', originalPrice: 49.99, salePrice: 19.99, category: DealCategory.electronics, hoursLeft: 2, claimed: 92, totalAvailable: 100),
    Deal(id: '4', title: 'Organic Coffee Bundle', description: '3 bags of premium single-origin beans', originalPrice: 59.99, salePrice: 29.99, category: DealCategory.food, hoursLeft: 8, claimed: 30, totalAvailable: 50),
    Deal(id: '5', title: 'Cashmere Sweater', description: '100% cashmere, classic fit', originalPrice: 199.99, salePrice: 89.99, category: DealCategory.fashion, hoursLeft: 6, claimed: 55, totalAvailable: 70),
    Deal(id: '6', title: 'Air Purifier Mini', description: 'HEPA filter, covers 200 sq ft', originalPrice: 129.99, salePrice: 49.99, category: DealCategory.home, hoursLeft: 4, claimed: 65, totalAvailable: 90),
    Deal(id: '7', title: 'Yoga Mat Premium', description: 'Non-slip, eco-friendly material', originalPrice: 79.99, salePrice: 34.99, category: DealCategory.sports, hoursLeft: 7, claimed: 25, totalAvailable: 60),
    Deal(id: '8', title: 'Desk Lamp LED', description: 'Adjustable brightness, USB charging port', originalPrice: 69.99, salePrice: 29.99, category: DealCategory.home, hoursLeft: 1, claimed: 88, totalAvailable: 100),
  ];

  int _tabIndex = 0;
  DealCategory? _filterCategory;

  List<Deal> get deals => _filterCategory == null
      ? List.unmodifiable(_deals)
      : _deals.where((d) => d.category == _filterCategory).toList();
  List<Deal> get savedDeals => _deals.where((d) => d.isSaved).toList();
  List<Deal> get allDeals => List.unmodifiable(_deals);
  int get tabIndex => _tabIndex;
  DealCategory? get filterCategory => _filterCategory;

  int get totalSaved => savedDeals.length;
  double get avgDiscount =>
      _deals.isEmpty ? 0 : _deals.fold(0.0, (s, d) => s + d.discount) / _deals.length;

  void setTab(int t) { _tabIndex = t; notifyListeners(); }
  void setFilter(DealCategory? c) { _filterCategory = c; notifyListeners(); }

  void toggleSave(String id) {
    final deal = _deals.firstWhere((d) => d.id == id);
    deal.isSaved = !deal.isSaved;
    notifyListeners();
  }
}

// --- App ---

class FlashSaleApp extends StatefulWidget {
  const FlashSaleApp({super.key});
  @override
  State<FlashSaleApp> createState() => _FlashSaleAppState();
}

class _FlashSaleAppState extends State<FlashSaleApp> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => MaterialApp(
        title: 'FlashSale',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepOrange,
          useMaterial3: true,
        ),
        home: MainScreen(state: _state),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final screens = [
      DealsScreen(state: state),
      SavedScreen(state: state),
      ProfileScreen(state: state),
    ];
    return Scaffold(
      body: screens[state.tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.setTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Deals'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- Deals Screen ---

class DealsScreen extends StatelessWidget {
  final AppState state;
  const DealsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deals = state.deals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Sales'),
        actions: [
          PopupMenuButton<DealCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: state.setFilter,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Categories')),
              ...DealCategory.values.map((c) =>
                  PopupMenuItem(value: c, child: Text(c.label))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Up to 60% OFF',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimary)),
                const SizedBox(height: 4),
                Text('Limited time deals ending soon!',
                    style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: deals.length,
              itemBuilder: (context, i) => DealCard(deal: deals[i], state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class DealCard extends StatelessWidget {
  final Deal deal;
  final AppState state;
  const DealCard({super.key, required this.deal, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal, state: state)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Discount badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('-${deal.discount}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onErrorContainer,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('\$${deal.salePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(width: 8),
                        Text('\$${deal.originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: cs.outline,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: cs.outline),
                        const SizedBox(width: 4),
                        Text('${deal.hoursLeft}h left',
                            style: TextStyle(color: cs.outline, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('${deal.remaining} left',
                            style: TextStyle(color: cs.outline, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  deal.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: deal.isSaved ? cs.primary : cs.outline,
                ),
                onPressed: () => state.toggleSave(deal.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Deal Detail ---

class DealDetailScreen extends StatelessWidget {
  final Deal deal;
  final AppState state;
  const DealDetailScreen({super.key, required this.deal, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(deal.title),
        actions: [
          IconButton(
            icon: Icon(deal.isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => state.toggleSave(deal.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Price section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('\$${deal.salePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: cs.error)),
                      const SizedBox(width: 12),
                      Text('\$${deal.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              color: cs.outline)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Save ${deal.discount}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onErrorContainer)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text('Description',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(deal.description, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
          // Details
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Category'),
                  trailing: Text(deal.category.label),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time Remaining'),
                  trailing: Text('${deal.hoursLeft} hours'),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Stock'),
                  trailing: Text('${deal.remaining} of ${deal.totalAvailable}'),
                ),
                // Claimed progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(deal.claimedPercent * 100).round()}% claimed',
                          style: TextStyle(fontSize: 12, color: cs.outline)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: deal.claimedPercent,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deal claimed! Check your email.')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Claim Deal'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Saved Screen ---

class SavedScreen extends StatelessWidget {
  final AppState state;
  const SavedScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final saved = state.savedDeals;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Deals')),
      body: saved.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No saved deals yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the bookmark icon to save deals',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: saved.length,
              itemBuilder: (context, i) => DealCard(deal: saved[i], state: state),
            ),
    );
  }
}

// --- Profile Screen ---

class ProfileScreen extends StatelessWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: cs.primaryContainer,
                    child: Text('JD',
                        style: TextStyle(
                            fontSize: 20, color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jane Doe',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('jane.doe@email.com',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${state.totalSaved}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Saved'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${state.avgDiscount.round()}%',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Avg Discount'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Menu items
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notifications'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Payment Methods'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help Center'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
