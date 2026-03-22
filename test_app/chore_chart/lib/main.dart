import 'package:flutter/material.dart';

void main() {
  runApp(const ChoreChartApp());
}

// --- Data Models ---

enum ChoreFrequency { daily, weekly, monthly }

extension ChoreFrequencyLabel on ChoreFrequency {
  String get label {
    switch (this) {
      case ChoreFrequency.daily: return 'Daily';
      case ChoreFrequency.weekly: return 'Weekly';
      case ChoreFrequency.monthly: return 'Monthly';
    }
  }
}

class Chore {
  final String id;
  final String name;
  final String assignee;
  final ChoreFrequency frequency;
  final String room;
  final bool isCompleted;
  final int points;

  Chore({
    required this.id,
    required this.name,
    required this.assignee,
    required this.frequency,
    required this.room,
    this.isCompleted = false,
    this.points = 10,
  });

  Chore copyWith({bool? isCompleted}) => Chore(
    id: id, name: name, assignee: assignee, frequency: frequency,
    room: room, isCompleted: isCompleted ?? this.isCompleted, points: points,
  );
}

class FamilyMember {
  final String name;
  final String avatar;
  int totalPoints;

  FamilyMember({required this.name, required this.avatar, this.totalPoints = 0});
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<FamilyMember> _members = [
    FamilyMember(name: 'Mom', avatar: '👩'),
    FamilyMember(name: 'Dad', avatar: '👨'),
    FamilyMember(name: 'Alex', avatar: '🧒'),
    FamilyMember(name: 'Sam', avatar: '👧'),
  ];

  final List<Chore> _chores = [
    Chore(id: '1', name: 'Wash Dishes', assignee: 'Alex', frequency: ChoreFrequency.daily, room: 'Kitchen', points: 10),
    Chore(id: '2', name: 'Vacuum Living Room', assignee: 'Dad', frequency: ChoreFrequency.weekly, room: 'Living Room', points: 20),
    Chore(id: '3', name: 'Take Out Trash', assignee: 'Sam', frequency: ChoreFrequency.daily, room: 'Kitchen', points: 5),
    Chore(id: '4', name: 'Clean Bathroom', assignee: 'Mom', frequency: ChoreFrequency.weekly, room: 'Bathroom', points: 25),
    Chore(id: '5', name: 'Mow Lawn', assignee: 'Dad', frequency: ChoreFrequency.monthly, room: 'Yard', points: 30),
    Chore(id: '6', name: 'Make Bed', assignee: 'Alex', frequency: ChoreFrequency.daily, room: 'Bedroom', points: 5),
    Chore(id: '7', name: 'Feed Pets', assignee: 'Sam', frequency: ChoreFrequency.daily, room: 'Kitchen', points: 10),
    Chore(id: '8', name: 'Dust Shelves', assignee: 'Mom', frequency: ChoreFrequency.weekly, room: 'Living Room', points: 15),
  ];

  List<FamilyMember> get members => List.unmodifiable(_members);
  List<Chore> get chores => List.unmodifiable(_chores);

  List<Chore> choresFor(String assignee) => _chores.where((c) => c.assignee == assignee).toList();
  int completedCount() => _chores.where((c) => c.isCompleted).length;
  int pendingCount() => _chores.where((c) => !c.isCompleted).length;

  void toggleChore(String id) {
    final idx = _chores.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final chore = _chores[idx];
      _chores[idx] = chore.copyWith(isCompleted: !chore.isCompleted);
      if (_chores[idx].isCompleted) {
        final member = _members.firstWhere((m) => m.name == chore.assignee);
        member.totalPoints += chore.points;
      } else {
        final member = _members.firstWhere((m) => m.name == chore.assignee);
        member.totalPoints -= chore.points;
      }
      notifyListeners();
    }
  }

  void addChore(Chore chore) {
    _chores.add(chore);
    notifyListeners();
  }

  void addMember(FamilyMember member) {
    _members.add(member);
    notifyListeners();
  }
}

// --- App ---

class ChoreChartApp extends StatefulWidget {
  const ChoreChartApp({super.key});

  @override
  State<ChoreChartApp> createState() => _ChoreChartAppState();
}

class _ChoreChartAppState extends State<ChoreChartApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chore Chart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
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
      ChoresPage(state: widget.state),
      MembersPage(state: widget.state),
      LeaderboardPage(state: widget.state),
      SettingsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Chores'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Family'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Points'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// --- Chores Page ---

