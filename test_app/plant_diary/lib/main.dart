import 'package:flutter/material.dart';

void main() {
  runApp(const PlantDiaryApp());
}

// --- Data Model ---

enum PlantLocation { indoor, outdoor, balcony, garden }

extension PlantLocationLabel on PlantLocation {
  String get label {
    switch (this) {
      case PlantLocation.indoor:
        return 'Indoor';
      case PlantLocation.outdoor:
        return 'Outdoor';
      case PlantLocation.balcony:
        return 'Balcony';
      case PlantLocation.garden:
        return 'Garden';
    }
  }
}

enum HealthStatus { thriving, good, needsAttention, critical }

extension HealthStatusLabel on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.thriving:
        return 'Thriving';
      case HealthStatus.good:
        return 'Good';
      case HealthStatus.needsAttention:
        return 'Needs Attention';
      case HealthStatus.critical:
        return 'Critical';
    }
  }
}

class Plant {
  String name;
  String species;
  PlantLocation location;
  String waterFrequency;
  DateTime lastWatered;
  HealthStatus healthStatus;
  String notes;

  Plant({
    required this.name,
    required this.species,
    required this.location,
    required this.waterFrequency,
    required this.lastWatered,
    required this.healthStatus,
    this.notes = '',
  });

  bool get needsWater {
    final now = DateTime.now();
    final diff = now.difference(lastWatered).inDays;
    final freq = _parseDaysFromFrequency(waterFrequency);
    return diff >= freq;
  }

  int get daysSinceWatered => DateTime.now().difference(lastWatered).inDays;

  static int _parseDaysFromFrequency(String freq) {
    final lower = freq.toLowerCase();
    final match = RegExp(r'(\d+)').firstMatch(lower);
    if (match != null) {
      final n = int.parse(match.group(1)!);
      if (lower.contains('week')) return n * 7;
      return n;
    }
    if (lower.contains('daily')) return 1;
    if (lower.contains('weekly')) return 7;
    return 3;
  }
}

// --- Sample Data ---

List<Plant> _createSamplePlants() {
  final now = DateTime.now();
  return [
    Plant(
      name: 'Monstera',
      species: 'Monstera deliciosa',
      location: PlantLocation.indoor,
      waterFrequency: 'Every 7 days',
      lastWatered: now.subtract(const Duration(days: 8)),
      healthStatus: HealthStatus.thriving,
      notes: 'Growing a new leaf this month.',
    ),
    Plant(
      name: 'Basil',
      species: 'Ocimum basilicum',
      location: PlantLocation.balcony,
      waterFrequency: 'Every 2 days',
      lastWatered: now.subtract(const Duration(days: 1)),
      healthStatus: HealthStatus.good,
      notes: 'Harvest leaves weekly for cooking.',
    ),
    Plant(
      name: 'Rose Bush',
      species: 'Rosa gallica',
      location: PlantLocation.garden,
      waterFrequency: 'Every 3 days',
      lastWatered: now.subtract(const Duration(days: 5)),
      healthStatus: HealthStatus.needsAttention,
      notes: 'Check for aphids regularly.',
    ),
    Plant(
      name: 'Snake Plant',
      species: 'Dracaena trifasciata',
      location: PlantLocation.indoor,
      waterFrequency: 'Every 14 days',
      lastWatered: now.subtract(const Duration(days: 10)),
      healthStatus: HealthStatus.thriving,
      notes: 'Low maintenance, tolerates low light.',
    ),
    Plant(
      name: 'Tomato',
      species: 'Solanum lycopersicum',
      location: PlantLocation.outdoor,
      waterFrequency: 'Every 2 days',
      lastWatered: now.subtract(const Duration(days: 4)),
      healthStatus: HealthStatus.critical,
      notes: 'Leaves turning yellow, needs fertilizer.',
    ),
    Plant(
      name: 'Lavender',
      species: 'Lavandula angustifolia',
      location: PlantLocation.balcony,
      waterFrequency: 'Every 5 days',
      lastWatered: now.subtract(const Duration(days: 3)),
      healthStatus: HealthStatus.good,
      notes: 'Fragrant blooms in summer.',
    ),
  ];
}

// --- App ---

class PlantDiaryApp extends StatelessWidget {
  const PlantDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Diary',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
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
  final List<Plant> _plants = _createSamplePlants();
  String _selectedFilter = 'All';

  List<Plant> get _filteredPlants {
    if (_selectedFilter == 'All') return _plants;
    return _plants
        .where((p) => p.location.label == _selectedFilter)
        .toList();
  }

