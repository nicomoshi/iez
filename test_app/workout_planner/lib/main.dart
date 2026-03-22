import 'package:flutter/material.dart';

void main() {
  runApp(const WorkoutPlannerApp());
}

// --- Data Models ---

enum MuscleGroup { chest, back, legs, shoulders, arms, core }

extension MuscleGroupLabel on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest: return 'Chest';
      case MuscleGroup.back: return 'Back';
      case MuscleGroup.legs: return 'Legs';
      case MuscleGroup.shoulders: return 'Shoulders';
      case MuscleGroup.arms: return 'Arms';
      case MuscleGroup.core: return 'Core';
    }
  }
  IconData get icon {
    switch (this) {
      case MuscleGroup.chest: return Icons.fitness_center;
      case MuscleGroup.back: return Icons.accessibility_new;
      case MuscleGroup.legs: return Icons.directions_run;
      case MuscleGroup.shoulders: return Icons.sports_gymnastics;
      case MuscleGroup.arms: return Icons.sports_martial_arts;
      case MuscleGroup.core: return Icons.self_improvement;
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final int sets;
  final int reps;
  final double weight;
  final bool isCompleted;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
    this.isCompleted = false,
  });

  Exercise copyWith({
    String? name,
    MuscleGroup? muscleGroup,
    int? sets,
    int? reps,
    double? weight,
    bool? isCompleted,
  }) => Exercise(
    id: id,
    name: name ?? this.name,
    muscleGroup: muscleGroup ?? this.muscleGroup,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

class WorkoutPlan {
  final String id;
  final String name;
  final String day;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.day,
    required this.exercises,
  });
}

// --- State ---

class AppState extends ChangeNotifier {
  final List<WorkoutPlan> _plans = [
    WorkoutPlan(
      id: '1',
      name: 'Push Day',
      day: 'Monday',
      exercises: [
        Exercise(id: 'e1', name: 'Bench Press', muscleGroup: MuscleGroup.chest, sets: 4, reps: 8, weight: 60),
        Exercise(id: 'e2', name: 'Overhead Press', muscleGroup: MuscleGroup.shoulders, sets: 3, reps: 10, weight: 40),
        Exercise(id: 'e3', name: 'Tricep Dips', muscleGroup: MuscleGroup.arms, sets: 3, reps: 12),
      ],
    ),
    WorkoutPlan(
      id: '2',
      name: 'Pull Day',
      day: 'Wednesday',
      exercises: [
        Exercise(id: 'e4', name: 'Deadlift', muscleGroup: MuscleGroup.back, sets: 4, reps: 6, weight: 100),
        Exercise(id: 'e5', name: 'Pull Ups', muscleGroup: MuscleGroup.back, sets: 3, reps: 8),
        Exercise(id: 'e6', name: 'Bicep Curls', muscleGroup: MuscleGroup.arms, sets: 3, reps: 12, weight: 15),
      ],
    ),
    WorkoutPlan(
      id: '3',
      name: 'Leg Day',
      day: 'Friday',
      exercises: [
        Exercise(id: 'e7', name: 'Squats', muscleGroup: MuscleGroup.legs, sets: 4, reps: 8, weight: 80),
        Exercise(id: 'e8', name: 'Leg Press', muscleGroup: MuscleGroup.legs, sets: 3, reps: 12, weight: 120),
        Exercise(id: 'e9', name: 'Plank', muscleGroup: MuscleGroup.core, sets: 3, reps: 60),
      ],
    ),
  ];

  List<WorkoutPlan> get plans => List.unmodifiable(_plans);
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void selectTab(int i) { _selectedTab = i; notifyListeners(); }

  void toggleExercise(String planId, String exerciseId) {
    final plan = _plans.firstWhere((p) => p.id == planId);
    final idx = plan.exercises.indexWhere((e) => e.id == exerciseId);
    if (idx >= 0) {
      plan.exercises[idx] = plan.exercises[idx].copyWith(
        isCompleted: !plan.exercises[idx].isCompleted,
      );
      notifyListeners();
    }
  }

  void addPlan(String name, String day) {
    _plans.add(WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      day: day,
      exercises: [],
    ));
    notifyListeners();
  }

  void addExercise(String planId, Exercise exercise) {
    final plan = _plans.firstWhere((p) => p.id == planId);
    plan.exercises.add(exercise);
    notifyListeners();
  }

  void deletePlan(String planId) {
    _plans.removeWhere((p) => p.id == planId);
    notifyListeners();
  }
}

// --- App ---

