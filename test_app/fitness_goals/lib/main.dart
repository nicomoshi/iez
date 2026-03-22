import 'package:flutter/material.dart';

void main() {
  runApp(const FitnessGoalsApp());
}

class FitnessGoalsApp extends StatelessWidget {
  const FitnessGoalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Goals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class Goal {
  final String title;
  final String target;
  final String category;
  final int progressPercent;

  const Goal({
    required this.title,
    required this.target,
    this.category = 'Cardio',
    this.progressPercent = 0,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _selectedFilter = 'All';

  List<Goal> _goals = const [
    Goal(title: 'Run 5K', target: '30 min', category: 'Cardio', progressPercent: 65),
    Goal(title: '100 Push-ups', target: 'Daily', category: 'Strength', progressPercent: 40),
    Goal(title: 'Lose 5kg', target: '3 months', category: 'Cardio', progressPercent: 20),
    Goal(title: 'Swim 1km', target: 'Weekly', category: 'Cardio', progressPercent: 80),
  ];

  List<Goal> get _filteredGoals {
    if (_selectedFilter == 'All') return _goals;
    return _goals.where((g) => g.category == _selectedFilter).toList();
  }

  void _addGoal(Goal goal) {
    setState(() {
      _goals = [..._goals, goal];
    });
  }

  void _deleteGoal(Goal goal) {
    setState(() {
      _goals = _goals.where((g) => g.title != goal.title).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _GoalsTab(
            goals: _filteredGoals,
            selectedFilter: _selectedFilter,
            onFilterChanged: (f) => setState(() => _selectedFilter = f),
            onGoalTap: (goal) async {
              final deleted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => GoalDetailPage(goal: goal)),
              );
              if (deleted == true) _deleteGoal(goal);
            },
          ),
          const _ProgressTab(),
          const _AchievementsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final goal = await Navigator.push<Goal>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGoalPage()),
                );
                if (goal != null) _addGoal(goal);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Achievements'),
        ],
      ),
    );
  }
}

// --- Goals Tab ---

class _GoalsTab extends StatelessWidget {
  final List<Goal> goals;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<Goal> onGoalTap;

  const _GoalsTab({
    required this.goals,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Cardio', 'Strength', 'Flexibility'];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: filters.map((f) {
              final selected = f == selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => onFilterChanged(f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: goals.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return Card(
                child: ListTile(
                  title: Text(goal.title),
                  subtitle: Text('Target: ${goal.target}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onGoalTap(goal),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Goal Detail Page ---

class GoalDetailPage extends StatelessWidget {
  final Goal goal;

  const GoalDetailPage({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text('Target', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.track_changes),
                    const SizedBox(width: 12),
                    Text(goal.target, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Completion'),
                        Text('${goal.progressPercent}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: goal.progressPercent / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Progress Tab ---

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Progress', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Activity', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DayIndicator(day: 'M', active: true),
                    _DayIndicator(day: 'T', active: true),
                    _DayIndicator(day: 'W', active: false),
                    _DayIndicator(day: 'T', active: true),
                    _DayIndicator(day: 'F', active: false),
                    _DayIndicator(day: 'S', active: true),
                    _DayIndicator(day: 'S', active: false),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.local_fire_department, color: Colors.orange),
            title: Text('Calories Burned'),
            subtitle: Text('1,250 kcal this week'),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.directions_run, color: Colors.blue),
            title: Text('Distance'),
            subtitle: Text('12.5 km this week'),
          ),
        ),
      ],
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final bool active;

  const _DayIndicator({required this.day, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? Colors.green : Colors.grey.shade300,
          child: Text(day, style: TextStyle(color: active ? Colors.white : Colors.black54, fontSize: 12)),
        ),
      ],
    );
  }
}

// --- Achievements Tab ---

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'name': 'First Run', 'icon': Icons.directions_run, 'desc': 'Complete your first run'},
      {'name': 'Week Streak', 'icon': Icons.calendar_month, 'desc': '7 days in a row'},
      {'name': 'Early Bird', 'icon': Icons.wb_sunny, 'desc': 'Work out before 7 AM'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Achievements', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        ...achievements.map((a) => Card(
              child: ListTile(
                leading: Icon(a['icon'] as IconData, color: Colors.amber),
                title: Text(a['name'] as String),
                subtitle: Text(a['desc'] as String),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            )),
      ],
    );
  }
}

// --- Add Goal Page ---

class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _deadlineController = TextEditingController();
  String _category = 'Cardio';

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Goal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Goal Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ['Cardio', 'Strength', 'Flexibility']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetController,
            decoration: const InputDecoration(
              labelText: 'Target',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deadlineController,
            decoration: const InputDecoration(
              labelText: 'Deadline',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _targetController.text.isNotEmpty) {
                Navigator.pop(
                  context,
                  Goal(
                    title: _nameController.text,
                    target: _targetController.text,
                    category: _category,
                  ),
                );
              }
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Goals', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
