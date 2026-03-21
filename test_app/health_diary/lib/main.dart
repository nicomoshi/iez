import 'package:flutter/material.dart';

void main() {
  runApp(const HealthDiaryApp());
}

enum EntryType { water, meal, sleep, mood }

enum MoodValue { happy, neutral, stressed, tired, energized }

class HealthEntry {
  final EntryType type;
  final String time;
  final String? notes;
  final int? glasses;
  final String? mealName;
  final int? calories;
  final double? hours;
  final MoodValue? mood;

  HealthEntry({
    required this.type,
    required this.time,
    this.notes,
    this.glasses,
    this.mealName,
    this.calories,
    this.hours,
    this.mood,
  });

  String get title {
    switch (type) {
      case EntryType.water:
        return 'Water: ${glasses ?? 0} glasses';
      case EntryType.meal:
        return '${mealName ?? "Meal"}: ${calories ?? 0} cal';
      case EntryType.sleep:
        return 'Sleep: ${hours ?? 0} hours';
      case EntryType.mood:
        return 'Mood: ${mood?.name ?? "unknown"}';
    }
  }

  IconData get icon {
    switch (type) {
      case EntryType.water:
        return Icons.water_drop;
      case EntryType.meal:
        return Icons.restaurant;
      case EntryType.sleep:
        return Icons.bedtime;
      case EntryType.mood:
        return Icons.emoji_emotions;
    }
  }

  String get moodEmoji {
    switch (mood) {
      case MoodValue.happy:
        return '😊';
      case MoodValue.neutral:
        return '😐';
      case MoodValue.stressed:
        return '😰';
      case MoodValue.tired:
        return '😴';
      case MoodValue.energized:
        return '⚡';
      default:
        return '😊';
    }
  }
}