class WorkoutPlannerApp extends StatelessWidget {
  const WorkoutPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkoutPlanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.light,
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
  final _state = AppState();
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_currentTab == 0 ? 'My Workouts' : _currentTab == 1 ? 'Progress' : 'Settings'),
          ),
          body: _buildBody(),
          floatingActionButton: _currentTab == 0
              ? FloatingActionButton(
                  tooltip: 'Add Plan',
                  onPressed: () => _showAddPlanDialog(),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (i) => setState(() => _currentTab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workouts'),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0: return _buildWorkoutsTab();
      case 1: return _buildProgressTab();
      case 2: return _buildSettingsTab();
      default: return const SizedBox();
    }
  }

  Widget _buildWorkoutsTab() {
    if (_state.plans.isEmpty) {
      return const Center(child: Text('No workout plans yet.\nTap + to create one.'));
    }
    return ListView.builder(
      itemCount: _state.plans.length,
      itemBuilder: (context, index) {
        final plan = _state.plans[index];
        final completed = plan.exercises.where((e) => e.isCompleted).length;
        final total = plan.exercises.length;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(plan.name),
            subtitle: Text('${plan.day} • $completed/$total exercises done'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openPlanDetail(plan),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    final totalExercises = _state.plans.fold<int>(0, (sum, p) => sum + p.exercises.length);
    final completedExercises = _state.plans.fold<int>(0, (sum, p) => sum + p.exercises.where((e) => e.isCompleted).length);
    final percentage = totalExercises > 0 ? (completedExercises / totalExercises * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Progress', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: totalExercises > 0 ? completedExercises / totalExercises : 0,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  Center(child: Text('$percentage%', style: Theme.of(context).textTheme.headlineMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('$completedExercises of $totalExercises exercises completed'),
          const SizedBox(height: 16),
          Text('${_state.plans.length} workout plans'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Reset all exercises
              for (var plan in _state.plans) {
                for (int i = 0; i < plan.exercises.length; i++) {
                  if (plan.exercises[i].isCompleted) {
                    _state.toggleExercise(plan.id, plan.exercises[i].id);
                  }
                }
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Week'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Workout Reminders'),
          trailing: Switch(
            value: true,
            onChanged: (_) {},
          ),
        ),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('Rest Timer'),
          subtitle: const Text('90 seconds'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          trailing: Switch(
            value: false,
            onChanged: (_) {},
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          subtitle: const Text('WorkoutPlanner v1.0'),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'WorkoutPlanner',
            applicationVersion: '1.0.0',
          ),
        ),
      ],
    );
  }

  void _showAddPlanDialog() {
    final nameController = TextEditingController();
    String selectedDay = 'Monday';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Workout Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Plan Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedDay = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _state.addPlan(nameController.text, selectedDay);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlanDetail(WorkoutPlan plan) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlanDetailScreen(state: _state, planId: plan.id),
    ));
  }
}

// --- Plan Detail ---

class PlanDetailScreen extends StatelessWidget {
  final AppState state;
  final String planId;

  const PlanDetailScreen({super.key, required this.state, required this.planId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final plan = state.plans.firstWhere((p) => p.id == planId);
        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            actions: [
              IconButton(
                tooltip: 'Delete Plan',
                icon: const Icon(Icons.delete),
                onPressed: () {
                  state.deletePlan(planId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: plan.exercises.isEmpty
              ? const Center(child: Text('No exercises yet.\nTap + to add one.'))
              : ListView.builder(
                  itemCount: plan.exercises.length,
                  itemBuilder: (context, index) {
                    final ex = plan.exercises[index];
                    return CheckboxListTile(
                      title: Text(ex.name),
                      subtitle: Text('${ex.sets}×${ex.reps} ${ex.weight > 0 ? "@ ${ex.weight}kg" : ""} • ${ex.muscleGroup.label}'),
                      value: ex.isCompleted,
                      onChanged: (_) => state.toggleExercise(planId, ex.id),
                      secondary: Icon(ex.muscleGroup.icon),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add Exercise',
            onPressed: () => _showAddExerciseDialog(context, plan),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context, WorkoutPlan plan) {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    MuscleGroup selectedGroup = MuscleGroup.chest;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MuscleGroup>(
                  value: selectedGroup,
                  decoration: const InputDecoration(labelText: 'Muscle Group'),
                  items: MuscleGroup.values
                      .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedGroup = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: setsController,
                      decoration: const InputDecoration(labelText: 'Sets'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: repsController,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  state.addExercise(plan.id, Exercise(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    muscleGroup: selectedGroup,
                    sets: int.tryParse(setsController.text) ?? 3,
                    reps: int.tryParse(repsController.text) ?? 10,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
