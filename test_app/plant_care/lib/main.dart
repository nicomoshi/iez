import 'package:flutter/material.dart';

void main() {
  runApp(const PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Care',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Data Models ---

class Plant {
  String name;
  String species;
  String location;
  String wateringSchedule;
  DateTime lastWatered;
  String sunlight;
  String notes;
  List<DateTime> wateringHistory;

  Plant({
    required this.name,
    required this.species,
    required this.location,
    required this.wateringSchedule,
    required this.lastWatered,
    this.sunlight = 'Partial',
    this.notes = '',
    List<DateTime>? wateringHistory,
  }) : wateringHistory = wateringHistory ?? [lastWatered];

  String get category {
    final loc = location.toLowerCase();
    if (loc == 'indoor') return 'Indoor';
    if (loc == 'outdoor') return 'Outdoor';
    if (loc == 'succulents') return 'Succulents';
    if (loc == 'herbs') return 'Herbs';
    return 'Indoor';
  }

  bool get needsWater {
    final now = DateTime.now();
    final diff = now.difference(lastWatered).inDays;
    switch (wateringSchedule) {
      case 'Daily':
        return diff >= 1;
      case 'Every 3 days':
        return diff >= 3;
      case 'Weekly':
        return diff >= 7;
      case 'Bi-weekly':
        return diff >= 14;
      default:
        return diff >= 3;
    }
  }

  String get healthEmoji => needsWater ? '\u{1F342}' : '\u{1F33F}';
}

// --- Global State ---

final List<Plant> _plants = [
  Plant(
    name: 'Monstera',
    species: 'Monstera Deliciosa',
    location: 'Indoor',
    wateringSchedule: 'Every 3 days',
    lastWatered: DateTime.now().subtract(const Duration(days: 1)),
    sunlight: 'Partial',
    notes: 'Likes humidity. Wipe leaves monthly.',
  ),
  Plant(
    name: 'Basil',
    species: 'Ocimum Basilicum',
    location: 'Herbs',
    wateringSchedule: 'Daily',
    lastWatered: DateTime.now(),
    sunlight: 'Full Sun',
    notes: 'Pinch flowers to encourage leaf growth.',
  ),
  Plant(
    name: 'Aloe Vera',
    species: 'Aloe Barbadensis',
    location: 'Succulents',
    wateringSchedule: 'Weekly',
    lastWatered: DateTime.now().subtract(const Duration(days: 2)),
    sunlight: 'Full Sun',
    notes: 'Well-draining soil. Do not overwater.',
  ),
  Plant(
    name: 'Tomato',
    species: 'Solanum Lycopersicum',
    location: 'Outdoor',
    wateringSchedule: 'Every 3 days',
    lastWatered: DateTime.now().subtract(const Duration(days: 5)),
    sunlight: 'Full Sun',
    notes: 'Needs staking when tall. Feed weekly.',
  ),
  Plant(
    name: 'Snake Plant',
    species: 'Sansevieria',
    location: 'Indoor',
    wateringSchedule: 'Bi-weekly',
    lastWatered: DateTime.now().subtract(const Duration(days: 3)),
    sunlight: 'Shade',
    notes: 'Very low maintenance. Tolerates neglect.',
  ),
  Plant(
    name: 'Lavender',
    species: 'Lavandula',
    location: 'Outdoor',
    wateringSchedule: 'Weekly',
    lastWatered: DateTime.now().subtract(const Duration(days: 4)),
    sunlight: 'Full Sun',
    notes: 'Prune after flowering. Prefers dry soil.',
  ),
];

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Indoor',
    'Outdoor',
    'Succulents',
    'Herbs',
  ];

  List<Plant> get _filteredPlants {
    if (_selectedFilter == 'All') return _plants;
    return _plants.where((p) => p.category == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Care'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Care Tips') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareTipsScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Care Tips', child: Text('Care Tips')),
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
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = _filteredPlants[index];
                return _PlantCard(
                  plant: plant,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantDetailScreen(plant: plant),
                      ),
                    );
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
          );
          setState(() {});
        },
        child: const Text('Add Plant'),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(plant.healthEmoji, style: const TextStyle(fontSize: 28)),
        title: Text(plant.name),
        subtitle: Text(
          '${plant.species}\n${plant.location} \u00B7 ${plant.wateringSchedule}\nLast watered: ${_formatDate(plant.lastWatered)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// --- Detail Screen ---

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WateringHistoryScreen(plant: plant),
                ),
              );
            },
            child: const Text('History'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(plant.healthEmoji, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 16),
          _DetailRow('Name', plant.name),
          _DetailRow('Species', plant.species),
          _DetailRow('Location', plant.location),
          _DetailRow('Watering Schedule', plant.wateringSchedule),
          _DetailRow('Last Watered', _formatDate(plant.lastWatered)),
          _DetailRow('Sunlight', plant.sunlight),
          _DetailRow('Notes', plant.notes.isEmpty ? 'None' : plant.notes),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      plant.lastWatered = DateTime.now();
                      plant.wateringHistory.insert(0, DateTime.now());
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${plant.name} watered!')),
                    );
                  },
                  child: const Text('Water Now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditPlantScreen(plant: plant),
                      ),
                    );
                    setState(() {});
                  },
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