  void _addPlant(Plant plant) {
    setState(() {
      _plants.add(plant);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Indoor', 'Outdoor', 'Balcony', 'Garden'];
    final filtered = _filteredPlants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Diary'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Care Guide') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CareGuideScreen(),
                  ),
                );
              } else if (value == 'Watering Schedule') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WateringScheduleScreen(plants: _plants),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Care Guide', child: Text('Care Guide')),
              PopupMenuItem(
                  value: 'Watering Schedule',
                  child: Text('Watering Schedule')),
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
              children: filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
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
                ? const Center(child: Text('No plants found.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final plant = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(plant.name),
                          subtitle: Text(plant.species),
                          trailing: Text(plant.healthStatus.label),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(plant: plant),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Plant>(
            context,
            MaterialPageRoute(builder: (_) => const AddPlantScreen()),
          );
          if (result != null) {
            _addPlant(result);
          }
        },
        label: const Text('Add Plant'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatefulWidget {
  final Plant plant;

  const DetailScreen({super.key, required this.plant});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Plant plant;

  @override
  void initState() {
    super.initState();
    plant = widget.plant;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _waterNow() {
    setState(() {
      plant.lastWatered = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plant.name} watered!')),
    );
  }

  void _editNotes() {
    final controller = TextEditingController(text: plant.notes);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Notes'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  plant.notes = controller.text;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plant.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(plant.species, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _infoRow('Location', plant.location.label),
            _infoRow('Water Frequency', plant.waterFrequency),
            _infoRow('Last Watered', _formatDate(plant.lastWatered)),
            _infoRow('Health Status', plant.healthStatus.label),
            _infoRow('Needs Water', plant.needsWater ? 'Yes' : 'No'),
            const SizedBox(height: 16),
            Text('Notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(plant.notes.isEmpty ? 'No notes.' : plant.notes),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _waterNow,
                    child: const Text('Water Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _editNotes,
                    child: const Text('Edit Notes'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

// --- Add Plant Screen ---

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();
  PlantLocation _location = PlantLocation.indoor;
  HealthStatus _health = HealthStatus.good;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final plant = Plant(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        location: _location,
        waterFrequency: _frequencyController.text.trim(),
        lastWatered: DateTime.now(),
        healthStatus: _health,
        notes: _notesController.text.trim(),
      );
      Navigator.pop(context, plant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Plant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Water Frequency',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlantLocation>(
                value: _location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                items: PlantLocation.values.map((loc) {
                  return DropdownMenuItem(
                    value: loc,
                    child: Text(loc.label),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _location = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HealthStatus>(
                value: _health,
                decoration: const InputDecoration(
                  labelText: 'Health Status',
                  border: OutlineInputBorder(),
                ),
                items: HealthStatus.values.map((h) {
                  return DropdownMenuItem(
                    value: h,
                    child: Text(h.label),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _health = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Plant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Care Guide Screen ---

class CareGuideScreen extends StatelessWidget {
  const CareGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Watering',
        'desc':
            'Water when the top inch of soil feels dry. Overwatering causes root rot.'
      },
      {
        'title': 'Light',
        'desc':
            'Most houseplants prefer bright, indirect light. Rotate pots for even growth.'
      },
      {
        'title': 'Soil',
        'desc':
            'Use well-draining potting mix. Add perlite for extra drainage.'
      },
      {
        'title': 'Fertilizing',
        'desc':
            'Feed monthly during spring and summer with balanced liquid fertilizer.'
      },
      {
        'title': 'Humidity',
        'desc':
            'Tropical plants love humidity. Group plants together or use a pebble tray.'
      },
      {
        'title': 'Pruning',
        'desc':
            'Remove dead or yellowing leaves promptly. Trim leggy stems to encourage bushier growth.'
      },
      {
        'title': 'Repotting',
        'desc':
            'Repot when roots circle the bottom. Go up one pot size, usually every 1-2 years.'
      },
      {
        'title': 'Pest Control',
        'desc':
            'Inspect leaves regularly. Treat pests early with neem oil or insecticidal soap.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Guide'),
      ),
      body: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return ListTile(
            title: Text(tip['title']!),
            subtitle: Text(tip['desc']!),
          );
        },
      ),
    );
  }
}

// --- Watering Schedule Screen ---

class WateringScheduleScreen extends StatelessWidget {
  final List<Plant> plants;

  const WateringScheduleScreen({super.key, required this.plants});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watering Schedule'),
      ),
      body: ListView.builder(
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          final days = plant.daysSinceWatered;
          return ListTile(
            title: Text(plant.name),
            subtitle: Text(plant.waterFrequency),
            trailing: Text(
              '$days day${days == 1 ? '' : 's'} ago',
              style: TextStyle(
                color: plant.needsWater ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
