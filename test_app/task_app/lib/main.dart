import 'package:flutter/material.dart';

void main() {
  runApp(const TaskApp());
}

enum Priority { high, medium, low }

class Task {
  String name;
  Priority priority;
  String category;
  DateTime? dueDate;
  bool completed;

  Task({
    required this.name,
    this.priority = Priority.medium,
    this.category = 'Work',
    this.dueDate,
    this.completed = false,
  });
}

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  bool _darkMode = false;

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        darkMode: _darkMode,
        onDarkModeChanged: _toggleDarkMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _notificationsEnabled = true;
  String _searchQuery = '';
  bool _isSearching = false;

  final List<Task> _tasks = [
    Task(
      name: 'Review pull requests',
      priority: Priority.high,
      category: 'Work',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    Task(
      name: 'Buy groceries',
      priority: Priority.medium,
      category: 'Shopping',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Task(
      name: 'Call dentist',
      priority: Priority.low,
      category: 'Personal',
      dueDate: DateTime.now().add(const Duration(days: 5)),
    ),
    Task(
      name: 'Prepare presentation',
      priority: Priority.high,
      category: 'Work',
      dueDate: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  final List<String> _categories = ['Work', 'Personal', 'Shopping'];

  List<Task> get _filteredTasks {
    if (_searchQuery.isEmpty) return _tasks;
    return _tasks
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
  }

  void _toggleTask(int index, List<Task> displayList) {
    setState(() {
      displayList[index].completed = !displayList[index].completed;
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void _showAddTaskDialog() {
    String taskName = '';
    Priority selectedPriority = Priority.medium;
    String selectedCategory = 'Work';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        taskName = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Priority>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: Priority.high,
                          child: Text('High'),
                        ),
                        DropdownMenuItem(
                          value: Priority.medium,
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: Priority.low,
                          child: Text('Low'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPriority = value ?? Priority.medium;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value ?? 'Work';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        selectedDate != null
                            ? 'Due: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                            : 'Pick Due Date',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (taskName.trim().isNotEmpty) {
                      _addTask(Task(
                        name: taskName.trim(),
                        priority: selectedPriority,
                        category: selectedCategory,
                        dueDate: selectedDate,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          darkMode: widget.darkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          notificationsEnabled: _notificationsEnabled,
          onNotificationsChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey('${task.name}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteTask(task),
          child: ListTile(
            leading: Checkbox(
              value: task.completed,
              onChanged: (_) => _toggleTask(
                _tasks.indexOf(task),
                _tasks,
              ),
            ),
            title: Text(
              task.name,
              style: TextStyle(
                decoration:
                    task.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${task.category} - ${_priorityLabel(task.priority)}'
              '${task.dueDate != null ? ' - Due: ${task.dueDate!.month}/${task.dueDate!.day}' : ''}',
            ),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: _priorityColor(task.priority),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllTasksTab() {
    final tasks = _filteredTasks;
    return _buildTaskList(tasks);
  }

  Widget _buildCategoriesTab() {
    return ListView(
      children: _categories.map((category) {
        final categoryTasks =
            _tasks.where((t) => t.category == category).toList();
        return ExpansionTile(
          title: Text(category),
          subtitle: Text('${categoryTasks.length} tasks'),
          leading: Icon(
            category == 'Work'
                ? Icons.work
                : category == 'Personal'
                    ? Icons.person
                    : Icons.shopping_cart,
          ),
          children: categoryTasks.map((task) {
            return ListTile(
              leading: Checkbox(
                value: task.completed,
                onChanged: (_) {
                  setState(() {
                    task.completed = !task.completed;
                  });
                },
              ),
              title: Text(
                task.name,
                style: TextStyle(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(_priorityLabel(task.priority)),
              trailing: Icon(
                Icons.circle,
                size: 12,
                color: _priorityColor(task.priority),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'settings') {
                _openSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _currentTab == 0 ? _buildAllTasksTab() : _buildCategoriesTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'All Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable task reminders'),
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App information'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Task Manager',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A simple task management app.',
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Manage your daily tasks with priorities, '
                      'categories, and due dates.',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
