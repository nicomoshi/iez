import 'package:flutter/material.dart';

void main() => runApp(const HabitLogApp());

class HabitLogApp extends StatelessWidget {
  const HabitLogApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HabitHome(),
    );
  }
}

class Habit {
  final String name;
  final String category;
  final IconData icon;
  int streak;
  bool completedToday;
  Habit({
    required this.name,
    required this.category,
    required this.icon,
    required this.streak,
    this.completedToday = false,
  });
}

class HabitHome extends StatefulWidget {
  const HabitHome({super.key});
  @override
  State<HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends State<HabitHome> {
  int _currentIndex = 0;
  final List<Habit> _habits = [
    Habit(name: 'Morning Meditation', category: 'Wellness', icon: Icons.self_improvement, streak: 12),
    Habit(name: 'Read 30 Minutes', category: 'Learning', icon: Icons.menu_book, streak: 7),
    Habit(name: 'Exercise', category: 'Health', icon: Icons.fitness_center, streak: 5),
    Habit(name: 'Drink 8 Glasses', category: 'Health', icon: Icons.water_drop, streak: 20),
    Habit(name: 'Journal Entry', category: 'Wellness', icon: Icons.edit_note, streak: 3),
    Habit(name: 'No Social Media', category: 'Productivity', icon: Icons.phone_disabled, streak: 0),
    Habit(name: 'Practice Coding', category: 'Learning', icon: Icons.code, streak: 15),
    Habit(name: 'Sleep by 11 PM', category: 'Health', icon: Icons.bedtime, streak: 8),
  ];

  int get _completedToday => _habits.where((h) => h.completedToday).length;
  int get _longestStreak => _habits.fold(0, (m, h) => h.streak > m ? h.streak : m);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => HabitStatsPage(habits: _habits))),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTodayTab(),
          _buildAllHabitsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.list), label: 'All Habits'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Habit',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddHabitPage()));
          if (result != null) {
            setState(() => _habits.add(Habit(
              name: result['name']!,
              category: result['category']!,
              icon: Icons.star,
              streak: 0,
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('$_completedToday', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Completed'),
                ]),
                Column(children: [
                  Text('${_habits.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Total'),
                ]),
                Column(children: [
                  Text('$_longestStreak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Best Streak'),
                ]),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _habits.length,
            itemBuilder: (_, i) {
              final habit = _habits[i];
              return CheckboxListTile(
                secondary: Icon(habit.icon),
                title: Text(habit.name),
                subtitle: Text('${habit.category} · ${habit.streak} day streak'),
                value: habit.completedToday,
                onChanged: (v) => setState(() {
                  habit.completedToday = v ?? false;
                  if (habit.completedToday) habit.streak++;
                  else if (habit.streak > 0) habit.streak--;
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllHabitsTab() {
    final categories = <String, List<Habit>>{};
    for (final h in _habits) {
      categories.putIfAbsent(h.category, () => []).add(h);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: categories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...entry.value.map((h) => ListTile(
              leading: Icon(h.icon),
              title: Text(h.name),
              trailing: Chip(label: Text('${h.streak} days')),
            )),
            const Divider(height: 24),
          ],
        );
      }).toList(),
    );
  }
}

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});
  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _nameCtrl = TextEditingController();
  String _category = 'Health';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Habit name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Health', 'Wellness', 'Learning', 'Productivity'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {'name': _nameCtrl.text, 'category': _category});
                  }
                },
                child: const Text('Save Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitStatsPage extends StatelessWidget {
  final List<Habit> habits;
  const HabitStatsPage({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final categories = <String, int>{};
    for (final h in habits) {
      categories[h.category] = (categories[h.category] ?? 0) + 1;
    }
    final totalStreaks = habits.fold<int>(0, (s, h) => s + h.streak);
    final completed = habits.where((h) => h.completedToday).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Total Habits: ${habits.length}'),
                  Text('Completed Today: $completed'),
                  Text('Total Streak Days: $totalStreaks'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('By Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...categories.entries.map((e) => ListTile(
            leading: const Icon(Icons.folder),
            title: Text(e.key),
            trailing: Chip(label: Text('${e.value}')),
          )),
        ],
      ),
    );
  }
}
