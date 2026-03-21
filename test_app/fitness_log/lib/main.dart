import 'package:flutter/material.dart';

void main() => runApp(const FitnessLogApp());

// --- Data Model ---

enum WorkoutType { strength, cardio, flexibility, hiit, sports }

extension WorkoutTypeExt on WorkoutType {
  String get label {
    switch (this) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.flexibility:
        return 'Flexibility';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.sports:
        return 'Sports';
    }
  }
}

class Workout {
  final String id;
  final String name;
  final DateTime date;
  final WorkoutType type;
  final int duration;
  final int calories;
  final List<String> exercises;
  final String notes;

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.duration,
    required this.calories,
    required this.exercises,
    this.notes = '',
  });
}

// --- Exercise Library ---

const Map<String, String> exerciseLibrary = {
  'Push-ups': 'Bodyweight upper body exercise targeting chest, shoulders, and triceps.',
  'Squats': 'Compound lower body exercise targeting quads, glutes, and hamstrings.',
  'Bench Press': 'Barbell chest exercise for building upper body strength.',
  'Deadlift': 'Full body compound lift targeting posterior chain muscles.',
  'Running': 'Cardiovascular endurance exercise for heart health and stamina.',
  'Cycling': 'Low-impact cardio exercise great for leg strength and endurance.',
  'Stretching': 'Flexibility exercise to improve range of motion and recovery.',
  'Burpees': 'Full body high-intensity exercise combining squat, plank, and jump.',
};

// --- App State ---

class WorkoutStore extends ChangeNotifier {
  final List<Workout> _workouts = _seedWorkouts();

  List<Workout> get workouts => List.unmodifiable(_workouts);

  void add(Workout w) {
    _workouts.insert(0, w);
    notifyListeners();
  }

  void remove(String id) {
    _workouts.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  static List<Workout> _seedWorkouts() {
    return [
      Workout(
        id: '1',
        name: 'Morning Strength',
        date: DateTime(2026, 3, 22),
        type: WorkoutType.strength,
        duration: 45,
        calories: 320,
        exercises: ['Bench Press', 'Squats', 'Deadlift'],
        notes: 'Felt strong today. Increased bench press weight.',
      ),
      Workout(
        id: '2',
        name: 'Cardio Blast',
        date: DateTime(2026, 3, 21),
        type: WorkoutType.cardio,
        duration: 30,
        calories: 280,
        exercises: ['Running', 'Cycling'],
        notes: 'Good pace on the treadmill.',
      ),
      Workout(
        id: '3',
        name: 'HIIT Circuit',
        date: DateTime(2026, 3, 20),
        type: WorkoutType.hiit,
        duration: 25,
        calories: 350,
        exercises: ['Burpees', 'Squats', 'Push-ups'],
        notes: 'Intense session, kept rest periods short.',
      ),
      Workout(
        id: '4',
        name: 'Yoga Flow',
        date: DateTime(2026, 3, 19),
        type: WorkoutType.flexibility,
        duration: 60,
        calories: 150,
        exercises: ['Stretching'],
        notes: 'Relaxing evening session.',
      ),
      Workout(
        id: '5',
        name: 'Basketball Game',
        date: DateTime(2026, 3, 18),
        type: WorkoutType.sports,
        duration: 90,
        calories: 500,
        exercises: ['Running', 'Squats'],
        notes: 'Pickup game at the gym.',
      ),
      Workout(
        id: '6',
        name: 'Upper Body Push',
        date: DateTime(2026, 3, 17),
        type: WorkoutType.strength,
        duration: 50,
        calories: 290,
        exercises: ['Bench Press', 'Push-ups'],
        notes: 'Focused on form over weight.',
      ),
    ];
  }
}

// --- App Root ---

class FitnessLogApp extends StatelessWidget {
  const FitnessLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: HomeScreen(store: _globalStore),
    );
  }
}

final WorkoutStore _globalStore = WorkoutStore();

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  final WorkoutStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Strength',
    'Cardio',
    'Flexibility',
    'HIIT',
    'Sports',
  ];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  List<Workout> get _filteredWorkouts {
    if (_selectedFilter == 'All') return widget.store.workouts;
    return widget.store.workouts
        .where((w) => w.type.label == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _filteredWorkouts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Log'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Summary') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryScreen(store: widget.store),
                  ),
                );
              } else if (value == 'Exercise Library') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExerciseLibraryScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Summary', child: Text('Summary')),
              PopupMenuItem(
                  value: 'Exercise Library', child: Text('Exercise Library')),
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
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: workouts.isEmpty
                ? const Center(child: Text('No workouts found.'))
                : ListView.builder(
                    itemCount: workouts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final w = workouts[index];
                      return Card(
                        child: ListTile(
                          title: Text(w.name),
                          subtitle: Text(
                            '${w.date.month}/${w.date.day}/${w.date.year} \u2022 ${w.duration} min',
                          ),
                          trailing: Text(
                            '${w.calories} cal',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(workout: w, store: widget.store),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddWorkoutScreen(store: widget.store),
            ),
          );
        },
        label: const Text('Add Workout'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatelessWidget {
  final Workout workout;
  final WorkoutStore store;
  const DetailScreen({super.key, required this.workout, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${workout.date.month}/${workout.date.day}/${workout.date.year}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Chip(label: Text(workout.type.label)),
            const SizedBox(height: 12),
            Text(
              'Duration: ${workout.duration} min',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Calories: ${workout.calories}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  workout.exercises.map((e) => Chip(label: Text(e))).toList(),
            ),
            if (workout.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(workout.notes),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  store.remove(workout.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Delete Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Workout Screen ---

class AddWorkoutScreen extends StatefulWidget {
  final WorkoutStore store;
  const AddWorkoutScreen({super.key, required this.store});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  WorkoutType _selectedType = WorkoutType.strength;
  final Set<String> _selectedExercises = {};

  final List<String> _availableExercises = exerciseLibrary.keys.toList();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      date: DateTime.now(),
      type: _selectedType,
      duration: int.tryParse(_durationController.text.trim()) ?? 0,
      calories: int.tryParse(_caloriesController.text.trim()) ?? 0,
      exercises: _selectedExercises.toList(),
      notes: _notesController.text.trim(),
    );
    widget.store.add(workout);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Workout Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WorkoutType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: WorkoutType.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (min)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableExercises.map((e) {
                  final selected = _selectedExercises.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedExercises.add(e);
                        } else {
                          _selectedExercises.remove(e);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Summary Screen ---

class SummaryScreen extends StatelessWidget {
  final WorkoutStore store;
  const SummaryScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final workouts = store.workouts;
    final totalWorkouts = workouts.length;
    final totalDuration = workouts.fold<int>(0, (s, w) => s + w.duration);
    final totalCalories = workouts.fold<int>(0, (s, w) => s + w.calories);

    final Map<String, int> byType = {};
    for (final w in workouts) {
      byType[w.type.label] = (byType[w.type.label] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Total Workouts'),
            trailing: Text('$totalWorkouts'),
          ),
          ListTile(
            title: const Text('Total Duration'),
            trailing: Text('$totalDuration min'),
          ),
          ListTile(
            title: const Text('Total Calories'),
            trailing: Text('$totalCalories'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Breakdown by Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...byType.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}'),
              )),
        ],
      ),
    );
  }
}

// --- Exercise Library Screen ---

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = exerciseLibrary.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Library')),
      body: ListView.builder(
        itemCount: entries.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final e = entries[index];
          return Card(
            child: ListTile(
              title: Text(e.key),
              subtitle: Text(e.value),
            ),
          );
        },
      ),
    );
  }
}
