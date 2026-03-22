import 'package:flutter/material.dart';

void main() => runApp(const GardenPlannerApp());

// ─── Data Model ───────────────────────────────────────────────

enum PlantCategory { vegetables, fruits, herbs, flowers, trees }

enum PlantLocation { raisedBed, ground, container, greenhouse }

enum PlantStatus { seedling, growing, flowering, harvesting, dormant }

String categoryLabel(PlantCategory c) {
  switch (c) {
    case PlantCategory.vegetables: return 'Vegetables';
    case PlantCategory.fruits: return 'Fruits';
    case PlantCategory.herbs: return 'Herbs';
    case PlantCategory.flowers: return 'Flowers';
    case PlantCategory.trees: return 'Trees';
  }
}

String locationLabel(PlantLocation l) {
  switch (l) {
    case PlantLocation.raisedBed: return 'Raised Bed';
    case PlantLocation.ground: return 'Ground';
    case PlantLocation.container: return 'Container';
    case PlantLocation.greenhouse: return 'Greenhouse';
  }
}

String statusLabel(PlantStatus s) {
  switch (s) {
    case PlantStatus.seedling: return 'Seedling';
    case PlantStatus.growing: return 'Growing';
    case PlantStatus.flowering: return 'Flowering';
    case PlantStatus.harvesting: return 'Harvesting';
    case PlantStatus.dormant: return 'Dormant';
  }
}

PlantStatus nextStatus(PlantStatus s) {
  final values = PlantStatus.values;
  return values[(s.index + 1) % values.length];
}

class GardenItem {
  String name;
  PlantCategory category;
  DateTime plantedDate;
  String expectedHarvest;
  PlantLocation location;
  PlantStatus status;
  String notes;

  GardenItem({
    required this.name,
    required this.category,
    required this.plantedDate,
    required this.expectedHarvest,
    required this.location,
    required this.status,
    this.notes = '',
  });
}

// ─── Sample Data ──────────────────────────────────────────────

List<GardenItem> createSampleItems() => [
  GardenItem(
    name: 'Tomato',
    category: PlantCategory.vegetables,
    plantedDate: DateTime(2026, 3, 1),
    expectedHarvest: 'June 2026',
    location: PlantLocation.raisedBed,
    status: PlantStatus.growing,
    notes: 'Roma variety, needs staking',
  ),
  GardenItem(
    name: 'Strawberry',
    category: PlantCategory.fruits,
    plantedDate: DateTime(2026, 2, 15),
    expectedHarvest: 'May 2026',
    location: PlantLocation.container,
    status: PlantStatus.flowering,
    notes: 'Everbearing type',
  ),
  GardenItem(
    name: 'Basil',
    category: PlantCategory.herbs,
    plantedDate: DateTime(2026, 3, 10),
    expectedHarvest: 'April 2026',
    location: PlantLocation.greenhouse,
    status: PlantStatus.seedling,
    notes: 'Sweet Genovese basil',
  ),
  GardenItem(
    name: 'Sunflower',
    category: PlantCategory.flowers,
    plantedDate: DateTime(2026, 2, 20),
    expectedHarvest: 'July 2026',
    location: PlantLocation.ground,
    status: PlantStatus.growing,
    notes: 'Mammoth variety, full sun',
  ),
  GardenItem(
    name: 'Lemon Tree',
    category: PlantCategory.trees,
    plantedDate: DateTime(2025, 11, 5),
    expectedHarvest: 'October 2026',
    location: PlantLocation.container,
    status: PlantStatus.harvesting,
    notes: 'Meyer lemon, indoor winter',
  ),
  GardenItem(
    name: 'Pepper',
    category: PlantCategory.vegetables,
    plantedDate: DateTime(2026, 3, 5),
    expectedHarvest: 'July 2026',
    location: PlantLocation.raisedBed,
    status: PlantStatus.seedling,
    notes: 'Bell pepper mix',
  ),
];

// ─── App ──────────────────────────────────────────────────────

