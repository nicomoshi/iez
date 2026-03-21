import 'package:flutter/material.dart';
void main() => runApp(const App61());
class App61 extends StatelessWidget {
  const App61({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskBoard',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const TaskBoardHome(),
    );
  }
}
class TaskBoardHome extends StatefulWidget {
  const TaskBoardHome({super.key});
  @override
  State<TaskBoardHome> createState() => _TaskBoardHomeState();
}
class _TaskBoardHomeState extends State<TaskBoardHome> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Buy groceries', 'category': 'Personal', 'done': false},
    {'title': 'Fix login bug', 'category': 'Work', 'done': false},
    {'title': 'Write tests', 'category': 'Work', 'done': true},
    {'title': 'Call dentist', 'category': 'Personal', 'done': false},
    {'title': 'Deploy v2', 'category': 'Work', 'done': false},
  ];
  final Set<String> _selectedFilters = {};
  String _searchQuery = '';
  List<Map<String, dynamic>> get _filteredTasks {
    return _tasks.where((t) {
      final matchesFilter = _selectedFilters.isEmpty || _selectedFilters.contains(t['category']);
      final matchesSearch = _searchQuery.isEmpty || (t['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }
  void _addTask(String title, String category) {
    setState(() => _tasks.add({'title': title, 'category': category, 'done': false}));
  }
  void _showAddSheet() {
    String newTitle = '';
    String newCategory = 'Personal';
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: StatefulBuilder(builder: (ctx, setSheetState) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Task', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(labelText: 'Task Title'), onChanged: (v) => newTitle = v),
          const SizedBox(height: 12),
          Row(children: [
            ChoiceChip(label: const Text('Personal'), selected: newCategory == 'Personal',
              onSelected: (_) => setSheetState(() => newCategory = 'Personal')),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Work'), selected: newCategory == 'Work',
              onSelected: (_) => setSheetState(() => newCategory = 'Work')),
          ]),
          const SizedBox(height: 16),
          FilledButton(onPressed: () { if (newTitle.isNotEmpty) { _addTask(newTitle, newCategory); Navigator.pop(ctx); } },
            child: const Text('Add')),
          const SizedBox(height: 16),
        ])),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final workCount = _tasks.where((t) => t['category'] == 'Work').length;
    final personalCount = _tasks.where((t) => t['category'] == 'Personal').length;
    return Scaffold(
      appBar: AppBar(title: const Text('TaskBoard')),
      floatingActionButton: FloatingActionButton(onPressed: _showAddSheet, child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          decoration: const InputDecoration(labelText: 'Search', prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          FilterChip(label: Text('Work ($workCount)'), selected: _selectedFilters.contains('Work'),
            onSelected: (v) => setState(() { v ? _selectedFilters.add('Work') : _selectedFilters.remove('Work'); })),
          const SizedBox(width: 8),
          FilterChip(label: Text('Personal ($personalCount)'), selected: _selectedFilters.contains('Personal'),
            onSelected: (v) => setState(() { v ? _selectedFilters.add('Personal') : _selectedFilters.remove('Personal'); })),
        ])),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('${filtered.length} tasks', style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (ctx, i) {
          final task = filtered[i];
          return Dismissible(
            key: ValueKey(task['title']),
            background: Container(color: Colors.red, alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              setState(() => _tasks.remove(task));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${task['title']}"')));
            },
            child: ExpansionTile(
              leading: Checkbox(value: task['done'] as bool, onChanged: (v) => setState(() => task['done'] = v)),
              title: Text(task['title'] as String,
                style: TextStyle(decoration: (task['done'] as bool) ? TextDecoration.lineThrough : null)),
              subtitle: Text(task['category'] as String),
              children: [Padding(padding: const EdgeInsets.all(16),
                child: Text('Category: ${task['category']}\nStatus: ${task['done'] ? "Done" : "Pending"}'))],
            ),
          );
        })),
      ]),
    );
  }
}
