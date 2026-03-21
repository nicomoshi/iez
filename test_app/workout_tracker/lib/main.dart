import 'package:flutter/material.dart';

void main() {
  runApp(const WorkoutTrackerApp());
}

// --- Data Models ---

class Exercise {
  final String name;
  final String category;
  final int sets;
  final int reps;
  final double weight;

  const Exercise({
    required this.name,
    required this.category,
    this.sets = 3,
    this.reps = 12,
    this.weight = 0,
  });
}

class WorkoutRecord {
  final String date;
  final String title;
  final int exerciseCount;
  final int durationMin;

  const WorkoutRecord({
    required this.date,
    required this.title,
    required this.exerciseCount,
    required this.durationMin,
  });
}

class SetEntry {
  int reps;
  double weight;
  SetEntry({this.reps = 12, this.weight = 0});
}

// --- Data ---

final Map<String, List<Exercise>> exercisesByCategory = {
  'Chest': [
    const Exercise(name: 'Bench Press', category: 'Chest', sets: 3, reps: 12),
    const Exercise(name: 'Incline Press', category: 'Chest', sets: 3, reps: 10),
    const Exercise(name: 'Chest Fly', category: 'Chest', sets: 3, reps: 15),
  ],
  'Back': [
    const Exercise(name: 'Pull Up', category: 'Back', sets: 3, reps: 10),
    const Exercise(name: 'Barbell Row', category: 'Back', sets: 3, reps: 12),
    const Exercise(name: 'Lat Pulldown', category: 'Back', sets: 3, reps: 12),
  ],
  'Legs': [
    const Exercise(name: 'Squat', category: 'Legs', sets: 4, reps: 10),
    const Exercise(name: 'Deadlift', category: 'Legs', sets: 3, reps: 8),
    const Exercise(name: 'Leg Press', category: 'Legs', sets: 3, reps: 12),
  ],
  'Arms': [
    const Exercise(name: 'Bicep Curl', category: 'Arms', sets: 3, reps: 12),
    const Exercise(name: 'Tricep Extension', category: 'Arms', sets: 3, reps: 12),
    const Exercise(name: 'Hammer Curl', category: 'Arms', sets: 3, reps: 10),
  ],
  'Shoulders': [
    const Exercise(name: 'Overhead Press', category: 'Shoulders', sets: 3, reps: 10),
    const Exercise(name: 'Lateral Raise', category: 'Shoulders', sets: 3, reps: 15),
    const Exercise(name: 'Face Pull', category: 'Shoulders', sets: 3, reps: 15),
  ],
  'Core': [
    const Exercise(name: 'Plank', category: 'Core', sets: 3, reps: 60),
    const Exercise(name: 'Crunches', category: 'Core', sets: 3, reps: 20),
    const Exercise(name: 'Russian Twist', category: 'Core', sets: 3, reps: 20),
  ],
};

final List<WorkoutRecord> workoutHistory = [
  const WorkoutRecord(date: 'Mar 20', title: 'Chest Day', exerciseCount: 4, durationMin: 45),
  const WorkoutRecord(date: 'Mar 19', title: 'Leg Day', exerciseCount: 3, durationMin: 50),
  const WorkoutRecord(date: 'Mar 18', title: 'Back & Biceps', exerciseCount: 5, durationMin: 55),
];

// --- App ---

class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = exercisesByCategory.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
            child: const Text('History'),
          ),
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddWorkoutScreen())),
            child: const Text('Add Workout'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Text('Workout Stats'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Summary",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        Text('3', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Exercises'),
                      ]),
                      Column(children: [
                        Text('9', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Total Sets'),
                      ]),
                      Column(children: [
                        Text('45 min', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Duration'),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Category cards
          ...categories.map((cat) => Card(
                child: ListTile(
                  title: Text(cat),
                  subtitle: Text('${exercisesByCategory[cat]!.length} exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ExerciseListScreen(category: cat)),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// --- Exercise List Screen ---

class ExerciseListScreen extends StatelessWidget {
  final String category;
  const ExerciseListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final exercises = exercisesByCategory[category] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final ex = exercises[index];
          return ListTile(
            title: Text(ex.name),
            subtitle: Text('${ex.sets} sets \u00d7 ${ex.reps} reps'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(exercise: ex)),
            ),
          );
        },
      ),
    );
  }
}

// --- Exercise Detail Screen ---

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late List<SetEntry> sets;
  bool timerRunning = false;
  int timerSeconds = 0;

  @override
  void initState() {
    super.initState();
    sets = List.generate(
        widget.exercise.sets, (_) => SetEntry(reps: widget.exercise.reps));
  }

  void _startTimer() {
    setState(() {
      timerRunning = !timerRunning;
    });
    if (timerRunning) {
      _tick();
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (timerRunning && mounted) {
        setState(() => timerSeconds++);
        _tick();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exercise.category,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            // Timer
            Row(
              children: [
                Text(_formatTime(timerSeconds),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _startTimer,
                  child: Text(timerRunning ? 'Pause' : 'Start Timer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sets table
            Text('Sets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                const TableRow(children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Weight', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
                ...sets.asMap().entries.map((entry) => TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${entry.key + 1}')),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${entry.value.reps}')),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${entry.value.weight} lbs')),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  sets.add(SetEntry(reps: widget.exercise.reps));
                });
              },
              child: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Workout Screen ---

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  String? selectedCategory;
  final exerciseNameController = TextEditingController();
  final setsController = TextEditingController(text: '3');
  final repsController = TextEditingController(text: '12');
  final weightController = TextEditingController(text: '0');

  @override
  void dispose() {
    exerciseNameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = exercisesByCategory.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Workout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Category'),
            value: selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => selectedCategory = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: exerciseNameController,
            decoration: const InputDecoration(labelText: 'Exercise Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: setsController,
            decoration: const InputDecoration(labelText: 'Sets'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: 'Reps'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: 'Weight (lbs)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (selectedCategory != null &&
                  exerciseNameController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout saved!')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Workout'),
          ),
        ],
      ),
    );
  }
}

// --- History Screen ---

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.builder(
        itemCount: workoutHistory.length,
        itemBuilder: (context, index) {
          final record = workoutHistory[index];
          return ListTile(
            title: Text(record.title),
            subtitle: Text(
                '${record.date} \u2022 ${record.exerciseCount} exercises \u2022 ${record.durationMin} min'),
          );
        },
      ),
    );
  }
}

// --- Stats Screen ---

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Workouts'),
                trailing: Text('${workoutHistory.length}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('Favorite Exercise'),
                trailing: Text('Bench Press',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('Current Streak'),
                trailing: Text('3 days',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Total Duration'),
                trailing: Text(
                    '${workoutHistory.fold<int>(0, (sum, r) => sum + r.durationMin)} min',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
