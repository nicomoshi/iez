import 'package:flutter/material.dart';

void main() {
  runApp(const CoffeeJournalApp());
}

// --- Data Model ---

enum BrewMethod { pourOver, espresso, frenchPress, aeroPress, coldBrew }

extension BrewMethodLabel on BrewMethod {
  String get label {
    switch (this) {
      case BrewMethod.pourOver:
        return 'Pour Over';
      case BrewMethod.espresso:
        return 'Espresso';
      case BrewMethod.frenchPress:
        return 'French Press';
      case BrewMethod.aeroPress:
        return 'AeroPress';
      case BrewMethod.coldBrew:
        return 'Cold Brew';
    }
  }
}

enum RoastLevel { light, medium, dark }

extension RoastLevelLabel on RoastLevel {
  String get label {
    switch (this) {
      case RoastLevel.light:
        return 'Light';
      case RoastLevel.medium:
        return 'Medium';
      case RoastLevel.dark:
        return 'Dark';
    }
  }
}

class CoffeeEntry {
  final String id;
  final String name;
  final String roaster;
  final String origin;
  final BrewMethod brewMethod;
  final RoastLevel roastLevel;
  final int rating; // 1-5
  final String tastingNotes;
  final double price;

  CoffeeEntry({
    required this.id,
    required this.name,
    required this.roaster,
    required this.origin,
    required this.brewMethod,
    required this.roastLevel,
    required this.rating,
    required this.tastingNotes,
    required this.price,
  });
}

// --- Sample Data ---

List<CoffeeEntry> _sampleCoffees() {
  return [
    CoffeeEntry(
      id: '1',
      name: 'Ethiopian Yirgacheffe',
      roaster: 'Blue Bottle',
      origin: 'Ethiopia',
      brewMethod: BrewMethod.pourOver,
      roastLevel: RoastLevel.light,
      rating: 5,
      tastingNotes:
          'Bright citrus, floral jasmine, clean finish with honey sweetness.',
      price: 18.50,
    ),
    CoffeeEntry(
      id: '2',
      name: 'Sumatra Mandheling',
      roaster: 'Stumptown',
      origin: 'Indonesia',
      brewMethod: BrewMethod.frenchPress,
      roastLevel: RoastLevel.dark,
      rating: 4,
      tastingNotes: 'Earthy, full body, notes of dark chocolate and cedar.',
      price: 16.00,
    ),
    CoffeeEntry(
      id: '3',
      name: 'Colombia Supremo',
      roaster: 'Intelligentsia',
      origin: 'Colombia',
      brewMethod: BrewMethod.espresso,
      roastLevel: RoastLevel.medium,
      rating: 4,
      tastingNotes:
          'Caramel, nutty, balanced acidity with a smooth finish.',
      price: 15.75,
    ),
    CoffeeEntry(
      id: '4',
      name: 'Kenya AA',
      roaster: 'Counter Culture',
      origin: 'Kenya',
      brewMethod: BrewMethod.aeroPress,
      roastLevel: RoastLevel.light,
      rating: 5,
      tastingNotes: 'Blackcurrant, grapefruit, vibrant and juicy.',
      price: 21.00,
    ),
    CoffeeEntry(
      id: '5',
      name: 'Guatemala Antigua',
      roaster: 'Blue Bottle',
      origin: 'Guatemala',
      brewMethod: BrewMethod.coldBrew,
      roastLevel: RoastLevel.medium,
      rating: 3,
      tastingNotes:
          'Chocolate, spice, smooth and mellow when cold brewed.',
      price: 14.50,
    ),
    CoffeeEntry(
      id: '6',
      name: 'Costa Rica Tarrazu',
      roaster: 'Stumptown',
      origin: 'Costa Rica',
      brewMethod: BrewMethod.pourOver,
      roastLevel: RoastLevel.medium,
      rating: 4,
      tastingNotes: 'Bright apple, brown sugar, clean and sweet.',
      price: 17.25,
    ),
  ];
}

// --- App ---

