import 'package:flutter/material.dart';

void main() {
  runApp(const MoodTrackerApp());
}

// --- Data Model ---

class MoodEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String note;
  final List<String> activities;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.note,
    required this.activities,
  });
}

const List<String> allMoods = ['\u{1F60A}', '\u{1F610}', '\u{1F622}', '\u{1F621}', '\u{1F634}'];
const Map<String, String> moodLabels = {
  '\u{1F60A}': 'Happy',
  '\u{1F610}': 'Neutral',
  '\u{1F622}': 'Sad',
  '\u{1F621}': 'Angry',
  '\u{1F634}': 'Tired',
};
const List<String> allActivities = [
  'Exercise',
  'Work',
  'Social',
  'Creative',
  'Outdoors',
  'Reading',
];

// --- App ---

class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- State holder ---

class _AppState {
  static final List<MoodEntry> entries = _buildSampleEntries();

  static List<MoodEntry> _buildSampleEntries() {
    final now = DateTime.now();
    return [
      MoodEntry(
        id: '1',
        date: now.subtract(const Duration(days: 5)),
        mood: '\u{1F60A}',
        note: 'Had a great morning run and felt energized all day',
        activities: ['Exercise', 'Outdoors'],
      ),
      MoodEntry(
        id: '2',
        date: now.subtract(const Duration(days: 4)),
        mood: '\u{1F610}',
        note: 'Regular work day, nothing special happened',
        activities: ['Work'],
      ),
      MoodEntry(
        id: '3',
        date: now.subtract(const Duration(days: 3)),
        mood: '\u{1F622}',
        note: 'Missing old friends, feeling lonely this evening',
        activities: ['Reading'],
      ),
      MoodEntry(
        id: '4',
        date: now.subtract(const Duration(days: 2)),
        mood: '\u{1F621}',
        note: 'Frustrated with a bug at work that took hours to fix',
        activities: ['Work', 'Creative'],
      ),
      MoodEntry(
        id: '5',
        date: now.subtract(const Duration(days: 1)),
        mood: '\u{1F634}',
        note: 'Could not sleep well last night, dragged through the day',
        activities: ['Work', 'Reading'],
      ),
      MoodEntry(
        id: '6',
        date: now,
        mood: '\u{1F60A}',
        note: 'Wonderful brunch with friends at the park',
        activities: ['Social', 'Outdoors', 'Exercise'],
      ),
    ];
  }
}

// --- HomeScreen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  List<MoodEntry> get _filteredEntries {
    if (_selectedFilter == 'All') return _AppState.entries;
    final moodEmoji = moodLabels.entries
        .firstWhere((e) => e.value == _selectedFilter)
        .key;
    return _AppState.entries.where((e) => e.mood == moodEmoji).toList();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Happy', 'Neutral', 'Sad', 'Angry', 'Tired'];
    final entries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Statistics') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(),
                  ),
                );
              } else if (value == 'Activities') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivitiesScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Statistics', child: Text('Statistics')),
              PopupMenuItem(value: 'Activities', child: Text('Activities')),
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
              children: filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No entries for this filter'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Text(
                            entry.mood,
                            style: const TextStyle(fontSize: 32),
                          ),
                          title: Text(_formatDate(entry.date)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: entry.activities
                                    .map((a) => Chip(
                                          label: Text(a),
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(entry: entry),
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMoodScreen()),
          );
          setState(() {});
        },
        label: const Text('Add Mood'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- DetailScreen ---

class DetailScreen extends StatelessWidget {
  final MoodEntry entry;

  const DetailScreen({super.key, required this.entry});

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                entry.mood,
                style: const TextStyle(fontSize: 72),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _formatDate(entry.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Note',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(entry.note, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  entry.activities.map((a) => Chip(label: Text(a))).toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _AppState.entries.removeWhere((e) => e.id == entry.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AddMoodScreen ---

class AddMoodScreen extends StatefulWidget {
  const AddMoodScreen({super.key});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  String? _selectedMood;
  final _noteController = TextEditingController();
  final Set<String> _selectedActivities = {};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Mood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: allMoods.map((mood) {
                final isSelected = _selectedMood == mood;
                return ElevatedButton(
                  onPressed: () => setState(() => _selectedMood = mood),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Text(mood, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: allActivities.map((activity) {
                return FilterChip(
                  label: Text(activity),
                  selected: _selectedActivities.contains(activity),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedActivities.add(activity);
                      } else {
                        _selectedActivities.remove(activity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _selectedMood == null
                    ? null
                    : () {
                        final entry = MoodEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          date: DateTime.now(),
                          mood: _selectedMood!,
                          note: _noteController.text,
                          activities: _selectedActivities.toList(),
                        );
                        _AppState.entries.add(entry);
                        Navigator.pop(context);
                      },
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- StatisticsScreen ---

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = _AppState.entries;
    final total = entries.length;

    final Map<String, int> moodCounts = {};
    for (final mood in allMoods) {
      moodCounts[mood] = entries.where((e) => e.mood == mood).length;
    }

    String mostCommon = 'None';
    if (entries.isNotEmpty) {
      final sorted = moodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostCommon =
          '${sorted.first.key} ${moodLabels[sorted.first.key]} (${sorted.first.value})';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total entries: $total',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Most common mood: $mostCommon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Mood Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...allMoods.map((mood) {
              final count = moodCounts[mood] ?? 0;
              final label = moodLabels[mood]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text(mood, style: const TextStyle(fontSize: 28)),
                  title: Text('$label: $count entries'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- ActivitiesScreen ---

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = _AppState.entries;

    final Map<String, int> activityCounts = {};
    for (final activity in allActivities) {
      activityCounts[activity] =
          entries.where((e) => e.activities.contains(activity)).length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: allActivities.map((activity) {
          final count = activityCounts[activity] ?? 0;
          return ListTile(
            title: Text(activity),
            trailing: Text(
              '$count entries',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }).toList(),
      ),
    );
  }
}
