import 'package:flutter/material.dart';

void main() => runApp(const TaskManagerApp());

// --- Data Model ---

enum Priority { low, medium, high, urgent }

extension PriorityExt on Priority {
  String get label {
    switch (this) {
      case Priority.low: return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high: return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low: return Colors.green;
      case Priority.medium: return Colors.orange;
      case Priority.high: return Colors.red;
      case Priority.urgent: return Colors.purple;
    }
  }
}

enum TaskStatus { todo, inProgress, done }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo: return 'To Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done: return 'Done';
    }
  }
}

class Task {
  final String id;
  String title;
  String description;
  Priority priority;
  TaskStatus status;
  String category;
  DateTime dueDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.priority,
    required this.status,
    required this.category,
    required this.dueDate,
    required this.createdAt,
  });

  bool get isOverdue => status != TaskStatus.done && dueDate.isBefore(DateTime.now());
}

// --- App State ---

class TaskStore extends ChangeNotifier {
  final List<Task> _tasks = _seedTasks();
  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health', 'Learning'];

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<String> get categories => List.unmodifiable(_categories);

  List<Task> byStatus(TaskStatus s) => _tasks.where((t) => t.status == s).toList();

  void add(Task t) {
    _tasks.insert(0, t);
    notifyListeners();
  }

  void remove(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void updateStatus(String id, TaskStatus status) {
    _tasks.firstWhere((t) => t.id == id).status = status;
    notifyListeners();
  }

  void addCategory(String c) {
    if (!_categories.contains(c)) {
      _categories.add(c);
      notifyListeners();
    }
  }

  static List<Task> _seedTasks() {
    return [
      Task(id: '1', title: 'Review quarterly report', description: 'Go through Q1 numbers and prepare summary.',
          priority: Priority.high, status: TaskStatus.inProgress, category: 'Work',
          dueDate: DateTime(2026, 3, 25), createdAt: DateTime(2026, 3, 18)),
      Task(id: '2', title: 'Buy groceries', description: 'Milk, eggs, bread, vegetables.',
          priority: Priority.medium, status: TaskStatus.todo, category: 'Shopping',
          dueDate: DateTime(2026, 3, 23), createdAt: DateTime(2026, 3, 20)),
      Task(id: '3', title: 'Morning jog', description: '30 minute run in the park.',
          priority: Priority.low, status: TaskStatus.done, category: 'Health',
          dueDate: DateTime(2026, 3, 22), createdAt: DateTime(2026, 3, 21)),
      Task(id: '4', title: 'Prepare presentation', description: 'Slides for Monday team meeting.',
          priority: Priority.urgent, status: TaskStatus.todo, category: 'Work',
          dueDate: DateTime(2026, 3, 24), createdAt: DateTime(2026, 3, 19)),
      Task(id: '5', title: 'Read Flutter docs', description: 'New material 3 widgets and animations.',
          priority: Priority.low, status: TaskStatus.inProgress, category: 'Learning',
          dueDate: DateTime(2026, 3, 28), createdAt: DateTime(2026, 3, 15)),
      Task(id: '6', title: 'Call dentist', description: 'Schedule annual checkup.',
          priority: Priority.medium, status: TaskStatus.todo, category: 'Personal',
          dueDate: DateTime(2026, 3, 26), createdAt: DateTime(2026, 3, 20)),
    ];
  }
}

final TaskStore _globalStore = TaskStore();

// --- App Root ---

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: MainScreen(store: _globalStore),
    );
  }
}

// --- Main Screen with Tabs ---

