import 'package:flutter/material.dart';

void main() {
  runApp(const MealLogApp());
}

// --- Data Models ---

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
      case MealType.snack: return 'Snack';
    }
  }
}

class MealEntry {
  final String id;
  final String name;
  final MealType type;
  final int calories;
  final String notes;
  final DateTime date;

  MealEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    this.notes = '',
    required this.date,
  });
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<MealEntry> _meals = [
    MealEntry(id: '1', name: 'Oatmeal with Berries', type: MealType.breakfast, calories: 350, notes: 'Added honey', date: DateTime.now()),
    MealEntry(id: '2', name: 'Grilled Chicken Salad', type: MealType.lunch, calories: 480, notes: 'Caesar dressing', date: DateTime.now()),
    MealEntry(id: '3', name: 'Salmon with Rice', type: MealType.dinner, calories: 620, notes: 'Teriyaki sauce', date: DateTime.now()),
    MealEntry(id: '4', name: 'Greek Yogurt', type: MealType.snack, calories: 150, notes: 'With granola', date: DateTime.now()),
    MealEntry(id: '5', name: 'Scrambled Eggs', type: MealType.breakfast, calories: 280, date: DateTime.now().subtract(const Duration(days: 1))),
    MealEntry(id: '6', name: 'Turkey Sandwich', type: MealType.lunch, calories: 420, date: DateTime.now().subtract(const Duration(days: 1))),
    MealEntry(id: '7', name: 'Pasta Primavera', type: MealType.dinner, calories: 550, date: DateTime.now().subtract(const Duration(days: 1))),
  ];

  int _dailyGoal = 2000;

  List<MealEntry> get meals => List.unmodifiable(_meals);
  int get dailyGoal => _dailyGoal;

  List<MealEntry> get todayMeals {
    final now = DateTime.now();
    return _meals.where((m) => m.date.year == now.year && m.date.month == now.month && m.date.day == now.day).toList();
  }

  int get todayCalories => todayMeals.fold(0, (sum, m) => sum + m.calories);
  int get totalCalories => _meals.fold(0, (sum, m) => sum + m.calories);
  int get totalMeals => _meals.length;

  Map<MealType, int> get caloriesByType {
    final map = <MealType, int>{};
    for (final m in todayMeals) {
      map[m.type] = (map[m.type] ?? 0) + m.calories;
    }
    return map;
  }

  void addMeal(MealEntry meal) {
    _meals.insert(0, meal);
    notifyListeners();
  }

  void deleteMeal(String id) {
    _meals.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal;
    notifyListeners();
  }
}

// --- App ---

class MealLogApp extends StatefulWidget {
  const MealLogApp({super.key});

  @override
  State<MealLogApp> createState() => _MealLogAppState();
}

class _MealLogAppState extends State<MealLogApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: MainScreen(state: _state),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(state: widget.state),
      HistoryPage(state: widget.state),
      SettingsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- Today Page ---

class TodayPage extends StatelessWidget {
  final AppState state;
  const TodayPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final todayMeals = state.todayMeals;
    final remaining = state.dailyGoal - state.todayCalories;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${state.todayCalories} / ${state.dailyGoal} cal', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: state.dailyGoal == 0 ? 0 : (state.todayCalories / state.dailyGoal).clamp(0.0, 1.0)),
                  const SizedBox(height: 8),
                  Text(remaining > 0 ? '$remaining cal remaining' : 'Goal reached!'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Meals', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (todayMeals.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No meals logged today')))
          else
            ...todayMeals.map((meal) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(meal.name),
                subtitle: Text('${meal.type.label} · ${meal.calories} cal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailPage(state: state, meal: meal))),
              ),
            )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final notesController = TextEditingController();
    MealType type = MealType.lunch;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Meal Name')),
              const SizedBox(height: 12),
              TextField(controller: calController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<MealType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: MealType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                state.addMeal(MealEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  type: type,
                  calories: int.tryParse(calController.text) ?? 0,
                  notes: notesController.text,
                  date: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- Meal Detail Page ---

class MealDetailPage extends StatelessWidget {
  final AppState state;
  final MealEntry meal;
  const MealDetailPage({super.key, required this.state, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              state.deleteMeal(meal.id);
              Navigator.pop(context);
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Type', value: meal.type.label),
                  _DetailRow(label: 'Calories', value: '${meal.calories} cal'),
                  if (meal.notes.isNotEmpty) _DetailRow(label: 'Notes', value: meal.notes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// --- History Page ---

class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Total Meals', value: '${state.totalMeals}'),
                  _SummaryRow(label: 'Total Calories', value: '${state.totalCalories} cal'),
                  _SummaryRow(label: 'Daily Average', value: '${state.totalMeals > 0 ? state.totalCalories ~/ 2 : 0} cal'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('All Meals', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...state.meals.map((meal) {
            final daysDiff = DateTime.now().difference(meal.date).inDays;
            final when = daysDiff == 0 ? 'Today' : daysDiff == 1 ? 'Yesterday' : '$daysDiff days ago';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(meal.name),
                subtitle: Text('${meal.type.label} · ${meal.calories} cal'),
                trailing: Text(when),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}

// --- Settings Page ---

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Daily Calorie Goal'),
            subtitle: Text('${state.dailyGoal} calories'),
            leading: const Icon(Icons.track_changes),
            onTap: () => _showGoalDialog(context),
          ),
          ListTile(
            title: const Text('Reminders'),
            subtitle: const Text('Meal logging reminders'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Meal Log v1.0'),
            leading: const Icon(Icons.info),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About'),
                content: const Text('Meal Log helps you track your daily food intake and monitor your calorie goals.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final controller = TextEditingController(text: '${state.dailyGoal}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Calorie Goal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Daily calories'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                state.setDailyGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