class HealthDiaryApp extends StatelessWidget {
  const HealthDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Diary',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  late List<HealthEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _defaultEntries();
  }

  List<HealthEntry> _defaultEntries() {
    return [
      HealthEntry(
        type: EntryType.water,
        time: '8:00 AM',
        glasses: 3,
        notes: 'Morning hydration',
      ),
      HealthEntry(
        type: EntryType.meal,
        time: '8:30 AM',
        mealName: 'Oatmeal and fruit',
        calories: 350,
        notes: 'Breakfast',
      ),
      HealthEntry(
        type: EntryType.water,
        time: '11:00 AM',
        glasses: 2,
        notes: 'Mid-morning',
      ),
      HealthEntry(
        type: EntryType.meal,
        time: '12:30 PM',
        mealName: 'Grilled chicken salad',
        calories: 520,
        notes: 'Lunch',
      ),
      HealthEntry(
        type: EntryType.mood,
        time: '2:00 PM',
        mood: MoodValue.happy,
        notes: 'Great afternoon walk',
      ),
      HealthEntry(
        type: EntryType.sleep,
        time: 'Last night',
        hours: 7.5,
        notes: 'Slept well',
      ),
    ];
  }

  List<HealthEntry> get _filteredEntries {
    if (_selectedFilter == 'All') return _entries;
    final typeMap = {
      'Water': EntryType.water,
      'Meals': EntryType.meal,
      'Sleep': EntryType.sleep,
      'Mood': EntryType.mood,
    };
    final type = typeMap[_selectedFilter];
    if (type == null) return _entries;
    return _entries.where((e) => e.type == type).toList();
  }

  int get _totalWater =>
      _entries.where((e) => e.type == EntryType.water).fold(0, (sum, e) => sum + (e.glasses ?? 0));

  int get _totalCalories =>
      _entries.where((e) => e.type == EntryType.meal).fold(0, (sum, e) => sum + (e.calories ?? 0));

  double get _totalSleep =>
      _entries.where((e) => e.type == EntryType.sleep).fold(0.0, (sum, e) => sum + (e.hours ?? 0));

  String get _currentMoodEmoji {
    final moodEntries = _entries.where((e) => e.type == EntryType.mood).toList();
    if (moodEntries.isEmpty) return '😊';
    return moodEntries.last.moodEmoji;
  }

  void _addEntry(HealthEntry entry) {
    setState(() {
      _entries.add(entry);
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Water', 'Meals', 'Sleep', 'Mood'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Diary'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Goals') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsScreen(
                      totalWater: _totalWater,
                      totalCalories: _totalCalories,
                      totalSleep: _totalSleep,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Goals',
                child: Text('Goals'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem(Icons.water_drop, '$_totalWater glasses', 'Water'),
                      _summaryItem(Icons.local_fire_department, '$_totalCalories cal', 'Calories'),
                      _summaryItem(Icons.bedtime, '${_totalSleep}h', 'Sleep'),
                      _summaryItem(null, _currentMoodEmoji, 'Mood', isEmoji: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: filters.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: _selectedFilter == f,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = f;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                final realIndex = _entries.indexOf(entry);
                return ListTile(
                  leading: Icon(entry.icon),
                  title: Text(entry.title),
                  subtitle: Text(entry.time),
                  trailing: entry.notes != null ? const Icon(Icons.notes) : null,
                  onTap: () async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(entry: entry),
                      ),
                    );
                    if (deleted == true) {
                      _deleteEntry(realIndex);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final entry = await Navigator.push<HealthEntry>(
            context,
            MaterialPageRoute(builder: (_) => const AddEntryScreen()),
          );
          if (entry != null) {
            _addEntry(entry);
          }
        },
        child: const Text('Add Entry'),
      ),
    );
  }

  Widget _summaryItem(IconData? icon, String value, String label, {bool isEmoji = false}) {
    return Column(
      children: [
        if (isEmoji)
          Text(value, style: const TextStyle(fontSize: 28))
        else
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        if (!isEmoji) Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class DetailScreen extends StatelessWidget {
  final HealthEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entry Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(entry.icon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Time: ${entry.time}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (entry.notes != null) ...[
              Text('Notes: ${entry.notes}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            if (entry.type == EntryType.water)
              Text('Glasses: ${entry.glasses}', style: const TextStyle(fontSize: 16)),
            if (entry.type == EntryType.meal) ...[
              Text('Meal: ${entry.mealName}', style: const TextStyle(fontSize: 16)),
              Text('Calories: ${entry.calories}', style: const TextStyle(fontSize: 16)),
            ],
            if (entry.type == EntryType.sleep)
              Text('Hours: ${entry.hours}', style: const TextStyle(fontSize: 16)),
            if (entry.type == EntryType.mood)
              Text('Mood: ${entry.mood?.name} ${entry.moodEmoji}',
                  style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit not implemented')),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context, true);
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
}

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  EntryType _selectedType = EntryType.water;
  MoodValue? _selectedMood;

  final _glassesController = TextEditingController();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void dispose() {
    _glassesController.dispose();
    _mealNameController.dispose();
    _caloriesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _save() {
    HealthEntry? entry;
    switch (_selectedType) {
      case EntryType.water:
        final glasses = int.tryParse(_glassesController.text) ?? 0;
        if (glasses <= 0) return;
        entry = HealthEntry(type: EntryType.water, time: 'Now', glasses: glasses);
        break;
      case EntryType.meal:
        final name = _mealNameController.text.trim();
        final cal = int.tryParse(_caloriesController.text) ?? 0;
        if (name.isEmpty) return;
        entry = HealthEntry(type: EntryType.meal, time: 'Now', mealName: name, calories: cal);
        break;
      case EntryType.sleep:
        final hrs = double.tryParse(_hoursController.text) ?? 0;
        if (hrs <= 0) return;
        entry = HealthEntry(type: EntryType.sleep, time: 'Now', hours: hrs);
        break;
      case EntryType.mood:
        if (_selectedMood == null) return;
        entry = HealthEntry(type: EntryType.mood, time: 'Now', mood: _selectedMood);
        break;
    }
    if (entry != null) {
      Navigator.pop(context, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<EntryType>(
              segments: const [
                ButtonSegment(value: EntryType.water, label: Text('Water')),
                ButtonSegment(value: EntryType.meal, label: Text('Meal')),
                ButtonSegment(value: EntryType.sleep, label: Text('Sleep')),
                ButtonSegment(value: EntryType.mood, label: Text('Mood')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                });
              },
            ),
            const SizedBox(height: 24),
            ..._buildFields(),
            const Spacer(),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (_selectedType) {
      case EntryType.water:
        return [
          TextField(
            controller: _glassesController,
            decoration: const InputDecoration(
              labelText: 'Glasses',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ];
      case EntryType.meal:
        return [
          TextField(
            controller: _mealNameController,
            decoration: const InputDecoration(
              labelText: 'Meal Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'Calories',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ];
      case EntryType.sleep:
        return [
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(
              labelText: 'Hours',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ];
      case EntryType.mood:
        return [
          Wrap(
            spacing: 8,
            children: MoodValue.values.map((m) {
              return ChoiceChip(
                label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
                selected: _selectedMood == m,
                onSelected: (selected) {
                  setState(() {
                    _selectedMood = selected ? m : null;
                  });
                },
              );
            }).toList(),
          ),
        ];
    }
  }
}

class GoalsScreen extends StatelessWidget {
  final int totalWater;
  final int totalCalories;
  final double totalSleep;

  const GoalsScreen({
    super.key,
    required this.totalWater,
    required this.totalCalories,
    required this.totalSleep,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _goalCard(
              context,
              icon: Icons.water_drop,
              title: 'Water',
              current: totalWater,
              target: 8,
              unit: 'glasses',
            ),
            const SizedBox(height: 16),
            _goalCard(
              context,
              icon: Icons.local_fire_department,
              title: 'Calories',
              current: totalCalories,
              target: 2000,
              unit: 'cal',
            ),
            const SizedBox(height: 16),
            _goalCard(
              context,
              icon: Icons.bedtime,
              title: 'Sleep',
              current: totalSleep.round(),
              target: 8,
              unit: 'hours',
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int current,
    required int target,
    required String unit,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$current / $target $unit'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }
}