class MainScreen extends StatefulWidget {
  final TaskStore store;
  const MainScreen({super.key, required this.store});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(tooltip: 'Overview', icon: const Icon(Icons.pie_chart), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OverviewPage(store: widget.store)));
          }),
          IconButton(tooltip: 'Categories', icon: const Icon(Icons.category), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesPage(store: widget.store)));
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To Do'),
            Tab(text: 'In Progress'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(TaskStatus.todo),
          _buildList(TaskStatus.inProgress),
          _buildList(TaskStatus.done),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(TaskStatus status) {
    final tasks = widget.store.byStatus(status);
    if (tasks.isEmpty) return const Center(child: Text('No tasks here.'));
    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Card(
          child: ListTile(
            title: Text(t.title, style: t.isOverdue ? const TextStyle(color: Colors.red) : null),
            subtitle: Text('${t.category} • ${t.priority.label}'),
            leading: CircleAvatar(backgroundColor: t.priority.color, radius: 8),
            trailing: t.isOverdue ? const Icon(Icons.warning, color: Colors.red, size: 20) : null,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TaskDetailPage(task: t, store: widget.store))),
          ),
        );
      },
    );
  }
}

// --- Task Detail Page ---

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final TaskStore store;
  const TaskDetailPage({super.key, required this.task, required this.store});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(children: [
              Chip(label: Text(t.priority.label), backgroundColor: t.priority.color.withValues(alpha: 0.2)),
              const SizedBox(width: 8),
              Chip(label: Text(t.status.label)),
              const SizedBox(width: 8),
              Chip(label: Text(t.category)),
            ]),
            const SizedBox(height: 12),
            Text('Due: ${t.dueDate.month}/${t.dueDate.day}/${t.dueDate.year}',
                style: TextStyle(color: t.isOverdue ? Colors.red : null, fontSize: 16)),
            if (t.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(t.description),
            ],
            const SizedBox(height: 24),
            Text('Change Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((s) => ChoiceChip(
                label: Text(s.label),
                selected: t.status == s,
                onSelected: (_) {
                  widget.store.updateStatus(t.id, s);
                  setState(() {});
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { widget.store.remove(t.id); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError),
                child: const Text('Delete Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Task Page ---

class AddTaskPage extends StatefulWidget {
  final TaskStore store;
  const AddTaskPage({super.key, required this.store});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  Priority _priority = Priority.medium;
  String _category = 'Work';

  @override
  void dispose() {
    _titleCtl.dispose(); _descCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.add(Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtl.text.trim(),
      description: _descCtl.text.trim(),
      priority: _priority,
      status: TaskStatus.todo,
      category: _category,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _titleCtl,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtl,
                  decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (v) { if (v != null) setState(() => _priority = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.store.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setState(() => _category = v); },
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Save Task'))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Overview Page ---

class OverviewPage extends StatelessWidget {
  final TaskStore store;
  const OverviewPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final tasks = store.tasks;
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final overdue = tasks.where((t) => t.isOverdue).length;

    final priorityCounts = <String, int>{};
    for (final t in tasks) {
      priorityCounts[t.priority.label] = (priorityCounts[t.priority.label] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Total Tasks'), trailing: Text('${tasks.length}')),
          ListTile(title: const Text('To Do'), trailing: Text('$todo')),
          ListTile(title: const Text('In Progress'), trailing: Text('$inProgress')),
          ListTile(title: const Text('Done'), trailing: Text('$done')),
          ListTile(title: const Text('Overdue'), trailing: Text('$overdue',
              style: const TextStyle(color: Colors.red))),
          const Divider(),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('By Priority', style: Theme.of(context).textTheme.titleMedium)),
          ...priorityCounts.entries.map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}'))),
        ],
      ),
    );
  }
}

// --- Categories Page ---

class CategoriesPage extends StatefulWidget {
  final TaskStore store;
  const CategoriesPage({super.key, required this.store});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cats = widget.store.categories;
    final tasks = widget.store.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {
            _showAddCategory(context);
          }),
        ],
      ),
      body: ListView.builder(
        itemCount: cats.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final cat = cats[index];
          final count = tasks.where((t) => t.category == cat).length;
          return Card(
            child: ListTile(
              title: Text(cat),
              trailing: Text('$count tasks', style: Theme.of(context).textTheme.bodyMedium),
            ),
          );
        },
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: ctl, decoration: const InputDecoration(labelText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (ctl.text.trim().isNotEmpty) {
              widget.store.addCategory(ctl.text.trim());
            }
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }
}
