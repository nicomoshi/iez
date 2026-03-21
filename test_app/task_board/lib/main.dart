import 'package:flutter/material.dart';

void main() {
  runApp(const TaskBoardApp());
}

class Task {
  final int id;
  String title;
  String description;
  String priority;
  String status;
  String dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
  });
}

final List<Task> _sampleTasks = [
  Task(
    id: 1,
    title: 'Design new logo',
    description: 'Create a modern logo for the rebrand.',
    priority: 'High',
    status: 'To Do',
    dueDate: '2026-03-25',
  ),
  Task(
    id: 2,
    title: 'Fix login bug',
    description: 'Users cannot log in on iOS 17.',
    priority: 'High',
    status: 'In Progress',
    dueDate: '2026-03-22',
  ),
  Task(
    id: 3,
    title: 'Write unit tests',
    description: 'Add tests for the auth module.',
    priority: 'Medium',
    status: 'To Do',
    dueDate: '2026-03-28',
  ),
  Task(
    id: 4,
    title: 'Update dependencies',
    description: 'Upgrade Flutter to latest stable.',
    priority: 'Low',
    status: 'Done',
    dueDate: '2026-03-20',
  ),
  Task(
    id: 5,
    title: 'Deploy to staging',
    description: 'Push latest build to staging environment.',
    priority: 'Medium',
    status: 'In Progress',
    dueDate: '2026-03-23',
  ),
  Task(
    id: 6,
    title: 'User research',
    description: 'Conduct 5 user interviews for feedback.',
    priority: 'Low',
    status: 'Done',
    dueDate: '2026-03-18',
  ),
  Task(
    id: 7,
    title: 'Implement dark mode',
    description: 'Add dark theme support throughout the app.',
    priority: 'Medium',
    status: 'To Do',
    dueDate: '2026-04-01',
  ),
];

class TaskBoardApp extends StatelessWidget {
  const TaskBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Board',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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
  final List<Task> _tasks = List.from(_sampleTasks);
  bool _showCompleted = true;
  String _sortBy = 'priority';

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
  }

  void _updateTask(Task task) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Board'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SettingsBottomSheet(
                  showCompleted: _showCompleted,
                  sortBy: _sortBy,
                  onShowCompletedChanged: (val) {
                    setState(() => _showCompleted = val);
                  },
                  onSortByChanged: (val) {
                    setState(() => _sortBy = val);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: KanbanBoard(
        tasks: _tasks,
        showCompleted: _showCompleted,
        sortBy: _sortBy,
        onTaskUpdated: _updateTask,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskPage(nextId: _tasks.length + 1),
            ),
          );
          if (newTask != null) {
            _addTask(newTask);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class KanbanBoard extends StatelessWidget {
  final List<Task> tasks;
  final bool showCompleted;
  final String sortBy;
  final ValueChanged<Task> onTaskUpdated;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.showCompleted,
    required this.sortBy,
    required this.onTaskUpdated,
  });

  List<Task> _filterAndSort(String status) {
    var filtered = tasks.where((t) => t.status == status).toList();
    if (!showCompleted && status == 'Done') return [];

    if (sortBy == 'priority') {
      const order = {'High': 0, 'Medium': 1, 'Low': 2};
      filtered.sort((a, b) =>
          (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3));
    } else if (sortBy == 'dueDate') {
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final columns = ['To Do', 'In Progress', 'Done'];
    return PageView(
      children: columns.map((status) {
        final columnTasks = _filterAndSort(status);
        return KanbanColumn(
          title: status,
          tasks: columnTasks,
          onTaskUpdated: onTaskUpdated,
        );
      }).toList(),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final ValueChanged<Task> onTaskUpdated;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.onTaskUpdated,
  });

  Color get _headerColor {
    switch (title) {
      case 'To Do':
        return Colors.blue.shade100;
      case 'In Progress':
        return Colors.orange.shade100;
      case 'Done':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _headerColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white70,
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return TaskCard(
                          task: tasks[index],
                          onUpdated: onTaskUpdated,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<Task> onUpdated;

  const TaskCard({super.key, required this.task, required this.onUpdated});

  Color get _priorityColor {
    switch (task.priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailPage(task: task, onUpdated: onUpdated),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Chip(
                    label: Text(
                      task.priority,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: _priorityColor.withOpacity(0.15),
                    side: BorderSide(color: _priorityColor),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                task.description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final ValueChanged<Task> onUpdated;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.onUpdated,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late String _status;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _status = widget.task.status;
    _priority = widget.task.priority;
  }

  Color get _priorityColor {
    switch (_priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              widget.task.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 20),
                        const SizedBox(width: 8),
                        const Text('Priority'),
                        const Spacer(),
                        Chip(
                          label: Text(_priority),
                          backgroundColor: _priorityColor.withOpacity(0.15),
                          side: BorderSide(color: _priorityColor),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz, size: 20),
                        const SizedBox(width: 8),
                        const Text('Status'),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _status,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: 'To Do', child: Text('To Do')),
                            DropdownMenuItem(
                                value: 'In Progress',
                                child: Text('In Progress')),
                            DropdownMenuItem(
                                value: 'Done', child: Text('Done')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _status = val!;
                              widget.task.status = val;
                              widget.onUpdated(widget.task);
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        const Text('Due Date'),
                        const Spacer(),
                        Text(
                          widget.task.dueDate,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final int nextId;

  const AddTaskPage({super.key, required this.nextId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'Medium';
  String _status = 'To Do';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.nextId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        status: _status,
        dueDate: '2026-04-01',
      );
      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (val) {
                  setState(() => _priority = val!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: const [
                  DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                  DropdownMenuItem(
                      value: 'In Progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'Done', child: Text('Done')),
                ],
                onChanged: (val) {
                  setState(() => _status = val!);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsBottomSheet extends StatelessWidget {
  final bool showCompleted;
  final String sortBy;
  final ValueChanged<bool> onShowCompletedChanged;
  final ValueChanged<String> onSortByChanged;

  const SettingsBottomSheet({
    super.key,
    required this.showCompleted,
    required this.sortBy,
    required this.onShowCompletedChanged,
    required this.onSortByChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool localShowCompleted = showCompleted;
        String localSortBy = sortBy;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show completed tasks'),
                subtitle: const Text('Display tasks in the Done column'),
                value: localShowCompleted,
                onChanged: (val) {
                  setLocalState(() => localShowCompleted = val);
                  onShowCompletedChanged(val);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              RadioListTile<String>(
                title: const Text('Priority'),
                value: 'priority',
                groupValue: localSortBy,
                onChanged: (val) {
                  setLocalState(() => localSortBy = val!);
                  onSortByChanged(val!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Due Date'),
                value: 'dueDate',
                groupValue: localSortBy,
                onChanged: (val) {
                  setLocalState(() => localSortBy = val!);
                  onSortByChanged(val!);
                },
              ),
              RadioListTile<String>(
                title: const Text('Title'),
                value: 'title',
                groupValue: localSortBy,
                onChanged: (val) {
                  setLocalState(() => localSortBy = val!);
                  onSortByChanged(val!);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
