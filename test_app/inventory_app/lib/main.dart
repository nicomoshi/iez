import 'package:flutter/material.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryItem {
  final String id;
  String name;
  String category;
  int quantity;
  double price;
  String notes;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    this.notes = '',
  });

  double get totalValue => quantity * price;
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<InventoryItem> _items = [
    InventoryItem(id: '1', name: 'MacBook Pro', category: 'Electronics', quantity: 5, price: 2499),
    InventoryItem(id: '2', name: 'Standing Desk', category: 'Furniture', quantity: 12, price: 899),
    InventoryItem(id: '3', name: 'Coffee Maker', category: 'Kitchen', quantity: 8, price: 199),
    InventoryItem(id: '4', name: 'Monitor 27in', category: 'Electronics', quantity: 15, price: 549),
    InventoryItem(id: '5', name: 'Office Chair', category: 'Furniture', quantity: 20, price: 449),
    InventoryItem(id: '6', name: 'Blender Pro', category: 'Kitchen', quantity: 6, price: 129),
    InventoryItem(id: '7', name: 'Keyboard MX', category: 'Office', quantity: 25, price: 99),
    InventoryItem(id: '8', name: 'Desk Lamp', category: 'Office', quantity: 18, price: 79),
  ];

  String _selectedCategory = 'All';
  String _sortBy = 'name';

  static const List<String> categories = ['All', 'Electronics', 'Furniture', 'Kitchen', 'Office'];

  List<InventoryItem> get _filteredItems {
    var items = _selectedCategory == 'All'
        ? List<InventoryItem>.from(_items)
        : _items.where((i) => i.category == _selectedCategory).toList();
    switch (_sortBy) {
      case 'price':
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'quantity':
        items.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      default:
        items.sort((a, b) => a.name.compareTo(b.name));
    }
    return items;
  }

  void _addItem(InventoryItem item) {
    setState(() => _items.add(item));
  }

  void _updateItem(InventoryItem updated) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == updated.id);
      if (idx != -1) _items[idx] = updated;
    });
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        String tempCategory = _selectedCategory;
        String tempSort = _sortBy;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((c) {
                      return FilterChip(
                        label: Text(c),
                        selected: tempCategory == c,
                        onSelected: (_) => setSheetState(() => tempCategory = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Name'),
                        selected: tempSort == 'name',
                        onSelected: (_) => setSheetState(() => tempSort = 'name'),
                      ),
                      FilterChip(
                        label: const Text('Price'),
                        selected: tempSort == 'price',
                        onSelected: (_) => setSheetState(() => tempSort = 'price'),
                      ),
                      FilterChip(
                        label: const Text('Quantity'),
                        selected: tempSort == 'quantity',
                        onSelected: (_) => setSheetState(() => tempSort = 'quantity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCategory;
                          _sortBy = tempSort;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: InventorySearchDelegate(
                  items: _items,
                  onTap: (item) => _navigateToDetail(item),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatsScreen(items: _items)),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'stats', child: Text('Stats')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: categories.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('${item.category} · \$${item.price.toStringAsFixed(0)}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        onTap: () => _navigateToDetail(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newItem = await Navigator.push<InventoryItem>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          );
          if (newItem != null) _addItem(newItem);
        },
        child: const Text('Add Item'),
      ),
    );
  }

  void _navigateToDetail(InventoryItem item) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item),
      ),
    );
    if (result == 'delete') {
      _deleteItem(item.id);
    } else if (result is InventoryItem) {
      _updateItem(result);
    }
  }
}

class DetailScreen extends StatelessWidget {
  final InventoryItem item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', item.name),
            _infoRow('Category', item.category),
            _infoRow('Quantity', '${item.quantity}'),
            _infoRow('Price', '\$${item.price.toStringAsFixed(2)}'),
            _infoRow('Total Value', '\$${item.totalValue.toStringAsFixed(2)}'),
            if (item.notes.isNotEmpty) _infoRow('Notes', item.notes),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push<InventoryItem>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditScreen(item: item),
                        ),
                      );
                      if (updated != null && context.mounted) {
                        Navigator.pop(context, updated);
                      }
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: Text('Delete "${item.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context, 'delete');
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class AddEditScreen extends StatefulWidget {
  final InventoryItem? item;

  const AddEditScreen({super.key, this.item});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notesCtrl;
  String _category = 'Electronics';

  static const List<String> _categories = ['Electronics', 'Furniture', 'Kitchen', 'Office'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _quantityCtrl = TextEditingController(text: widget.item?.quantity.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.item?.price.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.item?.notes ?? '');
    _category = widget.item?.category ?? 'Electronics';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _quantityCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    final item = InventoryItem(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      category: _category,
      quantity: int.tryParse(_quantityCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      notes: _notesCtrl.text,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Item' : 'Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  final List<InventoryItem> items;

  const StatsScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final totalItems = items.fold<int>(0, (sum, i) => sum + i.quantity);
    final totalValue = items.fold<double>(0, (sum, i) => sum + i.totalValue);
    final Map<String, int> perCategory = {};
    for (final item in items) {
      perCategory[item.category] = (perCategory[item.category] ?? 0) + item.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Items'),
                trailing: Text('$totalItems', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Total Value'),
                trailing: Text('\$${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Items per Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...perCategory.entries.map((e) => Card(
              child: ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class InventorySearchDelegate extends SearchDelegate<InventoryItem?> {
  final List<InventoryItem> items;
  final Function(InventoryItem) onTap;

  InventorySearchDelegate({required this.items, required this.onTap});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, idx) {
        final item = results[idx];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('${item.category} · \$${item.price.toStringAsFixed(0)}'),
          onTap: () {
            close(ctx, null);
            onTap(item);
          },
        );
      },
    );
  }
}