// --- Add/Edit Screen ---

class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant;

  const AddEditPlantScreen({super.key, this.plant});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _speciesCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _notesCtrl;
  late String _wateringSchedule;
  late String _sunlight;

  final _schedules = ['Daily', 'Every 3 days', 'Weekly', 'Bi-weekly'];
  final _sunlights = ['Full Sun', 'Partial', 'Shade'];

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.plant?.name ?? '');
    _speciesCtrl = TextEditingController(text: widget.plant?.species ?? '');
    _locationCtrl = TextEditingController(text: widget.plant?.location ?? '');
    _notesCtrl = TextEditingController(text: widget.plant?.notes ?? '');
    _wateringSchedule = widget.plant?.wateringSchedule ?? 'Every 3 days';
    _sunlight = widget.plant?.sunlight ?? 'Partial';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;

    if (_isEditing) {
      final p = widget.plant!;
      p.name = _nameCtrl.text;
      p.species = _speciesCtrl.text;
      p.location = _locationCtrl.text;
      p.notes = _notesCtrl.text;
      p.wateringSchedule = _wateringSchedule;
      p.sunlight = _sunlight;
    } else {
      _plants.add(Plant(
        name: _nameCtrl.text,
        species: _speciesCtrl.text,
        location: _locationCtrl.text.isEmpty ? 'Indoor' : _locationCtrl.text,
        wateringSchedule: _wateringSchedule,
        lastWatered: DateTime.now(),
        sunlight: _sunlight,
        notes: _notesCtrl.text,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plant' : 'Add Plant'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _speciesCtrl,
            decoration: const InputDecoration(
              labelText: 'Species',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _wateringSchedule,
            decoration: const InputDecoration(
              labelText: 'Watering Schedule',
              border: OutlineInputBorder(),
            ),
            items: _schedules
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _wateringSchedule = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sunlight,
            decoration: const InputDecoration(
              labelText: 'Sunlight',
              border: OutlineInputBorder(),
            ),
            items: _sunlights
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sunlight = v!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Plant'),
          ),
        ],
      ),
    );
  }
}

// --- Care Tips Screen ---

class CareTipsScreen extends StatelessWidget {
  const CareTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      _Tip(
        'Watering Basics',
        'Water when the top inch of soil is dry. Use room temperature water. '
            'Water deeply until it drains from the bottom. Avoid letting plants sit '
            'in standing water. Morning watering is best.',
      ),
      _Tip(
        'Sunlight Guide',
        'Full Sun: 6+ hours direct sunlight (herbs, tomatoes, lavender). '
            'Partial: 3-6 hours or filtered light (monstera, ferns). '
            'Shade: less than 3 hours, indirect light (snake plant, pothos).',
      ),
      _Tip(
        'Common Problems',
        'Yellow leaves: overwatering or nutrient deficiency. '
            'Brown tips: underwatering or low humidity. '
            'Leggy growth: insufficient light. '
            'Wilting: check soil moisture and root health.',
      ),
      _Tip(
        'Soil and Repotting',
        'Repot when roots circle the bottom or grow from drainage holes. '
            'Use well-draining soil mixes. Add perlite for extra drainage. '
            'Best time to repot is spring.',
      ),
      _Tip(
        'Seasonal Care',
        'Spring: increase watering, start fertilizing, repot if needed. '
            'Summer: watch for pests, water more frequently. '
            'Fall: reduce watering, stop fertilizing. '
            'Winter: minimal watering, move away from cold drafts.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Care Tips')),
      body: ListView(
        children: tips
            .map(
              (tip) => ExpansionTile(
                title: Text(tip.title),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(tip.body),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tip {
  final String title;
  final String body;
  const _Tip(this.title, this.body);
}

// --- Watering History Screen ---

class WateringHistoryScreen extends StatelessWidget {
  final Plant plant;

  const WateringHistoryScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${plant.name} History')),
      body: plant.wateringHistory.isEmpty
          ? const Center(child: Text('No watering history yet.'))
          : ListView.builder(
              itemCount: plant.wateringHistory.length,
              itemBuilder: (context, index) {
                final date = plant.wateringHistory[index];
                return ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: Text(_formatDate(date)),
                  subtitle: Text(_formatTime(date)),
                );
              },
            ),
    );
  }
}

// --- Helpers ---

String _formatDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime d) {
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
