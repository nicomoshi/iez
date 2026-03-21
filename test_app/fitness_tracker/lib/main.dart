import 'package:flutter/material.dart';

void main() => runApp(const FitnessTrackerApp());

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const FitnessHome(),
    );
  }
}

class Exercise {
  final String name;
  final String category; // Cardio, Strength, Flexibility, HIIT
  final int duration; // minutes
  final int calories;
  final String date;
  bool completed;
  Exercise({
    required this.name,
    required this.category,
    required this.duration,
    required this.calories,
    required this.date,
    this.completed = false,
  });
}

class FitnessHome extends StatefulWidget {
  const FitnessHome({super.key});
  @override
  State<FitnessHome> createState() => _FitnessHomeState();
}

class _FitnessHomeState extends State<FitnessHome> {
  int _currentIndex = 0;
  String _filter = 'All';
  final List<Exercise> _exercises = [
    Exercise(name: 'Morning Run', category: 'Cardio', duration: 30, calories: 300, date: 'Today'),
    Exercise(name: 'Bench Press', category: 'Strength', duration: 20, calories: 150, date: 'Today'),
    Exercise(name: 'Yoga Flow', category: 'Flexibility', duration: 45, calories: 180, date: 'Today'),
    Exercise(name: 'Burpees', category: 'HIIT', duration: 15, calories: 200, date: 'Today'),
    Exercise(name: 'Evening Walk', category: 'Cardio', duration: 40, calories: 200, date: 'Yesterday'),
    Exercise(name: 'Deadlifts', category: 'Strength', duration: 25, calories: 180, date: 'Yesterday'),
    Exercise(name: 'Stretching', category: 'Flexibility', duration: 20, calories: 80, date: 'Yesterday'),
  ];

  List<Exercise> get _filtered {
    if (_filter == 'All') return _exercises;
    return _exercises.where((e) => e.category == _filter).toList();
  }

  int get _totalCalories => _exercises.where((e) => e.completed).fold(0, (s, e) => s + e.calories);
  int get _totalMinutes => _exercises.where((e) => e.completed).fold(0, (s, e) => s + e.duration);
  int get _completedCount => _exercises.where((e) => e.completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => StatsPage(
                  exercises: _exercises,
                  totalCalories: _totalCalories,
                  totalMinutes: _totalMinutes,
                  completedCount: _completedCount,
                ))),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => HistoryPage(
                  exercises: _exercises.where((e) => e.date == 'Yesterday').toList(),
                ))),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildWorkoutsTab(),
          _buildProgressTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Progress'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              tooltip: 'Add Exercise',
              onPressed: () async {
                final result = await Navigator.push<Map<String, dynamic>>(context,
                    MaterialPageRoute(builder: (_) => const AddExercisePage()));
                if (result != null) {
                  setState(() => _exercises.insert(0, Exercise(
                    name: result['name'],
                    category: result['category'],
                    duration: result['duration'],
                    calories: result['calories'],
                    date: 'Today',
                  )));
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildWorkoutsTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCol('$_totalCalories', 'Calories'),
                _statCol('$_totalMinutes', 'Minutes'),
                _statCol('$_completedCount', 'Done'),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: ['All', 'Cardio', 'Strength', 'Flexibility', 'HIIT'].map((f) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FilterChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No exercises found'))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final ex = _filtered[i];
                    return CheckboxListTile(
                      title: Text(ex.name),
                      subtitle: Text('${ex.category} · ${ex.duration} min · ${ex.calories} cal'),
                      secondary: Icon(_catIcon(ex.category)),
                      value: ex.completed,
                      onChanged: (v) => setState(() => ex.completed = v ?? false),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final categories = ['Cardio', 'Strength', 'Flexibility', 'HIIT'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Weekly Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final catExercises = _exercises.where((e) => e.category == cat).toList();
          final completed = catExercises.where((e) => e.completed).length;
          final total = catExercises.length;
          final progress = total > 0 ? completed / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress, minHeight: 8),
                const SizedBox(height: 4),
                Text('$completed / $total completed'),
              ],
            ),
          );
        }),
        const Divider(height: 32),
        const Text('Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.local_fire_department, color: Colors.orange),
          title: const Text('Burn 500 calories'),
          subtitle: Text('$_totalCalories / 500 cal'),
          trailing: _totalCalories >= 500
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined),
        ),
        ListTile(
          leading: const Icon(Icons.timer, color: Colors.blue),
          title: const Text('Exercise 60 minutes'),
          subtitle: Text('$_totalMinutes / 60 min'),
          trailing: _totalMinutes >= 60
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined),
        ),
        ListTile(
          leading: const Icon(Icons.done_all, color: Colors.purple),
          title: const Text('Complete 5 exercises'),
          subtitle: Text('$_completedCount / 5 done'),
          trailing: _completedCount >= 5
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined),
        ),
      ],
    );
  }

  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Cardio': return Icons.directions_run;
      case 'Strength': return Icons.fitness_center;
      case 'Flexibility': return Icons.self_improvement;
      case 'HIIT': return Icons.flash_on;
      default: return Icons.sports;
    }
  }
}

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});
  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _nameCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _caloriesCtrl = TextEditingController(text: '150');
  String _category = 'Cardio';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Exercise name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Cardio', 'Strength', 'Flexibility', 'HIIT'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationCtrl,
              decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesCtrl,
              decoration: const InputDecoration(labelText: 'Calories', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'name': _nameCtrl.text,
                      'category': _category,
                      'duration': int.tryParse(_durationCtrl.text) ?? 30,
                      'calories': int.tryParse(_caloriesCtrl.text) ?? 150,
                    });
                  }
                },
                child: const Text('Save Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  final List<Exercise> exercises;
  final int totalCalories;
  final int totalMinutes;
  final int completedCount;
  const StatsPage({
    super.key,
    required this.exercises,
    required this.totalCalories,
    required this.totalMinutes,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['Cardio', 'Strength', 'Flexibility', 'HIIT'];
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Total Exercises: ${exercises.length}'),
                  Text('Completed: $completedCount'),
                  Text('Total Calories: $totalCalories'),
                  Text('Total Minutes: $totalMinutes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('By Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...categories.map((cat) {
            final count = exercises.where((e) => e.category == cat).length;
            final cals = exercises.where((e) => e.category == cat).fold(0, (s, e) => s + e.calories);
            return ListTile(
              leading: Icon(_catIcon(cat)),
              title: Text(cat),
              subtitle: Text('$count exercises · $cals cal'),
            );
          }),
        ],
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Cardio': return Icons.directions_run;
      case 'Strength': return Icons.fitness_center;
      case 'Flexibility': return Icons.self_improvement;
      case 'HIIT': return Icons.flash_on;
      default: return Icons.sports;
    }
  }
}

class HistoryPage extends StatelessWidget {
  final List<Exercise> exercises;
  const HistoryPage({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yesterday')),
      body: exercises.isEmpty
          ? const Center(child: Text('No exercises yesterday'))
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (_, i) {
                final ex = exercises[i];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(ex.name),
                  subtitle: Text('${ex.category} · ${ex.duration} min · ${ex.calories} cal'),
                );
              },
            ),
    );
  }
}
