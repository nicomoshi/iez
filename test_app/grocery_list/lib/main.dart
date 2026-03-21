import 'package:flutter/material.dart';

void main() {
  runApp(const GroceryListApp());
}

class GroceryListApp extends StatelessWidget {
  const GroceryListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery List',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Data Model ---

class GroceryItem {
  String name;
  String quantity;
  String brand;
  String category;
  int aisle;
  String notes;
  bool checked;

  GroceryItem({
    required this.name,
    required this.quantity,
    this.brand = '',
    required this.category,
    required this.aisle,
    this.notes = '',
    this.checked = false,
  });
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Produce',
    'Dairy',
    'Meat',
    'Pantry',
    'Frozen',
  ];

  final List<GroceryItem> _items = [
    GroceryItem(name: 'Bananas', quantity: '6', category: 'Produce', aisle: 1),
    GroceryItem(name: 'Whole Milk', quantity: '1 gal', category: 'Dairy', aisle: 4),
    GroceryItem(name: 'Chicken Breast', quantity: '2 lbs', category: 'Meat', aisle: 7),
    GroceryItem(name: 'Pasta', quantity: '2 boxes', category: 'Pantry', aisle: 3, checked: true),
    GroceryItem(name: 'Ice Cream', quantity: '1 pint', category: 'Frozen', aisle: 10),
    GroceryItem(name: 'Eggs', quantity: '1 dozen', category: 'Dairy', aisle: 4),
    GroceryItem(name: 'Bread', quantity: '1 loaf', category: 'Pantry', aisle: 2, checked: true),
    GroceryItem(name: 'Broccoli', quantity: '2 heads', category: 'Produce', aisle: 1),
  ];

  List<GroceryItem> get _filteredItems {
    final filtered = _selectedCategory == 'All'
        ? List<GroceryItem>.from(_items)
        : _items.where((i) => i.category == _selectedCategory).toList();
    filtered.sort((a, b) {
      if (a.checked == b.checked) return 0;
      return a.checked ? 1 : -1;
    });
    return filtered;
  }

  void _addItem(GroceryItem item) {
    setState(() {
      _items.add(item);
    });
  }

  void _updateItem(GroceryItem oldItem, GroceryItem newItem) {
    setState(() {
      final index = _items.indexOf(oldItem);
      if (index != -1) {
        _items[index] = newItem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'meal_plans') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealPlansScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'meal_plans',
                child: Text('Meal Plans'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return CheckboxListTile(
                  value: item.checked,
                  onChanged: (val) {
                    setState(() {
                      item.checked = val ?? false;
                    });
                  },
                  title: Text(
                    item.name,
                    style: item.checked
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Row(
                    children: [
                      Text('${item.quantity}  '),
                      Text('Aisle ${item.aisle}  '),
                      Chip(label: Text(item.category)),
                    ],
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            item: item,
                            onUpdate: (updated) => _updateItem(item, updated),
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<GroceryItem>(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (result != null) {
            _addItem(result);
          }
        },
        child: const Text('Add Item'),
      ),
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatelessWidget {
  final GroceryItem item;
  final ValueChanged<GroceryItem> onUpdate;

  const DetailScreen({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', item.name),
            _infoRow('Quantity', item.quantity),
            _infoRow('Brand', item.brand.isEmpty ? '\u2014' : item.brand),
            _infoRow('Aisle', '${item.aisle}'),
            _infoRow('Category', item.category),
            _infoRow('Notes', item.notes.isEmpty ? '\u2014' : item.notes),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final updated = await Navigator.push<GroceryItem>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditItemScreen(item: item),
                    ),
                  );
                  if (updated != null) {
                    onUpdate(updated);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Add Item Screen ---

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _brandController = TextEditingController();
  final _aisleController = TextEditingController();
  String _selectedCategory = 'Produce';

  final List<String> _categories = [
    'Produce',
    'Dairy',
    'Meat',
    'Pantry',
    'Frozen',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _aisleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aisleController,
              decoration: const InputDecoration(labelText: 'Aisle'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty) return;
                final item = GroceryItem(
                  name: _nameController.text,
                  quantity: _quantityController.text,
                  brand: _brandController.text,
                  category: _selectedCategory,
                  aisle: int.tryParse(_aisleController.text) ?? 0,
                );
                Navigator.pop(context, item);
              },
              child: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Edit Item Screen ---

class EditItemScreen extends StatefulWidget {
  final GroceryItem item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _brandController;
  late final TextEditingController _aisleController;
  late final TextEditingController _notesController;
  late String _selectedCategory;

  final List<String> _categories = [
    'Produce',
    'Dairy',
    'Meat',
    'Pantry',
    'Frozen',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity);
    _brandController = TextEditingController(text: widget.item.brand);
    _aisleController = TextEditingController(text: '${widget.item.aisle}');
    _notesController = TextEditingController(text: widget.item.notes);
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _aisleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aisleController,
              decoration: const InputDecoration(labelText: 'Aisle'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final updated = GroceryItem(
                  name: _nameController.text,
                  quantity: _quantityController.text,
                  brand: _brandController.text,
                  category: _selectedCategory,
                  aisle: int.tryParse(_aisleController.text) ?? 0,
                  notes: _notesController.text,
                  checked: widget.item.checked,
                );
                Navigator.pop(context, updated);
              },
              child: const Text('Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Meal Plans Screen ---

class MealPlansScreen extends StatelessWidget {
  const MealPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meals = [
      ('Monday', 'Grilled Chicken Salad'),
      ('Tuesday', 'Pasta Primavera'),
      ('Wednesday', 'Tacos'),
      ('Thursday', 'Stir Fry'),
      ('Friday', 'Pizza Night'),
      ('Saturday', 'Burgers'),
      ('Sunday', 'Roast Dinner'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
      ),
      body: ListView.builder(
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final (day, meal) = meals[index];
          return ListTile(
            title: Text(day),
            subtitle: Text(meal),
            leading: const Icon(Icons.restaurant),
          );
        },
      ),
    );
  }
}