class ChoresPage extends StatelessWidget {
  final AppState state;
  const ChoresPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chore Chart'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('${state.completedCount()}/${state.chores.length} done', style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.chores.length,
        itemBuilder: (context, index) {
          final chore = state.chores[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              value: chore.isCompleted,
              onChanged: (_) => state.toggleChore(chore.id),
              title: Text(chore.name, style: TextStyle(decoration: chore.isCompleted ? TextDecoration.lineThrough : null)),
              subtitle: Text('${chore.assignee} · ${chore.room} · ${chore.frequency.label}'),
              secondary: Text('${chore.points}pts', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChoreDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Chore'),
      ),
    );
  }

  void _showAddChoreDialog(BuildContext context) {
    final nameController = TextEditingController();
    final roomController = TextEditingController();
    String assignee = state.members.first.name;
    ChoreFrequency frequency = ChoreFrequency.daily;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Chore'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Chore Name')),
              const SizedBox(height: 12),
              TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Room')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: assignee,
                decoration: const InputDecoration(labelText: 'Assign To'),
                items: state.members.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))).toList(),
                onChanged: (v) => assignee = v ?? assignee,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ChoreFrequency>(
                value: frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: ChoreFrequency.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
                onChanged: (v) => frequency = v ?? frequency,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                state.addChore(Chore(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  assignee: assignee,
                  frequency: frequency,
                  room: roomController.text.isNotEmpty ? roomController.text : 'General',
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// --- Members Page ---

class MembersPage extends StatelessWidget {
  final AppState state;
  const MembersPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.members.length,
        itemBuilder: (context, index) {
          final member = state.members[index];
          final memberChores = state.choresFor(member.name);
          final completed = memberChores.where((c) => c.isCompleted).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text(member.avatar, style: const TextStyle(fontSize: 24))),
              title: Text(member.name),
              subtitle: Text('$completed/${memberChores.length} chores done · ${member.totalPoints} pts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailPage(state: state, member: member))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Family Member'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                state.addMember(FamilyMember(name: nameController.text, avatar: '🙂'));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// --- Member Detail Page ---

class MemberDetailPage extends StatelessWidget {
  final AppState state;
  final FamilyMember member;
  const MemberDetailPage({super.key, required this.state, required this.member});

  @override
  Widget build(BuildContext context) {
    final memberChores = state.choresFor(member.name);
    return Scaffold(
      appBar: AppBar(title: Text(member.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [Text('${member.totalPoints}', style: Theme.of(context).textTheme.headlineMedium), const Text('Points')]),
                    Column(children: [Text('${memberChores.length}', style: Theme.of(context).textTheme.headlineMedium), const Text('Chores')]),
                    Column(children: [Text('${memberChores.where((c) => c.isCompleted).length}', style: Theme.of(context).textTheme.headlineMedium), const Text('Done')]),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: memberChores.length,
              itemBuilder: (context, index) {
                final chore = memberChores[index];
                return CheckboxListTile(
                  value: chore.isCompleted,
                  onChanged: (_) => state.toggleChore(chore.id),
                  title: Text(chore.name),
                  subtitle: Text('${chore.room} · ${chore.frequency.label} · ${chore.points}pts'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Leaderboard Page ---

class LeaderboardPage extends StatelessWidget {
  final AppState state;
  const LeaderboardPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sorted = List<FamilyMember>.from(state.members)..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Household Progress', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${state.completedCount()} of ${state.chores.length} chores completed'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: state.chores.isEmpty ? 0 : state.completedCount() / state.chores.length),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rankings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...sorted.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final member = entry.value;
            final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '  ';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(medal, style: const TextStyle(fontSize: 24)),
                title: Text(member.name),
                trailing: Text('${member.totalPoints} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }),
        ],
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
            title: const Text('Reset All Chores'),
            subtitle: const Text('Mark all chores as incomplete'),
            leading: const Icon(Icons.refresh),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Chores'),
                content: const Text('Are you sure you want to reset all chores?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reset')),
                ],
              ),
            ),
          ),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Chore reminders'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Chore Chart v1.0'),
            leading: const Icon(Icons.info),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About'),
                content: const Text('Chore Chart helps families organize and track household chores. Assign tasks, earn points, and see who leads!'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
