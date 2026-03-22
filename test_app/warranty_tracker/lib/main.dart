import 'package:flutter/material.dart';

void main() {
  runApp(const WarrantyTrackerApp());
}

// --- Data Models ---

enum WarrantyStatus { active, expiringSoon, expired }

class Warranty {
  final String id;
  final String productName;
  final String brand;
  final String category;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String notes;

  Warranty({
    required this.id,
    required this.productName,
    required this.brand,
    required this.category,
    required this.purchaseDate,
    required this.expiryDate,
    this.notes = '',
  });

  WarrantyStatus get status {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return WarrantyStatus.expired;
    if (expiryDate.difference(now).inDays <= 30) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  String get daysRemaining {
    final days = expiryDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired ${-days} days ago';
    if (days == 0) return 'Expires today';
    return '$days days left';
  }

  String get formattedPurchaseDate => '${purchaseDate.month}/${purchaseDate.day}/${purchaseDate.year}';
  String get formattedExpiryDate => '${expiryDate.month}/${expiryDate.day}/${expiryDate.year}';
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<Warranty> _warranties = [
    Warranty(id: '1', productName: 'MacBook Pro', brand: 'Apple', category: 'Electronics', purchaseDate: DateTime(2024, 6, 15), expiryDate: DateTime(2027, 6, 15), notes: 'AppleCare+ included'),
    Warranty(id: '2', productName: 'Washing Machine', brand: 'Samsung', category: 'Appliances', purchaseDate: DateTime(2023, 3, 20), expiryDate: DateTime(2026, 3, 20), notes: 'Extended warranty purchased'),
    Warranty(id: '3', productName: 'Running Shoes', brand: 'Nike', category: 'Clothing', purchaseDate: DateTime(2025, 11, 1), expiryDate: DateTime(2026, 5, 1), notes: '6-month warranty'),
    Warranty(id: '4', productName: 'Blender', brand: 'Vitamix', category: 'Appliances', purchaseDate: DateTime(2022, 8, 10), expiryDate: DateTime(2025, 8, 10), notes: 'Standard 3-year warranty'),
    Warranty(id: '5', productName: 'Headphones', brand: 'Sony', category: 'Electronics', purchaseDate: DateTime(2025, 1, 5), expiryDate: DateTime(2027, 1, 5), notes: 'WH-1000XM5'),
    Warranty(id: '6', productName: 'Office Chair', brand: 'Herman Miller', category: 'Furniture', purchaseDate: DateTime(2023, 9, 1), expiryDate: DateTime(2035, 9, 1), notes: '12-year warranty'),
  ];

  String _searchQuery = '';
  String _filterCategory = 'All';

  List<Warranty> get warranties => List.unmodifiable(_warranties);
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;

  List<String> get categories {
    final cats = _warranties.map((w) => w.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Warranty> get filteredWarranties {
    var list = _warranties.toList();
    if (_filterCategory != 'All') {
      list = list.where((w) => w.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((w) =>
        w.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        w.brand.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return list;
  }

  int get activeCount => _warranties.where((w) => w.status == WarrantyStatus.active).length;
  int get expiringSoonCount => _warranties.where((w) => w.status == WarrantyStatus.expiringSoon).length;
  int get expiredCount => _warranties.where((w) => w.status == WarrantyStatus.expired).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void addWarranty(Warranty warranty) {
    _warranties.add(warranty);
    notifyListeners();
  }

  void deleteWarranty(String id) {
    _warranties.removeWhere((w) => w.id == id);
    notifyListeners();
  }
}

// --- App ---

class WarrantyTrackerApp extends StatefulWidget {
  const WarrantyTrackerApp({super.key});

  @override
  State<WarrantyTrackerApp> createState() => _WarrantyTrackerAppState();
}

class _WarrantyTrackerAppState extends State<WarrantyTrackerApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warranty Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: MainScreen(state: _state),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      WarrantyListPage(state: widget.state),
      DashboardPage(state: widget.state),
      SettingsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Warranties'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- Warranty List Page ---

class WarrantyListPage extends StatelessWidget {
  final AppState state;
  const WarrantyListPage({super.key, required this.state});

  Color _statusColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active: return Colors.green;
      case WarrantyStatus.expiringSoon: return Colors.orange;
      case WarrantyStatus.expired: return Colors.red;
    }
  }

  String _statusLabel(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active: return 'Active';
      case WarrantyStatus.expiringSoon: return 'Expiring Soon';
      case WarrantyStatus.expired: return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredWarranties;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Warranties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No warranties found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final warranty = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(warranty.productName),
                    subtitle: Text('${warranty.brand} · ${warranty.daysRemaining}'),
                    trailing: Chip(
                      label: Text(_statusLabel(warranty.status), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: _statusColor(warranty.status),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WarrantyDetailPage(state: state, warranty: warranty))),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWarrantyDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Warranty'),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: state.searchQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Warranties'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Search by product or brand'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () { state.setSearchQuery(''); Navigator.pop(ctx); }, child: const Text('Clear')),
          FilledButton(onPressed: () { state.setSearchQuery(controller.text); Navigator.pop(ctx); }, child: const Text('Search')),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: state.categories.map((cat) => RadioListTile<String>(
            value: cat,
            groupValue: state.filterCategory,
            title: Text(cat),
            onChanged: (v) { state.setFilterCategory(v ?? 'All'); Navigator.pop(ctx); },
          )).toList(),
        ),
      ),
    );
  }

  void _showAddWarrantyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'Electronics';
    int warrantyYears = 2;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Warranty'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 12),
              TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Electronics', 'Appliances', 'Furniture', 'Clothing', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: warrantyYears,
                decoration: const InputDecoration(labelText: 'Warranty Period'),
                items: [1, 2, 3, 5, 10].map((y) => DropdownMenuItem(value: y, child: Text('$y year${y > 1 ? 's' : ''}'))).toList(),
                onChanged: (v) => warrantyYears = v ?? warrantyYears,
              ),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final now = DateTime.now();
                state.addWarranty(Warranty(
                  id: now.millisecondsSinceEpoch.toString(),
                  productName: nameController.text,
                  brand: brandController.text.isNotEmpty ? brandController.text : 'Unknown',
                  category: category,
                  purchaseDate: now,
                  expiryDate: DateTime(now.year + warrantyYears, now.month, now.day),
                  notes: notesController.text,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- Warranty Detail Page ---

class WarrantyDetailPage extends StatelessWidget {
  final AppState state;
  final Warranty warranty;
  const WarrantyDetailPage({super.key, required this.state, required this.warranty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(warranty.productName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Warranty'),
                  content: Text('Delete ${warranty.productName}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () { state.deleteWarranty(warranty.id); Navigator.pop(ctx); Navigator.pop(context); },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product Details', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Product', value: warranty.productName),
                  _DetailRow(label: 'Brand', value: warranty.brand),
                  _DetailRow(label: 'Category', value: warranty.category),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warranty Period', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Purchase Date', value: warranty.formattedPurchaseDate),
                  _DetailRow(label: 'Expiry Date', value: warranty.formattedExpiryDate),
                  _DetailRow(label: 'Status', value: warranty.daysRemaining),
                ],
              ),
            ),
          ),
          if (warranty.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(warranty.notes),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// --- Dashboard Page ---

class DashboardPage extends StatelessWidget {
  final AppState state;
  const DashboardPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final expiringSoon = state.warranties.where((w) => w.status == WarrantyStatus.expiringSoon).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Active', value: '${state.activeCount}', color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Expiring Soon', value: '${state.expiringSoonCount}', color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Expired', value: '${state.expiredCount}', color: Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Expiring Soon', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (expiringSoon.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No warranties expiring soon')))
          else
            ...expiringSoon.map((w) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(w.productName),
                subtitle: Text('${w.brand} · ${w.daysRemaining}'),
                trailing: const Icon(Icons.warning, color: Colors.orange),
              ),
            )),
          const SizedBox(height: 24),
          Text('By Category', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...state.categories.where((c) => c != 'All').map((cat) {
            final count = state.warranties.where((w) => w.category == cat).length;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(cat),
                trailing: Text('$count items', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// --- Settings Page ---

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Expiry Reminders'),
            subtitle: const Text('Get notified before warranties expire'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Export warranties as CSV'),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Warranty Tracker v1.0'),
            leading: const Icon(Icons.info),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About'),
                content: const Text('Warranty Tracker helps you keep track of product warranties so you never miss a claim deadline.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
