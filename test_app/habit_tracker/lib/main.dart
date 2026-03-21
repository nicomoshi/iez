import 'package:flutter/material.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class Habit {
  final String id;
  String name;
  int streak;
  int bestStreak;
  int totalCompletions;
  List<bool> weeklyProgress;
  bool completedToday;

  Habit({
    required this.id,
    required this.name,
    required this.streak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.weeklyProgress,
    this.completedToday = false,
  });
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Habit> _habits = [
    Habit(
      id: '1',
      name: 'Drink Water',
      streak: 3,
      bestStreak: 7,
      totalCompletions: 15,
      weeklyProgress: [true, true, true, false, true, true, false],
    ),
    Habit(
      id: '2',
      name: 'Exercise',
      streak: 5,
      bestStreak: 10,
      totalCompletions: 22,
      weeklyProgress: [true, false, true, true, true, true, false],
    ),
    Habit(
      id: '3',
      name: 'Read',
      streak: 2,
      bestStreak: 14,
      totalCompletions: 30,
      weeklyProgress: [false, true, true, false, false, true, true],
    ),
    Habit(
      id: '4',
      name: 'Meditate',
      streak: 7,
      bestStreak: 21,
      totalCompletions: 45,
      weeklyProgress: [true, true, true, true, true, true, true],
    ),
  ];

  void _addHabit(String name) {
    setState(() {
      _habits.add(Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        streak: 0,
        bestStreak: 0,
        totalCompletions: 0,
        weeklyProgress: [false, false, false, false, false, false, false],
      ));
    });
  }

  void _deleteHabit(String id) {
    setState(() {
      _habits.removeWhere((h) => h.id == id);
    });
  }

  void _toggleComplete(String id) {
    setState(() {
      final habit = _habits.firstWhere((h) => h.id == id);
      habit.completedToday = !habit.completedToday;
    });
  }

  void _showAddHabitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Habit Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _addHabit(name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
      ),
      body: _selectedIndex == 0
          ? TodayTab(
              habits: _habits,
              onDelete: _deleteHabit,
              onToggle: _toggleComplete,
            )
          : StatsTab(habits: _habits),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              tooltip: '+',
              onPressed: _showAddHabitDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

class TodayTab extends StatelessWidget {
  final List<Habit> habits;
  final void Function(String) onDelete;
  final void Function(String) onToggle;

  const TodayTab({
    super.key,
    required this.habits,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitCard(
          habit: habit,
          onDelete: () => onDelete(habit.id),
          onToggle: () => onToggle(habit.id),
        );
      },
    );
  }
}

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habit: habit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: habit.completedToday,
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${habit.streak} day streak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final done = habit.weeklyProgress[i];
                return Column(
                  children: [
                    Text(days[i], style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 32),
            Text(
              'Current Streak: ${habit.streak} days',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Best Streak: ${habit.bestStreak} days',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Completions: ${habit.totalCompletions}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsTab extends StatelessWidget {
  final List<Habit> habits;

  const StatsTab({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final completedToday = habits.where((h) => h.completedToday).length;
    final totalHabits = habits.length;

    // Overall completion rate: average of weekly progress across all habits
    double totalRate = 0;
    for (final habit in habits) {
      final done = habit.weeklyProgress.where((d) => d).length;
      totalRate += done / 7.0;
    }
    final overallRate = habits.isEmpty ? 0.0 : totalRate / habits.length;
    final ratePercent = (overallRate * 100).round();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          StatCard(label: 'Total Habits: $totalHabits'),
          const SizedBox(height: 12),
          StatCard(label: 'Completed Today: $completedToday'),
          const SizedBox(height: 12),
          StatCard(label: 'Overall Completion Rate: $ratePercent%'),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;

  const StatCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
