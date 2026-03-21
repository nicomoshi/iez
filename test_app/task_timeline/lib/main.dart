import 'package:flutter/material.dart';

void main() => runApp(const TaskTimelineApp());

class TaskTimelineApp extends StatelessWidget {
  const TaskTimelineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Timeline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const TaskHome(),
    );
  }
}

class Task {
  final String title;
  final String description;
  final String deadline;
  final String priority; // High, Medium, Low
  bool completed;
  Task({
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.completed = false,
  });
}

class TaskHome extends StatefulWidget {
  const TaskHome({super.key});
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  String _filter = 'All';
  final List<Task> _tasks = [
    Task(title: 'Design Review', description: 'Review new UI mockups', deadline: 'Mar 22', priority: 'High'),
    Task(title: 'API Integration', description: 'Connect user service endpoints', deadline: 'Mar 24', priority: 'High'),
    Task(title: 'Write Tests', description: 'Unit tests for auth module', deadline: 'Mar 25', priority: 'Medium'),
    Task(title: 'Update Docs', description: 'API documentation refresh', deadline: 'Mar 26', priority: 'Low'),
    Task(title: 'Code Review', description: 'Review PR #42 and #43', deadline: 'Mar 23', priority: 'Medium'),
    Task(title: 'Deploy Staging', description: 'Push v2.1 to staging env', deadline: 'Mar 27', priority: 'High'),
    Task(title: 'Team Standup', description: 'Daily sync with team', deadline: 'Mar 22', priority: 'Low'),
    Task(title: 'Bug Fix', description: 'Fix login timeout issue', deadline: 'Mar 23', priority: 'High'),
  ];

  List<Task> get _filtered {
    if (_filter == 'All') return _tasks;
    if (_filter == 'Done') return _tasks.where((t) => t.completed).toList();
    if (_filter == 'Pending') return _tasks.where((t) => !t.completed).toList();
    return _tasks.where((t) => t.priority == _filter).toList();
  }

  int get _completedCount => _tasks.where((t) => t.completed).length;
  int get _highCount => _tasks.where((t) => t.priority == 'High' && !t.completed).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Overview',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => OverviewPage(tasks: _tasks))),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('${_tasks.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Total'),
                  ]),
                  Column(children: [
                    Text('$_completedCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Done'),
                  ]),
                  Column(children: [
                    Text('$_highCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                    const Text('Urgent'),
                  ]),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['All', 'High', 'Medium', 'Low', 'Done', 'Pending'].map((f) => Padding(
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
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final task = _filtered[i];
                      return CheckboxListTile(
                        title: Text(task.title,
                            style: TextStyle(decoration: task.completed ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${task.priority} · ${task.deadline}'),
                        secondary: Icon(
                          _priorityIcon(task.priority),
                          color: _priorityColor(task.priority),
                        ),
                        value: task.completed,
                        onChanged: (v) => setState(() => task.completed = v ?? false),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Task',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddTaskPage()));
          if (result != null) {
            setState(() => _tasks.add(Task(
              title: result['title']!,
              description: result['description']!,
              deadline: result['deadline'] ?? 'Mar 28',
              priority: result['priority']!,
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'High': return Icons.priority_high;
      case 'Medium': return Icons.remove;
      case 'Low': return Icons.arrow_downward;
      default: return Icons.circle;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});
  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['High', 'Medium', 'Low'].map((p) =>
                  DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'title': _titleCtrl.text,
                      'description': _descCtrl.text,
                      'priority': _priority,
                    });
                  }
                },
                child: const Text('Save Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  final List<Task> tasks;
  const OverviewPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final byPriority = <String, int>{};
    for (final t in tasks) {
      byPriority[t.priority] = (byPriority[t.priority] ?? 0) + 1;
    }
    final completed = tasks.where((t) => t.completed).length;
    final pending = tasks.length - completed;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Overview')),
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
                  Text('Total Tasks: ${tasks.length}'),
                  Text('Completed: $completed'),
                  Text('Pending: $pending'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('By Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...['High', 'Medium', 'Low'].map((p) => ListTile(
            leading: Icon(Icons.circle, color: p == 'High' ? Colors.red : p == 'Medium' ? Colors.orange : Colors.green),
            title: Text(p),
            trailing: Chip(label: Text('${byPriority[p] ?? 0}')),
          )),
        ],
      ),
    );
  }
}