class CoffeeJournalApp extends StatelessWidget {
  const CoffeeJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Journal',
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CoffeeEntry> _coffees = _sampleCoffees();
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Pour Over',
    'Espresso',
    'French Press',
    'AeroPress',
    'Cold Brew',
  ];

  List<CoffeeEntry> get _filteredCoffees {
    if (_selectedFilter == 'All') return _coffees;
    return _coffees
        .where((c) => c.brewMethod.label == _selectedFilter)
        .toList();
  }

  String _starRating(int rating) {
    return List.generate(5, (i) => i < rating ? '\u2605' : '\u2606').join();
  }

  void _addCoffee(CoffeeEntry entry) {
    setState(() {
      _coffees.add(entry);
    });
  }

  void _deleteCoffee(String id) {
    setState(() {
      _coffees.removeWhere((c) => c.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCoffees;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Journal'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'roasters') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoastersScreen(coffees: _coffees),
                  ),
                );
              } else if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BrewStatsScreen(coffees: _coffees),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'roasters', child: Text('Roasters')),
              const PopupMenuItem(
                  value: 'stats', child: Text('Brew Stats')),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: _filters.map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = f;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No coffees found.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final coffee = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(coffee.name),
                          subtitle: Text(coffee.roaster),
                          trailing: Text(
                            _starRating(coffee.rating),
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () async {
                            final deleted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(coffee: coffee),
                              ),
                            );
                            if (deleted == true) {
                              _deleteCoffee(coffee.id);
                            }
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
          final entry = await Navigator.push<CoffeeEntry>(
            context,
            MaterialPageRoute(builder: (_) => const AddCoffeeScreen()),
          );
          if (entry != null) {
            _addCoffee(entry);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Coffee'),
      ),
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatelessWidget {
  final CoffeeEntry coffee;

  const DetailScreen({super.key, required this.coffee});

  String _starRating(int rating) {
    return List.generate(5, (i) => i < rating ? '\u2605' : '\u2606').join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coffee.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              coffee.roaster,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              coffee.origin,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(coffee.brewMethod.label)),
                Chip(label: Text(coffee.roastLevel.label)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _starRating(coffee.rating),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Tasting Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(coffee.tastingNotes),
            const SizedBox(height: 16),
            Text(
              '\$${coffee.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Coffee Screen ---

class AddCoffeeScreen extends StatefulWidget {
  const AddCoffeeScreen({super.key});

  @override
  State<AddCoffeeScreen> createState() => _AddCoffeeScreenState();
}

class _AddCoffeeScreenState extends State<AddCoffeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roasterController = TextEditingController();
  final _originController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  BrewMethod _brewMethod = BrewMethod.pourOver;
  RoastLevel _roastLevel = RoastLevel.medium;
  double _rating = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _roasterController.dispose();
    _originController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Coffee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Coffee Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roasterController,
                decoration:
                    const InputDecoration(labelText: 'Roaster'),
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter a roaster'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _originController,
                decoration:
                    const InputDecoration(labelText: 'Origin'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BrewMethod>(
                value: _brewMethod,
                decoration:
                    const InputDecoration(labelText: 'Brew Method'),
                items: BrewMethod.values.map((m) {
                  return DropdownMenuItem(
                      value: m, child: Text(m.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _brewMethod = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoastLevel>(
                value: _roastLevel,
                decoration:
                    const InputDecoration(labelText: 'Roast Level'),
                items: RoastLevel.values.map((r) {
                  return DropdownMenuItem(
                      value: r, child: Text(r.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _roastLevel = v);
                },
              ),
              const SizedBox(height: 16),
              Text('Rating: ${_rating.round()}',
                  style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.round().toString(),
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Tasting Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration:
                    const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final entry = CoffeeEntry(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: _nameController.text.trim(),
                      roaster: _roasterController.text.trim(),
                      origin: _originController.text.trim(),
                      brewMethod: _brewMethod,
                      roastLevel: _roastLevel,
                      rating: _rating.round(),
                      tastingNotes: _notesController.text.trim(),
                      price: double.tryParse(
                              _priceController.text.trim()) ??
                          0.0,
                    );
                    Navigator.pop(context, entry);
                  }
                },
                child: const Text('Save Coffee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Roasters Screen ---

class RoastersScreen extends StatelessWidget {
  final List<CoffeeEntry> coffees;

  const RoastersScreen({super.key, required this.coffees});

  @override
  Widget build(BuildContext context) {
    final roasterMap = <String, int>{};
    for (final c in coffees) {
      roasterMap[c.roaster] = (roasterMap[c.roaster] ?? 0) + 1;
    }
    final roasters = roasterMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roasters'),
      ),
      body: ListView.builder(
        itemCount: roasters.length,
        itemBuilder: (context, index) {
          final entry = roasters[index];
          return ListTile(
            title: Text(entry.key),
            trailing: Text(
              '${entry.value} coffee${entry.value == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}

// --- Brew Stats Screen ---

class BrewStatsScreen extends StatelessWidget {
  final List<CoffeeEntry> coffees;

  const BrewStatsScreen({super.key, required this.coffees});

  @override
  Widget build(BuildContext context) {
    final total = coffees.length;
    final avgRating = total > 0
        ? coffees.map((c) => c.rating).reduce((a, b) => a + b) / total
        : 0.0;

    final brewCounts = <String, int>{};
    for (final c in coffees) {
      final label = c.brewMethod.label;
      brewCounts[label] = (brewCounts[label] ?? 0) + 1;
    }

    final roastCounts = <String, int>{};
    for (final c in coffees) {
      final label = c.roastLevel.label;
      roastCounts[label] = (roastCounts[label] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Stats'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Coffees',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('$total',
                      style:
                          Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Average Rating',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(avgRating.toStringAsFixed(1),
                      style:
                          Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('By Brew Method',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...brewCounts.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}'),
              )),
          const SizedBox(height: 16),
          Text('By Roast Level',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...roastCounts.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}'),
              )),
        ],
      ),
    );
  }
}