class GardenPlannerApp extends StatelessWidget {
  const GardenPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garden Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lime,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ──────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GardenItem> _items = createSampleItems();
  String _selectedCategory = 'All';

  List<GardenItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items
        .where((i) => categoryLabel(i.category) == _selectedCategory)
        .toList();
  }

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Herbs',
    'Flowers',
    'Trees',
  ];

  void _addItem(GardenItem item) {
    setState(() => _items.add(item));
  }

  void _deleteItem(GardenItem item) {
    setState(() => _items.remove(item));
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garden Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Calendar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarScreen(items: _items),
                  ),
                );
              } else if (value == 'Harvest Log') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HarvestLogScreen(items: _items),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Calendar', child: Text('Calendar')),
              PopupMenuItem(value: 'Harvest Log', child: Text('Harvest Log')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No plants found'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(categoryLabel(item.category)),
                          trailing: Text(statusLabel(item.status)),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  item: item,
                                  onDelete: () => _deleteItem(item),
                                ),
                              ),
                            );
                            _refresh();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<GardenItem>(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (result != null) _addItem(result);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Plant'),
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────

class DetailScreen extends StatefulWidget {
  final GardenItem item;
  final VoidCallback onDelete;

  const DetailScreen({super.key, required this.item, required this.onDelete});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Chip(label: Text(categoryLabel(item.category))),
            const SizedBox(height: 16),
            Text(
              'Planted: ${item.plantedDate.month}/${item.plantedDate.day}/${item.plantedDate.year}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Expected Harvest: ${item.expectedHarvest}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${locationLabel(item.location)}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${statusLabel(item.status)}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (item.notes.isNotEmpty)
              Text(
                'Notes: ${item.notes}',
                style: theme.textTheme.bodyLarge,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      item.status = nextStatus(item.status);
                    });
                  },
                  child: const Text('Update Status'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                  child: const Text('Delete Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Item Screen ──────────────────────────────────────────

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _harvestController = TextEditingController();
  final _notesController = TextEditingController();
  PlantCategory _category = PlantCategory.vegetables;
  PlantLocation _location = PlantLocation.raisedBed;
  PlantStatus _status = PlantStatus.seedling;

  @override
  void dispose() {
    _nameController.dispose();
    _harvestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Plant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plant Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: PlantCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(categoryLabel(c)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantLocation>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              items: PlantLocation.values
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(locationLabel(l)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _location = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlantStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: PlantStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(statusLabel(s)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _harvestController,
              decoration:
                  const InputDecoration(labelText: 'Expected Harvest'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                final item = GardenItem(
                  name: _nameController.text.trim(),
                  category: _category,
                  plantedDate: DateTime.now(),
                  expectedHarvest: _harvestController.text.trim(),
                  location: _location,
                  status: _status,
                  notes: _notesController.text.trim(),
                );
                Navigator.pop(context, item);
              },
              child: const Text('Add Plant'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Screen ──────────────────────────────────────────

class CalendarScreen extends StatelessWidget {
  final List<GardenItem> items;

  const CalendarScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final sorted = List<GardenItem>.from(items)
      ..sort((a, b) => a.plantedDate.compareTo(b.plantedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: sorted.isEmpty
          ? const Center(child: Text('No plants yet'))
          : ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final item = sorted[index];
                final date = item.plantedDate;
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Planted: ${date.month}/${date.day}/${date.year}',
                  ),
                  trailing: Text(statusLabel(item.status)),
                );
              },
            ),
    );
  }
}

// ─── Harvest Log Screen ───────────────────────────────────────

class HarvestLogScreen extends StatelessWidget {
  final List<GardenItem> items;

  const HarvestLogScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final harvesting =
        items.where((i) => i.status == PlantStatus.harvesting).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Harvest Log')),
      body: harvesting.isEmpty
          ? const Center(child: Text('No plants currently harvesting'))
          : ListView.builder(
              itemCount: harvesting.length,
              itemBuilder: (context, index) {
                final item = harvesting[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Expected: ${item.expectedHarvest}'),
                );
              },
            ),
    );
  }
}
